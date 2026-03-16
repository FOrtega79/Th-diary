import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, FlatList, Pressable,
  TextInput, Alert, RefreshControl, ActivityIndicator,
} from 'react-native';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import {
  fetchPackMembers, fetchIncomingRequests,
  sendPackRequest, respondToPackRequest, removePackMember,
  searchByUsername,
} from '@/services/firestore';
import { useAuthStore, usePackStore, usePurchaseStore, useAdUnlockStore } from '@/store';
import { TherianUser, PackRequest, maxPackSize, getTheriotype } from '@/constants/types';
import { AD_TRIGGER_COPY, showRewardedAd } from '@/services/admob';
import { Colors, FontSizes, Spacing, Radii, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';
import GlassCard from '@/components/GlassCard';
import PaywallModal from '@/components/PaywallModal';

export default function PackScreen() {
  const haptics  = useHaptics();
  const { therianUser, updateTherianUser } = useAuthStore();
  const { members, incomingRequests, isLoading, setMembers, setIncomingRequests, removeMember, removeRequest, setLoading } = usePackStore();
  const { isPremium } = usePurchaseStore();
  const { hasPackSlot, grantPackSlot } = useAdUnlockStore();

  const [searchQuery, setSearchQuery] = useState('');
  const [searchResult, setSearchResult] = useState<TherianUser | null | 'notfound'>('notfound');
  const [searching, setSearching] = useState(false);
  const [showPaywall, setShowPaywall] = useState(false);
  const [refreshing, setRefreshing] = useState(false);

  const limit = maxPackSize(therianUser ?? { isPremium: false } as any);

  async function load() {
    if (!therianUser) return;
    setLoading(true);
    const [m, r] = await Promise.all([
      fetchPackMembers(therianUser.packMembers),
      fetchIncomingRequests(therianUser.uid),
    ]);
    setMembers(m);
    setIncomingRequests(r);
    setLoading(false);
  }

  useEffect(() => { load(); }, [therianUser?.uid]);

  async function onRefresh() {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  }

  async function handleSearch() {
    const q = searchQuery.trim();
    if (!q) return;
    setSearching(true);
    const result = await searchByUsername(q);
    setSearchResult(result ?? 'notfound');
    setSearching(false);
  }

  function checkLimitAndAdd() {
    const canAdd = members.length < limit || hasPackSlot();
    if (isPremium || canAdd) {
      handleSearch();
      return;
    }
    // Show ad prompt
    Alert.alert(
      AD_TRIGGER_COPY.packSlot.title,
      AD_TRIGGER_COPY.packSlot.message,
      [
        { text: 'Watch Ad', onPress: () => showRewardedAd(() => { grantPackSlot(); }) },
        { text: 'Upgrade to Pro', onPress: () => setShowPaywall(true) },
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  }

  async function sendHowl(target: TherianUser) {
    if (!therianUser) return;
    haptics.medium();
    await sendPackRequest(therianUser.uid, target.uid);
    Alert.alert('Howl sent! 🐾', `Your howl has been sent to @${target.username}.`);
    setSearchQuery('');
    setSearchResult('notfound');
  }

  async function accept(req: PackRequest) {
    if (!therianUser) return;
    await respondToPackRequest(req.requestId, req.fromUserId, req.toUserId, true);
    haptics.success();
    removeRequest(req.requestId);
    updateTherianUser({ packMembers: [...(therianUser.packMembers ?? []), req.fromUserId] });
    await load();
  }

  async function decline(req: PackRequest) {
    if (!therianUser) return;
    await respondToPackRequest(req.requestId, req.fromUserId, req.toUserId, false);
    removeRequest(req.requestId);
  }

  async function remove(memberId: string) {
    if (!therianUser) return;
    Alert.alert('Remove from Pack?', 'This will remove them from both your packs.', [
      { text: 'Remove', style: 'destructive', onPress: async () => {
        await removePackMember(therianUser.uid, memberId);
        removeMember(memberId);
      }},
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  return (
    <View style={styles.root}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.title}>The Pack</Text>
        <Text style={styles.count}>{members.length}/{limit}</Text>
      </View>

      <FlatList
        data={members}
        keyExtractor={m => m.uid}
        contentContainerStyle={styles.list}
        showsVerticalScrollIndicator={false}
        refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
        ListHeaderComponent={() => (
          <>
            {/* Incoming Howls */}
            {incomingRequests.length > 0 && (
              <View style={styles.section}>
                <Text style={styles.sectionLabel}>Incoming Howls 🐾</Text>
                {incomingRequests.map(req => (
                  <GlassCard key={req.requestId} padding={12} style={styles.requestCard}>
                    <Text style={styles.requestText}>Howl from {req.fromUserId.slice(0, 8)}…</Text>
                    <View style={styles.requestActions}>
                      <Pressable style={styles.declineBtn} onPress={() => decline(req)}>
                        <Text style={styles.declineTxt}>✕</Text>
                      </Pressable>
                      <Pressable style={styles.acceptBtn} onPress={() => accept(req)}>
                        <Text style={styles.acceptTxt}>✓</Text>
                      </Pressable>
                    </View>
                  </GlassCard>
                ))}
              </View>
            )}

            {/* Search */}
            <View style={styles.section}>
              <Text style={styles.sectionLabel}>Add a Packmate</Text>
              <View style={styles.searchRow}>
                <TextInput
                  value={searchQuery}
                  onChangeText={setSearchQuery}
                  placeholder="Search by username…"
                  placeholderTextColor={Colors.pineDark + '44'}
                  style={styles.searchInput}
                  autoCapitalize="none"
                  autoCorrect={false}
                  onSubmitEditing={checkLimitAndAdd}
                  returnKeyType="search"
                />
                <Pressable style={styles.searchBtn} onPress={checkLimitAndAdd}>
                  <Text style={styles.searchBtnTxt}>🔍</Text>
                </Pressable>
              </View>

              {searching && <ActivityIndicator color={Colors.pineMedium} style={{ marginTop: 12 }} />}

              {searchResult && searchResult !== 'notfound' && !searching && (
                <GlassCard padding={14} style={{ marginTop: 10 }}>
                  <View style={styles.searchResultRow}>
                    <Text style={styles.searchEmoji}>
                      {getTheriotype(searchResult.primaryTheriotype).emoji}
                    </Text>
                    <View style={{ flex: 1 }}>
                      <Text style={styles.searchUsername}>@{searchResult.username}</Text>
                      <Text style={styles.searchType}>{searchResult.primaryTheriotype}</Text>
                    </View>
                    <Pressable
                      style={styles.howlBtn}
                      onPress={() => sendHowl(searchResult)}
                    >
                      <Text style={styles.howlTxt}>Send Howl</Text>
                    </Pressable>
                  </View>
                </GlassCard>
              )}
            </View>

            {members.length > 0 && (
              <Text style={[styles.sectionLabel, styles.section]}>Pack Members</Text>
            )}
          </>
        )}
        ListEmptyComponent={() => (
          !isLoading ? (
            <View style={styles.empty}>
              <Text style={styles.emptyEmoji}>🐾</Text>
              <Text style={styles.emptyTitle}>Your pack is empty</Text>
              <Text style={styles.emptyText}>Search for therians by username and send them a Howl!</Text>
            </View>
          ) : null
        )}
        renderItem={({ item }) => (
          <GlassCard padding={14} style={styles.memberCard}>
            <View style={styles.memberRow}>
              {item.profileImageUrl ? (
                <Image source={{ uri: item.profileImageUrl }} style={styles.avatar} contentFit="cover" />
              ) : (
                <View style={styles.avatarFallback}>
                  <Text style={styles.avatarLetter}>{item.username[0].toUpperCase()}</Text>
                </View>
              )}
              <View style={{ flex: 1, marginLeft: 12 }}>
                <Text style={styles.memberName}>@{item.username}</Text>
                <Text style={styles.memberType}>
                  {getTheriotype(item.primaryTheriotype).emoji} {item.primaryTheriotype}
                </Text>
              </View>
              {item.isPremium && <Text style={{ fontSize: 16 }}>⭐</Text>}
              <Pressable onPress={() => remove(item.uid)} style={styles.removeBtn}>
                <Text style={styles.removeTxt}>✕</Text>
              </Pressable>
            </View>
          </GlassCard>
        )}
      />

      <PaywallModal visible={showPaywall} onClose={() => setShowPaywall(false)} />
    </View>
  );
}

const styles = StyleSheet.create({
  root:   { flex: 1, backgroundColor: Colors.moonlit },
  header: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center', padding: Spacing.screen, paddingTop: 60 },
  title:  { fontSize: FontSizes.xxl, fontWeight: '700', color: Colors.pineDark },
  count:  { fontSize: FontSizes.md, fontWeight: '700', color: Colors.soil },
  list:   { paddingHorizontal: Spacing.screen, paddingBottom: 100 },
  section: { marginBottom: Spacing.lg },
  sectionLabel: {
    fontSize: FontSizes.xs, fontWeight: '600',
    color: Colors.pineDark + '66',
    textTransform: 'uppercase', letterSpacing: 0.8,
    marginBottom: 8,
  },
  requestCard:    { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', marginBottom: 8 },
  requestText:    { fontSize: FontSizes.sm, color: Colors.pineDark, flex: 1 },
  requestActions: { flexDirection: 'row', gap: 8 },
  declineBtn: { width: 32, height: 32, borderRadius: Radii.full, backgroundColor: Colors.pineDark + '10', alignItems: 'center', justifyContent: 'center' },
  declineTxt: { fontSize: 14, color: Colors.pineDark + '88' },
  acceptBtn:  { width: 32, height: 32, borderRadius: Radii.full, backgroundColor: Colors.pineMedium, alignItems: 'center', justifyContent: 'center' },
  acceptTxt:  { fontSize: 14, color: Colors.white, fontWeight: '700' },
  searchRow:  { flexDirection: 'row', gap: 8 },
  searchInput: {
    flex: 1, height: 46, borderRadius: Radii.md,
    backgroundColor: Colors.moonlitCard,
    paddingHorizontal: Spacing.md,
    fontSize: FontSizes.md, color: Colors.pineDark,
    borderWidth: 1, borderColor: Colors.pineDark + '18',
  },
  searchBtn:    { width: 46, height: 46, borderRadius: Radii.md, backgroundColor: Colors.pineMedium, alignItems: 'center', justifyContent: 'center' },
  searchBtnTxt: { fontSize: 18 },
  searchResultRow: { flexDirection: 'row', alignItems: 'center', gap: 10 },
  searchEmoji:   { fontSize: 28 },
  searchUsername:{ fontSize: FontSizes.md, fontWeight: '700', color: Colors.pineDark },
  searchType:    { fontSize: FontSizes.sm, color: Colors.pineDark + '66' },
  howlBtn: { backgroundColor: Colors.pineMedium, paddingHorizontal: 12, paddingVertical: 7, borderRadius: Radii.full },
  howlTxt: { fontSize: FontSizes.sm, color: Colors.white, fontWeight: '600' },
  memberCard: { marginBottom: 10 },
  memberRow:  { flexDirection: 'row', alignItems: 'center' },
  avatar:     { width: 44, height: 44, borderRadius: Radii.full },
  avatarFallback: { width: 44, height: 44, borderRadius: Radii.full, backgroundColor: Colors.pineDark, alignItems: 'center', justifyContent: 'center' },
  avatarLetter:   { fontSize: FontSizes.lg, color: Colors.moonlit, fontWeight: '700' },
  memberName:     { fontSize: FontSizes.md, fontWeight: '700', color: Colors.pineDark },
  memberType:     { fontSize: FontSizes.sm, color: Colors.pineDark + '66' },
  removeBtn:  { padding: 8 },
  removeTxt:  { fontSize: FontSizes.md, color: Colors.pineDark + '55' },
  empty:      { alignItems: 'center', paddingVertical: 48, gap: 8 },
  emptyEmoji: { fontSize: 48 },
  emptyTitle: { fontSize: FontSizes.xl, fontWeight: '700', color: Colors.pineDark + '66' },
  emptyText:  { fontSize: FontSizes.md, color: Colors.pineDark + '44', textAlign: 'center' },
});
