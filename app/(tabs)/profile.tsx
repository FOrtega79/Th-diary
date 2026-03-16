import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable,
  TextInput, Alert, ActivityIndicator,
} from 'react-native';
import { Image } from 'expo-image';
import { router } from 'expo-router';
import * as ImagePicker from 'expo-image-picker';
import { updateUser } from '@/services/firestore';
import { uploadProfileImage } from '@/services/storage';
import { isUsernameTaken } from '@/services/firestore';
import { signOut } from '@/services/auth';
import { logOutPurchases } from '@/services/revenuecat';
import { useAuthStore, usePurchaseStore, useAdUnlockStore } from '@/store';
import { THERIOTYPES, getTheriotype } from '@/constants/types';
import { AD_TRIGGER_COPY, showRewardedAd } from '@/services/admob';
import { Colors, FontSizes, Spacing, Radii, Gradients, Shadows } from '@/constants/theme';
import { LinearGradient } from 'expo-linear-gradient';
import { useHaptics } from '@/hooks/useHaptics';
import GlassCard from '@/components/GlassCard';
import PaywallModal from '@/components/PaywallModal';

export default function ProfileScreen() {
  const haptics = useHaptics();
  const { therianUser, updateTherianUser, clear } = useAuthStore();
  const { isPremium } = usePurchaseStore();
  const { hasBioEdit, grantBioEdit } = useAdUnlockStore();

  const [editing, setEditing]         = useState(false);
  const [editUsername, setEditUsername]   = useState(therianUser?.username ?? '');
  const [editBio, setEditBio]             = useState(therianUser?.bio ?? '');
  const [editSecondary, setEditSecondary] = useState(therianUser?.secondaryTheriotype ?? '');
  const [newImageUri, setNewImageUri]     = useState<string | null>(null);
  const [saving, setSaving]               = useState(false);
  const [showPaywall, setShowPaywall]     = useState(false);

  if (!therianUser) return null;

  const primary   = getTheriotype(therianUser.primaryTheriotype);
  const bioUnlocked = isPremium || hasBioEdit();

  function startEdit() {
    if (!isPremium) { setShowPaywall(true); return; }
    setEditUsername(therianUser!.username);
    setEditBio(therianUser!.bio);
    setEditSecondary(therianUser!.secondaryTheriotype ?? '');
    setNewImageUri(null);
    setEditing(true);
  }

  async function pickImage() {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ImagePicker.MediaTypeOptions.Images,
      allowsEditing: true,
      aspect: [1, 1],
      quality: 0.8,
    });
    if (!result.canceled) setNewImageUri(result.assets[0].uri);
  }

  async function saveProfile() {
    const trimmed = editUsername.trim();
    if (trimmed.length < 3) {
      Alert.alert('Invalid username', 'Username must be at least 3 characters.');
      return;
    }
    setSaving(true);
    try {
      const updates: Record<string, any> = {
        bio: editBio.trim(),
        secondaryTheriotype: editSecondary || null,
      };

      if (trimmed !== therianUser!.username) {
        const taken = await isUsernameTaken(trimmed);
        if (taken) { Alert.alert('Username taken', 'Try another!'); setSaving(false); return; }
        updates.username = trimmed;
      }

      if (newImageUri) {
        const url = await uploadProfileImage(newImageUri, therianUser!.uid);
        updates.profileImageUrl = url;
      }

      await updateUser(therianUser!.uid, updates);
      updateTherianUser(updates);
      haptics.success();
      setEditing(false);
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setSaving(false);
    }
  }

  function handleSignOut() {
    Alert.alert('Sign Out', 'Are you sure?', [
      { text: 'Sign Out', style: 'destructive', onPress: async () => {
        await signOut();
        logOutPurchases();
        clear();
        router.replace('/(auth)/login');
      }},
      { text: 'Cancel', style: 'cancel' },
    ]);
  }

  function handleBioEdit() {
    if (bioUnlocked) { setEditing(true); return; }
    Alert.alert(
      AD_TRIGGER_COPY.bioEdit.title,
      AD_TRIGGER_COPY.bioEdit.message,
      [
        { text: 'Watch Ad', onPress: () => showRewardedAd(() => { grantBioEdit(); setEditing(true); }) },
        { text: 'Upgrade to Pro', onPress: () => setShowPaywall(true) },
        { text: 'Cancel', style: 'cancel' },
      ]
    );
  }

  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
      {/* Avatar */}
      <View style={styles.avatarSection}>
        <Pressable onPress={editing ? pickImage : undefined} style={styles.avatarWrap}>
          {(newImageUri ?? therianUser.profileImageUrl) ? (
            <Image
              source={{ uri: newImageUri ?? therianUser.profileImageUrl }}
              style={styles.avatar}
              contentFit="cover"
            />
          ) : (
            <LinearGradient colors={Gradients.pine} style={styles.avatarFallback}>
              <Text style={styles.avatarLetter}>{therianUser.username[0].toUpperCase()}</Text>
            </LinearGradient>
          )}
          {editing && <View style={styles.cameraOverlay}><Text style={styles.cameraIcon}>📷</Text></View>}
          {isPremium && !editing && (
            <View style={styles.premiumBadge}><Text style={{ fontSize: 12 }}>⭐</Text></View>
          )}
        </Pressable>

        <Text style={styles.username}>@{therianUser.username}</Text>
        <Text style={styles.type}>{primary.emoji} {primary.id}</Text>
        {isPremium && (
          <View style={styles.proBadge}>
            <Text style={styles.proBadgeText}>Therian Pro ⭐</Text>
          </View>
        )}
      </View>

      {/* Edit / view */}
      {editing ? (
        <GlassCard style={styles.editCard}>
          <Text style={styles.fieldLabel}>Username</Text>
          <TextInput
            value={editUsername}
            onChangeText={setEditUsername}
            style={styles.input}
            autoCapitalize="none"
            autoCorrect={false}
          />

          <Text style={[styles.fieldLabel, { marginTop: 12 }]}>Bio</Text>
          <TextInput
            value={editBio}
            onChangeText={setEditBio}
            style={[styles.input, styles.bioInput]}
            multiline
            placeholder="Tell your pack about yourself..."
            placeholderTextColor={Colors.pineDark + '44'}
            textAlignVertical="top"
          />

          {isPremium && (
            <>
              <Text style={[styles.fieldLabel, { marginTop: 12 }]}>Secondary Theriotype</Text>
              <View style={styles.typeGrid}>
                {THERIOTYPES.map(t => (
                  <Pressable
                    key={t.id}
                    onPress={() => setEditSecondary(t.id === editSecondary ? '' : t.id)}
                    style={[styles.typeChip, editSecondary === t.id && styles.typeChipActive]}
                  >
                    <Text style={styles.typeChipText}>{t.emoji} {t.id}</Text>
                  </Pressable>
                ))}
              </View>
            </>
          )}

          <View style={styles.editActions}>
            <Pressable style={styles.cancelBtn} onPress={() => setEditing(false)}>
              <Text style={styles.cancelTxt}>Cancel</Text>
            </Pressable>
            <Pressable style={styles.saveWrap} onPress={saveProfile} disabled={saving}>
              <LinearGradient colors={Gradients.pine} style={styles.saveGradient}>
                {saving ? <ActivityIndicator color={Colors.moonlit} /> : <Text style={styles.saveTxt}>Save</Text>}
              </LinearGradient>
            </Pressable>
          </View>
        </GlassCard>
      ) : (
        <>
          {therianUser.bio ? (
            <GlassCard>
              <Text style={styles.bioText}>{therianUser.bio}</Text>
            </GlassCard>
          ) : null}

          {therianUser.secondaryTheriotype && isPremium && (
            <GlassCard padding={14} style={styles.secondaryCard}>
              <Text style={styles.fieldLabel}>Secondary Theriotype</Text>
              <Text style={styles.secondaryType}>
                {getTheriotype(therianUser.secondaryTheriotype).emoji}{' '}
                {therianUser.secondaryTheriotype}
              </Text>
            </GlassCard>
          )}
        </>
      )}

      {/* Settings */}
      {!editing && (
        <View style={styles.settings}>
          <SettingsRow icon="✏️" label="Edit Profile" onPress={startEdit} />
          {!isPremium && (
            <SettingsRow icon="⭐" label="Upgrade to Therian Pro" onPress={() => setShowPaywall(true)} accent />
          )}
          <SettingsRow icon="🚪" label="Sign Out" onPress={handleSignOut} />
        </View>
      )}

      <View style={{ height: 100 }} />
      <PaywallModal visible={showPaywall} onClose={() => setShowPaywall(false)} />
    </ScrollView>
  );
}

function SettingsRow({ icon, label, onPress, accent }: { icon: string; label: string; onPress: () => void; accent?: boolean }) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.settingsRow, { opacity: pressed ? 0.7 : 1 }]}>
      <Text style={styles.settingsIcon}>{icon}</Text>
      <Text style={[styles.settingsLabel, accent && { color: Colors.soil }]}>{label}</Text>
      <Text style={styles.settingsArrow}>›</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: Colors.moonlit },
  scroll:  { padding: Spacing.screen, paddingTop: 60, gap: Spacing.xl },
  avatarSection: { alignItems: 'center', gap: 8 },
  avatarWrap: { position: 'relative' },
  avatar: { width: 96, height: 96, borderRadius: Radii.full, borderWidth: 3, borderColor: Colors.pineMedium + '55' },
  avatarFallback: { width: 96, height: 96, borderRadius: Radii.full, alignItems: 'center', justifyContent: 'center' },
  avatarLetter:   { fontSize: 38, fontWeight: '700', color: Colors.moonlit },
  cameraOverlay:  { position: 'absolute', bottom: 0, right: 0, width: 28, height: 28, borderRadius: Radii.full, backgroundColor: Colors.soil, alignItems: 'center', justifyContent: 'center' },
  cameraIcon:     { fontSize: 14 },
  premiumBadge:   { position: 'absolute', bottom: 0, right: 0, width: 24, height: 24, borderRadius: Radii.full, backgroundColor: Colors.white, alignItems: 'center', justifyContent: 'center', ...Shadows.card },
  username: { fontSize: FontSizes.xl, fontWeight: '700', color: Colors.pineDark },
  type:     { fontSize: FontSizes.md, color: Colors.pineDark + '88' },
  proBadge: { backgroundColor: Colors.soil + '22', paddingHorizontal: 12, paddingVertical: 4, borderRadius: Radii.full },
  proBadgeText: { fontSize: FontSizes.sm, color: Colors.soil, fontWeight: '700' },
  editCard: { gap: Spacing.xs },
  fieldLabel: { fontSize: FontSizes.xs, fontWeight: '600', color: Colors.pineDark + '66', textTransform: 'uppercase', letterSpacing: 0.8 },
  input: { backgroundColor: Colors.moonlitCard, borderRadius: Radii.md, paddingHorizontal: Spacing.md, height: 48, fontSize: FontSizes.md, color: Colors.pineDark, borderWidth: 1, borderColor: Colors.pineDark + '18' },
  bioInput: { height: 90, paddingTop: Spacing.sm },
  typeGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 6 },
  typeChip: { paddingHorizontal: 10, paddingVertical: 6, borderRadius: Radii.full, backgroundColor: Colors.moonlitCard },
  typeChipActive: { backgroundColor: Colors.pineDark },
  typeChipText: { fontSize: FontSizes.sm, color: Colors.pineDark },
  editActions: { flexDirection: 'row', gap: 10, marginTop: Spacing.md },
  cancelBtn:   { flex: 1, height: 48, borderRadius: Radii.md, backgroundColor: Colors.pineDark + '10', alignItems: 'center', justifyContent: 'center' },
  cancelTxt:   { fontSize: FontSizes.md, fontWeight: '600', color: Colors.pineDark + '77' },
  saveWrap:    { flex: 2, borderRadius: Radii.md, overflow: 'hidden', ...Shadows.button },
  saveGradient:{ height: 48, alignItems: 'center', justifyContent: 'center' },
  saveTxt:     { fontSize: FontSizes.md, fontWeight: '700', color: Colors.moonlit },
  bioText:     { fontSize: FontSizes.md, color: Colors.pineDark + 'CC', lineHeight: 22 },
  secondaryCard: {},
  secondaryType: { fontSize: FontSizes.lg, color: Colors.pineDark, marginTop: 4 },
  settings: { borderRadius: Radii.lg, overflow: 'hidden', backgroundColor: Colors.white, ...Shadows.card },
  settingsRow: { flexDirection: 'row', alignItems: 'center', padding: Spacing.lg, borderBottomWidth: 1, borderBottomColor: Colors.pineDark + '0A', gap: 12 },
  settingsIcon:  { fontSize: 18, width: 28 },
  settingsLabel: { flex: 1, fontSize: FontSizes.md, fontWeight: '500', color: Colors.pineDark },
  settingsArrow: { fontSize: FontSizes.xl, color: Colors.pineDark + '33', fontWeight: '300' },
});
