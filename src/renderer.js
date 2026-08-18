// renderer.js — ponto de entrada da UI. Junta o state, os sistemas
// (pesca, loja, cosméticos, mapa, eventos, auto-fish) e desenha tudo.

import { mergeWithDefaults } from './state.js';
import { loadSave, persist, persistSync, startAutosave } from './systems/save.js';
import { createFishingSession } from './systems/fishing.js';
import { canAfford } from './systems/economy.js';
import { sellFish, sellAll, fishSellValue, nextRod, nextBait, buyNextRod, buyNextBait, buyAutoFishUnlock } from './systems/shop.js';
import { buyCosmetic, equipCosmetic } from './systems/cosmetics.js';
import {
  sortedLocations, isLocationUnlocked, travelTo, unlockLocation,
  venuesForLocation, venueById, isVenueUnlocked, unlockVenue, LOCATIONS,
} from './systems/map.js';
import { tickEvents } from './systems/eventsEngine.js';
import { tickAutoFish } from './systems/autoFish.js';
import { computeOfflineEarnings } from './systems/offline.js';
import { rareBonusFrom } from './systems/effects.js';
import { FISH, RARITY_LABEL } from './data/fish.js';
import { cosmeticsBySlot } from './data/cosmetics.js';
import { AUTO_FISH_UNLOCK, baitByTier } from './data/equipment.js';
import { renderScene } from './render/scene.js';
import { drawFishIcon } from './render/pixelSprites.js';

const DEFAULT_LOCATION = 'ancoradouro';
const MAX_FRAME_DT_MS = 250;               // trava dt do minigame pra evitar saltos após pausa
const MAX_WALL_DT_MS = 8 * 60 * 60 * 1000; // teto do "catch-up" do assistente

// ---------- boot ----------
let state = mergeWithDefaults(await loadSave());

const offlineSummary = computeOfflineEarnings(state, liveRareBonus(state));
state.lastSeen = Date.now();

const runtime = { fishingPhase: 'idle' };
const autoFishAccumulator = { value: 0 };
// Qual estabelecimento está aberto — o cabeçalho da loja/ateliê usa o nome dele.
let currentVenue = null;

const canvas = document.getElementById('scene');
const ctx = canvas.getContext('2d');

// ---------- helpers ----------
function currentLocation() {
  return LOCATIONS[state.locationId] || LOCATIONS[DEFAULT_LOCATION];
}

function liveRareBonus(s) {
  const bait = baitByTier(s.equipment.baitTier);
  return rareBonusFrom(s, bait ? bait.rareBonusPct : 0);
}

function pushToast(text) {
  const container = document.getElementById('toast-container');
  const el = document.createElement('div');
  el.className = 'toast';
  el.textContent = text;
  container.appendChild(el);
  setTimeout(() => el.remove(), 2700);
}

function fmt(n) { return Math.round(n).toLocaleString('pt-BR'); }

function totalFishInPocket() {
  return state.inventory.reduce((sum, entry) => sum + entry.qty, 0);
}

// ---------- fishing session ----------
const fishingSession = createFishingSession({
  getState: () => state,
  onChange: (snap) => { runtime.fishingPhase = snap.phase; updateActionUI(snap); },
  onCatch: (caught, fish) => {
    const tag = fish.rarity === 'raro' || fish.rarity === 'lendario' ? ` (${RARITY_LABEL[fish.rarity]}!)` : '';
    pushToast(`🎣 Pescou: ${fish.name}${tag}`);
    if (caught.ranksGained > 0) {
      setTimeout(() => pushToast(`⭐ Subiu para o rank ${state.player.rank}!`), 500);
    }
    renderStatBar();
  },
  onEscape: (fish) => {
    pushToast(fish ? `${fish.name} escapou...` : 'Escapou...');
  },
});

// ---------- game loop ----------
let lastTs = performance.now();
let lastWallMs = Date.now();
function loop(ts) {
  const dt = Math.min(MAX_FRAME_DT_MS, Math.max(0, ts - lastTs));
  lastTs = ts;

  // O assistente conta pelo relógio de parede: com a janela escondida o
  // requestAnimationFrame congela, e antes ele parava junto sem que o cálculo
  // offline cobrisse o buraco (o autosave seguia atualizando o lastSeen).
  const nowMs = Date.now();
  const wallDt = Math.min(MAX_WALL_DT_MS, Math.max(0, nowMs - lastWallMs));
  lastWallMs = nowMs;

  fishingSession.tick(dt);

  const autoResults = tickAutoFish(state, wallDt, liveRareBonus(state), autoFishAccumulator);
  if (autoResults.length > 0) {
    const last = autoResults[autoResults.length - 1];
    pushToast(autoResults.length === 1
      ? `🤖 Assistente pescou: ${last.fish.name}`
      : `🤖 Assistente pescou ${autoResults.length} peixes`);
    renderStatBar();
  }

  tickEvents(state, nowMs, (evt) => pushToast(`✨ ${evt.title}`));

  renderScene(ctx, state, runtime);
  requestAnimationFrame(loop);
}

// stats são atualizados por evento, não a cada frame — mais leve
function renderStatBar() {
  document.getElementById('rank-value').textContent = state.player.rank;
  document.getElementById('xp-fill').style.width = `${Math.min(100, (state.player.xp / state.player.xpToNext) * 100)}%`;
  document.getElementById('conchas-value').textContent = fmt(state.currencies.conchas);
  document.getElementById('escamas-value').textContent = fmt(state.currencies.escamas);
  document.getElementById('location-tag').textContent = currentLocation().name;
  document.getElementById('pocket-count').textContent = fmt(totalFishInPocket());

  const autoRow = document.getElementById('auto-fish-row');
  autoRow.classList.toggle('hidden', !state.autoFish.unlocked);
  document.getElementById('auto-fish-toggle').checked = state.autoFish.enabled;
}

function updateActionUI(snap) {
  const btn = document.getElementById('btn-main-action');
  const meter = document.getElementById('reel-meter');
  const fill = document.getElementById('reel-fill');
  const wait = document.getElementById('wait-indicator');

  meter.classList.add('hidden');
  wait.classList.add('hidden');
  btn.disabled = false;

  if (snap.phase === 'idle') {
    btn.textContent = 'Lançar a isca';
  } else if (snap.phase === 'casting') {
    btn.textContent = 'Lançando…';
    btn.disabled = true;
  } else if (snap.phase === 'waiting') {
    btn.textContent = 'Aguardando…';
    btn.disabled = true;
    wait.classList.remove('hidden');
  } else if (snap.phase === 'reeling') {
    btn.textContent = 'Puxar!';
    meter.classList.remove('hidden');
    fill.style.width = `${snap.reelPct}%`;
  }
}

document.getElementById('btn-main-action').addEventListener('click', () => {
  if (fishingSession.phase === 'idle') fishingSession.startCast();
  else if (fishingSession.phase === 'reeling') fishingSession.pull();
});

document.getElementById('btn-hide').addEventListener('click', () => {
  saveNow();
  if (window.mareApi) window.mareApi.hideWindow();
});

document.getElementById('auto-fish-toggle').addEventListener('change', (e) => {
  // Sem o unlocked o toggle nem aparece, mas o state é o que manda.
  state.autoFish.enabled = state.autoFish.unlocked && e.target.checked;
  e.target.checked = state.autoFish.enabled;
  autoFishAccumulator.value = 0;
  saveNow();
});

// ---------- painéis ----------
// Loja e ateliê não têm aba: são lugares, abertos pelo Mapa.
const PANEL_IDS = ['panel-map', 'panel-pocket', 'panel-shop', 'panel-cosmetics'];

document.querySelectorAll('.tab-btn').forEach((btn) => {
  btn.addEventListener('click', () => openPanel(btn.dataset.panel));
});
document.querySelectorAll('.panel-close').forEach((btn) => {
  btn.addEventListener('click', () => {
    closePanel(btn.dataset.close);
    // Saiu da loja/ateliê? Volta pro mapa, que foi de onde você entrou.
    if (btn.dataset.back) openPanel(btn.dataset.back);
  });
});

function openPanel(id) {
  if (!PANEL_IDS.includes(id)) return;
  // Os painéis ocupam a tela inteira: abrir um por cima do outro deixava o
  // de baixo aberto e "preso" atrás quando o de cima fechava.
  for (const other of PANEL_IDS) {
    if (other !== id) document.getElementById(other).classList.add('hidden');
  }
  if (id === 'panel-map') renderMapPanel();
  if (id === 'panel-pocket') renderPocketPanel();
  if (id === 'panel-shop') renderShopPanel();
  if (id === 'panel-cosmetics') renderCosmeticsPanel();
  document.getElementById(id).classList.remove('hidden');
}

function closePanel(id) {
  const panel = document.getElementById(id);
  if (panel) panel.classList.add('hidden');
  saveNow();
}

function rowCard({ title, sub, buttonLabel, disabled, onClick, equipped, className }) {
  const row = document.createElement('div');
  row.className = className ? `row-card ${className}` : 'row-card';
  const info = document.createElement('div');
  info.className = 'row-info';
  const t = document.createElement('div');
  t.className = 'row-title';
  t.textContent = title;
  info.appendChild(t);
  if (sub) {
    const s = document.createElement('div');
    s.className = 'row-sub';
    s.textContent = sub;
    info.appendChild(s);
  }
  row.appendChild(info);
  if (buttonLabel) {
    const btn = document.createElement('button');
    btn.textContent = buttonLabel;
    btn.disabled = !!disabled;
    if (equipped) btn.classList.add('equipped');
    btn.addEventListener('click', onClick);
    row.appendChild(btn);
  }
  return row;
}

const CURRENCY_LABEL = { conchas: 'conchas', escamas: 'escamas' };

function costLabel(cost) {
  const parts = Object.entries(cost || {}).filter(([, v]) => v > 0);
  if (parts.length === 0) return 'Grátis';
  return parts.map(([k, v]) => `${v} ${CURRENCY_LABEL[k] || k}`).join(' + ');
}

// ---- bolso ----
function renderPocketPanel() {
  const box = document.getElementById('pocket-list');
  box.innerHTML = '';
  if (state.inventory.length === 0) {
    box.appendChild(Object.assign(document.createElement('div'), {
      className: 'inv-empty',
      textContent: 'Nenhum peixe no bolso ainda. Lança a isca!',
    }));
    return;
  }
  for (const entry of state.inventory) {
    const fish = FISH[entry.fishId];
    if (!fish) continue;

    const item = document.createElement('div');
    item.className = 'pocket-item';

    const c = document.createElement('canvas');
    c.width = 40; c.height = 40;
    drawFishIcon(c.getContext('2d'), fish.palette, 2, 2, 34);

    const info = document.createElement('div');
    info.className = 'pocket-info';
    const name = document.createElement('div');
    name.className = 'pocket-name';
    name.textContent = fish.name;
    const sub = document.createElement('div');
    sub.className = 'pocket-sub';
    sub.textContent = `${RARITY_LABEL[fish.rarity]} — ${fishSellValue(state, fish)} conchas cada`;
    info.appendChild(name);
    info.appendChild(sub);

    const qty = document.createElement('span');
    qty.className = 'pocket-qty';
    qty.textContent = `×${entry.qty}`;

    item.appendChild(c);
    item.appendChild(info);
    item.appendChild(qty);
    box.appendChild(item);
  }
}

// ---- mapa: estabelecimentos daqui + viagens ----
function renderMapPanel() {
  const loc = currentLocation();
  document.getElementById('map-here-name').textContent = loc.name;

  const venueBox = document.getElementById('map-venues');
  venueBox.innerHTML = '';
  const venues = venuesForLocation(loc.id);
  if (venues.length === 0) {
    venueBox.appendChild(Object.assign(document.createElement('div'), {
      className: 'inv-empty', textContent: 'Nenhum estabelecimento por aqui.',
    }));
  }
  for (const venue of venues) {
    const unlocked = isVenueUnlocked(state, venue.id);
    const rankOk = state.player.rank >= (venue.unlockRank || 1);
    venueBox.appendChild(rowCard({
      className: unlocked ? 'venue' : 'venue locked',
      title: venue.name,
      sub: unlocked
        ? venue.description
        : `Fechado — requer rank ${venue.unlockRank} e ${costLabel(venue.unlockCost)}`,
      buttonLabel: unlocked ? 'Entrar' : 'Abrir',
      disabled: !unlocked && (!rankOk || !canAfford(state, venue.unlockCost)),
      onClick: () => {
        if (!unlocked) {
          const res = unlockVenue(state, venue.id);
          if (!res.ok) { renderMapPanel(); return; }
          pushToast(`🔓 ${venue.name} agora está aberto!`);
          renderStatBar();
          renderMapPanel();
          saveNow();
          return;
        }
        enterVenue(venue.id);
      },
    }));
  }

  const box = document.getElementById('map-locations');
  box.innerHTML = '';
  for (const place of sortedLocations()) {
    const unlocked = isLocationUnlocked(state, place.id);
    const here = state.locationId === place.id;
    box.appendChild(rowCard({
      title: place.name,
      sub: unlocked ? place.description : `Requer rank ${place.unlockRank} — ${costLabel(place.unlockCost)}`,
      buttonLabel: here ? 'Você está aqui' : unlocked ? 'Viajar' : 'Desbloquear',
      disabled: here || (!unlocked && (state.player.rank < place.unlockRank || !canAfford(state, place.unlockCost))),
      equipped: here,
      onClick: () => {
        if (unlocked) travelTo(state, place.id);
        else if (unlockLocation(state, place.id).ok) travelTo(state, place.id);
        renderMapPanel();
        renderStatBar();
        saveNow();
      },
    }));
  }
}

function enterVenue(venueId) {
  const venue = venueById(venueId);
  if (!venue || !isVenueUnlocked(state, venueId)) return;
  currentVenue = venue;
  openPanel(venue.kind === 'cosmetics' ? 'panel-cosmetics' : 'panel-shop');
}

// ---- loja ----
function renderShopPanel() {
  const name = currentVenue ? currentVenue.name : `Loja — ${currentLocation().vendor.name}`;
  document.getElementById('shop-vendor-name').textContent = name;

  const invBox = document.getElementById('shop-inventory');
  invBox.innerHTML = '';
  if (state.inventory.length === 0) {
    invBox.appendChild(Object.assign(document.createElement('div'), { className: 'inv-empty', textContent: 'Volte depois de pescar algo!' }));
  }
  for (const entry of state.inventory) {
    const fish = FISH[entry.fishId];
    if (!fish) continue;
    const unitValue = fishSellValue(state, fish);
    const bonusTag = unitValue > fish.value ? ' ✨' : '';
    invBox.appendChild(rowCard({
      title: `${fish.name} × ${entry.qty}`,
      sub: `${RARITY_LABEL[fish.rarity]} — vale ${unitValue} conchas cada${bonusTag}`,
      buttonLabel: 'Vender 1',
      onClick: () => { sellFish(state, fish.id, 1); renderShopPanel(); renderStatBar(); },
    }));
  }

  document.getElementById('btn-sell-all').onclick = () => {
    const total = sellAll(state);
    if (total > 0) pushToast(`💰 +${fmt(total)} conchas`);
    renderShopPanel(); renderStatBar();
  };

  const eqBox = document.getElementById('shop-equipment');
  eqBox.innerHTML = '';

  const rod = nextRod(state);
  if (rod) {
    eqBox.appendChild(rowCard({
      title: rod.name,
      sub: `Requer rank ${rod.rankReq} — ${costLabel(rod.cost)}`,
      buttonLabel: 'Comprar',
      disabled: state.player.rank < rod.rankReq || !canAfford(state, rod.cost),
      onClick: () => { buyNextRod(state); renderShopPanel(); renderStatBar(); saveNow(); },
    }));
  } else {
    eqBox.appendChild(rowCard({ title: 'Vara no nível máximo', buttonLabel: null }));
  }

  const bait = nextBait(state);
  if (bait) {
    eqBox.appendChild(rowCard({
      title: bait.name,
      sub: `Requer rank ${bait.rankReq} — ${costLabel(bait.cost)}`,
      buttonLabel: 'Comprar',
      disabled: state.player.rank < bait.rankReq || !canAfford(state, bait.cost),
      onClick: () => { buyNextBait(state); renderShopPanel(); renderStatBar(); saveNow(); },
    }));
  } else {
    eqBox.appendChild(rowCard({ title: 'Isca no nível máximo', buttonLabel: null }));
  }

  if (!state.autoFish.unlocked) {
    eqBox.appendChild(rowCard({
      title: AUTO_FISH_UNLOCK.name,
      sub: `Requer rank ${AUTO_FISH_UNLOCK.rankReq} — ${costLabel(AUTO_FISH_UNLOCK.cost)}`,
      buttonLabel: 'Comprar',
      disabled: state.player.rank < AUTO_FISH_UNLOCK.rankReq || !canAfford(state, AUTO_FISH_UNLOCK.cost),
      onClick: () => { buyAutoFishUnlock(state); renderShopPanel(); renderStatBar(); saveNow(); },
    }));
  }
}

// ---- cosméticos (ateliê) ----
const SLOT_LABEL = { hat: 'Chapéu', outfit: 'Roupa', accessory: 'Acessório' };

function renderCosmeticsPanel() {
  document.getElementById('cosmetics-venue-name').textContent = currentVenue ? currentVenue.name : 'Cosméticos';

  const box = document.getElementById('cosmetics-slots');
  box.innerHTML = '';
  for (const slot of ['hat', 'outfit', 'accessory']) {
    const title = document.createElement('div');
    title.className = 'section-title';
    title.textContent = SLOT_LABEL[slot];
    box.appendChild(title);

    for (const item of cosmeticsBySlot(slot)) {
      const owned = state.cosmetics.owned.includes(item.id);
      const equipped = state.cosmetics.equipped[slot] === item.id;
      box.appendChild(rowCard({
        title: item.name,
        sub: owned ? null : `Requer rank ${item.rankReq} — ${costLabel(item.cost)}`,
        buttonLabel: equipped ? 'Equipado' : owned ? 'Equipar' : 'Comprar',
        disabled: equipped || (!owned && (state.player.rank < item.rankReq || !canAfford(state, item.cost))),
        equipped,
        onClick: () => {
          // Comprar já equipa: dois cliques pra ver o item no boneco era chato.
          if (owned) equipCosmetic(state, item.id);
          else if (buyCosmetic(state, item.id).ok) equipCosmetic(state, item.id);
          renderCosmeticsPanel();
          renderStatBar();
          saveNow();
        },
      }));
    }
  }
}

// ---------- offline earnings modal ----------
function showOfflineModal() {
  if (!offlineSummary) return;
  const hours = offlineSummary.elapsedMs / 3600000;
  const parts = [
    `O assistente de pesca trabalhou por ${hours.toFixed(1)}h.`,
    `Pescou ${offlineSummary.catches} peixe(s) (${offlineSummary.rareCatches} raro(s)).`,
    `Ganhou ${offlineSummary.xp} de XP.`,
  ];
  if (offlineSummary.escamas > 0) parts.push(`+${offlineSummary.escamas} escamas.`);
  document.getElementById('offline-summary').textContent = parts.join(' ');
  document.getElementById('offline-modal').classList.remove('hidden');
  renderStatBar();
}
document.getElementById('btn-offline-close').addEventListener('click', () => {
  document.getElementById('offline-modal').classList.add('hidden');
});

// ---------- save ----------
function saveNow() {
  state.lastSeen = Date.now();
  persist(state);
}
window.addEventListener('beforeunload', () => {
  state.lastSeen = Date.now();
  persistSync(state); // assíncrono aqui não completa antes da janela morrer
});
// Esconder pra bandeja não dispara beforeunload; salvar aqui evita perder o
// que foi pescado desde o último autosave.
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'hidden') saveNow();
});
startAutosave(() => { state.lastSeen = Date.now(); return state; }, 20000);

// ---------- boot final ----------
renderStatBar();
updateActionUI(fishingSession.snapshot());
showOfflineModal();
requestAnimationFrame((ts) => { lastTs = ts; lastWallMs = Date.now(); loop(ts); });
