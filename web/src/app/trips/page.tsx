'use client';

import { useEffect, useState } from 'react';
import { db } from '../../lib/firebase';
import { collection, getDocs } from 'firebase/firestore';
import Link from 'next/link';

interface Vehicle {
  id: string;
  name: string;
  make: string;
  model: string;
  year: number;
}

interface Trip {
  id: string;
  vehicleId: string;
  startDate: string;
  endDate: string;
  startOdometer: number;
  endOdometer: number;
  purpose: string;
  notes?: string;
}

export default function TripsPage() {
  const [trips, setTrips] = useState<Trip[]>([]);
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchData() {
      try {
        // Fetch vehicles
        const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const vehiclesList = vehiclesSnapshot.docs.map((doc: any) => ({
          id: doc.id,
          ...doc.data(),
        })) as Vehicle[];
        setVehicles(vehiclesList);

        // Fetch all trips
        const tripsSnapshot = await getDocs(collection(db, 'trips'));
        // eslint-disable-next-line @typescript-eslint/no-explicit-any
        const tripsList = tripsSnapshot.docs.map((doc: any) => ({
          id: doc.id,
          ...doc.data(),
        })) as Trip[];

        // Sort trips by start date
        const sortedTrips = tripsList.sort((a, b) => 
          new Date(b.startDate).getTime() - new Date(a.startDate).getTime()
        );
        setTrips(sortedTrips);
      } catch (err) {
        console.error('Error fetching data:', err);
        setError('Failed to fetch trips data');
      } finally {
        setLoading(false);
      }
    }

    fetchData();
  }, []);

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
              Trips
            </h2>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <Link
              href="/trips/new"
              className="ml-3 inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Add Trip
            </Link>
          </div>
        </div>

        {/* Trips List */}
        <div className="mt-8">
          {error && (
            <div className="mb-4 bg-red-50 border-l-4 border-red-400 p-4">
              <div className="flex">
                <div className="flex-shrink-0">
                  <svg className="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                </div>
                <div className="ml-3">
                  <p className="text-sm text-red-700">{error}</p>
                </div>
              </div>
            </div>
          )}

          <div className="bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {trips.map((trip) => {
                const vehicle = vehicles.find((v) => v.id === trip.vehicleId);
                const distance = trip.endOdometer - trip.startOdometer;
                return (
                  <li key={trip.id}>
                    <div className="px-4 py-4 sm:px-6">
                      <div className="flex items-center justify-between">
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-indigo-600 truncate">
                            {vehicle?.name || 'Unknown Vehicle'}
                          </p>
                          <p className="mt-1 text-sm text-gray-500">
                            {new Date(trip.startDate).toLocaleDateString()} - {new Date(trip.endDate).toLocaleDateString()}
                          </p>
                        </div>
                        <div className="ml-4 flex-shrink-0">
                          <p className="text-sm font-medium text-gray-900">
                            {distance.toLocaleString()} miles
                          </p>
                        </div>
                      </div>
                      <div className="mt-2 sm:flex sm:justify-between">
                        <div className="sm:flex">
                          <p className="flex items-center text-sm text-gray-500">
                            {trip.purpose}
                          </p>
                          {trip.notes && (
                            <p className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                              {trip.notes}
                            </p>
                          )}
                        </div>
                        <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          <Link
                            href={`/trips/${trip.id}`}
                            className="text-indigo-600 hover:text-indigo-900"
                          >
                            View Details
                          </Link>
                        </div>
                      </div>
                    </div>
                  </li>
                );
              })}
              {trips.length === 0 && (
                <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                  No trips found. Add your first trip to get started.
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
} 