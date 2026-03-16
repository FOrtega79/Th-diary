import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable, RefreshControl,
} from 'react-native';
import { router } from 'expo-router';
import { Image } from 'expo-image';
import dayjs from 'dayjs';
import { fetchStats, fetchLatestShift } from '@/services/firestore';
import { useAuthStore, useShiftStore, usePurchaseStore } from '@/store';
import { Colors, FontSizes, Spacing, Radii } from '@/constants/theme';
import StatsCard from '@/components/StatsCard';
import LatestEntryCard from '@/components/LatestEntryCard';
import LogShiftButton from '@/components/LogShiftButton';
import ProBanner from '@/components/ProBanner';
import { Shift } from '@/constants/types';

function greeting(username: string): string {
  const h = new Date().getHours();
  if (h < 12)  return `Good morning, ${username} 🌿`;
  if (h < 17)  return `Good afternoon, ${username} ☀️`;
  if (h < 21)  return `Good evening, ${username} 🌙`;
  return `Night, ${username} 🌑`;
}

export default function HomeScreen() {
  const { therianUser } = useAuthStore();
  const { streak, total, setStats } = useShiftStore();
  const { isPremium } = usePurchaseStore();
  const [latestShift, setLatestShift] = useState<Shift | null>(null);
  const [refreshing, setRefreshing]   = useState(false);

  const uid = therianUser?.uid ?? '';

  async function load() {
    if (!uid) return;
    const [stats, latest] = await Promise.all([
      fetchStats(uid),
      fetchLatestShift(uid),
    ]);
    setStats(stats.streak, stats.total);
    setLatestShift(latest);
  }

  useEffect(() => { load(); }, [uid]);

  async function onRefresh() {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  }

  return (
    <View style={styles.root}>
      <ScrollView
        contentContainerStyle={styles.scroll}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
      >
        {/* Header */}
        <View style={styles.header}>
          <View>
            <Text style={styles.date}>{dayjs().format('dddd, MMMM D')}</Text>
            <Text style={styles.greeting}>{greeting(therianUser?.username ?? 'Traveller')}</Text>
          </View>
          <Pressable onPress={() => router.push('/(tabs)/profile')}>
            {therianUser?.profileImageUrl ? (
              <Image
                source={{ uri: therianUser.profileImageUrl }}
                style={styles.avatar}
                contentFit="cover"
              />
            ) : (
              <View style={styles.avatarPlaceholder}>
                <Text style={styles.avatarLetter}>
                  {(therianUser?.username ?? 'T')[0].toUpperCase()}
                </Text>
              </View>
            )}
          </Pressable>
        </View>

        {/* Log Shift button */}
        <LogShiftButton onPress={() => router.push('/log-shift')} />

        {/* Stats */}
        <View style={styles.statsRow}>
          <StatsCard title="Day Streak" value={`${streak}`} emoji="🔥" />
          <View style={{ width: 12 }} />
          <StatsCard title="Total Shifts" value={`${total}`} emoji="🐾" />
        </View>

        {/* Latest entry */}
        {latestShift && (
          <View>
            <Text style={styles.sectionLabel}>Latest Entry</Text>
            <LatestEntryCard shift={latestShift} />
          </View>
        )}

        {/* Pro banner for free users */}
        {!isPremium && <ProBanner onPress={() => router.push('/paywall')} />}

        <View style={{ height: 100 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: Colors.moonlit },
  scroll:  { padding: Spacing.screen, paddingTop: 60, gap: Spacing.xl },
  header:  { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  date:    { fontSize: FontSizes.sm, color: Colors.pineDark + '66', marginBottom: 2, fontWeight: '500' },
  greeting:{ fontSize: FontSizes.xxl, fontWeight: '700', color: Colors.pineDark, lineHeight: 30 },
  avatar: {
    width: 44, height: 44,
    borderRadius: Radii.full,
    borderWidth: 2, borderColor: Colors.pineMedium + '55',
  },
  avatarPlaceholder: {
    width: 44, height: 44,
    borderRadius: Radii.full,
    backgroundColor: Colors.pineDark,
    alignItems: 'center', justifyContent: 'center',
  },
  avatarLetter: { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.moonlit },
  statsRow: { flexDirection: 'row' },
  sectionLabel: {
    fontSize: FontSizes.xs,
    fontWeight: '600',
    color: Colors.pineDark + '66',
    textTransform: 'uppercase',
    letterSpacing: 0.8,
    marginBottom: 8,
  },
});
