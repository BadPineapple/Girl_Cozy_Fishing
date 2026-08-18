import { COSMETICS } from '../data/cosmetics.js';
import { canAfford, spend } from './economy.js';

export function buyCosmetic(state, cosmeticId) {
  const item = COSMETICS[cosmeticId];
  if (!item) return { ok: false, reason: 'missing' };
  if (state.cosmetics.owned.includes(cosmeticId)) return { ok: false, reason: 'owned' };
  if (state.player.rank < item.rankReq) return { ok: false, reason: 'rank' };
  if (!canAfford(state, item.cost)) return { ok: false, reason: 'cost' };
  spend(state, item.cost);
  state.cosmetics.owned.push(cosmeticId);
  return { ok: true, item };
}

export function equipCosmetic(state, cosmeticId) {
  const item = COSMETICS[cosmeticId];
  if (!item) return { ok: false, reason: 'missing' };
  if (!state.cosmetics.owned.includes(cosmeticId)) return { ok: false, reason: 'not-owned' };
  state.cosmetics.equipped[item.slot] = cosmeticId;
  return { ok: true, item };
}
