import React, { useEffect, useState } from 'react';
import {
  View, Text, StyleSheet, Pressable, ActivityIndicator, Alert, Platform,
} from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import * as AppleAuthentication from 'expo-apple-authentication';
import * as WebBrowser from 'expo-web-browser';
import { signInWithApple, useGoogleAuth, handleGoogleResponse } from '@/services/auth';
import { useAuthStore } from '@/store';
import { Colors, Gradients, FontSizes, Spacing, Radii } from '@/constants/theme';
import { useHaptics } from '@/hooks/useHaptics';

WebBrowser.maybeCompleteAuthSession();

export default function LoginScreen() {
  const haptics = useHaptics();
  const { isLoading, setLoading, setError, error } = useAuthStore();
  const [request, response, promptAsync] = useGoogleAuth();

  useEffect(() => {
    if (response) handleGoogleResponse(response).catch(e => setError(e.message));
  }, [response]);

  useEffect(() => {
    if (error) {
      Alert.alert('Sign-In Error', error, [{ text: 'OK', onPress: () => setError(null) }]);
    }
  }, [error]);

  async function handleApple() {
    haptics.light();
    setLoading(true);
    try {
      await signInWithApple();
    } catch (e: any) {
      if (e.code !== 'ERR_REQUEST_CANCELED') {
        setError(e.message ?? 'Apple Sign-In failed');
        haptics.error();
      }
    } finally {
      setLoading(false);
    }
  }

  async function handleGoogle() {
    haptics.light();
    await promptAsync();
  }

  return (
    <LinearGradient colors={Gradients.pine} style={styles.root}>
      {/* Decorative orb */}
      <View style={styles.orb} />

      <View style={styles.branding}>
        <Text style={styles.paw}>🐾</Text>
        <Text style={styles.title}>Therian Diary</Text>
        <Text style={styles.tagline}>Log your shifts. Know yourself.</Text>
      </View>

      <View style={styles.actions}>
        {isLoading ? (
          <ActivityIndicator color={Colors.moonlit} size="large" />
        ) : (
          <>
            {/* Apple Sign-In — iOS only */}
            {Platform.OS === 'ios' && (
              <AppleAuthentication.AppleAuthenticationButton
                buttonType={AppleAuthentication.AppleAuthenticationButtonType.SIGN_IN}
                buttonStyle={AppleAuthentication.AppleAuthenticationButtonStyle.WHITE}
                cornerRadius={Radii.lg}
                style={styles.appleBtn}
                onPress={handleApple}
              />
            )}

            {/* Google */}
            <Pressable
              style={({ pressed }) => [styles.googleBtn, { opacity: pressed ? 0.85 : 1 }]}
              onPress={handleGoogle}
              disabled={!request}
            >
              <Text style={styles.googleIcon}>G</Text>
              <Text style={styles.googleText}>Continue with Google</Text>
            </Pressable>
          </>
        )}
      </View>
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, justifyContent: 'space-between', paddingBottom: 60 },
  orb: {
    position: 'absolute',
    width: 320, height: 320,
    borderRadius: 160,
    backgroundColor: Colors.soil,
    opacity: 0.18,
    top: -80, right: -80,
  },
  branding: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: Spacing.md,
  },
  paw:      { fontSize: 64 },
  title:    { fontSize: FontSizes.hero, fontWeight: '700', color: Colors.moonlit },
  tagline:  { fontSize: FontSizes.lg, color: Colors.moonlit + 'AA', textAlign: 'center' },
  actions:  { paddingHorizontal: Spacing.screen, gap: Spacing.md },
  appleBtn: { height: 54, width: '100%' },
  googleBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    height: 54,
    backgroundColor: Colors.white,
    borderRadius: Radii.lg,
  },
  googleIcon: { fontSize: FontSizes.lg, fontWeight: '700', color: Colors.pineDark },
  googleText: { fontSize: FontSizes.md, fontWeight: '600', color: Colors.pineDark },
});
