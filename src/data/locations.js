// locations.js — o "mapa": pontos que o jogador pode desbloquear e visitar.
// Cada local tem sua paisagem (paleta), seu peixário e um NPC vendedor
// com falas originais (nada copiado de jogo nenhum).

export const LOCATIONS = {
  ancoradouro: {
    id: 'ancoradouro',
    name: 'Ancoradouro',
    order: 0,
    unlockRank: 1,
    unlockCost: { conchas: 0, escamas: 0 },
    sky: { top: '#3b4a6b', bottom: '#e8935a' },
    water: '#2e6e75',
    description: 'Onde tudo começou: um cais de madeira gasto pelo tempo.',
    vendor: {
      name: 'Seu Tico',
      palette: ['#caa06b', '#7a5230', '#3a2718'],
      lines: [
        'Bom dia! Bora ver o que a maré trouxe hoje.',
        'Essa vara aí já pescou muita coisa boa, viu.',
        'Isca fresquinha rende peixe mais graúdo.',
      ],
    },
  },
  enseada: {
    id: 'enseada',
    name: 'Enseada dos Corais',
    order: 1,
    unlockRank: 5,
    unlockCost: { conchas: 150, escamas: 0 },
    sky: { top: '#254a5e', bottom: '#f2a154' },
    water: '#1f7a8c',
    description: 'Águas mais claras, recifes logo abaixo da superfície.',
    vendor: {
      name: 'Marina',
      palette: ['#e8a3c0', '#a3486b', '#4a1f33'],
      lines: [
        'Cuidado com os caranguejos, eles beliscam!',
        'Já achei conchas lindas por aqui, guarda uma pra mim?',
        'A água tá um espelho hoje. Boa sorte na pesca.',
      ],
    },
  },
  mar_aberto: {
    id: 'mar_aberto',
    name: 'Mar Aberto',
    order: 2,
    unlockRank: 12,
    unlockCost: { conchas: 500, escamas: 20 },
    sky: { top: '#141c30', bottom: '#3a3a6b' },
    water: '#0f2e42',
    description: 'Longe da costa, onde moram os peixes de verdade.',
    vendor: {
      name: 'Capitã Ori',
      palette: ['#6b7fa3', '#2e3b5c', '#161c2e'],
      lines: [
        'Águas fundas guardam coisas que a costa nunca vê.',
        'Já vi uma sombra enorme passar ali embaixo outro dia...',
        'Garrafa com bilhete de novo? Alguém tá mandando recado.',
      ],
    },
  },
};

export function sortedLocations() {
  return Object.values(LOCATIONS).sort((a, b) => a.order - b.order);
}

export function isLocationUnlocked(state, locationId) {
  return state.unlockedLocations.includes(locationId);
}
