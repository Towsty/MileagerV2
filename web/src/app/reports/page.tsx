'use client';

import { useEffect, useState } from 'react';
import { db } from '../../lib/firebase';
import { collection, getDocs, query, where } from 'firebase/firestore';

interface Vehicle {
  id: string;
  name: string;
  make: string;
  model: string;
  year: number;
  odometer?: number;
}

interface MileageEntry {
  id: string;
  vehicleId: string;
  date: string;
  odometer: number;
  notes?: string;
}

interface VehicleStats {
  vehicle: Vehicle;
  totalMiles: number;
  entries: number;
  averageMilesPerDay: number;
  lastEntry?: MileageEntry;
}

export default function ReportsPage() {
  // const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [stats, setStats] = useState<VehicleStats[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [dateRange, setDateRange] = useState({
    start: new Date(new Date().getFullYear(), 0, 1).toISOString().split('T')[0], // Start of year
    end: new Date().toISOString().split('T')[0], // Today
  });

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  async function fetchData() {
    try {
      setLoading(true);
      // Fetch vehicles
      // const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
      // const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
      //   id: doc.id,
      //   ...doc.data(),
      // })) as Vehicle[];
      // setVehicles(vehiclesList);

      // Fetch mileage entries for each vehicle
      const statsPromises = // vehiclesList.map(async (vehicle: Vehicle) => {
        // First get all entries for the vehicle
        const entriesQuery = query(
          collection(db, 'mileage_entries'),
          where('vehicleId', '==', 'your-vehicle-id')
        );
        const entriesSnapshot = await getDocs(entriesQuery);
        const allEntries = entriesSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as MileageEntry[];

        // Filter entries by date range in memory
        const entries = allEntries
          .filter(entry => {
            const entryDate = new Date(entry.date);
            return entryDate >= new Date(dateRange.start) && entryDate <= new Date(dateRange.end);
          })
          .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

        // Calculate statistics
        let totalMiles = 0;
        if (entries.length > 1) {
          totalMiles = entries[0].odometer - entries[entries.length - 1].odometer;
        }

        const daysDiff = Math.max(
          1,
          Math.ceil(
            (new Date(dateRange.end).getTime() - new Date(dateRange.start).getTime()) /
              (1000 * 60 * 60 * 24)
          )
        );

        return {
          vehicle: {
            id: 'your-vehicle-id',
            name: 'Your Vehicle',
            make: 'Your Make',
            model: 'Your Model',
            year: new Date().getFullYear(),
            odometer: entries[0].odometer,
          },
          totalMiles,
          entries: entries.length,
          averageMilesPerDay: totalMiles / daysDiff,
          lastEntry: entries[0],
        };
      // });

      const statsResults = await Promise.all(statsPromises);
      setStats(statsResults);
      setError(null);
    } catch (err) {
      console.error('Error fetching data:', err);
      setError('Failed to fetch report data');
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
              Mileage Reports
            </h2>
          </div>
        </div>

        {/* Date Range Selector */}
        <div className="mt-8 bg-white shadow sm:rounded-lg">
          <div className="px-4 py-5 sm:p-6">
            <h3 className="text-lg leading-6 font-medium text-gray-900">Date Range</h3>
            <div className="mt-2 max-w-xl text-sm text-gray-500">
              <p>Select the date range for the report.</p>
            </div>
            <div className="mt-5 grid grid-cols-1 gap-4 sm:grid-cols-2">
              <div>
                <label htmlFor="start-date" className="block text-sm font-medium text-gray-700">
                  Start Date
                </label>
                <input
                  type="date"
                  name="start-date"
                  id="start-date"
                  value={dateRange.start}
                  onChange={(e) => setDateRange({ ...dateRange, start: e.target.value })}
                  className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                />
              </div>
              <div>
                <label htmlFor="end-date" className="block text-sm font-medium text-gray-700">
                  End Date
                </label>
                <input
                  type="date"
                  name="end-date"
                  id="end-date"
                  value={dateRange.end}
                  onChange={(e) => setDateRange({ ...dateRange, end: e.target.value })}
                  className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Report Content */}
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
              {stats.map((stat) => (
                <li key={stat.vehicle.id}>
                  <div className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div className="flex-1 min-w-0">
                        <h3 className="text-lg font-medium text-indigo-600 truncate">
                          {stat.vehicle.name}
                        </h3>
                        <p className="mt-1 text-sm text-gray-500">
                          {stat.vehicle.year} {stat.vehicle.make} {stat.vehicle.model}
                        </p>
                      </div>
                      <div className="ml-4 flex-shrink-0">
                        <p className="text-sm font-medium text-gray-900">
                          {stat.totalMiles.toLocaleString()} miles
                        </p>
                      </div>
                    </div>
                    <div className="mt-2 sm:flex sm:justify-between">
                      <div className="sm:flex">
                        <p className="flex items-center text-sm text-gray-500">
                          {stat.entries} entries
                        </p>
                        <p className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0 sm:ml-6">
                          {stat.averageMilesPerDay.toFixed(1)} miles per day
                        </p>
                      </div>
                      {stat.lastEntry && (
                        <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                          Last entry: {new Date(stat.lastEntry.date).toLocaleDateString()}
                        </div>
                      )}
                    </div>
                  </div>
                </li>
              ))}
              {stats.length === 0 && (
                <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                  No data available for the selected date range.
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
} 