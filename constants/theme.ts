import { Platform } from 'react-native';

// ─── Color Palette ────────────────────────────────────────────────────────────
export const Colors = {
  // Pine (Primary) — deep forest greens
  pineDark:   '#1A2421',
  pineMedium: '#2C4C3B',
  pineLight:  '#3A6B52',

  // Soil (Accent) — earthy orange/brown
  soil:       '#C85A28',
  soilLight:  '#E07040',

  // Moonlit (Background) — warm off-white
  moonlit:    '#F5F7F2',
  moonlitCard:'#EDEEF0',
  moonlitDark:'#E0E2DC',

  // Utility
  white:      '#FFFFFF',
  black:      '#000000',
  error:      '#D32F2F',
  success:    '#2E7D32',
} as const;

// ─── Gradients (array format for LinearGradient) ──────────────────────────────
export const Gradients = {
  pine:       [Colors.pineDark, Colors.pineMedium] as string[],
  soil:       [Colors.soil, Colors.soilLight] as string[],
  logShift:   [Colors.pineMedium, '#1A5C40', Colors.soil] as string[],
} as const;

// ─── Typography ───────────────────────────────────────────────────────────────
// Playfair Display for serif headers (loaded via expo-font)
// System font for body/UI (feels like SF Pro Rounded on iOS)
export const Fonts = {
  serifBold:       'PlayfairDisplay_700Bold',
  serifSemiBold:   'PlayfairDisplay_600SemiBold',
  serifRegular:    'PlayfairDisplay_400Regular',

  // System rounded (closest to SF Pro Rounded cross-platform)
  rounded: Platform.select({
    ios:     'System',
    android: 'sans-serif-medium',
    default: 'System',
  }) as string,
} as const;

export const FontSizes = {
  xs:   11,
  sm:   13,
  md:   15,
  lg:   17,
  xl:   20,
  xxl:  24,
  hero: 34,
} as const;

// ─── Spacing & Shape ─────────────────────────────────────────────────────────
export const Spacing = {
  xs:     4,
  sm:     8,
  md:     12,
  lg:     16,
  xl:     20,
  xxl:    28,
  screen: 20,
} as const;

export const Radii = {
  sm:   10,
  md:   16,
  lg:   24,   // PRD spec: cornerRadius 24
  full: 999,
} as const;

// ─── Shadows ─────────────────────────────────────────────────────────────────
export const Shadows = {
  card: {
    shadowColor:   Colors.pineDark,
    shadowOffset:  { width: 0, height: 6 },
    shadowOpacity: 0.12,
    shadowRadius:  14,
    elevation:     6,
  },
  button: {
    shadowColor:   Colors.pineDark,
    shadowOffset:  { width: 0, height: 8 },
    shadowOpacity: 0.25,
    shadowRadius:  16,
    elevation:     8,
  },
} as const;
