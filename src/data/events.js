// events.js — eventos aleatórios e passageiros que dão um empurrãozinho
// temporário. São só flavor + multiplicadores, nada de textos de outro jogo.

export const EVENTS = [
  {
    id: 'cardume_raro',
    title: 'Cardume raro por perto!',
    icon: '#e8734a',
    durationMs: 3 * 60 * 1000,
    weight: 20,
    effect: { rareBonusPct: 25 },
  },
  {
    id: 'mare_cheia',
    title: 'Maré cheia — os peixes mordem rápido!',
    icon: '#2e6e75',
    durationMs: 4 * 60 * 1000,
    weight: 25,
    effect: { biteWaitMultiplier: 0.5 },
  },
  {
    id: 'brisa_da_sorte',
    title: 'Uma brisa de sorte passou por aqui.',
    icon: '#f2c14e',
    durationMs: 5 * 60 * 1000,
    weight: 20,
    effect: { valueMultiplier: 1.3 },
  },
  {
    id: 'visita_gaivota',
    title: 'Uma gaivota curiosa pousou no barco.',
    icon: '#f2e9e4',
    durationMs: 2 * 60 * 1000,
    weight: 15,
    effect: { xpMultiplier: 1.5 },
  },
];

export function rollEvent() {
  const total = EVENTS.reduce((sum, e) => sum + e.weight, 0);
  let roll = Math.random() * total;
  for (const e of EVENTS) {
    roll -= e.weight;
    if (roll <= 0) return e;
  }
  return EVENTS[0];
}
