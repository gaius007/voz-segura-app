import * as admin from 'firebase-admin';
import * as dotenv from 'dotenv';
import * as path from 'path';
import * as fs from 'fs';

dotenv.config();

const projectId = process.env.FIREBASE_PROJECT_ID || 'voz-segura---database';
const serviceAccountPathEnv = process.env.FIREBASE_SERVICE_ACCOUNT_KEY;

let initialized = false;

try {
  if (serviceAccountPathEnv) {
    const absolutePath = path.resolve(serviceAccountPathEnv);
    if (fs.existsSync(absolutePath)) {
      console.log(`FirebaseAdmin: ✅ Initializing using service account key at ${absolutePath}`);
      const serviceAccount = JSON.parse(fs.readFileSync(absolutePath, 'utf8'));
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        projectId: projectId,
      });
      initialized = true;
    } else {
      console.warn(`FirebaseAdmin: ⚠️ Service account file specified but NOT found at ${absolutePath}`);
    }
  }

  if (!initialized) {
    // Tenta inicializar com credenciais padrão do ambiente
    console.log(`FirebaseAdmin: 🛡️ Attempting to initialize using Application Default Credentials...`);
    admin.initializeApp({
      projectId: projectId,
    });
    initialized = true;
  }
} catch (error) {
  console.error('FirebaseAdmin Error: ❌ Failed to initialize Firebase Admin SDK:', error);
  console.warn('FirebaseAdmin: ⚠️ Backend is running in DEMO/MOCK mode. Auth token validations and database changes will not connect to Firebase.');
}

const db = initialized ? admin.firestore() : null;
const auth = initialized ? admin.auth() : null;

export { admin, db, auth, initialized };
