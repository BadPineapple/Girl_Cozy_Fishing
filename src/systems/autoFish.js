// autoFish.js — o "assistente de pesca": enquanto ligado, tenta uma pescaria
// automática de tempos em tempos, sem precisar do minigame manual. Rende um
// pouco menos de XP que pescar na mão (pra manual continuar valendo a pena),
// mas os peixes valem o mesmo quando vendidos.

import { rollFish } from '../data/fish.js';
import { rodByTier } from '../data/equipment.js';
import { addXp, addCurrency } from './economy.js';
import { addInventory } from '../state.js';

export const AUTO_FISH_INTERVAL_MS = 45000; // uma tentativa a cada ~45s — cozy, não uma metralhadora
export const AUTO_FISH_XP_MULT = 0.55;
const MAX_CATCHUP_ATTEMPTS = 800; // ~10h de catch-up; teto só pra não travar o frame

export function autoFishSuccessChance(state) {
  const rod = rodByTier(state.equipment.rodTier);
  const power = rod ? rod.power : 1;
  return Math.min(0.9, 0.5 + power * 0.06);
}

export function simulateAutoCatch(state, rareBonus = 0) {
  const success = Math.random() < autoFishSuccessChance(state);
  if (!success) return null;

  const fish = rollFish(state.locationId, rareBonus);
  if (!fish) return null;

  addInventory(state, fish.id, 1);
  const xpGain = Math.max(1, Math.round(fish.xp * AUTO_FISH_XP_MULT));
  addXp(state, xpGain);
  if (fish.escamas) addCurrency(state, 'escamas', Math.max(1, Math.round(fish.escamas * 0.5)));

  state.stats.totalCatches += 1;
  if (fish.rarity === 'raro' || fish.rarity === 'lendario') state.stats.rareCatches += 1;

  return { fish, xpGain };
}

// accumulatorRef: objeto { value } que guarda quanto tempo já passou desde
// a última tentativa — evita ter que guardar isso no state persistido.
// dtMs deve vir do relógio de parede (Date.now), não do requestAnimationFrame:
// com a janela escondida o rAF congela, e o assistente parava junto.
// Retorna um array com as fisgadas do tick (vazio se nenhuma).
export function tickAutoFish(state, dtMs, rareBonus, accumulatorRef) {
  if (!state.autoFish.unlocked || !state.autoFish.enabled) {
    accumulatorRef.value = 0;
    return [];
  }
  if (!Number.isFinite(dtMs) || dtMs <= 0) return [];

  accumulatorRef.value += dtMs;
  const results = [];
  let attempts = 0;
  while (accumulatorRef.value >= AUTO_FISH_INTERVAL_MS && attempts < MAX_CATCHUP_ATTEMPTS) {
    accumulatorRef.value -= AUTO_FISH_INTERVAL_MS;
    attempts += 1;
    const result = simulateAutoCatch(state, rareBonus);
    if (result) results.push(result);
  }
  if (attempts >= MAX_CATCHUP_ATTEMPTS) accumulatorRef.value = 0;
  return results;
}
