# Therian Diary — React Native (Expo)

A beautifully crafted iOS & Android journaling app for the alterhuman community. Built with Expo (managed workflow) so you can develop entirely on **Windows** and ship to both platforms from the cloud.

---

## Windows Development Workflow

```
Edit code in VS Code on Windows
        ↓
npx expo start
        ↓
Scan QR code with Expo Go on your iPhone → live preview instantly
        ↓
git push  →  GitHub Actions runs EAS Build in Expo's cloud
        ↓
✅ iOS .ipa  /  🤖 Android .apk  — no Mac, no Xcode ever needed
```

---

## Tech Stack

| Layer | Library |
|---|---|
| Framework | Expo SDK 51 (managed workflow) |
| Navigation | Expo Router v3 (file-based) |
| UI Animations | React Native Reanimated 3 |
| Glassmorphism | expo-blur |
| State | Zustand |
| Backend | Firebase JS SDK v10 (Auth · Firestore · Storage) |
| Auth | expo-apple-authentication · expo-auth-session (Google) |
| Subscriptions | RevenueCat (react-native-purchases) |
| Ads | Google AdMob (react-native-google-mobile-ads) |
| Fonts | Playfair Display (@expo-google-fonts) |
| Images | expo-image |
| Haptics | expo-haptics |

---

## Project Structure

```
app/
├── _layout.tsx          ← Root layout (fonts, Firebase listener, auth state)
├── index.tsx            ← Smart redirect (splash → auth/onboarding/home)
├── log-shift.tsx        ← Modal: log a new shift
├── paywall.tsx          ← Modal: Therian Pro paywall
├── (auth)/
│   ├── login.tsx        ← Apple + Google Sign-In
│   └── onboarding.tsx   ← Theriotype picker + username
└── (tabs)/
    ├── index.tsx        ← Home (dashboard)
    ├── pack.tsx         ← The Pack (social)
    ├── stats.tsx        ← Stats & charts
    └── profile.tsx      ← Profile + settings

components/              ← GlassCard, LogShiftButton, ProBanner, StatsCard…
services/                ← firebase, auth, firestore, storage, revenuecat, admob
store/                   ← Zustand stores (auth, shifts, pack, purchases, ad unlocks)
hooks/                   ← useHaptics, usePaywall
constants/               ← theme.ts (colors, fonts, spacing), types.ts
```

---

## Quick Start (Windows)

### 1. Install Node.js
Download from [nodejs.org](https://nodejs.org) (LTS version).

### 2. Install Expo CLI + EAS CLI
```powershell
npm install -g expo-cli eas-cli
```

### 3. Clone & install dependencies
```powershell
git clone https://github.com/FOrtega79/Th-diary.git
cd Th-diary
npm install
```

### 4. Start the dev server
```powershell
npx expo start
```
Scan the QR code with **Expo Go** (free on App Store / Play Store).

> **Note:** Some native features (Apple Sign-In, RevenueCat, AdMob) require a **development build** instead of Expo Go. Run `eas build --profile development --platform ios` once — EAS builds it in the cloud and sends you a download link.

---

## Configuration Checklist

### Firebase
1. [Create a project](https://console.firebase.google.com)
2. Add an iOS app (bundle ID: `com.yourcompany.theriandiary`)
3. Enable **Auth** → Apple, Google providers
4. Create **Firestore** database → paste security rules below
5. Enable **Storage**
6. Open `services/firebase.ts` and replace all `YOUR_*` values

#### Firestore Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    match /shifts/{shiftId} {
      allow read, write: if request.auth.uid == resource.data.userId
                         || request.auth.uid == request.resource.data.userId;
    }
    match /packRequests/{requestId} {
      allow read:   if request.auth.uid == resource.data.fromUserId
                    || request.auth.uid == resource.data.toUserId;
      allow create: if request.auth.uid == request.resource.data.fromUserId;
      allow update: if request.auth.uid == resource.data.toUserId;
    }
  }
}
```

### Google Sign-In (Firebase)
In `services/auth.ts`, replace:
- `YOUR_EXPO_CLIENT_ID`
- `YOUR_IOS_CLIENT_ID`
- `YOUR_ANDROID_CLIENT_ID`

Get these from Firebase Console → Auth → Google provider → Web SDK configuration.

### RevenueCat
1. Sign up at [app.revenuecat.com](https://app.revenuecat.com)
2. Create entitlement: `therian_pro`
3. Create offerings: monthly + annual (3-day free trial on annual)
4. Replace keys in `services/revenuecat.ts`

### AdMob
1. Create account at [admob.google.com](https://admob.google.com)
2. Register app → create a **Rewarded** ad unit
3. Replace App ID in `app.json` → `ios.infoPlist.GADApplicationIdentifier`
4. Replace ad unit ID in `services/admob.ts`

### EAS (for cloud builds)
1. Sign up at [expo.dev](https://expo.dev)
2. `eas login`
3. `eas init` → updates `app.json` with your `projectId`
4. Update `eas.json` with your Apple ID and Team ID

---

## Building without a Mac

### Option 1 — Expo Go (instant, no build needed)
`npx expo start` → scan QR. Works for most UI work. Native modules (Sign-In, RevenueCat, AdMob) won't load in Expo Go.

### Option 2 — EAS Development Build (recommended)
```powershell
eas build --profile development --platform ios
```
EAS builds on a cloud Mac. You get a download link to install on your iPhone. After this, `npx expo start` serves updates instantly to this build.

### Option 3 — Production build for App Store
```powershell
eas build --profile production --platform ios
eas submit --platform ios
```
Or trigger from **GitHub Actions → Actions tab → EAS Build → Run workflow**.

---

## GitHub Actions CI

Every push to `claude/**` or `main`:
1. Runs TypeScript type-check and lint on Ubuntu (free, fast)
2. Optionally triggers EAS Build (manual dispatch from Actions tab)

To enable EAS builds in CI, add `EXPO_TOKEN` to your GitHub secrets:
- [expo.dev](https://expo.dev) → Account → Access Tokens → Create

---

## Monetization Flow

```
Free User
  ├─ 5 Pack members max  →  Paywall  OR  Watch Ad (24h slot)
  ├─ Edit bio             →  Watch Ad (24h)  OR  Paywall
  └─ Stats charts blurred →  Watch Ad (24h)  OR  Paywall

Therian Pro (RevenueCat)
  ├─ 20 Pack members
  ├─ Custom bio, avatar, secondary theriotype
  ├─ Full stats
  └─ No ads
```

---

## Design System

| Token | Value |
|---|---|
| Pine Dark | `#1A2421` |
| Pine Medium | `#2C4C3B` |
| Soil (Accent) | `#C85A28` |
| Moonlit (Background) | `#F5F7F2` |
| Border radius | 24 pt |
| Headers | Playfair Display (serif) |
| Body | System rounded (SF Pro Rounded on iOS) |

---

## Android (when you're ready)

The app already supports Android. Just run:
```powershell
eas build --profile production --platform android
eas submit --platform android
```
You'll need a Google Play developer account ($25 one-time fee). The same Firebase project works for both platforms.

---

## License
Private — All Rights Reserved
