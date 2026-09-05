const { S3Client } = require('@aws-sdk/client-s3');

// No explicit credentials — picked up automatically via the EC2 instance's
// attached IAM role (default credential provider chain). Never add a
// static access key/secret here.
const s3 = new S3Client({ region: process.env.AWS_REGION });

module.exports = s3;
