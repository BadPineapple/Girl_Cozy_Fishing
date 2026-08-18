// eventsEngine.js — de tempos em tempos, sorteia um eventinho passageiro
// (ver data/events.js) que dá um bônus temporário. Puramente cosmético
// na frequência: não deixa o jogo mais difícil, só mais gostoso de acompanhar.

import { rollEvent } from '../data/events.js';

const CHECK_COOLDOWN_MS = 5 * 60 * 1000; // não tenta rolar de novo antes disso
const ROLL_CHANCE = 0.35; // chance de "dar evento" a cada checagem após o cooldown

export function tickEvents(state, now = Date.now(), onEventStart) {
  if (state.activeEvent && state.activeEvent.expiresAt <= now) {
    state.activeEvent = null;
  }

  if (state.activeEvent) return;
  if (now - state.lastEventRollAt < CHECK_COOLDOWN_MS) return;

  state.lastEventRollAt = now;
  if (Math.random() > ROLL_CHANCE) return;

  const def = rollEvent();
  state.activeEvent = {
    id: def.id,
    title: def.title,
    icon: def.icon,
    effect: def.effect,
    expiresAt: now + def.durationMs,
  };
  if (onEventStart) onEventStart(state.activeEvent);
}
