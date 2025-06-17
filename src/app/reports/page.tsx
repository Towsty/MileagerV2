import { useState, useEffect } from 'react';
import { collection, getDocs, query, where } from 'firebase/firestore';
import { db } from '@/lib/firebase';

interface Vehicle {
  id: string;
  name: string;
  [key: string]: any;
}

interface MileageEntry {
  id: string;
  date: string;
  odometer: number;
  vehicleId: string;
  [key: string]: any;
}

interface VehicleStats {
  vehicle: Vehicle;
  totalMiles: number;
  entries: number;
  averageMilesPerDay: number;
  lastEntry: MileageEntry | undefined;
}

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
    const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
    const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
      id: doc.id,
      ...doc.data(),
    })) as Vehicle[];
    // setVehicles(vehiclesList);

    // Fetch mileage entries for each vehicle
    const statsPromises = vehiclesList.map(async (vehicle: Vehicle) => {
      // First get all entries for the vehicle
      const entriesQuery = query(
        collection(db, 'mileage_entries'),
        where('vehicleId', '==', vehicle.id)
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
        vehicle,
        totalMiles,
        entries: entries.length,
        averageMilesPerDay: totalMiles / daysDiff,
        lastEntry: entries[0],
      };
    });

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