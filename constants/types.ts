import { Timestamp } from 'firebase/firestore';

// ─── Theriotype ───────────────────────────────────────────────────────────────
export const THERIOTYPES = [
  { id: 'Wolf',    emoji: '🐺' },
  { id: 'Fox',     emoji: '🦊' },
  { id: 'Cat',     emoji: '🐱' },
  { id: 'Dog',     emoji: '🐶' },
  { id: 'Deer',    emoji: '🦌' },
  { id: 'Dragon',  emoji: '🐉' },
  { id: 'Eagle',   emoji: '🦅' },
  { id: 'Bear',    emoji: '🐻' },
  { id: 'Rabbit',  emoji: '🐰' },
  { id: 'Horse',   emoji: '🐴' },
  { id: 'Lion',    emoji: '🦁' },
  { id: 'Tiger',   emoji: '🐯' },
  { id: 'Owl',     emoji: '🦉' },
  { id: 'Snake',   emoji: '🐍' },
  { id: 'Other',   emoji: '✨' },
] as const;

export type TheriotypeName = typeof THERIOTYPES[number]['id'];

export function getTheriotype(name: string) {
  return THERIOTYPES.find(t => t.id === name) ?? { id: name, emoji: '✨' };
}

// ─── Shift ────────────────────────────────────────────────────────────────────
export type ShiftTypeName =
  | 'Mental' | 'Phantom' | 'Dream' | 'Cameo'
  | 'Astral' | 'Sensory' | 'Aura'  | 'Bi-location';

export const SHIFT_TYPES: {
  id: ShiftTypeName;
  icon: string;
  description: string;
}[] = [
  { id: 'Mental',      icon: 'brain',         description: 'A mental shift in thinking or awareness' },
  { id: 'Phantom',     icon: 'sparkles',      description: 'Phantom limb sensations (tail, wings, etc.)' },
  { id: 'Dream',       icon: 'moon.stars',    description: 'Theriotype appeared in a dream' },
  { id: 'Cameo',       icon: 'theatermasks',  description: 'Brief shift into a non-primary theriotype' },
  { id: 'Astral',      icon: 'rays',          description: 'Spiritual or astral projection experience' },
  { id: 'Sensory',     icon: 'eye',           description: 'Heightened or altered senses' },
  { id: 'Aura',        icon: 'sun.max',       description: 'Energy or aura-based shift' },
  { id: 'Bi-location', icon: 'arrow.triangle.branch', description: 'Sense of being in two places' },
];

export const SHIFT_TAGS = [
  'Nature', 'Full Moon', 'Music', 'Running', 'Meditation',
  'Stress', 'Crowd', 'Rain', 'Night', 'Solitude',
  'Social Media', 'Forest', 'Water', 'Wind', 'Animals',
];

export interface Shift {
  shiftId:   string;
  userId:    string;
  type:      ShiftTypeName;
  intensity: number;   // 1–10
  tags:      string[];
  notes:     string;
  date:      Date;
}

export function shiftFromFirestore(data: Record<string, any>): Shift | null {
  if (!data.shiftId || !data.userId || !data.type) return null;
  return {
    shiftId:   data.shiftId,
    userId:    data.userId,
    type:      data.type as ShiftTypeName,
    intensity: data.intensity ?? 5,
    tags:      data.tags ?? [],
    notes:     data.notes ?? '',
    date:      (data.date as Timestamp)?.toDate() ?? new Date(),
  };
}

export function intensityLabel(intensity: number): string {
  if (intensity <= 3)  return 'Mild';
  if (intensity <= 6)  return 'Moderate';
  if (intensity <= 9)  return 'Strong';
  return 'Overwhelming';
}

// ─── User ─────────────────────────────────────────────────────────────────────
export interface TherianUser {
  uid:                  string;
  username:             string;
  primaryTheriotype:    string;
  secondaryTheriotype?: string;
  bio:                  string;
  profileImageUrl:      string;
  isPremium:            boolean;
  packMembers:          string[];
  createdAt:            Date;
}

export function userFromFirestore(data: Record<string, any>): TherianUser | null {
  if (!data.uid || !data.username) return null;
  return {
    uid:                 data.uid,
    username:            data.username,
    primaryTheriotype:   data.primaryTheriotype ?? 'Other',
    secondaryTheriotype: data.secondaryTheriotype,
    bio:                 data.bio ?? '',
    profileImageUrl:     data.profileImageUrl ?? '',
    isPremium:           data.isPremium ?? false,
    packMembers:         data.packMembers ?? [],
    createdAt:           (data.createdAt as Timestamp)?.toDate() ?? new Date(),
  };
}

export function maxPackSize(user: TherianUser) {
  return user.isPremium ? 20 : 5;
}

// ─── Pack Request ─────────────────────────────────────────────────────────────
export type PackRequestStatus = 'pending' | 'accepted' | 'declined';

export interface PackRequest {
  requestId:  string;
  fromUserId: string;
  toUserId:   string;
  status:     PackRequestStatus;
  createdAt:  Date;
}

export function packRequestFromFirestore(data: Record<string, any>): PackRequest | null {
  if (!data.requestId || !data.fromUserId || !data.toUserId) return null;
  return {
    requestId:  data.requestId,
    fromUserId: data.fromUserId,
    toUserId:   data.toUserId,
    status:     data.status as PackRequestStatus,
    createdAt:  (data.createdAt as Timestamp)?.toDate() ?? new Date(),
  };
}

// ─── Ad unlock state (stored in Zustand, non-persistent) ─────────────────────
export interface AdUnlocks {
  packSlotExpiry:   Date | null;
  bioEditExpiry:    Date | null;
  chartViewExpiry:  Date | null;
}

export function isUnlockActive(expiry: Date | null): boolean {
  return expiry !== null && expiry > new Date();
}
