import React, { useEffect } from 'react';
import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { StyleSheet } from 'react-native';
import * as SplashScreen from 'expo-splash-screen';
import { useFonts, PlayfairDisplay_400Regular, PlayfairDisplay_600SemiBold, PlayfairDisplay_700Bold } from '@expo-google-fonts/playfair-display';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '@/services/firebase';
import { fetchUser } from '@/services/firestore';
import { configurePurchases, getIsPremium, identifyUser } from '@/services/revenuecat';
import { useAuthStore, usePurchaseStore } from '@/store';

SplashScreen.preventAutoHideAsync();

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    PlayfairDisplay_400Regular,
    PlayfairDisplay_600SemiBold,
    PlayfairDisplay_700Bold,
  });

  const { setFirebaseUser, setTherianUser, setAuthReady } = useAuthStore();
  const { setIsPremium } = usePurchaseStore();

  useEffect(() => {
    configurePurchases();
  }, []);

  useEffect(() => {
    const unsub = onAuthStateChanged(auth, async (firebaseUser) => {
      setFirebaseUser(firebaseUser);

      if (firebaseUser) {
        const [profile, isPremium] = await Promise.all([
          fetchUser(firebaseUser.uid),
          getIsPremium().catch(() => false),
        ]);
        setTherianUser(profile);
        setIsPremium(isPremium);
        identifyUser(firebaseUser.uid);
      } else {
        setTherianUser(null);
        setIsPremium(false);
      }

      setAuthReady(true);
    });
    return unsub;
  }, []);

  useEffect(() => {
    if (fontsLoaded) SplashScreen.hideAsync();
  }, [fontsLoaded]);

  if (!fontsLoaded) return null;

  return (
    <GestureHandlerRootView style={styles.root}>
      <StatusBar style="dark" />
      <Stack screenOptions={{ headerShown: false }}>
        <Stack.Screen name="index" />
        <Stack.Screen name="(auth)" />
        <Stack.Screen name="(tabs)" />
        <Stack.Screen
          name="log-shift"
          options={{ presentation: 'modal', animation: 'slide_from_bottom' }}
        />
        <Stack.Screen
          name="paywall"
          options={{ presentation: 'modal', animation: 'slide_from_bottom' }}
        />
      </Stack>
    </GestureHandlerRootView>
  );
}

const styles = StyleSheet.create({ root: { flex: 1 } });
