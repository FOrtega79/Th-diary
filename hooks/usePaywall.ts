import { useState } from 'react';
import { usePurchaseStore } from '@/store';
import { useAdUnlockStore } from '@/store';
import { AD_TRIGGER_COPY, AdTrigger, showRewardedAd } from '@/services/admob';

interface PaywallGate {
  // Call to attempt a premium action.
  // Returns true if the action should proceed (user is premium or has ad unlock).
  // Returns false if paywall or ad prompt was shown instead.
  attempt: (trigger: AdTrigger) => {
    allowed: boolean;
    showPaywall: boolean;
    showAdPrompt: boolean;
  };
  handleWatchAd: (trigger: AdTrigger, onGranted: () => void) => void;
}

export function usePaywallGate(): PaywallGate {
  const isPremium     = usePurchaseStore(s => s.isPremium);
  const hasPackSlot   = useAdUnlockStore(s => s.hasPackSlot);
  const hasBioEdit    = useAdUnlockStore(s => s.hasBioEdit);
  const hasChartReveal= useAdUnlockStore(s => s.hasChartReveal);
  const grantPackSlot   = useAdUnlockStore(s => s.grantPackSlot);
  const grantBioEdit    = useAdUnlockStore(s => s.grantBioEdit);
  const grantChartReveal= useAdUnlockStore(s => s.grantChartReveal);

  function hasAdUnlock(trigger: AdTrigger): boolean {
    switch (trigger) {
      case 'packSlot':    return hasPackSlot();
      case 'bioEdit':     return hasBioEdit();
      case 'chartReveal': return hasChartReveal();
    }
  }

  function attempt(trigger: AdTrigger) {
    if (isPremium || hasAdUnlock(trigger)) {
      return { allowed: true, showPaywall: false, showAdPrompt: false };
    }
    return { allowed: false, showPaywall: false, showAdPrompt: true };
  }

  function handleWatchAd(trigger: AdTrigger, onGranted: () => void) {
    showRewardedAd(
      () => {
        switch (trigger) {
          case 'packSlot':    grantPackSlot();    break;
          case 'bioEdit':     grantBioEdit();     break;
          case 'chartReveal': grantChartReveal(); break;
        }
        onGranted();
      }
    );
  }

  return { attempt, handleWatchAd };
}
