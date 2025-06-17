// Server Component wrapper
import { use } from 'react';
import MileagePageClient from './MileagePageClient';

export default function MileagePage({ params }: { params: Promise<{ id: string }> }) {
  const { id: vehicleId } = use(params);
  return <MileagePageClient vehicleId={vehicleId} />;
} 