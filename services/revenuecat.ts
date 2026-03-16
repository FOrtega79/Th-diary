import Purchases, { PurchasesOfferings, PurchasesPackage } from 'react-native-purchases';
import { Platform } from 'react-native';

// Replace with your RevenueCat API keys from the RevenueCat dashboard
const API_KEYS = {
  ios:     'YOUR_REVENUECAT_IOS_API_KEY',
  android: 'YOUR_REVENUECAT_ANDROID_API_KEY',
};

export const ENTITLEMENT_ID = 'therian_pro';

// ─── Configure (call once at app startup) ────────────────────────────────────
export function configurePurchases(): void {
  const key = Platform.OS === 'ios' ? API_KEYS.ios : API_KEYS.android;
  Purchases.configure({ apiKey: key });
}

// ─── Identify user (call after sign-in) ──────────────────────────────────────
export async function identifyUser(userId: string): Promise<void> {
  await Purchases.logIn(userId);
}

// ─── Log out ──────────────────────────────────────────────────────────────────
export async function logOutPurchases(): Promise<void> {
  await Purchases.logOut();
}

// ─── Check premium status ────────────────────────────────────────────────────
export async function getIsPremium(): Promise<boolean> {
  const info = await Purchases.getCustomerInfo();
  return info.entitlements.active[ENTITLEMENT_ID] !== undefined;
}

// ─── Fetch offerings ─────────────────────────────────────────────────────────
export async function getOfferings(): Promise<PurchasesOfferings | null> {
  try {
    return await Purchases.getOfferings();
  } catch {
    return null;
  }
}

// ─── Purchase ─────────────────────────────────────────────────────────────────
export async function purchasePackage(pkg: PurchasesPackage): Promise<boolean> {
  const { customerInfo } = await Purchases.purchasePackage(pkg);
  return customerInfo.entitlements.active[ENTITLEMENT_ID] !== undefined;
}

// ─── Restore ──────────────────────────────────────────────────────────────────
export async function restorePurchases(): Promise<boolean> {
  const info = await Purchases.restorePurchases();
  return info.entitlements.active[ENTITLEMENT_ID] !== undefined;
}
