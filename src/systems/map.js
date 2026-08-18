import { LOCATIONS, sortedLocations, isLocationUnlocked } from '../data/locations.js';
import { canAfford, spend } from './economy.js';

export function unlockLocation(state, locationId) {
  const loc = LOCATIONS[locationId];
  if (!loc) return { ok: false, reason: 'missing' };
  if (isLocationUnlocked(state, locationId)) return { ok: false, reason: 'owned' };
  if (state.player.rank < loc.unlockRank) return { ok: false, reason: 'rank' };
  if (!canAfford(state, loc.unlockCost)) return { ok: false, reason: 'cost' };
  spend(state, loc.unlockCost);
  state.unlockedLocations.push(locationId);
  return { ok: true, loc };
}

export function travelTo(state, locationId) {
  if (!isLocationUnlocked(state, locationId)) return { ok: false, reason: 'locked' };
  state.locationId = locationId;
  return { ok: true };
}

export { sortedLocations, isLocationUnlocked, LOCATIONS };
