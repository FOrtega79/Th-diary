import React, { useEffect } from 'react';
import { Pressable, Text, StyleSheet, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import Animated, {
  useSharedValue, useAnimatedStyle,
  withRepeat, withSequence, withTiming, withSpring,
} from 'react-native-reanimated';
import { Gradients, Colors, Radii, FontSizes, Shadows } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

interface Props { onPress: () => void }

export default function LogShiftButton({ onPress }: Props) {
  const haptics  = useHaptics();
  const glow     = useSharedValue(0.3);
  const scale    = useSharedValue(1);

  useEffect(() => {
    glow.value = withRepeat(
      withSequence(
        withTiming(0.6, { duration: 1200 }),
        withTiming(0.25, { duration: 1200 })
      ),
      -1, true
    );
  }, []);

  const glowStyle = useAnimatedStyle(() => ({
    opacity: glow.value,
  }));

  const scaleStyle = useAnimatedStyle(() => ({
    transform: [{ scale: scale.value }],
  }));

  function handlePress() {
    scale.value = withSequence(
      withSpring(0.94, { damping: 10 }),
      withSpring(1.0,  { damping: 10 })
    );
    haptics.medium();
    onPress();
  }

  return (
    <Pressable onPress={handlePress} style={styles.wrapper}>
      {/* Glow orb */}
      <Animated.View style={[styles.glow, glowStyle]} />

      {/* Button */}
      <Animated.View style={[styles.buttonWrap, scaleStyle]}>
        <LinearGradient
          colors={Gradients.logShift}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.gradient}
        >
          <Text style={styles.plus}>＋</Text>
          <Text style={styles.label}>Log a Shift</Text>
        </LinearGradient>
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  wrapper: {
    alignItems: 'center',
    justifyContent: 'center',
    height: 80,
  },
  glow: {
    position: 'absolute',
    width: 220,
    height: 100,
    borderRadius: 50,
    backgroundColor: Colors.soil,
    // blur via opacity — real blur via expo-blur if needed
  },
  buttonWrap: {
    width: '100%',
    borderRadius: Radii.lg,
    overflow: 'hidden',
    ...Shadows.button,
  },
  gradient: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    height: 66,
    paddingHorizontal: 24,
  },
  plus: {
    fontSize: 24,
    color: Colors.white,
    fontWeight: '300',
    lineHeight: 28,
  },
  label: {
    fontSize: FontSizes.xl,
    fontWeight: '700',
    color: Colors.white,
    letterSpacing: 0.3,
  },
});
