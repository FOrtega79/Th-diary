import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import GlassCard from './GlassCard';
import { Colors, FontSizes, Spacing } from '@/constants/theme';

interface Props {
  title: string;
  value: string;
  emoji: string;
}

export default function StatsCard({ title, value, emoji }: Props) {
  return (
    <GlassCard style={styles.card} padding={Spacing.md}>
      <Text style={styles.emoji}>{emoji}</Text>
      <Text style={styles.value}>{value}</Text>
      <Text style={styles.title}>{title}</Text>
    </GlassCard>
  );
}

const styles = StyleSheet.create({
  card: {
    flex: 1,
    alignItems: 'flex-start',
    gap: 4,
  },
  emoji: {
    fontSize: 22,
    marginBottom: 2,
  },
  value: {
    fontSize: FontSizes.hero,
    fontWeight: '700',
    color: Colors.pineDark,
    lineHeight: 38,
  },
  title: {
    fontSize: FontSizes.sm,
    fontWeight: '500',
    color: Colors.pineDark + '88',
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
});
