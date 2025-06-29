'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import Link from 'next/link';
import Image from 'next/image';

interface Vehicle {
  id: string;
  make: string;
  model: string;
  year: number;
  color: string;
  licensePlate?: string;
  vin?: string;
  startingOdometer: number;
  nickname?: string;
  photoUrl?: string;
}

export default function VehiclesPage() {
  const [vehicles, setVehicles] = useState<Vehicle[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchVehicles() {
      console.log('Fetching vehicles...');
      try {
        console.log('Firebase db instance:', db);
        const vehiclesCollection = collection(db, 'vehicles');
        console.log('Vehicles collection ref:', vehiclesCollection);
        const vehiclesSnapshot = await getDocs(vehiclesCollection);
        console.log('Vehicles snapshot:', vehiclesSnapshot.docs.length, 'documents found');
        const vehiclesList = vehiclesSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        })) as Vehicle[];
        
        // Filter out vehicles with empty IDs
        const validVehicles = vehiclesList.filter(vehicle => {
          if (!vehicle.id) {
            console.warn('Found vehicle with empty ID:', vehicle);
            return false;
          }
          return true;
        });
        
        console.log('Processed vehicles:', validVehicles);
        setVehicles(validVehicles);
        setError(null);
      } catch (err) {
        console.error('Error fetching vehicles:', err);
        setError(err instanceof Error ? err : new Error('Failed to fetch vehicles'));
      } finally {
        setLoading(false);
      }
    }

    fetchVehicles();
  }, []);

  if (loading) {
    return (
      <div className="p-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Loading Vehicles...</h1>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {[1, 2, 3].map((i) => (
            <div key={i} className="bg-white p-4 rounded-lg shadow animate-pulse">
              <div className="h-48 bg-gray-200 rounded-lg mb-4"></div>
              <div className="h-6 bg-gray-200 rounded w-3/4 mb-2"></div>
              <div className="h-4 bg-gray-200 rounded w-1/2"></div>
            </div>
          ))}
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 text-red-600">
        <h2 className="text-xl font-bold">Error</h2>
        <p>{error.message}</p>
      </div>
    );
  }

  return (
    <div className="p-4">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">Vehicles</h1>
        <Link 
          href="/vehicles/manage/add"
          className="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded"
        >
          Add Vehicle
        </Link>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {vehicles.map((vehicle) => (
          <div key={vehicle.id} className="bg-white p-4 rounded-lg shadow">
            {vehicle.photoUrl ? (
              <div className="relative h-48 mb-4">
                <Image
                  src={vehicle.photoUrl}
                  alt={`${vehicle.year} ${vehicle.make} ${vehicle.model}`}
                  fill
                  sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
                  className="rounded-lg object-cover"
                />
              </div>
            ) : (
              <div className="h-48 bg-gray-100 rounded-lg mb-4 flex items-center justify-center">
                <svg className="h-24 w-24 text-gray-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M3 18v-6a9 9 0 0118 0v6" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M21 19a2 2 0 01-2 2h-1a2 2 0 01-2-2v-3a2 2 0 012-2h3zM3 19a2 2 0 002 2h1a2 2 0 002-2v-3a2 2 0 00-2-2H3z" />
                </svg>
              </div>
            )}
            <div className="flex justify-between items-start">
              <div>
                <h3 className="text-lg font-semibold">
                  {vehicle.nickname || `${vehicle.year} ${vehicle.make} ${vehicle.model}`}
                </h3>
                {!vehicle.nickname && (
                  <p className="text-sm text-gray-600">{`${vehicle.year} ${vehicle.make} ${vehicle.model}`}</p>
                )}
                {vehicle.licensePlate && <p className="text-gray-600">License: {vehicle.licensePlate}</p>}
              </div>
              <Link
                href={`/vehicles/manage/edit?id=${vehicle.id}`}
                className="text-blue-500 hover:text-blue-600"
              >
                Edit
              </Link>
            </div>
            <div className="mt-2 text-sm text-gray-500">
              {vehicle.vin && <p>VIN: {vehicle.vin}</p>}
              <p>Starting Odometer: {vehicle.startingOdometer.toLocaleString()} miles</p>
              <p>Color: {vehicle.color}</p>
            </div>
          </div>
        ))}
      </div>

      {vehicles.length === 0 && (
        <div className="text-center py-8 text-gray-500">
          No vehicles found. Add your first vehicle to get started.
        </div>
      )}
    </div>
  );
} 