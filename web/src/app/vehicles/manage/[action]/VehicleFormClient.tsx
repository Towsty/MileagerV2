'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { db } from '../../../../lib/firebase';
import { doc, getDoc, collection, addDoc, updateDoc } from 'firebase/firestore';

interface Vehicle {
  id?: string;
  name: string;
  make: string;
  model: string;
  year: number;
  odometer?: number;
}

export default function VehicleFormClient({ action }: { action: string }) {
  const router = useRouter();
  const [vehicle, setVehicle] = useState<Partial<Vehicle>>({
    name: '',
    make: '',
    model: '',
    year: new Date().getFullYear(),
    odometer: 0,
  });
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (action !== 'new') {
      fetchVehicle();
    } else {
      setLoading(false);
    }
    // eslint-disable-next-line
  }, [action]);

  async function fetchVehicle() {
    try {
      const vehicleDoc = await getDoc(doc(db, 'vehicles', action));
      if (!vehicleDoc.exists()) {
        setError('Vehicle not found');
        return;
      }
      setVehicle({ id: vehicleDoc.id, ...vehicleDoc.data() } as Vehicle);
    } catch (err) {
      console.error('Error fetching vehicle:', err);
      setError('Failed to fetch vehicle data');
    } finally {
      setLoading(false);
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      if (action !== 'new' && vehicle.id) {
        await updateDoc(doc(db, 'vehicles', vehicle.id), {
          name: vehicle.name,
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          odometer: vehicle.odometer,
        });
      } else {
        await addDoc(collection(db, 'vehicles'), {
          name: vehicle.name,
          make: vehicle.make,
          model: vehicle.model,
          year: vehicle.year,
          odometer: vehicle.odometer,
        });
      }
      router.push('/vehicles');
    } catch (err) {
      console.error('Error saving vehicle:', err);
      setError('Failed to save vehicle');
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
        <div className="md:flex md:items-center md:justify-between">
          <div className="flex-1 min-w-0">
            <h2 className="text-2xl font-bold leading-7 text-gray-900 sm:text-3xl sm:truncate">
              {action === 'new' ? 'Add New Vehicle' : 'Edit Vehicle'}
            </h2>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <button
              type="button"
              onClick={() => router.push('/vehicles')}
              className="ml-3 inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Cancel
            </button>
          </div>
        </div>

        <div className="mt-8">
          <div className="md:grid md:grid-cols-3 md:gap-6">
            <div className="md:col-span-1">
              <div className="px-4 sm:px-0">
                <h3 className="text-lg font-medium leading-6 text-gray-900">Vehicle Information</h3>
                <p className="mt-1 text-sm text-gray-600">
                  Enter the details of your vehicle.
                </p>
              </div>
            </div>

            <div className="mt-5 md:mt-0 md:col-span-2">
              <form onSubmit={handleSubmit}>
                <div className="shadow sm:rounded-md sm:overflow-hidden">
                  <div className="px-4 py-5 bg-white space-y-6 sm:p-6">
                    {error && (
                      <div className="bg-red-50 border-l-4 border-red-400 p-4">
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

                    <div className="grid grid-cols-6 gap-6">
                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                          Vehicle Name
                        </label>
                        <input
                          type="text"
                          name="name"
                          id="name"
                          required
                          value={vehicle.name}
                          onChange={(e) => setVehicle({ ...vehicle, name: e.target.value })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>

                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="year" className="block text-sm font-medium text-gray-700">
                          Year
                        </label>
                        <input
                          type="number"
                          name="year"
                          id="year"
                          required
                          min="1900"
                          max={new Date().getFullYear() + 1}
                          value={vehicle.year}
                          onChange={(e) => setVehicle({ ...vehicle, year: parseInt(e.target.value) })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>

                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="make" className="block text-sm font-medium text-gray-700">
                          Make
                        </label>
                        <input
                          type="text"
                          name="make"
                          id="make"
                          required
                          value={vehicle.make}
                          onChange={(e) => setVehicle({ ...vehicle, make: e.target.value })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>

                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="model" className="block text-sm font-medium text-gray-700">
                          Model
                        </label>
                        <input
                          type="text"
                          name="model"
                          id="model"
                          required
                          value={vehicle.model}
                          onChange={(e) => setVehicle({ ...vehicle, model: e.target.value })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>

                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="odometer" className="block text-sm font-medium text-gray-700">
                          Current Odometer (miles)
                        </label>
                        <input
                          type="number"
                          name="odometer"
                          id="odometer"
                          min="0"
                          value={vehicle.odometer}
                          onChange={(e) => setVehicle({ ...vehicle, odometer: parseInt(e.target.value) || 0 })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>
                    </div>
                  </div>

                  <div className="px-4 py-3 bg-gray-50 text-right sm:px-6">
                    <button
                      type="submit"
                      className="inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                    >
                      {action === 'new' ? 'Add Vehicle' : 'Save Changes'}
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
} 