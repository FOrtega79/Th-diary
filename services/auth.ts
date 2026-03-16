import {
  signInWithCredential,
  OAuthProvider,
  GoogleAuthProvider,
  signOut as firebaseSignOut,
  deleteUser,
} from 'firebase/auth';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as Google from 'expo-auth-session/providers/google';
import * as Crypto from 'expo-crypto';
import { auth } from './firebase';

// ─── Apple Sign-In ────────────────────────────────────────────────────────────

export async function signInWithApple(): Promise<void> {
  // Generate a secure nonce
  const rawNonce = Array.from(
    { length: 32 },
    () => Math.random().toString(36)[2]
  ).join('');
  const hashedNonce = await Crypto.digestStringAsync(
    Crypto.CryptoDigestAlgorithm.SHA256,
    rawNonce
  );

  const credential = await AppleAuthentication.signInAsync({
    requestedScopes: [
      AppleAuthentication.AppleAuthenticationScope.FULL_NAME,
      AppleAuthentication.AppleAuthenticationScope.EMAIL,
    ],
    nonce: hashedNonce,
  });

  if (!credential.identityToken) throw new Error('Apple Sign-In failed: no identity token');

  const provider = new OAuthProvider('apple.com');
  const oauthCredential = provider.credential({
    idToken:    credential.identityToken,
    rawNonce,
  });

  await signInWithCredential(auth, oauthCredential);
}

// ─── Google Sign-In (hook — used in component) ────────────────────────────────
// Returns the hook result tuple; call promptAsync() from your component.
export function useGoogleAuth() {
  return Google.useAuthRequest({
    clientId:        '641148007074-9250ojr4nhtaihf1857ft0kdvv5jd3sf.apps.googleusercontent.com',
    iosClientId:     'com.googleusercontent.apps.641148007074-nntukdre5mbp7qhfr9fgkorfj42cj2bi',
  });
}

export async function handleGoogleResponse(
  response: Google.AuthSessionResult | null
): Promise<void> {
  if (response?.type !== 'success') return;
  const { id_token } = response.params;
  const credential = GoogleAuthProvider.credential(id_token);
  await signInWithCredential(auth, credential);
}

// ─── Sign Out ─────────────────────────────────────────────────────────────────
export async function signOut(): Promise<void> {
  await firebaseSignOut(auth);
}

// ─── Delete account ───────────────────────────────────────────────────────────
export async function deleteAccount(): Promise<void> {
  const user = auth.currentUser;
  if (user) await deleteUser(user);
}
