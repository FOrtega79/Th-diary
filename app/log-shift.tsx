import React, { useState } from 'react';
import {
  View, Text, StyleSheet, ScrollView, Pressable,
  TextInput, Alert, ActivityIndicator,
} from 'react-native';
import { router } from 'expo-router';
import { LinearGradient } from 'expo-linear-gradient';
import Slider from '@react-native-community/slider';
import { saveShift } from '@/services/firestore';
import { useAuthStore, useShiftStore } from '@/store';
import { SHIFT_TYPES, SHIFT_TAGS, ShiftTypeName, Shift } from '@/constants/types';
import { Colors, Gradients, FontSizes, Spacing, Radii, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

export default function LogShiftModal() {
  const haptics = useHaptics();
  const { therianUser } = useAuthStore();
  const { addShift }    = useShiftStore();

  const [type, setType]       = useState<ShiftTypeName>('Mental');
  const [intensity, setIntensity] = useState(5);
  const [tags, setTags]       = useState<Set<string>>(new Set());
  const [notes, setNotes]     = useState('');
  const [saving, setSaving]   = useState(false);
  const [saved, setSaved]     = useState(false);

  async function handleSave() {
    if (!therianUser) return;
    setSaving(true);
    try {
      const shift: Shift = {
        shiftId:   `${therianUser.uid}_${Date.now()}`,
        userId:    therianUser.uid,
        type,
        intensity,
        tags:      Array.from(tags),
        notes:     notes.trim(),
        date:      new Date(),
      };
      await saveShift(shift);
      addShift(shift);
      await haptics.medium();
      setSaved(true);
      setTimeout(() => router.back(), 900);
    } catch (e: any) {
      Alert.alert('Error', e.message);
      haptics.error();
    } finally {
      setSaving(false);
    }
  }

  function toggleTag(tag: string) {
    haptics.light();
    setTags(prev => {
      const next = new Set(prev);
      next.has(tag) ? next.delete(tag) : next.add(tag);
      return next;
    });
  }

  return (
    <View style={styles.root}>
      {/* Handle */}
      <View style={styles.handle} />

      <View style={styles.titleRow}>
        <Text style={styles.title}>Log a Shift</Text>
        <Pressable onPress={() => router.back()}>
          <Text style={styles.close}>✕</Text>
        </Pressable>
      </View>

      <ScrollView contentContainerStyle={styles.scroll} showsVerticalScrollIndicator={false}>
        {/* Shift Type */}
        <Text style={styles.label}>Shift Type</Text>
        <ScrollView horizontal showsHorizontalScrollIndicator={false} style={styles.typeScroll}>
          {SHIFT_TYPES.map(t => (
            <Pressable
              key={t.id}
              onPress={() => { haptics.light(); setType(t.id); }}
              style={[styles.typeChip, type === t.id && styles.typeChipActive]}
            >
              <Text style={[styles.typeChipText, type === t.id && styles.typeChipTextActive]}>
                {t.id}
              </Text>
            </Pressable>
          ))}
        </ScrollView>
        <Text style={styles.hint}>{SHIFT_TYPES.find(t => t.id === type)?.description}</Text>

        {/* Intensity */}
        <View style={styles.intensityHeader}>
          <Text style={styles.label}>Intensity</Text>
          <Text style={styles.intensityValue}>{intensity} / 10</Text>
        </View>
        <Slider
          minimumValue={1}
          maximumValue={10}
          step={1}
          value={intensity}
          onValueChange={v => { setIntensity(Math.round(v)); haptics.light(); }}
          minimumTrackTintColor={Colors.soil}
          maximumTrackTintColor={Colors.pineDark + '22'}
          thumbTintColor={Colors.soil}
          style={styles.slider}
        />
        <View style={styles.sliderLabels}>
          <Text style={styles.hint}>Mild</Text>
          <Text style={styles.hint}>Moderate</Text>
          <Text style={styles.hint}>Intense</Text>
        </View>

        {/* Tags */}
        <Text style={styles.label}>Triggers / Tags</Text>
        <View style={styles.tagWrap}>
          {SHIFT_TAGS.map(tag => (
            <Pressable
              key={tag}
              onPress={() => toggleTag(tag)}
              style={[styles.tag, tags.has(tag) && styles.tagActive]}
            >
              <Text style={[styles.tagText, tags.has(tag) && styles.tagTextActive]}>
                {tag}
              </Text>
            </Pressable>
          ))}
        </View>

        {/* Notes */}
        <Text style={styles.label}>Journal Entry</Text>
        <TextInput
          value={notes}
          onChangeText={setNotes}
          placeholder="Describe your experience..."
          placeholderTextColor={Colors.pineDark + '44'}
          multiline
          style={styles.notes}
          textAlignVertical="top"
        />

        {/* Save */}
        <Pressable
          onPress={handleSave}
          disabled={saving || saved}
          style={styles.saveWrap}
        >
          <LinearGradient
            colors={saved ? [Colors.pineMedium, Colors.pineMedium] : Gradients.logShift}
            start={{ x: 0, y: 0 }} end={{ x: 1, y: 1 }}
            style={styles.saveGradient}
          >
            {saving ? (
              <ActivityIndicator color={Colors.white} />
            ) : (
              <Text style={styles.saveText}>{saved ? '✓ Saved!' : 'Save Entry'}</Text>
            )}
          </LinearGradient>
        </Pressable>

        <View style={{ height: 40 }} />
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  root:    { flex: 1, backgroundColor: Colors.moonlit },
  handle: {
    width: 36, height: 4, borderRadius: Radii.full,
    backgroundColor: Colors.pineDark + '33',
    alignSelf: 'center', marginTop: 10,
  },
  titleRow: {
    flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center',
    paddingHorizontal: Spacing.screen, paddingVertical: Spacing.md,
  },
  title: { fontSize: FontSizes.xxl, fontWeight: '700', color: Colors.pineDark },
  close: { fontSize: FontSizes.xl, color: Colors.pineDark + '66', fontWeight: '600' },
  scroll:  { padding: Spacing.screen, gap: Spacing.md },
  label:   {
    fontSize: FontSizes.xs, fontWeight: '600',
    color: Colors.pineDark + '66',
    textTransform: 'uppercase', letterSpacing: 0.8,
    marginBottom: 4,
  },
  hint:    { fontSize: FontSizes.sm, color: Colors.pineDark + '55', marginTop: -4 },
  typeScroll: { marginBottom: 6 },
  typeChip: {
    paddingHorizontal: 14, paddingVertical: 9,
    borderRadius: Radii.full,
    backgroundColor: Colors.moonlitCard,
    marginRight: 8,
    borderWidth: 1.5, borderColor: 'transparent',
  },
  typeChipActive: { backgroundColor: Colors.pineDark, borderColor: Colors.pineMedium },
  typeChipText:   { fontSize: FontSizes.sm, fontWeight: '600', color: Colors.pineDark },
  typeChipTextActive: { color: Colors.moonlit },
  intensityHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  intensityValue:  { fontSize: FontSizes.md, fontWeight: '700', color: Colors.pineMedium },
  slider:  { marginHorizontal: -8 },
  sliderLabels: { flexDirection: 'row', justifyContent: 'space-between' },
  tagWrap: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  tag: {
    paddingHorizontal: 12, paddingVertical: 6,
    borderRadius: Radii.full,
    backgroundColor: Colors.moonlitCard,
  },
  tagActive: { backgroundColor: Colors.pineMedium },
  tagText:       { fontSize: FontSizes.sm, fontWeight: '500', color: Colors.pineDark },
  tagTextActive: { color: Colors.white },
  notes: {
    height: 130,
    fontSize: FontSizes.md,
    color: Colors.pineDark,
    backgroundColor: Colors.moonlitCard,
    borderRadius: Radii.md,
    padding: Spacing.md,
    borderWidth: 1, borderColor: Colors.pineDark + '18',
  },
  saveWrap:     { borderRadius: Radii.lg, overflow: 'hidden', ...Shadows.button },
  saveGradient: { height: 56, alignItems: 'center', justifyContent: 'center' },
  saveText:     { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.white },
});
