import { Tabs } from 'expo-router';
import { Platform, StyleSheet, View, Text } from 'react-native';
import { BlurView } from 'expo-blur';
import { Colors, FontSizes } from '@/constants/theme';

const TABS = [
  { name: 'index',   label: 'Home',    emoji: '🏠' },
  { name: 'pack',    label: 'Pack',    emoji: '🐾' },
  { name: 'stats',   label: 'Stats',   emoji: '📊' },
  { name: 'profile', label: 'Profile', emoji: '🪐' },
];

export default function TabLayout() {
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarStyle:            styles.tabBar,
        tabBarBackground: ()   => (
          <BlurView intensity={50} tint="light" style={StyleSheet.absoluteFill} />
        ),
        tabBarActiveTintColor:   Colors.soil,
        tabBarInactiveTintColor: Colors.pineDark + '55',
        tabBarLabelStyle:        styles.label,
      }}
    >
      {TABS.map(tab => (
        <Tabs.Screen
          key={tab.name}
          name={tab.name}
          options={{
            title: tab.label,
            tabBarIcon: ({ focused }) => (
              <Text style={{ fontSize: focused ? 22 : 20, opacity: focused ? 1 : 0.5 }}>
                {tab.emoji}
              </Text>
            ),
          }}
        />
      ))}
    </Tabs>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    position: 'absolute',
    borderTopWidth: 0,
    elevation: 0,
    backgroundColor: 'transparent',
    height: Platform.select({ ios: 84, android: 64 }),
    paddingBottom: Platform.select({ ios: 28, android: 8 }),
  },
  label: {
    fontSize: FontSizes.xs,
    fontWeight: '600',
  },
});
