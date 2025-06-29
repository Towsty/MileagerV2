// import { db } from '@/lib/firebase';
// import { collection, getDocs } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import { Vehicle, Trip, TripPurpose } from '@/types';

// interface Stats {
//   totalVehicles: number;
//   totalTrips: number;
//   totalMiles: number;
// }

interface StatsOverviewProps {
  vehicles: Vehicle[];
  trips: Trip[];
}

export default function StatsOverview({ vehicles, trips }: StatsOverviewProps) {
  // const [stats, setStats] = useState<Stats>({
  //   totalVehicles: 0,
  //   totalTrips: 0,
  //   totalMiles: 0,
  // });

  // useEffect(() => {
  //   async function fetchStats() {
  //     const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
  //     const tripsSnapshot = await getDocs(collection(db, 'trips'));
  //
  //     let totalMiles = 0;
  //     tripsSnapshot.forEach((doc) => {
  //       const trip = doc.data();
  //       totalMiles += trip.miles || 0;
  //     });
  //
  //     setStats({
  //       totalVehicles: vehiclesSnapshot.size,
  //       totalTrips: tripsSnapshot.size,
  //       totalMiles: totalMiles,
  //     });
  //   }
  //
  //   fetchStats();
  // }, []);

  const totalVehicles = vehicles.length;
  const totalTrips = trips.length;
  const totalMiles = trips.reduce((sum, trip) => sum + trip.distance, 0);
  const businessMiles = trips
    .filter((trip) => trip.purpose === TripPurpose.Business)
    .reduce((sum, trip) => sum + trip.distance, 0);

  const stats = [
    {
      name: 'Total Vehicles',
      value: totalVehicles,
      unit: 'vehicles',
    },
    {
      name: 'Total Trips',
      value: totalTrips,
      unit: 'trips',
    },
    {
      name: 'Total Miles',
      value: totalMiles.toFixed(1),
      unit: 'miles',
    },
    {
      name: 'Business Miles',
      value: businessMiles.toFixed(1),
      unit: 'miles',
    },
  ];

  return (
    <div>
      <dl className="mt-5 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <div
            key={stat.name}
            className="relative overflow-hidden rounded-lg bg-white px-4 pb-12 pt-5 shadow sm:px-6 sm:pt-6"
          >
            <dt>
              <div className="absolute rounded-md bg-primary-500 p-3">
                <svg
                  className="h-6 w-6 text-white"
                  fill="none"
                  viewBox="0 0 24 24"
                  strokeWidth={1.5}
                  stroke="currentColor"
                >
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M8.25 18.75a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 01-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 01-3 0m3 0a1.5 1.5 0 00-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 00-3.213-9.193 2.056 2.056 0 00-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 00-10.026 0 1.106 1.106 0 00-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12"
                  />
                </svg>
              </div>
              <p className="ml-16 truncate text-sm font-medium text-gray-500">
                {stat.name}
              </p>
            </dt>
            <dd className="ml-16 flex items-baseline pb-6 sm:pb-7">
              <p className="text-2xl font-semibold text-gray-900">
                {stat.value}
              </p>
              <p className="ml-2 text-sm text-gray-500">{stat.unit}</p>
            </dd>
          </div>
        ))}
      </dl>
    </div>
  );
} 