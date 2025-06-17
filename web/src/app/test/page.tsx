'use client';

import { useEffect, useState } from 'react';
import { db } from '../../lib/firebase';
import { collection, getDocs } from 'firebase/firestore';

interface Vehicle {
  id: string;
  name: string;
  make: string;
  model: string;
  year: number;
  odometer?: number;  // Make odometer optional
}

export default function TestPage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function fetchVehicles() {
      try {
        const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
        const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        })) as Vehicle[];
        setVehicles(vehiclesList);
        setError(null);
      } catch (err) {
        console.error('Error fetching vehicles:', err);
        setError(err instanceof Error ? err.message : 'Failed to fetch vehicles');
      } finally {
        setLoading(false);
      }
    }

    fetchVehicles();
  }, []);

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-4">Firebase Connection Test</h1>
      
      {loading && (
        <div className="text-gray-600">Loading vehicles...</div>
      )}

      {error && (
        <div className="text-red-600 mb-4">
          Error: {error}
        </div>
      )}

      {!loading && !error && (
        <div>
          <h2 className="text-xl font-semibold mb-2">Vehicles Found: {vehicles.length}</h2>
          <div className="space-y-4">
            {vehicles.map((vehicle) => (
              <div key={vehicle.id} className="p-4 bg-white rounded-lg shadow">
                <h3 className="font-medium">{vehicle.name}</h3>
                <p className="text-gray-600">
                  {vehicle.year} {vehicle.make} {vehicle.model}
                </p>
                <p className="text-gray-500">
                  Odometer: {vehicle.odometer ? vehicle.odometer.toLocaleString() : 'Not set'} miles
                </p>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
} 