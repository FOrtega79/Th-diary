// Modal route wrapper — renders the PaywallModal component as a full-page route.
// Accessed via router.push('/paywall') from anywhere in the app.
import { router } from 'expo-router';
import PaywallModal from '@/components/PaywallModal';

export default function PaywallRoute() {
  return <PaywallModal visible onClose={() => router.back()} />;
}
