import { create } from 'zustand';
import { User as FirebaseUser } from 'firebase/auth';
import {
  TherianUser, Shift, PackRequest, AdUnlocks,
  isUnlockActive,
} from '@/constants/types';
import { PurchasesOfferings } from 'react-native-purchases';

// ─── Auth ─────────────────────────────────────────────────────────────────────
interface AuthState {
  firebaseUser:  FirebaseUser | null;
  therianUser:   TherianUser | null;
  isLoading:     boolean;
  authReady:     boolean;       // true once Firebase auth state is known
  error:         string | null;

  setFirebaseUser:  (u: FirebaseUser | null) => void;
  setTherianUser:   (u: TherianUser | null) => void;
  updateTherianUser:(partial: Partial<TherianUser>) => void;
  setLoading:       (v: boolean) => void;
  setAuthReady:     (v: boolean) => void;
  setError:         (e: string | null) => void;
  clear:            () => void;
}

export const useAuthStore = create<AuthState>((set, get) => ({
  firebaseUser:  null,
  therianUser:   null,
  isLoading:     false,
  authReady:     false,
  error:         null,

  setFirebaseUser:  u => set({ firebaseUser: u }),
  setTherianUser:   u => set({ therianUser: u }),
  updateTherianUser: partial => {
    const current = get().therianUser;
    if (current) set({ therianUser: { ...current, ...partial } });
  },
  setLoading:   v => set({ isLoading: v }),
  setAuthReady: v => set({ authReady: v }),
  setError:     e => set({ error: e }),
  clear: () => set({ firebaseUser: null, therianUser: null, isLoading: false, error: null }),
}));

// ─── Shifts ───────────────────────────────────────────────────────────────────
interface ShiftState {
  shifts:      Shift[];
  streak:      number;
  total:       number;
  isLoading:   boolean;

  setShifts:   (s: Shift[]) => void;
  addShift:    (s: Shift) => void;
  removeShift: (id: string) => void;
  setStats:    (streak: number, total: number) => void;
  setLoading:  (v: boolean) => void;
}

export const useShiftStore = create<ShiftState>(set => ({
  shifts:    [],
  streak:    0,
  total:     0,
  isLoading: false,

  setShifts:   shifts => set({ shifts, total: shifts.length }),
  addShift:    shift  => set(s => ({ shifts: [shift, ...s.shifts], total: s.total + 1 })),
  removeShift: id     => set(s => ({ shifts: s.shifts.filter(x => x.shiftId !== id) })),
  setStats:    (streak, total) => set({ streak, total }),
  setLoading:  v => set({ isLoading: v }),
}));

// ─── Pack ─────────────────────────────────────────────────────────────────────
interface PackState {
  members:          TherianUser[];
  incomingRequests: PackRequest[];
  isLoading:        boolean;

  setMembers:          (m: TherianUser[]) => void;
  setIncomingRequests: (r: PackRequest[]) => void;
  removeRequest:       (id: string) => void;
  removeMember:        (uid: string) => void;
  setLoading:          (v: boolean) => void;
}

export const usePackStore = create<PackState>(set => ({
  members:          [],
  incomingRequests: [],
  isLoading:        false,

  setMembers:          members  => set({ members }),
  setIncomingRequests: requests => set({ incomingRequests: requests }),
  removeRequest: id => set(s => ({
    incomingRequests: s.incomingRequests.filter(r => r.requestId !== id),
  })),
  removeMember: uid => set(s => ({
    members: s.members.filter(m => m.uid !== uid),
  })),
  setLoading: v => set({ isLoading: v }),
}));

// ─── Subscription / Paywall ───────────────────────────────────────────────────
interface PurchaseState {
  isPremium:    boolean;
  offerings:    PurchasesOfferings | null;
  isLoading:    boolean;

  setIsPremium: (v: boolean)  => void;
  setOfferings: (o: PurchasesOfferings | null) => void;
  setLoading:   (v: boolean)  => void;
}

export const usePurchaseStore = create<PurchaseState>(set => ({
  isPremium:    false,
  offerings:    null,
  isLoading:    false,

  setIsPremium: v => set({ isPremium: v }),
  setOfferings: o => set({ offerings: o }),
  setLoading:   v => set({ isLoading: v }),
}));

// ─── Ad unlocks (in-memory, 24h timer) ───────────────────────────────────────
interface AdUnlockState {
  unlocks: AdUnlocks;
  grantPackSlot:    () => void;
  grantBioEdit:     () => void;
  grantChartReveal: () => void;
  hasPackSlot:      () => boolean;
  hasBioEdit:       () => boolean;
  hasChartReveal:   () => boolean;
}

const in24h = () => new Date(Date.now() + 86_400_000);

export const useAdUnlockStore = create<AdUnlockState>((set, get) => ({
  unlocks: { packSlotExpiry: null, bioEditExpiry: null, chartViewExpiry: null },

  grantPackSlot:    () => set(s => ({ unlocks: { ...s.unlocks, packSlotExpiry:  in24h() } })),
  grantBioEdit:     () => set(s => ({ unlocks: { ...s.unlocks, bioEditExpiry:   in24h() } })),
  grantChartReveal: () => set(s => ({ unlocks: { ...s.unlocks, chartViewExpiry: in24h() } })),

  hasPackSlot:    () => isUnlockActive(get().unlocks.packSlotExpiry),
  hasBioEdit:     () => isUnlockActive(get().unlocks.bioEditExpiry),
  hasChartReveal: () => isUnlockActive(get().unlocks.chartViewExpiry),
}));
