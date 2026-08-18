// fishing.js — a máquina de estados do minigame de pesca.
// Fases: idle -> casting -> waiting (esperando fisgar) -> reeling (cabo de guerra) -> idle
// Isso roda em memória (não é salvo no arquivo); só o RESULTADO de uma pescaria
// (peixe, xp, moeda) é que mexe no `state` persistido.

import { rollFish, FISH } from '../data/fish.js';
import { rodByTier, baitByTier } from '../data/equipment.js';
import { addXp, addCurrency } from './economy.js';
import { addInventory } from '../state.js';
import { rareBonusFrom, xpMultiplier, biteWaitMultiplier } from './effects.js';

const CAST_MS = 700;
const BASE_BITE_MIN_MS = 1200;
const BASE_BITE_MAX_MS = 3200;
const REEL_START_PCT = 38;
const REEL_CATCH_PCT = 100;

export function createFishingSession({ getState, onChange, onCatch, onEscape }) {
  let phase = 'idle'; // idle | casting | waiting | reeling
  let timer = 0;
  let fish = null;
  let reelPct = 0;
  let reelDecayPerSec = 0;
  let pullPower = 0;

  function currentRareBonus() {
    const state = getState();
    const bait = baitByTier(state.equipment.baitTier);
    return rareBonusFrom(state, bait ? bait.rareBonusPct : 0);
  }

  function startCast() {
    if (phase !== 'idle') return;
    phase = 'casting';
    timer = CAST_MS;
    onChange(snapshot());
  }

  function beginWaiting() {
    phase = 'waiting';
    const mult = biteWaitMultiplier(getState());
    const min = BASE_BITE_MIN_MS * mult;
    const max = BASE_BITE_MAX_MS * mult;
    timer = min + Math.random() * (max - min);
    onChange(snapshot());
  }

  function beginReeling() {
    const state = getState();
    fish = rollFish(state.locationId, currentRareBonus());
    if (!fish) { phase = 'idle'; onChange(snapshot()); return; }

    const rod = rodByTier(state.equipment.rodTier);
    pullPower = 7 + (rod ? rod.power * 3 : 0);
    reelPct = REEL_START_PCT;
    reelDecayPerSec = 6 + fish.strength * 3.2;
    phase = 'reeling';
    onChange(snapshot());
  }

  function pull() {
    if (phase !== 'reeling') return;
    reelPct = Math.min(REEL_CATCH_PCT, reelPct + pullPower);
    // resolveCatch() já emite o onChange final; sem o return, a UI recebia
    // dois eventos seguidos e piscava o medidor depois de fisgar.
    if (reelPct >= REEL_CATCH_PCT) { resolveCatch(); return; }
    onChange(snapshot());
  }

  function resolveCatch() {
    const state = getState();
    const xpMult = xpMultiplier(state);

    addInventory(state, fish.id, 1);
    const xpGain = Math.max(1, Math.round(fish.xp * xpMult));
    const ranksGained = addXp(state, xpGain);
    if (fish.escamas) addCurrency(state, 'escamas', fish.escamas);

    state.stats.totalCatches += 1;
    if (fish.rarity === 'raro' || fish.rarity === 'lendario') state.stats.rareCatches += 1;

    const finishedFish = fish;
    const caught = { fish: finishedFish, xpGain, ranksGained };
    phase = 'idle';
    fish = null;
    reelPct = 0;
    onCatch(caught, finishedFish);
    onChange(snapshot());
  }

  function resolveEscape() {
    const state = getState();
    state.stats.totalEscaped += 1;
    const lostFish = fish;
    phase = 'idle';
    fish = null;
    reelPct = 0;
    onEscape(lostFish);
    onChange(snapshot());
  }

  function tick(dtMs) {
    if (!Number.isFinite(dtMs) || dtMs <= 0) return;
    if (phase === 'casting') {
      timer -= dtMs;
      if (timer <= 0) beginWaiting();
    } else if (phase === 'waiting') {
      timer -= dtMs;
      if (timer <= 0) beginReeling();
    } else if (phase === 'reeling') {
      reelPct -= (reelDecayPerSec * dtMs) / 1000;
      if (reelPct <= 0) { resolveEscape(); return; }
      onChange(snapshot());
    }
  }

  function snapshot() {
    return {
      phase,
      fish,
      reelPct: Math.round(reelPct),
      fishName: fish ? fish.name : null,
      fishRarity: fish ? fish.rarity : null,
    };
  }

  return { startCast, pull, tick, snapshot, get phase() { return phase; } };
}

export { FISH };
