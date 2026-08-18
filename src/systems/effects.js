// effects.js — ponto único de leitura dos efeitos do evento ativo.
// Antes cada sistema relia `state.activeEvent` por conta própria (e um deles
// esquecia de aplicar o multiplicador de valor); centralizar evita divergência.

const EMPTY = Object.freeze({});

export function activeEffect(state, now = Date.now()) {
  const evt = state && state.activeEvent;
  if (!evt || typeof evt !== 'object') return EMPTY;
  if (!(evt.expiresAt > now)) return EMPTY;
  return evt.effect && typeof evt.effect === 'object' ? evt.effect : EMPTY;
}

export function num(value, fallback) {
  return Number.isFinite(value) ? value : fallback;
}

export function rareBonusFrom(state, baitBonusPct = 0, now = Date.now()) {
  return num(baitBonusPct, 0) + num(activeEffect(state, now).rareBonusPct, 0);
}

export function valueMultiplier(state, now = Date.now()) {
  return num(activeEffect(state, now).valueMultiplier, 1);
}

export function xpMultiplier(state, now = Date.now()) {
  return num(activeEffect(state, now).xpMultiplier, 1);
}

export function biteWaitMultiplier(state, now = Date.now()) {
  const m = num(activeEffect(state, now).biteWaitMultiplier, 1);
  return m > 0 ? m : 1;
}
