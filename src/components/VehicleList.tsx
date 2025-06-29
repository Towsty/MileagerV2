// import { db } from '@/lib/firebase';
// import { collection, getDocs } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import Image from 'next/image';
import { Vehicle } from '@/types';

// interface Vehicle {
//   id: string;
//   name: string;
//   make: string;
//   model: string;
//   year: number;
//   odometer: number;
// }

interface VehicleListProps {
  vehicles: Vehicle[];
}

export default function VehicleList({ vehicles }: VehicleListProps) {
  // const [vehicles, setVehicles] = useState<Vehicle[]>([]);

  // useEffect(() => {
  //   async function fetchVehicles() {
  //     const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
  //     const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
  //       id: doc.id,
  //       ...doc.data(),
  //     })) as Vehicle[];
  //     setVehicles(vehiclesList);
  //   }
  //
  //   fetchVehicles();
  // }, []);

  return (
    <div>
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-medium text-gray-900">Your Vehicles</h2>
        <Link
          href="/vehicles/manage/add"
          className="text-sm font-medium text-primary-600 hover:text-primary-500"
        >
          Add Vehicle
        </Link>
      </div>
      <div className="mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2">
        {vehicles.map((vehicle) => (
          <Link
            key={vehicle.id}
            href={`/vehicles/${vehicle.id}`}
            className="group relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-5 py-4 shadow-sm hover:border-primary-400 focus-within:ring-2 focus-within:ring-primary-500"
          >
            <div className="flex-shrink-0">
              {vehicle.photoUrl ? (
                <Image
                  src={vehicle.photoUrl}
                  alt={`${vehicle.year} ${vehicle.make} ${vehicle.model}`}
                  width={48}
                  height={48}
                  className="h-12 w-12 rounded-full object-cover"
                />
              ) : (
                <div className="flex h-12 w-12 items-center justify-center rounded-full bg-primary-100">
                  <svg
                    className="h-6 w-6 text-primary-600"
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
              )}
            </div>
            <div className="min-w-0 flex-1">
              <span className="absolute inset-0" aria-hidden="true" />
              <p className="text-sm font-medium text-gray-900">
                {vehicle.year} {vehicle.make} {vehicle.model}
              </p>
              {vehicle.nickname && (
                <p className="truncate text-sm text-gray-500">{vehicle.nickname}</p>
              )}
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
} 