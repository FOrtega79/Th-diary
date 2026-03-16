import * as Haptics from 'expo-haptics';

export function useHaptics() {
  return {
    light:   () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light),
    medium:  () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium),
    heavy:   () => Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy),
    success: () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success),
    error:   () => Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error),
    payment: async () => {
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Heavy);
      await new Promise(r => setTimeout(r, 100));
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);
      await new Promise(r => setTimeout(r, 100));
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    },
  };
}
