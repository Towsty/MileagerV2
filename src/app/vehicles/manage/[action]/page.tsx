import VehicleFormClient from './VehicleFormClient';

interface PageProps {
  params: {
    action: string;
  };
  searchParams: {
    id?: string;
  };
}

export default function VehicleFormPage({ params, searchParams }: PageProps) {
  const action = params.action === 'edit' ? 'edit' : 'add';
  const vehicleId = searchParams.id;

  return (
    <VehicleFormClient 
      action={action} 
      vehicleId={vehicleId}
    />
  );
} 