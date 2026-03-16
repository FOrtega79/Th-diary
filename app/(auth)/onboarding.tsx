import React, { useState } from 'react';
import {
  View, Text, StyleSheet, Pressable, ScrollView,
  TextInput, ActivityIndicator, Alert,
} from 'react-native';
import { router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import { auth } from '@/services/firebase';
import { createUser, isUsernameTaken } from '@/services/firestore';
import { useAuthStore } from '@/store';
import { THERIOTYPES, TherianUser } from '@/constants/types';
import { Colors, Gradients, FontSizes, Spacing, Radii, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

export default function OnboardingScreen() {
  const haptics = useHaptics();
  const { setTherianUser } = useAuthStore();
  const [step, setStep]           = useState<1 | 2>(1);
  const [theriotype, setTheriotype] = useState('Wolf');
  const [username, setUsername]   = useState('');
  const [loading, setLoading]     = useState(false);

  async function finish() {
    const uid = auth.currentUser?.uid;
    if (!uid) return;

    const trimmed = username.trim();
    if (trimmed.length < 3 || trimmed.length > 20) {
      Alert.alert('Invalid username', 'Username must be 3–20 characters.');
      return;
    }

    setLoading(true);
    try {
      const taken = await isUsernameTaken(trimmed);
      if (taken) {
        Alert.alert('Username taken', 'That username is already in use. Try another!');
        setLoading(false);
        return;
      }

      const user: TherianUser = {
        uid,
        username:           trimmed,
        primaryTheriotype:  theriotype,
        bio:                '',
        profileImageUrl:    '',
        isPremium:          false,
        packMembers:        [],
        createdAt:          new Date(),
      };

      await createUser(user);
      setTherianUser(user);
      haptics.success();
      router.replace('/(tabs)/');
    } catch (e: any) {
      Alert.alert('Error', e.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <View style={styles.root}>
      {/* Progress bar */}
      <View style={styles.progress}>
        <View style={[styles.progressBar, { flex: 1, backgroundColor: Colors.pineMedium }]} />
        <View style={[styles.progressBar, { flex: 1, backgroundColor: step === 2 ? Colors.pineMedium : Colors.pineDark + '22' }]} />
      </View>

      {step === 1 ? (
        <ScrollView contentContainerStyle={styles.scroll}>
          <Text style={styles.heading}>Welcome.</Text>
          <Text style={styles.sub}>What is your primary theriotype?</Text>

          <View style={styles.grid}>
            {THERIOTYPES.map(t => (
              <Pressable
                key={t.id}
                onPress={() => { haptics.light(); setTheriotype(t.id); }}
                style={[styles.typeCard, theriotype === t.id && styles.typeCardActive]}
              >
                <Text style={styles.typeEmoji}>{t.emoji}</Text>
                <Text style={[styles.typeLabel, theriotype === t.id && styles.typeLabelActive]}>
                  {t.id}
                </Text>
              </Pressable>
            ))}
          </View>
        </ScrollView>
      ) : (
        <View style={styles.scroll}>
          <Text style={styles.heading}>Your Name.</Text>
          <Text style={styles.sub}>Choose a unique username for your Pack.</Text>
          <View style={styles.inputWrap}>
            <Text style={styles.at}>@</Text>
            <TextInput
              value={username}
              onChangeText={setUsername}
              autoCapitalize="none"
              autoCorrect={false}
              placeholder="username"
              placeholderTextColor={Colors.pineDark + '44'}
              style={styles.input}
              maxLength={20}
              autoFocus
            />
          </View>
          <Text style={styles.hint}>3–20 characters, letters and numbers only.</Text>
        </View>
      )}

      <View style={styles.footer}>
        {loading ? (
          <ActivityIndicator color={Colors.moonlit} />
        ) : (
          <Pressable
            style={({ pressed }) => [styles.cta, { opacity: pressed ? 0.88 : 1 }]}
            onPress={() => {
              haptics.medium();
              if (step === 1) setStep(2);
              else finish();
            }}
            disabled={step === 2 && username.trim().length < 3}
          >
            <LinearGradient
              colors={Gradients.pine}
              start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}
              style={styles.ctaGradient}
            >
              <Text style={styles.ctaText}>
                {step === 1 ? 'Next' : 'Enter the Pack 🐾'}
              </Text>
            </LinearGradient>
          </Pressable>
        )}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: Colors.moonlit },
  progress: { flexDirection: 'row', gap: 6, padding: Spacing.screen, paddingTop: 60 },
  progressBar: { height: 4, borderRadius: Radii.full },
  scroll:  { flex: 1, padding: Spacing.screen },
  heading: { fontSize: FontSizes.hero, fontWeight: '700', color: Colors.pineDark, marginBottom: 6 },
  sub:     { fontSize: FontSizes.lg, color: Colors.pineDark + '99', marginBottom: Spacing.xl },
  grid:    { flexDirection: 'row', flexWrap: 'wrap', gap: 10 },
  typeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    paddingHorizontal: 14, paddingVertical: 12,
    borderRadius: Radii.md,
    backgroundColor: Colors.moonlitCard,
    borderWidth: 1.5,
    borderColor: 'transparent',
    width: '47%',
  },
  typeCardActive: {
    backgroundColor: Colors.pineDark,
    borderColor: Colors.pineMedium,
  },
  typeEmoji: { fontSize: 18 },
  typeLabel: { fontSize: FontSizes.sm, fontWeight: '600', color: Colors.pineDark },
  typeLabelActive: { color: Colors.moonlit },
  inputWrap: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: Colors.moonlitCard,
    borderRadius: Radii.md,
    paddingHorizontal: Spacing.md,
    marginBottom: Spacing.sm,
    borderWidth: 1,
    borderColor: Colors.pineMedium + '44',
  },
  at:    { fontSize: FontSizes.lg, color: Colors.pineMedium, fontWeight: '700' },
  input: { flex: 1, height: 52, fontSize: FontSizes.lg, color: Colors.pineDark },
  hint:  { fontSize: FontSizes.xs, color: Colors.pineDark + '55', paddingLeft: 4 },
  footer: { padding: Spacing.screen, paddingBottom: 48 },
  cta:   { borderRadius: Radii.lg, overflow: 'hidden', ...Shadows.button },
  ctaGradient: { height: 56, alignItems: 'center', justifyContent: 'center' },
  ctaText: { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.moonlit },
});
