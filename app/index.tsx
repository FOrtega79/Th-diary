import { useEffect } from 'react';
import { View, StyleSheet } from 'react-native';
import { Redirect } from 'expo-router';
import { useAuthStore } from '@/store';
import { Colors } from '@/constants/theme';

// Redirects to the right screen once auth state is known.
// Shows a plain background while Firebase resolves (Expo SplashScreen covers it).
export default function Index() {
  const { authReady, firebaseUser, therianUser } = useAuthStore();

  if (!authReady) {
    return <View style={styles.splash} />;
  }

  if (!firebaseUser) {
    return <Redirect href="/(auth)/login" />;
  }

  if (!therianUser) {
    return <Redirect href="/(auth)/onboarding" />;
  }

  return <Redirect href="/(tabs)/" />;
}

const styles = StyleSheet.create({
  splash: { flex: 1, backgroundColor: Colors.pineDark },
});
