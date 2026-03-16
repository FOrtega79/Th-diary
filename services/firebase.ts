import { initializeApp, getApps } from 'firebase/app';
import { initializeAuth, getReactNativePersistence } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';
import AsyncStorage from '@react-native-async-storage/async-storage';

// ─────────────────────────────────────────────────────────────────────────────
// Replace these values with your project's config from:
// Firebase Console → Project Settings → Your apps → SDK setup and configuration
// ─────────────────────────────────────────────────────────────────────────────
const firebaseConfig = {
  apiKey:            'AIzaSyArGKzMokZ4nRTcrMr0akWS-ijk2BcHN2c',
  authDomain:        'th-diary.firebaseapp.com',
  projectId:         'th-diary',
  storageBucket:     'th-diary.appspot.com',
  messagingSenderId: '641148007074',
  appId:             '1:641148007074:ios:f24e2c093fe346b5aa5dfb',
};

// Prevent duplicate initialization (hot reload)
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApps()[0];

// Auth with AsyncStorage persistence (survives app restarts)
export const auth = initializeAuth(app, {
  persistence: getReactNativePersistence(AsyncStorage),
});

export const db      = getFirestore(app);
export const storage = getStorage(app);
