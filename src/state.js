// state.js — a "planilha" com tudo que precisa ser salvo. Um objeto simples,
// sem classes, pra ficar fácil de inspecionar/depurar e salvar como JSON puro.

import { FISH } from './data/fish.js';
import { LOCATIONS, allVenueIds } from './data/locations.js';
import { COSMETICS } from './data/cosmetics.js';
import { RODS, BAITS } from './data/equipment.js';

export const SAVE_VERSION = 1;

const DEFAULT_LOCATION = 'ancoradouro';
const MAX_INVENTORY_QTY = 1e9;

export function defaultState() {
  const now = Date.now();
  return {
    version: SAVE_VERSION,
    createdAt: now,
    lastSeen: now,

    player: {
      rank: 1,
      xp: 0,
      xpToNext: xpForRank(1),
    },

    currencies: {
      conchas: 20,   // moeda principal, ganha vendendo peixe
      escamas: 0,    // moeda "rara", vem de peixes/achados especiais
    },

    equipment: {
      rodTier: 1,
      baitTier: 1,
    },

    autoFish: {
      unlocked: false,
      enabled: false,
    },

    locationId: DEFAULT_LOCATION,
    unlockedLocations: [DEFAULT_LOCATION],
    unlockedVenues: [], // lojas/ateliês visitáveis (ver venues em data/locations.js)

    inventory: [], // { fishId, qty }

    cosmetics: {
      owned: ['hat_none', 'outfit_base', 'acc_none'],
      equipped: { hat: 'hat_none', outfit: 'outfit_base', accessory: 'acc_none' },
    },

    activeEvent: null, // { id, title, icon, effect, expiresAt }
    lastEventRollAt: now,

    stats: {
      totalCatches: 0,
      totalEscaped: 0,
      totalSoldConchas: 0,
      rareCatches: 0,
    },
  };
}

export function xpForRank(rank) {
  const r = Number.isFinite(rank) && rank > 0 ? Math.floor(rank) : 1;
  return 50 + r * 25;
}

// Aplica defaults por cima de um save antigo/incompleto, sem perder progresso.
// Depois passa por `sanitizeState`: o arquivo de save fica em disco e pode ser
// editado à mão ou corromper num desligamento, então nada que vem de lá entra
// no jogo sem checagem — um NaN, um id inexistente ou um xpToNext zerado viram
// crash ou loop infinito lá na frente.
export function mergeWithDefaults(saved) {
  if (!saved || typeof saved !== 'object' || Array.isArray(saved)) return defaultState();
  return sanitizeState(deepMerge(defaultState(), saved));
}

function deepMerge(base, override) {
  if (Array.isArray(base)) return Array.isArray(override) ? override : base;
  if (typeof base === 'object' && base !== null) {
    const result = { ...base };
    for (const key of Object.keys(base)) {
      if (override && Object.prototype.hasOwnProperty.call(override, key)) {
        result[key] = deepMerge(base[key], override[key]);
      }
    }
    return result;
  }
  return override !== undefined ? override : base;
}

function int(value, fallback, min = 0, max = Number.MAX_SAFE_INTEGER) {
  const n = Math.floor(Number(value));
  if (!Number.isFinite(n)) return fallback;
  return Math.min(max, Math.max(min, n));
}

function timestamp(value, fallback) {
  const n = Number(value);
  if (!Number.isFinite(n) || n <= 0) return fallback;
  return Math.min(n, fallback + 60000); // save "do futuro" não vira crédito offline
}

export function sanitizeState(state) {
  const def = defaultState();
  const now = Date.now();
  const s = state && typeof state === 'object' ? state : def;

  s.version = SAVE_VERSION;
  s.createdAt = timestamp(s.createdAt, now);
  s.lastSeen = timestamp(s.lastSeen, now);
  s.lastEventRollAt = timestamp(s.lastEventRollAt, now);

  const p = s.player && typeof s.player === 'object' ? s.player : {};
  const rank = int(p.rank, 1, 1);
  s.player = {
    rank,
    xp: int(p.xp, 0, 0),
    // xpToNext <= 0 travava o `while` de subida de rank em loop infinito.
    xpToNext: int(p.xpToNext, 0, 0) > 0 ? int(p.xpToNext, 0, 0) : xpForRank(rank),
  };

  const c = s.currencies && typeof s.currencies === 'object' ? s.currencies : {};
  s.currencies = {
    conchas: int(c.conchas, def.currencies.conchas, 0),
    escamas: int(c.escamas, 0, 0),
  };

  const eq = s.equipment && typeof s.equipment === 'object' ? s.equipment : {};
  const maxRod = RODS[RODS.length - 1].tier;
  const maxBait = BAITS[BAITS.length - 1].tier;
  s.equipment = {
    rodTier: int(eq.rodTier, 1, 1, maxRod),
    baitTier: int(eq.baitTier, 1, 1, maxBait),
  };

  const af = s.autoFish && typeof s.autoFish === 'object' ? s.autoFish : {};
  s.autoFish = { unlocked: !!af.unlocked, enabled: !!af.unlocked && !!af.enabled };

  s.unlockedLocations = Array.isArray(s.unlockedLocations)
    ? [...new Set(s.unlockedLocations.filter((id) => typeof id === 'string' && LOCATIONS[id]))]
    : [DEFAULT_LOCATION];
  if (!s.unlockedLocations.includes(DEFAULT_LOCATION)) s.unlockedLocations.unshift(DEFAULT_LOCATION);
  s.locationId = typeof s.locationId === 'string' && s.unlockedLocations.includes(s.locationId)
    ? s.locationId
    : DEFAULT_LOCATION;

  const knownVenues = new Set(allVenueIds());
  s.unlockedVenues = Array.isArray(s.unlockedVenues)
    ? [...new Set(s.unlockedVenues.filter((id) => typeof id === 'string' && knownVenues.has(id)))]
    : [];

  const invMap = new Map();
  if (Array.isArray(s.inventory)) {
    for (const entry of s.inventory) {
      if (!entry || typeof entry !== 'object') continue;
      if (typeof entry.fishId !== 'string' || !FISH[entry.fishId]) continue;
      const qty = int(entry.qty, 0, 0, MAX_INVENTORY_QTY);
      if (qty <= 0) continue;
      invMap.set(entry.fishId, Math.min(MAX_INVENTORY_QTY, (invMap.get(entry.fishId) || 0) + qty));
    }
  }
  s.inventory = [...invMap].map(([fishId, qty]) => ({ fishId, qty }));

  const cos = s.cosmetics && typeof s.cosmetics === 'object' ? s.cosmetics : {};
  const owned = new Set(def.cosmetics.owned);
  if (Array.isArray(cos.owned)) {
    for (const id of cos.owned) if (typeof id === 'string' && COSMETICS[id]) owned.add(id);
  }
  const equipped = { ...def.cosmetics.equipped };
  const savedEquipped = cos.equipped && typeof cos.equipped === 'object' ? cos.equipped : {};
  for (const slot of Object.keys(equipped)) {
    const id = savedEquipped[slot];
    if (typeof id === 'string' && COSMETICS[id] && COSMETICS[id].slot === slot && owned.has(id)) {
      equipped[slot] = id;
    }
  }
  s.cosmetics = { owned: [...owned], equipped };

  const evt = s.activeEvent;
  const validEvent = evt && typeof evt === 'object'
    && typeof evt.id === 'string'
    && Number.isFinite(evt.expiresAt) && evt.expiresAt > now
    && evt.effect && typeof evt.effect === 'object' && !Array.isArray(evt.effect);
  s.activeEvent = validEvent
    ? {
        id: evt.id,
        title: typeof evt.title === 'string' ? evt.title : '',
        icon: typeof evt.icon === 'string' ? evt.icon : '#ffffff',
        effect: evt.effect,
        expiresAt: evt.expiresAt,
      }
    : null;

  const st = s.stats && typeof s.stats === 'object' ? s.stats : {};
  s.stats = {
    totalCatches: int(st.totalCatches, 0, 0),
    totalEscaped: int(st.totalEscaped, 0, 0),
    totalSoldConchas: int(st.totalSoldConchas, 0, 0),
    rareCatches: int(st.rareCatches, 0, 0),
  };

  return s;
}

export function addInventory(state, fishId, qty = 1) {
  if (!FISH[fishId] || !Number.isFinite(qty) || qty <= 0) return;
  const entry = state.inventory.find((i) => i.fishId === fishId);
  if (entry) entry.qty = Math.min(MAX_INVENTORY_QTY, entry.qty + qty);
  else state.inventory.push({ fishId, qty });
}

export function removeInventory(state, fishId, qty = 1) {
  const entry = state.inventory.find((i) => i.fishId === fishId);
  if (!entry) return false;
  entry.qty -= qty;
  if (entry.qty <= 0) {
    state.inventory = state.inventory.filter((i) => i.fishId !== fishId);
  }
  return true;
}
