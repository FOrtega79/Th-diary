import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, Pressable, ScrollView,
  ActivityIndicator, Alert, Modal,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { PurchasesPackage } from 'react-native-purchases';
import {
  getOfferings, purchasePackage, restorePurchases,
} from '@/services/revenuecat';
import { usePurchaseStore } from '@/store';
import { Colors, Gradients, FontSizes, Spacing, Radii, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

const FEATURES = [
  { emoji: '🐾', label: 'Up to 20 Pack Members' },
  { emoji: '📸', label: 'Custom Profile Picture' },
  { emoji: '✏️', label: 'Custom Bio & Username' },
  { emoji: '📊', label: 'Advanced Shift Analytics' },
  { emoji: '✨', label: 'Secondary Theriotype' },
  { emoji: '🚫', label: 'Ad-Free Experience' },
];

interface Props {
  visible: boolean;
  onClose: () => void;
}

export default function PaywallModal({ visible, onClose }: Props) {
  const haptics    = useHaptics();
  const { setIsPremium, setOfferings, offerings, isLoading, setLoading } = usePurchaseStore();
  const [selected, setSelected] = useState<PurchasesPackage | null>(null);

  useEffect(() => {
    if (!visible) return;
    (async () => {
      setLoading(true);
      const o = await getOfferings();
      setOfferings(o);
      setSelected(o?.current?.annual ?? o?.current?.monthly ?? null);
      setLoading(false);
    })();
  }, [visible]);

  async function handlePurchase() {
    if (!selected) return;
    haptics.light();
    setLoading(true);
    try {
      const isPremium = await purchasePackage(selected);
      setIsPremium(isPremium);
      if (isPremium) {
        haptics.payment();
        onClose();
      }
    } catch (e: any) {
      if (!e.userCancelled) {
        Alert.alert('Purchase Failed', e.message ?? 'Something went wrong.');
      }
    } finally {
      setLoading(false);
    }
  }

  async function handleRestore() {
    setLoading(true);
    try {
      const isPremium = await restorePurchases();
      setIsPremium(isPremium);
      if (isPremium) { haptics.success(); onClose(); }
      else Alert.alert('No subscription found', 'We could not find an active subscription to restore.');
    } catch (e: any) {
      Alert.alert('Restore Failed', e.message ?? 'Something went wrong.');
    } finally {
      setLoading(false);
    }
  }

  const annual  = offerings?.current?.annual;
  const monthly = offerings?.current?.monthly;

  return (
    <Modal visible={visible} animationType="slide" presentationStyle="pageSheet">
      <LinearGradient colors={Gradients.pine} style={styles.root}>
        {/* Handle */}
        <View style={styles.handle} />

        <ScrollView
          contentContainerStyle={styles.scroll}
          showsVerticalScrollIndicator={false}
        >
          {/* Header */}
          <Text style={styles.icon}>⭐</Text>
          <Text style={styles.headline}>Therian Pro</Text>
          <Text style={styles.sub}>Unlock your full wild self.</Text>

          {/* Features */}
          <View style={styles.featureList}>
            {FEATURES.map(f => (
              <View key={f.label} style={styles.featureRow}>
                <Text style={styles.featureEmoji}>{f.emoji}</Text>
                <Text style={styles.featureLabel}>{f.label}</Text>
                <Text style={styles.check}>✓</Text>
              </View>
            ))}
          </View>

          {/* Pricing */}
          {isLoading ? (
            <ActivityIndicator color={Colors.moonlit} style={{ marginVertical: 24 }} />
          ) : (
            <View style={styles.pricing}>
              {annual && (
                <PackageButton
                  pkg={annual}
                  recommended
                  selected={selected?.identifier === annual.identifier}
                  onSelect={() => { haptics.light(); setSelected(annual); }}
                />
              )}
              {monthly && (
                <PackageButton
                  pkg={monthly}
                  recommended={false}
                  selected={selected?.identifier === monthly.identifier}
                  onSelect={() => { haptics.light(); setSelected(monthly); }}
                />
              )}
            </View>
          )}

          {/* CTA */}
          <Pressable
            style={({ pressed }) => [styles.cta, { opacity: pressed ? 0.88 : 1 }]}
            onPress={handlePurchase}
            disabled={!selected || isLoading}
          >
            <Text style={styles.ctaText}>
              {isLoading ? 'Loading…' : 'Start Free Trial'}
            </Text>
          </Pressable>

          <Pressable onPress={handleRestore} style={styles.restore}>
            <Text style={styles.restoreText}>Restore Purchases</Text>
          </Pressable>

          <Text style={styles.legal}>
            Subscriptions auto-renew. Cancel anytime in Settings.
          </Text>
        </ScrollView>

        {/* Close */}
        <Pressable style={styles.close} onPress={onClose}>
          <Text style={styles.closeText}>✕</Text>
        </Pressable>
      </LinearGradient>
    </Modal>
  );
}

function PackageButton({
  pkg, recommended, selected, onSelect,
}: {
  pkg: PurchasesPackage;
  recommended: boolean;
  selected: boolean;
  onSelect: () => void;
}) {
  return (
    <Pressable
      onPress={onSelect}
      style={[styles.pkgBtn, selected && styles.pkgBtnSelected]}
    >
      <View style={styles.pkgLeft}>
        <View style={styles.pkgTitleRow}>
          <Text style={styles.pkgTitle}>{pkg.product.title}</Text>
          {recommended && (
            <View style={styles.badge}>
              <Text style={styles.badgeText}>Best Value</Text>
            </View>
          )}
        </View>
        {recommended && (
          <Text style={styles.pkgSub}>3-day free trial, then billed yearly</Text>
        )}
      </View>
      <Text style={styles.pkgPrice}>{pkg.product.priceString}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root:      { flex: 1 },
  handle: {
    width: 36, height: 4,
    backgroundColor: 'rgba(255,255,255,0.3)',
    borderRadius: Radii.full,
    alignSelf: 'center',
    marginTop: 12, marginBottom: 4,
  },
  scroll:    { padding: Spacing.xl, paddingBottom: 60 },
  icon:      { fontSize: 52, textAlign: 'center', marginBottom: 8 },
  headline:  { fontSize: FontSizes.hero, fontWeight: '700', color: Colors.moonlit, textAlign: 'center' },
  sub:       { fontSize: FontSizes.lg, color: Colors.moonlit + 'AA', textAlign: 'center', marginBottom: Spacing.xxl },
  featureList: { gap: 10, marginBottom: Spacing.xxl },
  featureRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255,255,255,0.08)',
    padding: Spacing.md,
    borderRadius: Radii.md,
    gap: 10,
  },
  featureEmoji: { fontSize: 18, width: 28 },
  featureLabel: { flex: 1, fontSize: FontSizes.md, fontWeight: '500', color: Colors.moonlit },
  check:        { fontSize: FontSizes.sm, color: Colors.soil, fontWeight: '700' },
  pricing:      { gap: 10, marginBottom: Spacing.xl },
  pkgBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.lg,
    borderRadius: Radii.md,
    backgroundColor: 'rgba(255,255,255,0.07)',
    borderWidth: 2,
    borderColor: 'transparent',
  },
  pkgBtnSelected: { borderColor: Colors.soil },
  pkgLeft:        { flex: 1 },
  pkgTitleRow:    { flexDirection: 'row', alignItems: 'center', gap: 8 },
  pkgTitle:       { fontSize: FontSizes.md, fontWeight: '600', color: Colors.moonlit },
  pkgSub:         { fontSize: FontSizes.xs, color: Colors.moonlit + '77', marginTop: 2 },
  pkgPrice:       { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.moonlit },
  badge: {
    backgroundColor: Colors.soil,
    paddingHorizontal: 7, paddingVertical: 2,
    borderRadius: 8,
  },
  badgeText: { fontSize: FontSizes.xs, fontWeight: '700', color: Colors.pineDark },
  cta: {
    backgroundColor: Colors.moonlit,
    borderRadius: Radii.lg,
    height: 58,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: Spacing.md,
    ...Shadows.button,
  },
  ctaText:     { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.pineDark },
  restore:     { alignItems: 'center', marginBottom: Spacing.lg },
  restoreText: { fontSize: FontSizes.sm, color: Colors.moonlit + '55' },
  legal: {
    fontSize: FontSizes.xs,
    color: Colors.moonlit + '44',
    textAlign: 'center',
    lineHeight: 16,
  },
  close: {
    position: 'absolute',
    top: 16, right: 16,
    width: 32, height: 32,
    borderRadius: Radii.full,
    backgroundColor: 'rgba(255,255,255,0.15)',
    alignItems: 'center', justifyContent: 'center',
  },
  closeText: { color: Colors.moonlit, fontSize: FontSizes.md, fontWeight: '600' },
});
