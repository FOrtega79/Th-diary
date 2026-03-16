import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable,
  RefreshControl, Alert, Dimensions,
} from 'react-native';
import { router } from 'expo-router';
import { fetchShifts } from '@/services/firestore';
import { useAuthStore, usePurchaseStore, useAdUnlockStore } from '@/store';
import { Shift, ShiftTypeName } from '@/constants/types';
import { AD_TRIGGER_COPY, showRewardedAd } from '@/services/admob';
import { Colors, FontSizes, Spacing, Radii } from '@/constants/theme';
import GlassCard from '@/components/GlassCard';
import PaywallModal from '@/components/PaywallModal';
import dayjs from 'dayjs';

const { width: W } = Dimensions.get('window');
const BAR_WIDTH    = (W - Spacing.screen * 2 - 48) / 7;

export default function StatsScreen() {
  const { therianUser }   = useAuthStore();
  const { isPremium }     = usePurchaseStore();
  const { hasChartReveal, grantChartReveal } = useAdUnlockStore();
  const [shifts, setShifts]         = useState<Shift[]>([]);
  const [refreshing, setRefreshing] = useState(false);
  const [showPaywall, setShowPaywall] = useState(false);

  const uid = therianUser?.uid ?? '';

  async function load() {
    if (!uid) return;
    const s = await fetchShifts(uid, 365);
    setShifts(s);
  }

  useEffect(() => { load(); }, [uid]);

  async function onRefresh() { setRefreshing(true); await load(); setRefreshing(false); }

  // --- Computed stats
  const total    = shifts.length;
  const streak   = calcStreak(shifts);
  const avgInt   = total > 0 ? shifts.reduce((s, x) => s + x.intensity, 0) / total : 0;
  const last7    = getLast7(shifts);
  const maxBar   = Math.max(...last7.map(d => d.count), 1);
  const typeData = getTypeBreakdown(shifts);
  const triggers = getTopTriggers(shifts);

  const chartUnlocked = isPremium || hasChartReveal();

  function handleChartLock() {
    Alert.alert(
      AD_TRIGGER_COPY.chartReveal.title,
      AD_TRIGGER_COPY.chartReveal.message,
      [
        { text: 'Watch Ad', onPress: () => showRewardedAd(() => grantChartReveal()) },
        { text: 'Upgrade to Pro', onPress: () => setShowPaywall(true) },
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  }

  return (
    <View style={styles.root}>
      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        <Text style={styles.title}>Stats</Text>

        {/* Summary cards */}
        <View style={styles.row}>
          <MiniCard label="Streak" value={`${streak}d`} emoji="🔥" />
          <MiniCard label="Total" value={`${total}`} emoji="🐾" />
          <MiniCard label="Avg Intensity" value={avgInt.toFixed(1)} emoji="⚡" />
        </View>

        {/* Last 7 days bar chart */}
        <GlassCard style={styles.card}>
          <Text style={styles.cardTitle}>Last 7 Days</Text>
          <View style={styles.bars}>
            {last7.map(d => (
              <View key={d.label} style={styles.barCol}>
                <View style={styles.barTrack}>
                  <View style={[
                    styles.bar,
                    { height: `${(d.count / maxBar) * 100}%` },
                  ]} />
                </View>
                <Text style={styles.barLabel}>{d.label}</Text>
              </View>
            ))}
          </View>
        </GlassCard>

        {/* Shift type breakdown — gated */}
        <View>
          <GlassCard style={[styles.card, !chartUnlocked && styles.blurred]}>
            <Text style={styles.cardTitle}>Shift Type Breakdown</Text>
            {typeData.slice(0, 5).map(item => (
              <View key={item.type} style={styles.typeRow}>
                <Text style={styles.typeLabel}>{item.type}</Text>
                <View style={styles.typeTrack}>
                  <View style={[styles.typeFill, { width: `${item.pct}%` }]} />
                </View>
                <Text style={styles.typePct}>{item.pct.toFixed(0)}%</Text>
              </View>
            ))}
          </GlassCard>

          {!chartUnlocked && (
            <Pressable style={styles.lockOverlay} onPress={handleChartLock}>
              <Text style={styles.lockIcon}>🔒</Text>
              <Text style={styles.lockText}>Watch Ad to Reveal</Text>
            </Pressable>
          )}
        </View>

        {/* Top triggers — gated too */}
        {chartUnlocked && triggers.length > 0 && (
          <GlassCard style={styles.card}>
            <Text style={styles.cardTitle}>Top Triggers</Text>
            {triggers.map(([tag, count]) => (
              <View key={tag} style={styles.triggerRow}>
                <Text style={styles.triggerTag}>{tag}</Text>
                <Text style={styles.triggerCount}>{count}</Text>
              </View>
            ))}
          </GlassCard>
        )}

        <View style={{ height: 100 }} />
      </ScrollView>

      <PaywallModal visible={showPaywall} onClose={() => setShowPaywall(false)} />
    </View>
  );
}

function MiniCard({ label, value, emoji }: { label: string; value: string; emoji: string }) {
  return (
    <GlassCard style={styles.miniCard} padding={12}>
      <Text style={{ fontSize: 20, marginBottom: 4 }}>{emoji}</Text>
      <Text style={styles.miniVal}>{value}</Text>
      <Text style={styles.miniLabel}>{label}</Text>
    </GlassCard>
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
function calcStreak(shifts: Shift[]): number {
  const days = new Set(shifts.map(s => dayjs(s.date).format('YYYY-MM-DD')));
  let streak = 0;
  let d = dayjs();
  while (days.has(d.format('YYYY-MM-DD'))) { streak++; d = d.subtract(1, 'day'); }
  return streak;
}

function getLast7(shifts: Shift[]) {
  return Array.from({ length: 7 }, (_, i) => {
    const d = dayjs().subtract(6 - i, 'day');
    return {
      label: d.format('ddd'),
      count: shifts.filter(s => dayjs(s.date).isSame(d, 'day')).length,
    };
  });
}

function getTypeBreakdown(shifts: Shift[]) {
  const counts: Record<string, number> = {};
  shifts.forEach(s => { counts[s.type] = (counts[s.type] ?? 0) + 1; });
  const total = shifts.length || 1;
  return Object.entries(counts)
    .sort((a, b) => b[1] - a[1])
    .map(([type, count]) => ({ type, pct: (count / total) * 100 }));
}

function getTopTriggers(shifts: Shift[]): [string, number][] {
  const counts: Record<string, number> = {};
  shifts.forEach(s => s.tags.forEach(t => { counts[t] = (counts[t] ?? 0) + 1; }));
  return Object.entries(counts).sort((a, b) => b[1] - a[1]).slice(0, 5);
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: Colors.moonlit },
  scroll:  { padding: Spacing.screen, paddingTop: 60, gap: Spacing.xl },
  title:   { fontSize: FontSizes.hero, fontWeight: '700', color: Colors.pineDark },
  row:     { flexDirection: 'row', gap: 10 },
  card:    { width: '100%' },
  cardTitle: { fontSize: FontSizes.md, fontWeight: '700', color: Colors.pineDark, marginBottom: Spacing.md },
  miniCard:  { flex: 1 },
  miniVal:   { fontSize: 26, fontWeight: '700', color: Colors.pineDark },
  miniLabel: { fontSize: FontSizes.xs, fontWeight: '600', color: Colors.pineDark + '66', textTransform: 'uppercase', letterSpacing: 0.5, marginTop: 2 },
  bars:    { flexDirection: 'row', alignItems: 'flex-end', gap: 6, height: 100 },
  barCol:  { alignItems: 'center', flex: 1 },
  barTrack:{ flex: 1, width: '100%', backgroundColor: Colors.pineDark + '0F', borderRadius: Radii.sm, overflow: 'hidden', justifyContent: 'flex-end' },
  bar:     { width: '100%', backgroundColor: Colors.pineMedium, borderRadius: Radii.sm },
  barLabel:{ fontSize: FontSizes.xs, color: Colors.pineDark + '66', marginTop: 4 },
  typeRow: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 },
  typeLabel: { width: 80, fontSize: FontSizes.sm, color: Colors.pineDark },
  typeTrack: { flex: 1, height: 8, backgroundColor: Colors.pineDark + '12', borderRadius: Radii.full, overflow: 'hidden' },
  typeFill:  { height: '100%', backgroundColor: Colors.soil, borderRadius: Radii.full },
  typePct:   { width: 36, fontSize: FontSizes.xs, color: Colors.soil, fontWeight: '700', textAlign: 'right' },
  blurred:   { opacity: 0.25 },
  lockOverlay: {
    position: 'absolute', top: 0, left: 0, right: 0, bottom: 0,
    alignItems: 'center', justifyContent: 'center', gap: 8,
    borderRadius: Radii.lg,
  },
  lockIcon: { fontSize: 32 },
  lockText: { fontSize: FontSizes.md, fontWeight: '700', color: Colors.pineMedium },
  triggerRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', paddingVertical: 8, borderBottomWidth: 1, borderBottomColor: Colors.pineDark + '10' },
  triggerTag:   { fontSize: FontSizes.md, color: Colors.pineDark },
  triggerCount: { fontSize: FontSizes.md, fontWeight: '700', color: Colors.soil },
});
