// import { db } from '@/lib/firebase';
// import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { useEffect, useState } from 'react';
// import { format } from 'date-fns';
import Link from 'next/link';

// interface Trip {
//   id: string;
//   vehicleId: string;
//   vehicleName: string;
//   startTime: Date;
//   endTime: Date;
//   miles: number;
//   purpose: string;
// }

export default function RecentTrips() {
  // const [trips, setTrips] = useState<Trip[]>([]);

  // useEffect(() => {
  //   async function fetchTrips() {
  //     const tripsQuery = query(
  //       collection(db, 'trips'),
  //       orderBy('startTime', 'desc'),
  //       limit(5)
  //     );
  //     const tripsSnapshot = await getDocs(tripsQuery);
  //     const tripsList = tripsSnapshot.docs.map((doc) => ({
  //       id: doc.id,
  //       ...doc.data(),
  //       startTime: doc.data().startTime.toDate(),
  //       endTime: doc.data().endTime.toDate(),
  //     })) as Trip[];
  //     setTrips(tripsList);
  //   }
  //
  //   fetchTrips();
  // }, []);

  return (
    <div className="text-red-500">RecentTrips disabled for Firebase debug</div>
  );
} 