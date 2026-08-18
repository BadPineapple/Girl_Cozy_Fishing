import { xpForRank } from '../state.js';

export function canAfford(state, cost) {
  if (!cost) return true;
  for (const [currency, amount] of Object.entries(cost)) {
    if (!Number.isFinite(amount) || amount < 0) return false;
    if ((state.currencies[currency] || 0) < amount) return false;
  }
  return true;
}

export function spend(state, cost) {
  if (!canAfford(state, cost)) return false;
  for (const [currency, amount] of Object.entries(cost)) {
    state.currencies[currency] = (state.currencies[currency] || 0) - amount;
  }
  return true;
}

export function addCurrency(state, currency, amount) {
  if (!Number.isFinite(amount) || amount === 0) return;
  state.currencies[currency] = (state.currencies[currency] || 0) + amount;
}

// Adiciona XP e sobe de rank em cascata (caso um catch grande pule mais de um rank).
// Retorna quantos ranks foram ganhos, pra UI poder comemorar.
export function addXp(state, amount) {
  if (!Number.isFinite(amount) || amount <= 0) return 0;
  state.player.xp += amount;
  let ranksGained = 0;
  // O `while` só é seguro porque xpToNext é garantidamente > 0 (ver
  // sanitizeState + xpForRank); a checagem aqui é o cinto de segurança.
  while (state.player.xp >= state.player.xpToNext) {
    if (!(state.player.xpToNext > 0)) {
      state.player.xpToNext = xpForRank(state.player.rank);
      break;
    }
    state.player.xp -= state.player.xpToNext;
    state.player.rank += 1;
    state.player.xpToNext = xpForRank(state.player.rank);
    ranksGained += 1;
  }
  return ranksGained;
}
