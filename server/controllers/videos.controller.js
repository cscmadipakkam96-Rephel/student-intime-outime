const { ListObjectsV2Command, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const s3 = require('../config/s3');

const PRESIGNED_URL_EXPIRY_SECONDS = 600; // 10 minutes

// Course Admission uploads recordings to videos/<comn_enrol_no>/<filename>.
// The prefix is derived from the authenticated session only — never from a
// request parameter — so a student can never list another student's videos.
async function getMyRecordings(req, res) {
  try {
    const { comn_enrol_no } = req.user;
    const prefix = `videos/${comn_enrol_no}/`;

    const listing = await s3.send(
      new ListObjectsV2Command({
        Bucket: process.env.S3_BUCKET_NAME,
        Prefix: prefix,
      })
    );

    const objects = listing.Contents || [];

    const recordings = await Promise.all(
      objects
        .filter((obj) => obj.Key && obj.Key !== prefix) // skip the "folder" placeholder itself, if any
        .map(async (obj) => {
          const url = await getSignedUrl(
            s3,
            new GetObjectCommand({ Bucket: process.env.S3_BUCKET_NAME, Key: obj.Key }),
            { expiresIn: PRESIGNED_URL_EXPIRY_SECONDS }
          );
          return {
            filename: obj.Key.slice(prefix.length),
            lastModified: obj.LastModified,
            size: obj.Size,
            url,
          };
        })
    );

    recordings.sort((a, b) => new Date(b.lastModified) - new Date(a.lastModified));

    res.status(200).json({ success: true, recordings });
  } catch (err) {
    console.error('Get recordings error:', err);
    res.status(500).json({ success: false, error: 'Internal server error' });
  }
}

module.exports = { getMyRecordings };
