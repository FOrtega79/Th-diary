import { ref, uploadBytes, getDownloadURL, deleteObject } from 'firebase/storage';
import { storage } from './firebase';

export async function uploadProfileImage(
  uri: string,
  userId: string
): Promise<string> {
  const response = await fetch(uri);
  const blob = await response.blob();

  const storageRef = ref(storage, `profileImages/${userId}.jpg`);
  await uploadBytes(storageRef, blob, { contentType: 'image/jpeg' });
  return getDownloadURL(storageRef);
}

export async function deleteProfileImage(userId: string): Promise<void> {
  const storageRef = ref(storage, `profileImages/${userId}.jpg`);
  await deleteObject(storageRef);
}
