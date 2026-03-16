import {
  doc, getDoc, setDoc, updateDoc, deleteDoc,
  collection, query, where, orderBy, limit,
  getDocs, writeBatch, arrayUnion, arrayRemove,
  serverTimestamp, Timestamp,
} from 'firebase/firestore';
import { db } from './firebase';
import {
  TherianUser, userFromFirestore,
  Shift, shiftFromFirestore,
  PackRequest, packRequestFromFirestore,
} from '@/constants/types';

// ─── Collections ──────────────────────────────────────────────────────────────
const usersCol         = () => collection(db, 'users');
const shiftsCol        = () => collection(db, 'shifts');
const packRequestsCol  = () => collection(db, 'packRequests');

// ─── Users ────────────────────────────────────────────────────────────────────

export async function createUser(user: TherianUser): Promise<void> {
  await setDoc(doc(db, 'users', user.uid), {
    ...user,
    createdAt: serverTimestamp(),
  });
}

export async function fetchUser(uid: string): Promise<TherianUser | null> {
  const snap = await getDoc(doc(db, 'users', uid));
  if (!snap.exists()) return null;
  return userFromFirestore(snap.data());
}

export async function updateUser(uid: string, data: Partial<TherianUser>): Promise<void> {
  await updateDoc(doc(db, 'users', uid), data as Record<string, unknown>);
}

export async function isUsernameTaken(username: string): Promise<boolean> {
  const q = query(usersCol(), where('username', '==', username), limit(1));
  const snap = await getDocs(q);
  return !snap.empty;
}

export async function searchByUsername(username: string): Promise<TherianUser | null> {
  const q = query(usersCol(), where('username', '==', username), limit(1));
  const snap = await getDocs(q);
  if (snap.empty) return null;
  return userFromFirestore(snap.docs[0].data());
}

export async function fetchPackMembers(uids: string[]): Promise<TherianUser[]> {
  if (uids.length === 0) return [];
  // Firestore 'in' max 30 — chunk into 10s
  const chunks = chunk(uids, 10);
  const members: TherianUser[] = [];
  for (const c of chunks) {
    const q = query(usersCol(), where('uid', 'in', c));
    const snap = await getDocs(q);
    snap.docs.forEach(d => {
      const u = userFromFirestore(d.data());
      if (u) members.push(u);
    });
  }
  return members;
}

// ─── Shifts ───────────────────────────────────────────────────────────────────

export async function saveShift(shift: Shift): Promise<void> {
  await setDoc(doc(db, 'shifts', shift.shiftId), {
    ...shift,
    date: Timestamp.fromDate(shift.date),
  });
}

export async function fetchShifts(userId: string, maxResults = 50): Promise<Shift[]> {
  const q = query(
    shiftsCol(),
    where('userId', '==', userId),
    orderBy('date', 'desc'),
    limit(maxResults)
  );
  const snap = await getDocs(q);
  return snap.docs.map(d => shiftFromFirestore(d.data())).filter(Boolean) as Shift[];
}

export async function fetchLatestShift(userId: string): Promise<Shift | null> {
  const shifts = await fetchShifts(userId, 1);
  return shifts[0] ?? null;
}

export async function deleteShift(shiftId: string): Promise<void> {
  await deleteDoc(doc(db, 'shifts', shiftId));
}

// ─── Stats: streak + total ────────────────────────────────────────────────────

export async function fetchStats(userId: string): Promise<{ streak: number; total: number }> {
  const shifts = await fetchShifts(userId, 365);
  return { streak: calcStreak(shifts), total: shifts.length };
}

function calcStreak(shifts: Shift[]): number {
  if (shifts.length === 0) return 0;
  const calendar = new Set(
    shifts.map(s => s.date.toISOString().split('T')[0])
  );
  let streak = 0;
  let d = new Date();
  while (true) {
    const key = d.toISOString().split('T')[0];
    if (!calendar.has(key)) break;
    streak++;
    d = new Date(d.getTime() - 86_400_000);
  }
  return streak;
}

// ─── Pack Requests ────────────────────────────────────────────────────────────

export async function sendPackRequest(fromUserId: string, toUserId: string): Promise<void> {
  // Idempotency check
  const existing = query(
    packRequestsCol(),
    where('fromUserId', '==', fromUserId),
    where('toUserId',   '==', toUserId),
    where('status',     '==', 'pending'),
    limit(1)
  );
  const snap = await getDocs(existing);
  if (!snap.empty) return;

  const requestId = `${fromUserId}_${toUserId}_${Date.now()}`;
  await setDoc(doc(db, 'packRequests', requestId), {
    requestId,
    fromUserId,
    toUserId,
    status:    'pending',
    createdAt: serverTimestamp(),
  });
}

export async function fetchIncomingRequests(userId: string): Promise<PackRequest[]> {
  const q = query(
    packRequestsCol(),
    where('toUserId', '==', userId),
    where('status',   '==', 'pending')
  );
  const snap = await getDocs(q);
  return snap.docs.map(d => packRequestFromFirestore(d.data())).filter(Boolean) as PackRequest[];
}

export async function respondToPackRequest(
  requestId: string,
  fromUserId: string,
  toUserId: string,
  accept: boolean
): Promise<void> {
  const batch = writeBatch(db);

  batch.update(doc(db, 'packRequests', requestId), {
    status: accept ? 'accepted' : 'declined',
  });

  if (accept) {
    batch.update(doc(db, 'users', fromUserId), { packMembers: arrayUnion(toUserId) });
    batch.update(doc(db, 'users', toUserId),   { packMembers: arrayUnion(fromUserId) });
  }

  await batch.commit();
}

export async function removePackMember(userId: string, memberId: string): Promise<void> {
  const batch = writeBatch(db);
  batch.update(doc(db, 'users', userId),   { packMembers: arrayRemove(memberId) });
  batch.update(doc(db, 'users', memberId), { packMembers: arrayRemove(userId) });
  await batch.commit();
}

// ─── Utility ──────────────────────────────────────────────────────────────────
function chunk<T>(arr: T[], size: number): T[][] {
  return Array.from({ length: Math.ceil(arr.length / size) }, (_, i) =>
    arr.slice(i * size, i * size + size)
  );
}
