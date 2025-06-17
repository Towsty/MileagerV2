'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { db } from '../../../../lib/firebase';
import { doc, getDoc, collection, addDoc, updateDoc, getDocs, deleteDoc, GeoPoint } from 'firebase/firestore';

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

interface MileagePageClientProps {
  vehicleId: string;
}

interface TripFormEntry {
  date: string;
  distance: number;
  purpose: 'personal' | 'business';
  memo?: string;
}

export default function MileagePageClient({ vehicleId }: MileagePageClientProps) {
  const router = useRouter();
  const [vehicle, setVehicle] = useState<Vehicle | null>(null);
  const [activities, setActivities] = useState<Activity[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [newEntry, setNewEntry] = useState<TripFormEntry>({
    date: new Date().toISOString().split('T')[0],
    distance: 0,
    purpose: 'personal',
    memo: '',
  });
  const [editingTripId, setEditingTripId] = useState<string | null>(null);
  const [editTripData, setEditTripData] = useState<Partial<Trip>>({});

  useEffect(() => {
    fetchVehicleAndActivities();
  }, [vehicleId, fetchVehicleAndActivities]);

  async function fetchVehicleAndActivities() {
    try {
      // Fetch vehicle
      const vehicleDoc = await getDoc(doc(db, 'vehicles', vehicleId));
      console.log('Fetching vehicle with ID:', vehicleId);
      console.log('Vehicle doc exists:', vehicleDoc.exists());
      if (!vehicleDoc.exists()) {
        setError('Vehicle not found');
        return;
      }
      const vehicleData = { id: vehicleDoc.id, ...vehicleDoc.data() } as Vehicle;
      console.log('Vehicle data:', vehicleData);
      setVehicle(vehicleData);

      // Fetch mileage entries
      console.log('Fetching mileage entries...');
      const entriesSnapshot = await getDocs(collection(db, 'mileage_entries'));
      console.log('Raw mileage entries:', entriesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      const entriesList = entriesSnapshot.docs
        .map((doc) => ({
          id: doc.id,
          ...doc.data(),
          type: 'mileage' as const,
        } as Activity))
        .filter((entry) => entry.vehicleId === vehicleId);
      console.log('Filtered mileage entries for vehicle:', entriesList);

      // Fetch trips
      console.log('Fetching trips...');
      const tripsSnapshot = await getDocs(collection(db, 'trips'));
      console.log('Raw trips:', tripsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
      const tripsList = tripsSnapshot.docs
        .map((doc) => ({
          id: doc.id,
          ...doc.data(),
          type: 'trip' as const,
        } as Activity))
        .filter((trip) => trip.vehicleId === vehicleId);
      console.log('Filtered trips for vehicle:', tripsList);

      // Combine and sort all activities
      const allActivities = [...entriesList, ...tripsList].sort((a, b) => {
        const dateA = a.type === 'trip' ? new Date(a.startTime) : new Date(a.date);
        const dateB = b.type === 'trip' ? new Date(b.startTime) : new Date(b.date);
        return dateB.getTime() - dateA.getTime();
      });

      console.log('All activities for vehicle:', allActivities);
      setActivities(allActivities);
    } catch (err) {
      console.error('Error fetching data:', err);
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
      await addDoc(collection(db, 'trips'), {
        vehicleId,
        startTime: new Date(newEntry.date).toISOString(),
        endTime: null,
        distance: newEntry.distance,
        purpose: newEntry.purpose,
        memo: newEntry.memo || '',
        startLocation: new GeoPoint(0, 0), // Default, update if you have real location
        endLocation: null,
        isManualEntry: true,
        deviceName: 'Web',
        pausePeriods: [],
      });

      // Reset form and refresh data
      setNewEntry({
        date: new Date().toISOString().split('T')[0],
        distance: 0,
        purpose: 'personal',
        memo: '',
      });
      await fetchVehicleAndActivities();
    } catch (err) {
      console.error('Error adding trip:', err);
      setError('Failed to add trip');
      setLoading(false);
    }
  }

  async function handleDeleteTrip(tripId: string) {
    if (!window.confirm('Are you sure you want to delete this trip?')) return;
    try {
      await deleteDoc(doc(db, 'trips', tripId));
      await fetchVehicleAndActivities();
    } catch (err) {
      console.error('Error deleting trip:', err);
      setError('Failed to delete trip');
    }
  }

  async function handleDeleteMileageEntry(entryId: string) {
    if (!window.confirm('Are you sure you want to delete this mileage entry?')) return;
    try {
      await deleteDoc(doc(db, 'mileage_entries', entryId));
      await fetchVehicleAndActivities();
    } catch (err) {
      console.error('Error deleting mileage entry:', err);
      setError('Failed to delete mileage entry');
    }
  }

  // Edit trip handlers
  function startEditTrip(trip: Trip) {
    setEditingTripId(trip.id);
    setEditTripData({
      distance: trip.distance,
      vehicleId: trip.vehicleId,
      purpose: trip.purpose,
      memo: trip.memo,
    });
  }

  function cancelEditTrip() {
    setEditingTripId(null);
    setEditTripData({});
  }

  async function saveEditTrip(tripId: string) {
    setLoading(true);
    setError(null);
    try {
      const tripRef = doc(db, 'trips', tripId);
      await updateDoc(tripRef, {
        distance: editTripData.distance,
        vehicleId: editTripData.vehicleId,
        purpose: editTripData.purpose,
        memo: editTripData.memo,
      });
      setEditingTripId(null);
      setEditTripData({});
      await fetchVehicleAndActivities();
    } catch (err) {
      console.error('Error updating trip:', err);
      setError('Failed to update trip');
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

  if (!vehicle) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-red-600">Vehicle not found</div>
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
              {vehicle.tag} - Mileage Tracking
            </h2>
            <p className="mt-1 text-sm text-gray-500">
              {vehicle.year} {vehicle.make} {vehicle.model}
            </p>
          </div>
          <div className="mt-4 flex md:mt-0 md:ml-4">
            <button
              type="button"
              onClick={() => router.push('/vehicles')}
              className="ml-3 inline-flex items-center px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            >
              Back to Vehicles
            </button>
          </div>
        </div>

        {/* Add New Entry Form */}
        <div className="mt-8">
          <div className="md:grid md:grid-cols-3 md:gap-6">
            <div className="md:col-span-1">
              <div className="px-4 sm:px-0">
                <h3 className="text-lg font-medium leading-6 text-gray-900">Add Trip Entry</h3>
                <p className="mt-1 text-sm text-gray-600">
                  Record a new trip for this vehicle.
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
                        <label htmlFor="date" className="block text-sm font-medium text-gray-700">
                          Date
                        </label>
                        <input
                          type="date"
                          name="date"
                          id="date"
                          required
                          value={newEntry.date}
                          onChange={(e) => setNewEntry({ ...newEntry, date: e.target.value })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>

                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="distance" className="block text-sm font-medium text-gray-700">
                          Distance (miles)
                        </label>
                        <input
                          type="number"
                          name="distance"
                          id="distance"
                          required
                          min={0}
                          step="0.1"
                          value={newEntry.distance || ''}
                          onChange={(e) => setNewEntry({ ...newEntry, distance: parseFloat(e.target.value) || 0 })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-6 gap-6">
                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="purpose" className="block text-sm font-medium text-gray-700">
                          Purpose
                        </label>
                        <select
                          name="purpose"
                          id="purpose"
                          value={newEntry.purpose}
                          onChange={e => setNewEntry({ ...newEntry, purpose: e.target.value as 'personal' | 'business' })}
                          className="mt-1 focus:ring-indigo-500 focus:border-indigo-500 block w-full shadow-sm sm:text-sm border-gray-300 rounded-md"
                        >
                          <option value="personal">Personal</option>
                          <option value="business">Business</option>
                        </select>
                      </div>
                      <div className="col-span-6 sm:col-span-3">
                        <label htmlFor="memo" className="block text-sm font-medium text-gray-700">
                          Memo
                        </label>
                        <input
                          type="text"
                          name="memo"
                          id="memo"
                          value={newEntry.memo || ''}
                          onChange={e => setNewEntry({ ...newEntry, memo: e.target.value })}
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
                      Add Entry
                    </button>
                  </div>
                </div>
              </form>
            </div>
          </div>
        </div>

        {/* Activity History */}
        <div className="mt-8">
          <h3 className="text-lg font-medium leading-6 text-gray-900">Activity History</h3>
          <div className="mt-4 bg-white shadow overflow-hidden sm:rounded-md">
            <ul className="divide-y divide-gray-200">
              {activities.map((activity) => (
                <li key={activity.id}>
                  <div className="px-4 py-4 sm:px-6 flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center">
                        <p className="text-sm font-medium text-indigo-600 truncate">
                          {new Date(activity.type === 'trip' ? activity.startTime : activity.date).toLocaleDateString()}
                        </p>
                        {activity.type === 'trip' && (
                          <span className="ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                            Trip
                          </span>
                        )}
                      </div>
                      <div className="ml-2 flex-shrink-0 flex">
                        <p className="px-2 inline-flex text-xs leading-5 font-semibold rounded-full bg-green-100 text-green-800">
                          {activity.type === 'trip' ? activity.distance : activity.odometer} miles
                        </p>
                      </div>
                      {(activity.type === 'trip' ? activity.memo : activity.notes) && (
                        <div className="mt-2">
                          <p className="text-sm text-gray-500">
                            {activity.type === 'trip' ? activity.memo : activity.notes}
                          </p>
                        </div>
                      )}
                      {/* Edit form for trip */}
                      {activity.type === 'trip' && editingTripId === activity.id ? (
                        <form
                          className="mt-2 flex flex-col gap-2 bg-gray-50 p-2 rounded"
                          onSubmit={e => {
                            e.preventDefault();
                            saveEditTrip(activity.id);
                          }}
                        >
                          <label className="text-xs">Distance (miles):
                            <input
                              type="number"
                              className="ml-2 border rounded px-1 py-0.5 text-xs"
                              value={editTripData.distance ?? ''}
                              onChange={e => setEditTripData({ ...editTripData, distance: parseFloat(e.target.value) })}
                              required
                              min={0}
                            />
                          </label>
                          <label className="text-xs">Vehicle ID:
                            <input
                              type="text"
                              className="ml-2 border rounded px-1 py-0.5 text-xs"
                              value={editTripData.vehicleId ?? ''}
                              onChange={e => setEditTripData({ ...editTripData, vehicleId: e.target.value })}
                              required
                            />
                          </label>
                          <label className="text-xs">Purpose:
                            <input
                              type="text"
                              className="ml-2 border rounded px-1 py-0.5 text-xs"
                              value={editTripData.purpose ?? ''}
                              onChange={e => setEditTripData({ ...editTripData, purpose: e.target.value })}
                            />
                          </label>
                          <label className="text-xs">Memo:
                            <input
                              type="text"
                              className="ml-2 border rounded px-1 py-0.5 text-xs"
                              value={editTripData.memo ?? ''}
                              onChange={e => setEditTripData({ ...editTripData, memo: e.target.value })}
                            />
                          </label>
                          <div className="flex gap-2 mt-1">
                            <button type="submit" className="text-green-700 border border-green-200 rounded px-2 py-1 text-xs">Save</button>
                            <button type="button" className="text-gray-600 border border-gray-200 rounded px-2 py-1 text-xs" onClick={cancelEditTrip}>Cancel</button>
                          </div>
                        </form>
                      ) : null}
                    </div>
                    {activity.type === 'trip' && editingTripId !== activity.id && (
                      <>
                        <button
                          className="ml-2 text-blue-600 hover:text-blue-800 text-xs border border-blue-200 rounded px-2 py-1"
                          onClick={() => startEditTrip(activity)}
                        >
                          Edit
                        </button>
                        <button
                          className="ml-2 text-red-600 hover:text-red-800 text-xs border border-red-200 rounded px-2 py-1"
                          onClick={() => handleDeleteTrip(activity.id)}
                        >
                          Delete
                        </button>
                      </>
                    )}
                    {activity.type === 'mileage' && (
                      <button
                        className="ml-4 text-red-600 hover:text-red-800 text-xs border border-red-200 rounded px-2 py-1"
                        onClick={() => handleDeleteMileageEntry(activity.id)}
                      >
                        Delete
                      </button>
                    )}
                  </div>
                </li>
              ))}
              {activities.length === 0 && (
                <li className="px-4 py-4 sm:px-6 text-center text-gray-500">
                  No activity found. Add your first entry above.
                </li>
              )}
            </ul>
          </div>
        </div>
      </div>
    </div>
  );
} 