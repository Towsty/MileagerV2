'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { db } from '@/lib/firebase';
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

interface MileageEntry {
  id: string;
  vehicleId: string;
  date: string;
  odometer: number;
  notes?: string;
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

type Activity = 
  | (MileageEntry & { type: 'mileage' })
  | (Trip & { type: 'trip' });

interface VehicleWithActivity extends Vehicle {
  recentEntries: Activity[];
}

export default function Home() {
  const [vehicles, setVehicles] = useState<VehicleWithActivity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchData();
  }, []);

  async function fetchData() {
    try {
      // Fetch vehicles
      const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
      const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      } as Vehicle));

      // Fetch mileage entries
      const entriesSnapshot = await getDocs(collection(db, 'mileage_entries'));
      const entriesList = entriesSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      } as MileageEntry));

      // Fetch trips
      const tripsSnapshot = await getDocs(collection(db, 'trips'));
      const tripsList = tripsSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      } as Trip));

      // Combine and sort all activities
      const allActivities: Activity[] = [
        ...entriesList.map(entry => ({
          ...entry,
          type: 'mileage' as const,
          timestamp: new Date(entry.date).getTime()
        })),
        ...tripsList.map(trip => ({
          ...trip,
          type: 'trip' as const,
          timestamp: new Date(trip.startTime).getTime()
        }))
      ].sort((a, b) => b.timestamp - a.timestamp);

      // Get recent activities (last 5)
      const recentActivities = allActivities.slice(0, 5);

      // Combine vehicles with their recent activities
      const vehiclesWithActivity = vehiclesList.map((vehicle) => ({
        ...vehicle,
        recentEntries: recentActivities.filter(
          (activity) => activity.vehicleId === vehicle.id
        ),
      }));

      setVehicles(vehiclesWithActivity);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to fetch data');
    } finally {
      setLoading(false);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-red-600">{error}</div>
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
              Mileager Dashboard
            </h2>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <Link
              href="/vehicles"
              className="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-500 hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500"
            >
              Manage Vehicles
            </Link>
          </div>
        </div>

        {/* Recent Activity */}
        <div className="mt-8">
          <h3 className="text-lg font-medium leading-6 text-gray-900">Recent Activity</h3>
          <div className="mt-4 bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {vehicles.map((vehicle) =>
                vehicle.recentEntries.map((entry) => (
                  <li key={entry.id}>
                    <div className="px-4 py-4 sm:px-6">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center">
                          <p className="text-sm font-medium text-blue-600 truncate">
                            {vehicle.nickname || vehicle.tag}
                          </p>
                          <p className="ml-2 text-sm text-gray-500">
                            {new Date(entry.type === 'trip' ? entry.startTime : entry.date).toLocaleDateString()}
                          </p>
                          {entry.type === 'trip' && (
                            <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                              Trip
                            </span>
                          )}
                        </div>
                        <div className="ml-2 flex-shrink-0 flex">
                          <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                            {entry.type === 'trip' ? entry.distance : entry.odometer} miles
                          </p>
                        </div>
                      </div>
                      {(entry.type === 'trip' ? entry.memo : entry.notes) && (
                        <div className="mt-2">
                          <p className="text-sm text-gray-500">
                            {entry.type === 'trip' ? entry.memo : entry.notes}
                          </p>
                        </div>
                      )}
                    </div>
                  </li>
                ))
              )}
              {vehicles.every((vehicle) => vehicle.recentEntries.length === 0) && (
                <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                  No recent activity found.
                </li>
              )}
            </ul>
          </div>
        </div>

        {/* Quick Stats */}
        <div className="mt-8 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3">
          <div className="bg-white overflow-hidden shadow rounded-lg">
            <div className="px-4 py-5 sm:p-6">
              <dt className="text-sm font-medium text-gray-500 truncate">
                Total Vehicles
              </dt>
              <dd className="mt-1 text-3xl font-semibold text-gray-900">
                {vehicles.length}
              </dd>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 