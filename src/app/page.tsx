import { Suspense } from 'react';
// import VehicleList from '@/components/VehicleList';
// import RecentTrips from '@/components/RecentTrips';
// import StatsOverview from '@/components/StatsOverview';

export default function Home() {
  return (
    <div className="space-y-6">
      <div className="md:flex md:items-center md:justify-between">
        <div className="min-w-0 flex-1">
          <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:truncate sm:text-3xl sm:tracking-tight">
            Dashboard
          </h2>
        </div>
      </div>

      {/* <Suspense fallback={<div>Loading stats...</div>}>
        <StatsOverview />
      </Suspense>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Suspense fallback={<div>Loading vehicles...</div>}>
          <VehicleList />
        </Suspense>

        <Suspense fallback={<div>Loading recent trips...</div>}>
          <RecentTrips />
        </Suspense>
      </div> */}
      <div className="text-red-500">All dashboard components disabled for Firebase debug</div>
    </div>
  );
} 