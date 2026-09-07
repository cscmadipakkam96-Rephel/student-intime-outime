const { initializeApp, cert } = require('firebase-admin/app');
const { getMessaging } = require('firebase-admin/messaging');
const path = require('path');

// Service account key is a secret credential — never committed, lives only
// on disk (server/firebase-service-account.json, gitignored) or wherever
// FIREBASE_SERVICE_ACCOUNT_PATH points on the deploy host.
const keyPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH
  || path.join(__dirname, '..', 'firebase-service-account.json');

initializeApp({
  credential: cert(require(keyPath)),
});

module.exports = { messaging: getMessaging() };
