'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { db } from '../../lib/firebase';
import { collection, getDocs } from 'firebase/firestore';

interface Vehicle {
  id: string;
  tag: string;
  make?: string;
  model?: string;
  year: number;
  odometer?: number;
  vin?: string;
  photoPath?: string | null;
  color?: string;
  nickname?: string;
  startingOdometer?: number;
  bluetoothMacId?: string | null;
}

interface Trip {
  id: string;
  vehicleId: string;
  startTime: string;
  endTime?: string;
  distance: number;
  purpose: string;
  memo?: string;
  isManualEntry: boolean;
  deviceName?: string;
}

export default function VehiclesPage() {
  const router = useRouter();
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchVehicles();
  }, []);

  async function fetchVehicles() {
    try {
      const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
      const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      })) as Vehicle[];

      // For each vehicle, get all trips and calculate odometer
      const vehiclesWithOdometer = await Promise.all(
        vehiclesList.map(async (vehicle) => {
          // Get all trips for this vehicle
          const tripsSnapshot = await getDocs(collection(db, 'trips'));
          const trips = tripsSnapshot.docs
            .map(doc => ({ id: doc.id, ...doc.data() } as Trip))
            .filter(trip => trip.vehicleId === vehicle.id);

          // Odometer = startingOdometer + sum of all trip distances
          const startingOdometer = typeof vehicle.startingOdometer === 'number' ? vehicle.startingOdometer : 0;
          const totalDistance = trips.reduce((sum, trip) => sum + (typeof trip.distance === 'number' ? trip.distance : 0), 0);
          const odometer = startingOdometer + totalDistance;

          return { ...vehicle, odometer };
        })
      );

      setVehicles(vehiclesWithOdometer);
    } catch (err) {
      console.error('Error fetching vehicles:', err);
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-7xl mx-auto py-6 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="md:flex md:items-center md:justify-between">
          <div className="flex-1 min-w-0">
            <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
              Vehicles
            </h2>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <button
              type="button"
              onClick={() => router.push('/vehicles/manage/add')}
              className="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Add Vehicle
            </button>
          </div>
        </div>

        {/* Vehicle List */}
        <div className="mt-8">
          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {vehicles.map((vehicle) => (
                <li key={vehicle.id}>
                  <div className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center">
                        <p className="text-sm font-medium text-indigo-600 truncate">
                          {vehicle.tag}
                        </p>
                        <p className="ml-2 flex-shrink-0 inline-block px-2 py-0.5 text-xs font-medium rounded-full bg-gray-100 text-gray-800">
                          {vehicle.year} {vehicle.make} {vehicle.model}
                        </p>
                      </div>
                      <div className="ml-2 flex-shrink-0 flex">
                        <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          {vehicle.odometer?.toLocaleString(undefined, { maximumFractionDigits: 1 }) || 0} miles
                        </p>
                      </div>
                    </div>
                    <div className="mt-2 sm:flex sm:justify-between">
                      <div className="sm:flex">
                        <p className="flex items-center text-sm text-gray-500">
                          {vehicle.nickname || 'No nickname'}
                        </p>
                      </div>
                      <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                        <button
                          onClick={() => router.push(`/vehicles/${vehicle.id}/mileage`)}
                          className="text-indigo-600 hover:text-indigo-900"
                        >
                          View Mileage
                        </button>
                      </div>
                    </div>
                  </div>
                </li>
              ))}
              {vehicles.length === 0 && (
                <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                  No vehicles found. Add your first vehicle above.
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
} 