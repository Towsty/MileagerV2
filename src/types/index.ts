import { Timestamp } from 'firebase/firestore';

export enum TripPurpose {
  Business = 'business',
  Personal = 'personal',
}

export interface PausePeriod {
  pauseTime: string;
  resumeTime?: string;
}

export interface Trip {
  id: string;
  vehicleId: string;
  startTime: Timestamp;
  endTime?: Timestamp;
  distance: number;
  purpose: TripPurpose;
  memo?: string;
  startLocation?: SavedLocation;
  endLocation?: SavedLocation;
  isManualEntry: boolean;
  deviceName?: string;
  pausePeriods: PausePeriod[];
}

export interface Vehicle {
  id: string;
  make: string;
  model: string;
  year: number;
  color: string;
  licensePlate: string;
  vin: string;
  startingOdometer: number;
  currentOdometer?: number;
  imageUrl?: string;
  tag?: string;
  bluetoothDeviceName?: string;
  bluetoothMacId?: string;
  photoPath?: string;
  photoUrl?: string;
  nickname?: string;
}

export interface SavedLocation {
  id: string;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  type?: string;
  notes?: string;
  createdAt: string;
}

export interface TripSummary {
  totalTrips: number;
  totalDistance: number;
  businessDistance: number;
  personalDistance: number;
} 