const crypto = require('crypto');
const { execFile } = require('child_process');
const util = require('util');
const {
  ListObjectsV2Command,
  HeadObjectCommand,
  GetObjectCommand,
  CopyObjectCommand,
} = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const s3 = require('../config/s3');
const razorpay = require('../config/razorpay');
const prisma = require('../config/prisma');

const execFileAsync = util.promisify(execFile);

const PRESIGNED_URL_EXPIRY_SECONDS = 600; // 10 minutes
const PREFIX = 'course-videos/';

// The `id` handed to the client is the S3 key itself, opaque-encoded — never
// the raw key, and never trusted back from the client without re-validating
// it still lives under course-videos/ before using it in any S3 call.
function encodeId(key) {
  return Buffer.from(key, 'utf8').toString('base64url');
}

function decodeId(id) {
  try {
    return Buffer.from(id, 'base64url').toString('utf8');
  } catch {
    return null;
  }
}

// Reads just enough of the remote file (via a short-lived presigned URL) to
// get its duration — ffprobe doesn't need to download the whole video.
async function probeDurationMinutes(url) {
  try {
    const { stdout } = await execFileAsync(
      'ffprobe',
      ['-v', 'quiet', '-show_entries', 'format=duration', '-of', 'csv=p=0', url],
      { timeout: 30000 }
    );
    const seconds = parseFloat(stdout.trim());
    if (!Number.isFinite(seconds) || seconds <= 0) return null;
    return Math.max(1, Math.round(seconds / 60));
  } catch (err) {
    console.error('ffprobe failed:', err.message);
    return null;
  }
}

// Rewrites the object's metadata in place (S3 copy-to-self with
// MetadataDirective REPLACE — this does not re-transfer the file content)
// so we only ever have to probe a given video once.
async function backfillDurationMetadata(key, existingMeta, durationMinutes) {
  try {
    await s3.send(
      new CopyObjectCommand({
        Bucket: process.env.S3_BUCKET_NAME,
        CopySource: `${process.env.S3_BUCKET_NAME}/${encodeURIComponent(key)}`,
        Key: key,
        Metadata: { ...existingMeta, durationminutes: String(durationMinutes) },
        MetadataDirective: 'REPLACE',
      })
    );
  } catch (err) {
    console.error('Backfill duration metadata failed:', err.message);
  }
}

async function listCourseVideos(req, res) {
  try {
    const { comn_enrol_no } = req.user;

    const [listing, purchases] = await Promise.all([
      s3.send(new ListObjectsV2Command({ Bucket: process.env.S3_BUCKET_NAME, Prefix: PREFIX })),
      prisma.courseVideoPurchase.findMany({
        where: { comn_enrol_no },
        select: { video_key: true },
      }),
    ]);

    const purchasedKeys = new Set(purchases.map((p) => p.video_key));
    const objects = (listing.Contents || []).filter((obj) => obj.Key && obj.Key !== PREFIX);

    const videos = await Promise.all(
      objects.map(async (obj) => {
        const head = await s3.send(
          new HeadObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: obj.Key })
        );
        const meta = head.Metadata || {};

        const title = meta.title ? decodeURIComponent(meta.title) : obj.Key.slice(PREFIX.length);
        const price = meta.price ?? null;
        const createdAt = meta.createdat || obj.LastModified;

        let durationMinutes = meta.durationminutes ? parseInt(meta.durationminutes, 10) : null;
        if (!Number.isFinite(durationMinutes)) {
          durationMinutes = null;
        }

        if (durationMinutes === null) {
          const probeUrl = await getSignedUrl(
            s3,
            new GetObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: obj.Key }),
            { expiresIn: 120 }
          );
          const probed = await probeDurationMinutes(probeUrl);
          if (probed !== null) {
            durationMinutes = probed;
            backfillDurationMetadata(obj.Key, meta, probed); // fire-and-forget
          }
        }

        return {
          id: encodeId(obj.Key),
          title,
          price,
          durationMinutes,
          createdAt,
          purchased: purchasedKeys.has(obj.Key),
        };
      })
    );

    videos.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

    res.status(200).json({ success: true, videos });
  } catch (err) {
    console.error('List course videos error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function createOrder(req, res) {
  try {
    const key = decodeId(req.params.id);
    if (!key || !key.startsWith(PREFIX)) {
      return res.status(404).json({ success: false, error: 'Video not found' });
    }

    const { comn_enrol_no } = req.user;

    const already = await prisma.courseVideoPurchase.findUnique({
      where: { comn_enrol_no_video_key: { comn_enrol_no, video_key: key } },
    });
    if (already) {
      return res.status(400).json({ success: false, error: 'Already purchased' });
    }

    const head = await s3.send(
      new HeadObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: key })
    );
    const meta = head.Metadata || {};
    const price = parseFloat(meta.price);
    if (!Number.isFinite(price) || price <= 0) {
      return res.status(400).json({ success: false, error: 'This video has no valid price set' });
    }

    const amountPaise = Math.round(price * 100);

    const order = await razorpay.orders.create({
      amount: amountPaise,
      currency: 'INR',
      receipt: `cv_${Date.now()}`,
      notes: { comn_enrol_no, video_key: key },
    });

    res.status(200).json({
      success: true,
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: process.env.RAZORPAY_KEY_ID,
      title: meta.title ? decodeURIComponent(meta.title) : null,
    });
  } catch (err) {
    console.error('Create order error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function verifyPayment(req, res) {
  try {
    const key = decodeId(req.params.id);
    if (!key || !key.startsWith(PREFIX)) {
      return res.status(404).json({ success: false, error: 'Video not found' });
    }

    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ success: false, error: 'Missing payment verification fields' });
    }

    // This signature is what actually proves the payment is real and tied
    // to this exact order — never trust a client-reported "success" alone.
    const expectedSignature = crypto
      .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
      .update(`${razorpay_order_id}|${razorpay_payment_id}`)
      .digest('hex');

    if (expectedSignature !== razorpay_signature) {
      return res.status(400).json({ success: false, error: 'Payment verification failed' });
    }

    const order = await razorpay.orders.fetch(razorpay_order_id);
    if (!order || order.notes?.video_key !== key || order.notes?.comn_enrol_no !== req.user.comn_enrol_no) {
      return res.status(400).json({ success: false, error: 'Order does not match this request' });
    }

    await prisma.courseVideoPurchase.upsert({
      where: {
        comn_enrol_no_video_key: { comn_enrol_no: req.user.comn_enrol_no, video_key: key },
      },
      update: {},
      create: {
        comn_enrol_no: req.user.comn_enrol_no,
        video_key: key,
        razorpay_order_id,
        razorpay_payment_id,
        amount: String(order.amount),
      },
    });

    res.status(200).json({ success: true });
  } catch (err) {
    console.error('Verify payment error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

async function getCourseVideoPlayUrl(req, res) {
  try {
    const key = decodeId(req.params.id);
    if (!key || !key.startsWith(PREFIX)) {
      return res.status(404).json({ success: false, error: 'Video not found' });
    }

    const purchase = await prisma.courseVideoPurchase.findUnique({
      where: {
        comn_enrol_no_video_key: { comn_enrol_no: req.user.comn_enrol_no, video_key: key },
      },
    });
    if (!purchase) {
      return res.status(403).json({ success: false, error: 'You have not purchased this video' });
    }

    const url = await getSignedUrl(
      s3,
      new GetObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: key }),
      { expiresIn: PRESIGNED_URL_EXPIRY_SECONDS }
    );

    res.status(200).json({ success: true, url });
  } catch (err) {
    console.error('Get course video play URL error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { listCourseVideos, createOrder, verifyPayment, getCourseVideoPlayUrl };
