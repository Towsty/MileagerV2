import { use } from 'react';
import VehicleFormClient from './VehicleFormClient';

export default function ManageVehiclePage({ params }: { params: Promise<{ action: string }> }) {
  const { action } = use(params);
  return <VehicleFormClient action={action} />;
} 