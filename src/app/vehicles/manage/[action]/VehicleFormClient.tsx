'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { doc, addDoc, updateDoc, getDoc, collection } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import Link from 'next/link';
import Image from 'next/image';

interface VehicleFormProps {
  action: 'add' | 'edit';
  vehicleId?: string;
}

interface Vehicle {
  id?: string;
  make: string;
  model: string;
  year: number;
  color: string;
  vin?: string;
  tag?: string;
  startingOdometer: number;
  nickname?: string;
  photoUrl?: string;
}

export default function VehicleFormClient({ action, vehicleId }: VehicleFormProps) {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [fetchingVehicle, setFetchingVehicle] = useState(action === 'edit');
  const [error, setError] = useState<string | null>(null);
  const [vehicle, setVehicle] = useState<Vehicle>({
    make: '',
    model: '',
    year: new Date().getFullYear(),
    color: '',
    startingOdometer: 0,
  });

  useEffect(() => {
    if (action === 'edit') {
      if (!vehicleId) {
        console.error('No vehicle ID provided for edit');
        setError('Invalid vehicle ID');
        setFetchingVehicle(false);
        return;
      }
      
      console.log('Initializing edit form with vehicleId:', vehicleId);
      console.log('Firebase db instance:', db);
      
      // Verify Firebase config
      try {
        const app = db.app;
        console.log('Firebase app initialized:', app.name);
        console.log('Firebase project ID:', app.options.projectId);
      } catch (err) {
        console.error('Error checking Firebase config:', err);
        setError('Firebase configuration error. Please check console.');
      }
      
      fetchVehicle();
      
      // Add timeout to prevent infinite loading
      const timeout = setTimeout(() => {
        setFetchingVehicle(false);
        setError('Request timed out. Please try again.');
      }, 10000); // 10 second timeout

      return () => clearTimeout(timeout);
    }
  }, [action, vehicleId]);

  const fetchVehicle = async () => {
    setFetchingVehicle(true);
    try {
      console.log('Fetching vehicle with ID:', vehicleId);
      const docRef = doc(db, 'vehicles', vehicleId!);
      console.log('Document reference created');
      const docSnap = await getDoc(docRef);
      console.log('Document snapshot received:', docSnap.exists() ? 'exists' : 'does not exist');
      if (docSnap.exists()) {
        const data = docSnap.data();
        console.log('Vehicle data:', data);
        setVehicle({ 
          id: docSnap.id, 
          make: data.make || '',
          model: data.model || '',
          year: data.year || new Date().getFullYear(),
          color: data.color || '',
          vin: data.vin || '',
          tag: data.tag || '',
          startingOdometer: data.startingOdometer || 0,
          nickname: data.nickname || '',
          photoUrl: data.photoUrl || '',
        });
      } else {
        console.error('Vehicle document not found');
        setError('Vehicle not found');
      }
    } catch (err) {
      console.error('Error fetching vehicle:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch vehicle details');
    } finally {
      setFetchingVehicle(false);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (!vehicle.make || !vehicle.model || !vehicle.year || !vehicle.color || vehicle.startingOdometer < 0) {
        setError('Please fill in all required fields');
        setLoading(false);
        return;
      }

      if (action === 'add') {
        const docRef = await addDoc(collection(db, 'vehicles'), {
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          color: vehicle.color,
          vin: vehicle.vin,
          tag: vehicle.tag,
          startingOdometer: vehicle.startingOdometer,
          nickname: vehicle.nickname,
          photoUrl: vehicle.photoUrl,
          id: '', // Initialize with empty string
        });
        
        // Update the document with its own ID
        await updateDoc(docRef, {
          id: docRef.id
        });
      } else {
        const docRef = doc(db, 'vehicles', vehicleId!);
        await updateDoc(docRef, {
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          color: vehicle.color,
          vin: vehicle.vin,
          tag: vehicle.tag,
          startingOdometer: vehicle.startingOdometer,
          nickname: vehicle.nickname,
          photoUrl: vehicle.photoUrl,
          id: vehicleId, // Always include the ID in updates
        });
      }
      router.push('/vehicles');
    } catch (err) {
      console.error('Error saving vehicle:', err);
      setError('Failed to save vehicle');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setVehicle(prev => ({
      ...prev,
      [name]: name === 'year' || name === 'startingOdometer' ? Number(value) : value,
    }));
  };

  if (fetchingVehicle) {
    return (
      <div className="p-4">
        <div className="flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold">Loading Vehicle Details...</h1>
          <Link
            href="/vehicles"
            className="bg-gray-100 hover:bg-gray-200 text-gray-800 px-4 py-2 rounded"
          >
            Back to Vehicles
          </Link>
        </div>
        <div className="animate-pulse">
          <div className="h-8 bg-gray-200 rounded w-1/4 mb-4"></div>
          <div className="h-12 bg-gray-200 rounded mb-4"></div>
          <div className="h-12 bg-gray-200 rounded mb-4"></div>
          <div className="h-12 bg-gray-200 rounded mb-4"></div>
        </div>
      </div>
    );
  }

  return (
    <div className="p-4">
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-2xl font-bold">
          {action === 'add' ? 'Add New Vehicle' : 'Edit Vehicle'}
        </h1>
        <Link
          href="/vehicles"
          className="bg-gray-100 hover:bg-gray-200 text-gray-800 px-4 py-2 rounded"
        >
          Back to Vehicles
        </Link>
      </div>

      {error && (
        <div className="bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-4">
          {error}
        </div>
      )}

      <form onSubmit={handleSubmit} className="max-w-lg">
        <div className="space-y-4">
          {vehicle.photoUrl && (
            <div className="mb-4">
              <Image
                src={vehicle.photoUrl}
                alt={`${vehicle.year} ${vehicle.make} ${vehicle.model}`}
                width={600}
                height={400}
                className="rounded-lg w-full h-auto"
                priority
              />
            </div>
          )}

          <div>
            <label className="block text-sm font-medium mb-1">Photo URL</label>
            <input
              type="url"
              name="photoUrl"
              value={vehicle.photoUrl || ''}
              onChange={handleChange}
              placeholder="https://example.com/vehicle-photo.jpg"
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Nickname (Optional)</label>
            <input
              type="text"
              name="nickname"
              value={vehicle.nickname || ''}
              onChange={handleChange}
              placeholder="e.g., Family Van"
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Make</label>
            <input
              type="text"
              name="make"
              value={vehicle.make}
              onChange={handleChange}
              required
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Model</label>
            <input
              type="text"
              name="model"
              value={vehicle.model}
              onChange={handleChange}
              required
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Year</label>
            <input
              type="number"
              name="year"
              value={vehicle.year}
              onChange={handleChange}
              required
              min="1900"
              max={new Date().getFullYear() + 1}
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Color</label>
            <input
              type="text"
              name="color"
              value={vehicle.color}
              onChange={handleChange}
              required
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">VIN (Optional)</label>
            <input
              type="text"
              name="vin"
              value={vehicle.vin || ''}
              onChange={handleChange}
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">License Plate (Optional)</label>
            <input
              type="text"
              name="tag"
              value={vehicle.tag || ''}
              onChange={handleChange}
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-1">Starting Odometer</label>
            <input
              type="number"
              name="startingOdometer"
              value={vehicle.startingOdometer}
              onChange={handleChange}
              required
              min="0"
              className="w-full p-2 border rounded dark:bg-gray-700 dark:border-gray-600"
            />
          </div>

          <div className="pt-4">
            <button
              type="submit"
              disabled={loading}
              className={`
                w-full bg-blue-500 text-white py-2 px-4 rounded
                hover:bg-blue-600 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-opacity-50
                disabled:opacity-50 disabled:cursor-not-allowed
              `}
            >
              {loading ? 'Saving...' : action === 'add' ? 'Add Vehicle' : 'Save Changes'}
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}