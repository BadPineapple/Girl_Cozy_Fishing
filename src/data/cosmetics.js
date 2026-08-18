// cosmetics.js — itens puramente visuais, equipáveis por categoria.
// slot: 'hat' | 'outfit' | 'accessory'
// color: usado pelo desenho pixelado do personagem (render/pixelSprites.js)

export const COSMETICS = {
  hat_none: {
    id: 'hat_none', slot: 'hat', name: 'Sem chapéu', cost: {}, rankReq: 1, color: null,
  },
  hat_palha: {
    id: 'hat_palha', slot: 'hat', name: 'Chapéu de Palha', cost: { conchas: 40 }, rankReq: 1, color: '#d9b26a',
  },
  hat_boina: {
    id: 'hat_boina', slot: 'hat', name: 'Boina de Marinheiro', cost: { conchas: 80 }, rankReq: 4, color: '#3d5a80',
  },
  hat_coroa_conchinhas: {
    id: 'hat_coroa_conchinhas', slot: 'hat', name: 'Coroa de Conchinhas', cost: { escamas: 15 }, rankReq: 10, color: '#f2e9e4',
  },

  outfit_base: {
    id: 'outfit_base', slot: 'outfit', name: 'Roupa do dia a dia', cost: {}, rankReq: 1, color: '#c97b52',
  },
  outfit_moletom: {
    id: 'outfit_moletom', slot: 'outfit', name: 'Moletom Azul', cost: { conchas: 60 }, rankReq: 3, color: '#4a6fa5',
  },
  outfit_capa_amarela: {
    id: 'outfit_capa_amarela', slot: 'outfit', name: 'Capa Impermeável Amarela', cost: { conchas: 120 }, rankReq: 6, color: '#f2c14e',
  },
  outfit_festa: {
    id: 'outfit_festa', slot: 'outfit', name: 'Traje de Festa', cost: { escamas: 25 }, rankReq: 15, color: '#7a4a8f',
  },

  acc_none: {
    id: 'acc_none', slot: 'accessory', name: 'Sem acessório', cost: {}, rankReq: 1, color: null,
  },
  acc_cachecol: {
    id: 'acc_cachecol', slot: 'accessory', name: 'Cachecol Vermelho', cost: { conchas: 50 }, rankReq: 2, color: '#b5382f',
  },
  acc_oculos: {
    id: 'acc_oculos', slot: 'accessory', name: 'Óculos de Sol', cost: { conchas: 70 }, rankReq: 5, color: '#2b2b2b',
  },
  acc_brinco_perola: {
    id: 'acc_brinco_perola', slot: 'accessory', name: 'Brinco de Pérola', cost: { escamas: 10 }, rankReq: 8, color: '#f2e9e4',
  },
};

export function cosmeticsBySlot(slot) {
  return Object.values(COSMETICS).filter((c) => c.slot === slot);
}
