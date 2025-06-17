// import { db } from '@/lib/firebase';
// import { collection, getDocs } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import Link from 'next/link';

// interface Vehicle {
//   id: string;
//   name: string;
//   make: string;
//   model: string;
//   year: number;
//   odometer: number;
// }

export default function VehicleList() {
  // const [vehicles, setVehicles] = useState<Vehicle[]>([]);

  // useEffect(() => {
  //   async function fetchVehicles() {
  //     const vehiclesSnapshot = await getDocs(collection(db, 'vehicles'));
  //     const vehiclesList = vehiclesSnapshot.docs.map((doc) => ({
  //       id: doc.id,
  //       ...doc.data(),
  //     })) as Vehicle[];
  //     setVehicles(vehiclesList);
  //   }
  //
  //   fetchVehicles();
  // }, []);

  return (
    <div className="text-red-500">VehicleList disabled for Firebase debug</div>
  );
} 