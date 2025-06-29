// import { db } from '@/lib/firebase';
// import { collection, getDocs, query, orderBy, limit } from 'firebase/firestore';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { format } from 'date-fns';
import { Trip, Vehicle, TripPurpose } from '@/types';

// interface Trip {
//   id: string;
//   vehicleId: string;
//   vehicleName: string;
//   startTime: Date;
//   endTime: Date;
//   miles: number;
//   purpose: string;
// }

interface RecentTripsProps {
  trips: Trip[];
  vehicles: Vehicle[];
}

export default function RecentTrips({ trips, vehicles }: RecentTripsProps) {
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

  function getVehicleName(vehicleId: string) {
    const vehicle = vehicles.find((v) => v.id === vehicleId);
    return vehicle
      ? `${vehicle.year} ${vehicle.make} ${vehicle.model}`
      : 'Unknown Vehicle';
  }

  return (
    <div>
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-medium text-gray-900">Recent Trips</h2>
        <Link
          href="/trips"
          className="text-sm font-medium text-primary-600 hover:text-primary-500"
        >
          View All
        </Link>
      </div>
      <div className="mt-6 overflow-hidden rounded-lg bg-white shadow">
        <ul role="list" className="divide-y divide-gray-200">
          {trips.map((trip) => (
            <li key={trip.id}>
              <Link
                href={`/trips/${trip.id}`}
                className="block hover:bg-gray-50"
              >
                <div className="px-4 py-4 sm:px-6">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <p className="truncate text-sm font-medium text-primary-600">
                        {getVehicleName(trip.vehicleId)}
                      </p>
                      <div className="ml-2 flex flex-shrink-0">
                        <p
                          className={`inline-flex rounded-full px-2 text-xs font-semibold leading-5 ${
                            trip.purpose === TripPurpose.Business
                              ? 'bg-green-100 text-green-800'
                              : 'bg-blue-100 text-blue-800'
                          }`}
                        >
                          {trip.purpose}
                        </p>
                      </div>
                    </div>
                    <div className="ml-2 flex flex-shrink-0">
                      <p className="text-sm text-gray-500">
                        {format(new Date(trip.startTime), 'MMM d, yyyy')}
                      </p>
                    </div>
                  </div>
                  <div className="mt-2 sm:flex sm:justify-between">
                    <div className="sm:flex">
                      <p className="flex items-center text-sm text-gray-500">
                        {trip.distance.toFixed(1)} miles
                      </p>
                    </div>
                    {trip.memo && (
                      <div className="mt-2 flex items-center text-sm text-gray-500 sm:mt-0">
                        <p className="truncate">{trip.memo}</p>
                      </div>
                    )}
                  </div>
                </div>
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
} 