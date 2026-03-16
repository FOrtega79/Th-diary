import React, { useEffect } from 'react';
import { Pressable, Text, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue, useAnimatedStyle, withRepeat,
  withTiming, withSequence,
} from 'react-native-reanimated';
import { Gradients, Colors, Radii, FontSizes, Spacing, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

interface Props { onPress: () => void }

export default function ProBanner({ onPress }: Props) {
  const haptics = useHaptics();
  const shimmer = useSharedValue(-200);

  useEffect(() => {
    shimmer.value = withRepeat(
      withSequence(
        withTiming(400, { duration: 2200 }),
        withTiming(-200, { duration: 0 })
      ),
      -1, false
    );
  }, []);

  const shimmerStyle = useAnimatedStyle(() => ({
    transform: [{ translateX: shimmer.value }],
  }));

  return (
    <Pressable
      onPress={() => { haptics.light(); onPress(); }}
      style={({ pressed }) => [styles.wrapper, { opacity: pressed ? 0.88 : 1 }]}
    >
      <LinearGradient
        colors={Gradients.pine}
        start={{ x: 0, y: 0 }}
        end={{ x: 1, y: 1 }}
        style={styles.gradient}
      >
        {/* Shimmer */}
        <Animated.View style={[styles.shimmer, shimmerStyle]} />

        <Text style={styles.star}>⭐</Text>
        <View style={styles.text}>
          <Text style={styles.title}>Upgrade to Therian Pro</Text>
          <Text style={styles.sub}>Unlock everything · Free trial</Text>
        </View>
        <Text style={styles.arrow}>›</Text>
      </LinearGradient>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    borderRadius: Radii.lg,
    overflow: 'hidden',
    ...Shadows.button,
  },
  gradient: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: Spacing.lg,
    gap: Spacing.md,
    overflow: 'hidden',
  },
  shimmer: {
    position: 'absolute',
    top: 0, bottom: 0,
    width: 80,
    backgroundColor: 'rgba(255,255,255,0.12)',
    transform: [{ skewX: '-20deg' }],
  },
  star: { fontSize: 26 },
  text: { flex: 1 },
  title: {
    fontSize: FontSizes.md,
    fontWeight: '700',
    color: Colors.moonlit,
  },
  sub: {
    fontSize: FontSizes.sm,
    color: Colors.moonlit + 'AA',
    marginTop: 2,
  },
  arrow: {
    fontSize: 22,
    color: Colors.moonlit + '88',
    fontWeight: '300',
  },
});
