// fish.js — catálogo de peixes (e achados curiosos) por localização.
// rarity: 'comum' | 'incomum' | 'raro' | 'lendario'
// strength: quanto o peixe "puxa" durante o minigame de reel (afeta decaimento da barra)
// palette: cores usadas pelo desenho pixelado do peixe (ver render/pixelSprites.js)

export const RARITY_WEIGHT = {
  comum: 100,
  incomum: 40,
  raro: 12,
  lendario: 2,
};

export const RARITY_LABEL = {
  comum: 'Comum',
  incomum: 'Incomum',
  raro: 'Raro',
  lendario: 'Lendário',
};

export const FISH = {
  // --- Ancoradouro (início) ---
  lambari: {
    id: 'lambari', name: 'Lambari', location: 'ancoradouro', rarity: 'comum',
    value: 3, xp: 2, strength: 1, palette: ['#c9d6a3', '#8fae5a', '#4a5c2e'],
  },
  tilapia_cais: {
    id: 'tilapia_cais', name: 'Tilápia-do-Cais', location: 'ancoradouro', rarity: 'comum',
    value: 4, xp: 3, strength: 2, palette: ['#a9c4c9', '#5f8f96', '#2e4a4e'],
  },
  robalo_listrado: {
    id: 'robalo_listrado', name: 'Robalo-Listrado', location: 'ancoradouro', rarity: 'incomum',
    value: 9, xp: 6, strength: 3, palette: ['#d9d3c1', '#8a8570', '#3a3830'],
  },
  bota_velha: {
    id: 'bota_velha', name: 'Bota Velha', location: 'ancoradouro', rarity: 'raro',
    value: 2, xp: 1, strength: 1, palette: ['#6b4a2f', '#4a331f', '#2a1c10'],
    flavor: 'Não dá pra vender por muito, mas tem uma história pra contar.',
  },

  // --- Enseada ---
  peixe_borboleta: {
    id: 'peixe_borboleta', name: 'Peixe-Borboleta', location: 'enseada', rarity: 'comum',
    value: 6, xp: 4, strength: 2, palette: ['#f2c94c', '#e07a5f', '#3d405b'],
  },
  caranguejo_violinista: {
    id: 'caranguejo_violinista', name: 'Caranguejo-Violinista', location: 'enseada', rarity: 'incomum',
    value: 12, xp: 8, strength: 4, palette: ['#e8734a', '#b3492a', '#5c2413'],
  },
  estrela_rosea: {
    id: 'estrela_rosea', name: 'Estrela-do-Mar Rósea', location: 'enseada', rarity: 'raro',
    value: 22, xp: 14, strength: 5, palette: ['#f4a6c1', '#d1477e', '#7a2148'],
  },
  concha_perolada: {
    id: 'concha_perolada', name: 'Concha Perolada', location: 'enseada', rarity: 'raro',
    value: 4, xp: 10, strength: 4, escamas: 3, palette: ['#f2e9e4', '#dcd0c0', '#a89f91'],
    flavor: 'Guarda uma pérola pequena, mas brilhante.',
  },

  // --- Mar Aberto ---
  atum_prateado: {
    id: 'atum_prateado', name: 'Atum-Prateado', location: 'mar_aberto', rarity: 'incomum',
    value: 18, xp: 12, strength: 5, palette: ['#c7d3e0', '#7c93ab', '#374861'],
  },
  peixe_lanterna: {
    id: 'peixe_lanterna', name: 'Peixe-Lanterna', location: 'mar_aberto', rarity: 'raro',
    value: 35, xp: 20, strength: 7, palette: ['#ffe066', '#e8a33d', '#4a3418'],
  },
  serpente_profundezas: {
    id: 'serpente_profundezas', name: 'Serpente-das-Profundezas', location: 'mar_aberto', rarity: 'lendario',
    value: 80, xp: 45, strength: 9, palette: ['#4a2e6b', '#2d1a45', '#160d24'],
  },
  garrafa_bilhete: {
    id: 'garrafa_bilhete', name: 'Garrafa com Bilhete', location: 'mar_aberto', rarity: 'raro',
    value: 6, xp: 15, strength: 4, escamas: 8, palette: ['#dff0ea', '#a9cfc4', '#5c8a7d'],
    flavor: 'A tinta borrou, mas dá pra ler um pedaço da mensagem.',
    story: true,
  },
};

export function fishForLocation(locationId) {
  return Object.values(FISH).filter((f) => f.location === locationId);
}

// Sorteia um peixe daquela localização, respeitando raridade + bônus de isca.
export function rollFish(locationId, rareBonusPct = 0) {
  const pool = fishForLocation(locationId);
  if (pool.length === 0) return null;

  const weights = pool.map((f) => {
    let w = RARITY_WEIGHT[f.rarity] || 1;
    if (f.rarity === 'raro' || f.rarity === 'lendario') {
      w *= 1 + rareBonusPct / 100;
    }
    return w;
  });

  const total = weights.reduce((a, b) => a + b, 0);
  let roll = Math.random() * total;
  for (let i = 0; i < pool.length; i++) {
    roll -= weights[i];
    if (roll <= 0) return pool[i];
  }
  return pool[pool.length - 1];
}
