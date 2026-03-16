import {
  RewardedAd,
  RewardedAdEventType,
  TestIds,
  AdEventType,
} from 'react-native-google-mobile-ads';
import { Platform } from 'react-native';

// Replace with real ad unit IDs from AdMob dashboard.
// Use TestIds during development to avoid policy violations.
const AD_UNIT_IDS = {
  rewarded: __DEV__
    ? TestIds.REWARDED
    : Platform.select({
        ios:     'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
        android: 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX',
        default: TestIds.REWARDED,
      })!,
};

// ─── AdTrigger ────────────────────────────────────────────────────────────────
export type AdTrigger = 'packSlot' | 'bioEdit' | 'chartReveal';

export const AD_TRIGGER_COPY: Record<AdTrigger, { title: string; message: string }> = {
  packSlot: {
    title:   'Add Another Packmate',
    message: "You've reached your 5-member limit. Watch a short ad to unlock 1 extra slot for 24 hours, or upgrade to Pro for up to 20 members.",
  },
  bioEdit: {
    title:   'Edit Your Bio',
    message: 'Custom bios are a Pro feature. Watch a quick ad to edit your bio today.',
  },
  chartReveal: {
    title:   'Reveal Your Stats',
    message: 'Watch an ad to reveal your Shift Triggers chart for 24 hours.',
  },
};

// ─── Show Rewarded Ad ─────────────────────────────────────────────────────────
export function showRewardedAd(
  onEarned: () => void,
  onDismissed?: () => void
): void {
  const ad = RewardedAd.createForAdRequest(AD_UNIT_IDS.rewarded, {
    requestNonPersonalizedAdsOnly: false,
  });

  let rewarded = false;

  const unsubEarned = ad.addAdEventListener(RewardedAdEventType.EARNED_REWARD, () => {
    rewarded = true;
    onEarned();
  });

  const unsubClosed = ad.addAdEventListener(AdEventType.CLOSED, () => {
    if (!rewarded) onDismissed?.();
    unsubEarned();
    unsubClosed();
  });

  ad.load();

  const unsubLoaded = ad.addAdEventListener(AdEventType.LOADED, () => {
    ad.show();
    unsubLoaded();
  });
}
