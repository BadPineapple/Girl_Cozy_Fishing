import {
  LOCATIONS, sortedLocations, isLocationUnlocked,
  venuesForLocation, venueById,
} from '../data/locations.js';
import { canAfford, spend } from './economy.js';

export function unlockLocation(state, locationId) {
  const loc = LOCATIONS[locationId];
  if (!loc) return { ok: false, reason: 'missing' };
  if (isLocationUnlocked(state, locationId)) return { ok: false, reason: 'owned' };
  if (state.player.rank < loc.unlockRank) return { ok: false, reason: 'rank' };
  if (!spend(state, loc.unlockCost)) return { ok: false, reason: 'cost' };
  state.unlockedLocations.push(locationId);
  return { ok: true, loc };
}

export function travelTo(state, locationId) {
  if (!isLocationUnlocked(state, locationId)) return { ok: false, reason: 'locked' };
  state.locationId = locationId;
  return { ok: true };
}

// --- estabelecimentos (loja, ateliê) ---
// A loja abre junto com o local; o ateliê precisa ser desbloqueado à parte.
export function isVenueUnlocked(state, venueId) {
  const venue = venueById(venueId);
  if (!venue) return false;
  if (venue.alwaysOpen) return isLocationUnlocked(state, venue.locationId);
  return state.unlockedVenues.includes(venueId);
}

export function unlockVenue(state, venueId) {
  const venue = venueById(venueId);
  if (!venue) return { ok: false, reason: 'missing' };
  if (isVenueUnlocked(state, venueId)) return { ok: false, reason: 'owned' };
  if (!isLocationUnlocked(state, venue.locationId)) return { ok: false, reason: 'locked' };
  if (state.player.rank < (venue.unlockRank || 1)) return { ok: false, reason: 'rank' };
  if (!spend(state, venue.unlockCost)) return { ok: false, reason: 'cost' };
  state.unlockedVenues.push(venueId);
  return { ok: true, venue };
}

export { sortedLocations, isLocationUnlocked, venuesForLocation, venueById, LOCATIONS };
