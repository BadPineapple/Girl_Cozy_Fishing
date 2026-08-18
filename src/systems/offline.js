// offline.js — quando o app abre de novo, calcula quanto o "assistente de
// pesca" teria rendido enquanto a janela estava fechada (se estava ligado).
// Peixes vão pro inventário normalmente; é só a moeda de venda que espera
// você voltar pra loja — assim sempre tem uma surpresa te esperando.

import { simulateAutoCatch, AUTO_FISH_INTERVAL_MS } from './autoFish.js';

export const MAX_OFFLINE_MS = 8 * 60 * 60 * 1000; // teto de 8h de ausência
const OFFLINE_INTERVAL_MULT = 1.8; // menos eficiente que estar de olho na tela

export function computeOfflineEarnings(state, rareBonus = 0) {
  if (!state.autoFish.unlocked || !state.autoFish.enabled) return null;

  const now = Date.now();
  const elapsed = Math.min(Math.max(0, now - state.lastSeen), MAX_OFFLINE_MS);
  const interval = AUTO_FISH_INTERVAL_MS * OFFLINE_INTERVAL_MULT;
  const attempts = Math.floor(elapsed / interval);
  if (attempts <= 0) return null;

  const summary = { attempts, catches: 0, xp: 0, escamas: 0, rareCatches: 0, elapsedMs: elapsed };
  const escamasBefore = state.currencies.escamas;

  for (let i = 0; i < attempts; i++) {
    const result = simulateAutoCatch(state, rareBonus);
    if (result) {
      summary.catches += 1;
      summary.xp += result.xpGain;
      if (result.fish.rarity === 'raro' || result.fish.rarity === 'lendario') summary.rareCatches += 1;
    }
  }
  summary.escamas = state.currencies.escamas - escamasBefore;
  return summary;
}
