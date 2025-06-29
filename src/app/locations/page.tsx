'use client';

import { useEffect, useState } from 'react';
import { collection, getDocs } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface SavedLocation {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  type?: string;
}

export default function LocationsPage() {
  const [locations, setLocations] = useState<SavedLocation[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    async function fetchLocations() {
      try {
        const locationsSnapshot = await getDocs(collection(db, 'saved_locations'));
        const locationsList = locationsSnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        })) as SavedLocation[];
        setLocations(locationsList);
        setError(null);
      } catch (err) {
        console.error('Error fetching locations:', err);
        setError(err instanceof Error ? err : new Error('Failed to fetch locations'));
      } finally {
        setLoading(false);
      }
    }

    fetchLocations();
  }, []);

  if (loading) {
    return <div className="p-4">Loading locations...</div>;
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
        <h1 className="text-2xl font-bold">Saved Locations</h1>
        <button className="bg-primary-600 text-white px-4 py-2 rounded hover:bg-primary-700">
          Add Location
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {locations.map((location) => (
          <div key={location.id} className="bg-white p-4 rounded-lg shadow">
            <h3 className="text-lg font-semibold">{location.name}</h3>
            <p className="text-gray-600">{location.address}</p>
            {location.type && (
              <span className="mt-2 inline-block px-2 py-1 bg-gray-100 text-gray-700 rounded text-sm">
                {location.type}
              </span>
            )}
          </div>
        ))}
      </div>

      {locations.length === 0 && (
        <div className="text-center py-8 text-gray-500">
          No saved locations found. Add your first location to get started.
        </div>
      )}
    </div>
  );
} 