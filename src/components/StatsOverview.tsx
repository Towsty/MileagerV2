// import { db } from '@/lib/firebase';
// import { collection, getDocs } from 'firebase/firestore';
import { useEffect, useState } from 'react';

// interface Stats {
//   totalVehicles: number;
//   totalTrips: number;
//   totalMiles: number;
// }

export default function StatsOverview() {
  // const [stats, setStats] = useState<Stats>({
  //   totalVehicles: 0,
  //   totalTrips: 0,
  //   totalMiles: 0,
  // });

  // useEffect(() => {
  //   async function fetchStats() {
  //     const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
  //     const tripsSnapshot = await getDocs(collection(db, 'trips'));
  //
  //     let totalMiles = 0;
  //     tripsSnapshot.forEach((doc) => {
  //       const trip = doc.data();
  //       totalMiles += trip.miles || 0;
  //     });
  //
  //     setStats({
  //       totalVehicles: vehiclesSnapshot.size,
  //       totalTrips: tripsSnapshot.size,
  //       totalMiles: totalMiles,
  //     });
  //   }
  //
  //   fetchStats();
  // }, []);

  return (
    <div className="text-red-500">StatsOverview disabled for Firebase debug</div>
  );
} 