// equipment.js — upgrades funcionais: vara, isca e o "assistente de pesca"
// (auto-fish). Cada tier melhora um número específico do sistema de pesca.

export const RODS = [
  { tier: 1, id: 'vara_inicial', name: 'Vara Improvisada', cost: {}, rankReq: 1, power: 1 },
  { tier: 2, id: 'vara_bambu', name: 'Vara de Bambu', cost: { conchas: 100 }, rankReq: 3, power: 2 },
  { tier: 3, id: 'vara_reforcada', name: 'Vara Reforçada', cost: { conchas: 300, escamas: 10 }, rankReq: 8, power: 3 },
  { tier: 4, id: 'vara_encantada', name: 'Vara Encantada', cost: { escamas: 20 }, rankReq: 12, power: 5 },
];

export const BAITS = [
  { tier: 1, id: 'isca_comum', name: 'Isca Comum', cost: {}, rankReq: 1, rareBonusPct: 0 },
  { tier: 2, id: 'isca_fresca', name: 'Isca Fresca', cost: { conchas: 60 }, rankReq: 3, rareBonusPct: 10 },
  { tier: 3, id: 'isca_brilhante', name: 'Isca Brilhante', cost: { conchas: 150, escamas: 5 }, rankReq: 8, rareBonusPct: 20 },
  { tier: 4, id: 'isca_mistica', name: 'Isca Mística', cost: { escamas: 15 }, rankReq: 12, rareBonusPct: 35 },
];

export const AUTO_FISH_UNLOCK = {
  id: 'assistente_pesca', name: 'Assistente de Pesca', cost: { conchas: 250 }, rankReq: 8,
  description: 'Deixa a vara pescando sozinha, mesmo com você longe do teclado.',
};

export function rodByTier(tier) { return RODS.find((r) => r.tier === tier); }
export function baitByTier(tier) { return BAITS.find((b) => b.tier === tier); }
