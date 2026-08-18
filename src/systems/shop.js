import { FISH } from '../data/fish.js';
import { RODS, BAITS, AUTO_FISH_UNLOCK } from '../data/equipment.js';
import { spend, addCurrency } from './economy.js';
import { removeInventory } from '../state.js';
import { valueMultiplier } from './effects.js';

// O multiplicador de valor do evento ativo ("brisa da sorte") é aplicado aqui,
// na venda — antes ele era calculado na pescaria e jogado fora, então o evento
// não fazia absolutamente nada.
export function fishSellValue(state, fish) {
  return Math.max(1, Math.round(fish.value * valueMultiplier(state)));
}

export function sellFish(state, fishId, qty) {
  const fish = FISH[fishId];
  if (!fish) return 0;
  const entry = state.inventory.find((i) => i.fishId === fishId);
  const wanted = Number.isFinite(qty) ? Math.floor(qty) : 0;
  const sellQty = Math.min(wanted, entry ? entry.qty : 0);
  if (sellQty <= 0) return 0;

  removeInventory(state, fishId, sellQty);
  const gain = fishSellValue(state, fish) * sellQty;
  addCurrency(state, 'conchas', gain);
  state.stats.totalSoldConchas += gain;
  return gain;
}

export function sellAll(state) {
  let total = 0;
  for (const entry of [...state.inventory]) {
    total += sellFish(state, entry.fishId, entry.qty);
  }
  return total;
}

export function nextRod(state) {
  return RODS.find((r) => r.tier === state.equipment.rodTier + 1) || null;
}

export function nextBait(state) {
  return BAITS.find((b) => b.tier === state.equipment.baitTier + 1) || null;
}

export function buyNextRod(state) {
  const rod = nextRod(state);
  if (!rod) return { ok: false, reason: 'max' };
  if (state.player.rank < rod.rankReq) return { ok: false, reason: 'rank' };
  if (!spend(state, rod.cost)) return { ok: false, reason: 'cost' };
  state.equipment.rodTier = rod.tier;
  return { ok: true, rod };
}

export function buyNextBait(state) {
  const bait = nextBait(state);
  if (!bait) return { ok: false, reason: 'max' };
  if (state.player.rank < bait.rankReq) return { ok: false, reason: 'rank' };
  if (!spend(state, bait.cost)) return { ok: false, reason: 'cost' };
  state.equipment.baitTier = bait.tier;
  return { ok: true, bait };
}

export function buyAutoFishUnlock(state) {
  if (state.autoFish.unlocked) return { ok: false, reason: 'owned' };
  if (state.player.rank < AUTO_FISH_UNLOCK.rankReq) return { ok: false, reason: 'rank' };
  if (!spend(state, AUTO_FISH_UNLOCK.cost)) return { ok: false, reason: 'cost' };
  state.autoFish.unlocked = true;
  return { ok: true };
}
