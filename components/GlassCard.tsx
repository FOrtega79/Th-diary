import React from 'react';
import { StyleSheet, ViewStyle } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors, Radii, Spacing, Shadows } from '@/constants/theme';

interface Props {
  children: React.ReactNode;
  style?: ViewStyle;
  padding?: number;
  radius?: number;
}

export default function GlassCard({
  children,
  style,
  padding = Spacing.lg,
  radius = Radii.lg,
}: Props) {
  return (
    <BlurView
      intensity={30}
      tint="light"
      style={[
        styles.card,
        { padding, borderRadius: radius },
        style,
      ]}
    >
      {children}
    </BlurView>
  );
}

const styles = StyleSheet.create({
  card: {
    overflow: 'hidden',
    backgroundColor: 'rgba(255,255,255,0.55)',
    borderWidth: 1,
    borderColor: 'rgba(255,255,255,0.35)',
    ...Shadows.card,
  },
});
