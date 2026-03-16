import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import GlassCard from './GlassCard';
import { Colors, FontSizes, Spacing, Radii } from '@/constants/theme';
import { Shift, intensityLabel } from '@/constants/types';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
dayjs.extend(relativeTime);

interface Props { shift: Shift }

export default function LatestEntryCard({ shift }: Props) {
  return (
    <GlassCard>
      {/* Header */}
      <View style={styles.row}>
        <Text style={styles.type}>{shift.type}</Text>
        <Text style={styles.date}>{dayjs(shift.date).fromNow()}</Text>
      </View>

      {/* Intensity bar */}
      <View style={styles.intensityRow}>
        <Text style={styles.intensityLabel}>
          Intensity · {intensityLabel(shift.intensity)}
        </Text>
        <Text style={styles.intensityNum}>{shift.intensity}/10</Text>
      </View>
      <View style={styles.track}>
        <View style={[styles.fill, { width: `${shift.intensity * 10}%` }]} />
      </View>

      {/* Notes */}
      {shift.notes ? (
        <Text style={styles.notes} numberOfLines={2}>{shift.notes}</Text>
      ) : null}

      {/* Tags */}
      {shift.tags.length > 0 && (
        <View style={styles.tags}>
          {shift.tags.slice(0, 4).map(tag => (
            <View key={tag} style={styles.tag}>
              <Text style={styles.tagText}>{tag}</Text>
            </View>
          ))}
        </View>
      )}
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  row: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  type: {
    fontSize: FontSizes.md,
    fontWeight: '700',
    color: Colors.pineDark,
  },
  date: {
    fontSize: FontSizes.sm,
    color: Colors.pineDark + '66',
  },
  intensityRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  intensityLabel: {
    fontSize: FontSizes.xs,
    fontWeight: '500',
    color: Colors.pineDark + '77',
    textTransform: 'uppercase',
    letterSpacing: 0.4,
  },
  intensityNum: {
    fontSize: FontSizes.xs,
    fontWeight: '700',
    color: Colors.pineMedium,
  },
  track: {
    height: 6,
    backgroundColor: Colors.pineDark + '14',
    borderRadius: Radii.full,
    marginBottom: Spacing.sm,
    overflow: 'hidden',
  },
  fill: {
    height: '100%',
    backgroundColor: Colors.soil,
    borderRadius: Radii.full,
  },
  notes: {
    fontSize: FontSizes.sm,
    color: Colors.pineDark + 'BB',
    marginBottom: Spacing.sm,
    lineHeight: 20,
  },
  tags: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
  },
  tag: {
    backgroundColor: Colors.pineMedium + '1A',
    paddingHorizontal: 10,
    paddingVertical: 3,
    borderRadius: Radii.full,
  },
  tagText: {
    fontSize: FontSizes.xs,
    color: Colors.pineMedium,
    fontWeight: '600',
  },
});
