// scene.js — desenha só o que é "o mundo mesmo": a água, a jangada, o
// personagem e o NPC vendedor. O céu foi removido de propósito — o topo do
// canvas fica transparente e quem aparece atrás é a própria área de trabalho.
// O ciclo dia/noite continua vivo, agora tingindo a água (e a luz do casal).

import { drawChibi, drawBobber } from './pixelSprites.js';
import { COSMETICS } from '../data/cosmetics.js';
import { LOCATIONS } from '../data/locations.js';

const CANVAS_W = 308;
const CANVAS_H = 240;
const CHAR_SCALE = 7;
const WATER_Y = Math.round(CANVAS_H * 0.62); // linha d'água

function nightFactor(date = new Date()) {
  const h = date.getHours() + date.getMinutes() / 60;
  return (Math.cos((h / 24) * Math.PI * 2) + 1) / 2; // 0 = meio-dia, 1 = meia-noite
}

function lerpColor(hexA, hexB, t) {
  const a = hexToRgb(hexA);
  const b = hexToRgb(hexB);
  const r = Math.round(a.r + (b.r - a.r) * t);
  const g = Math.round(a.g + (b.g - a.g) * t);
  const bl = Math.round(a.b + (b.b - a.b) * t);
  return `rgb(${r},${g},${bl})`;
}

function hexToRgb(hex) {
  const clean = String(hex).replace('#', '');
  const bigint = parseInt(clean, 16);
  return { r: (bigint >> 16) & 255, g: (bigint >> 8) & 255, b: bigint & 255 };
}

function equippedColors(state) {
  const eq = state.cosmetics.equipped;
  const hat = COSMETICS[eq.hat];
  const outfit = COSMETICS[eq.outfit];
  const acc = COSMETICS[eq.accessory];
  return {
    hat: hat ? hat.color : null,
    outfit: outfit ? outfit.color : '#c97b52',
    accessory: acc ? acc.color : null,
  };
}

export function renderScene(ctx, state, runtime) {
  const loc = LOCATIONS[state.locationId] || LOCATIONS.ancoradouro;
  const night = nightFactor(new Date());
  const t = performance.now() / 1000;

  ctx.clearRect(0, 0, CANVAS_W, CANVAS_H); // topo continua transparente
  ctx.imageSmoothingEnabled = false;

  // água — a borda de cima ganha um degradê curto pra não virar um corte seco
  // contra a área de trabalho.
  const waterTop = lerpColor(loc.water, '#02040a', night * 0.55);
  const waterBottom = lerpColor('#05141a', '#01030a', night * 0.4);
  const waterGrad = ctx.createLinearGradient(0, WATER_Y, 0, CANVAS_H);
  waterGrad.addColorStop(0, waterTop);
  waterGrad.addColorStop(1, waterBottom);
  ctx.fillStyle = waterGrad;
  ctx.fillRect(0, WATER_Y, CANVAS_W, CANVAS_H - WATER_Y);

  // ondulações simples
  ctx.strokeStyle = `rgba(255,255,255,${0.08 + 0.04 * Math.sin(t)})`;
  ctx.lineWidth = 1;
  for (let i = 0; i < 3; i++) {
    const ly = WATER_Y + 16 + i * 18 + Math.sin(t * 0.8 + i) * 2;
    ctx.beginPath();
    ctx.moveTo(0, ly);
    for (let x = 0; x <= CANVAS_W; x += 12) {
      ctx.lineTo(x, ly + Math.sin(t * 1.4 + x * 0.08 + i) * 2.5);
    }
    ctx.stroke();
  }

  // jangada/doca
  const raftY = WATER_Y - 6;
  ctx.fillStyle = '#6b4a2f';
  ctx.fillRect(CANVAS_W * 0.12, raftY, CANVAS_W * 0.76, 12);
  ctx.fillStyle = '#4a331f';
  for (let i = 0; i < 8; i++) {
    ctx.fillRect(CANVAS_W * 0.12 + i * (CANVAS_W * 0.76) / 8, raftY, 2, 12);
  }

  // O vendedor não fica mais na jangada: agora ele atende no estabelecimento
  // dele (ver `venues` em data/locations.js), que se visita pelo Mapa.
  // A jangada é só da personagem.

  // personagem principal
  const colors = equippedColors(state);
  const phase = runtime.fishingPhase || 'idle';
  const charBob = phase === 'reeling'
    ? Math.sin(t * 9) * 2
    : Math.sin(t * 1.4) * 1.6;
  const charX = CANVAS_W * 0.18;
  const charY = raftY - 128;

  drawChibi(ctx, {
    x: charX, y: charY, scale: CHAR_SCALE,
    skin: '#f2d5ab',
    hair: '#3a2718',
    outfit: colors.outfit,
    boot: '#2a1c10',
    accessory: colors.accessory,
    hat: colors.hat,
    bobOffset: charBob,
  });

  // vara + bobber, só quando não está ociosa
  if (phase !== 'idle') {
    const rodTipX = charX + CHAR_SCALE * 15;
    const rodTipY = charY + CHAR_SCALE * 10;
    const bobberX = Math.min(CANVAS_W - 24, rodTipX + 46);
    const bobberY = WATER_Y + 10;
    ctx.strokeStyle = '#c9a35a';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(rodTipX, rodTipY);
    ctx.lineTo(bobberX, bobberY);
    ctx.stroke();
    const bobberBob = phase === 'waiting' ? Math.sin(t * 6) * 2 : Math.sin(t * 2) * 1.5;
    drawBobber(ctx, bobberX, bobberY, bobberBob);
  }

  // brilho quente à noite, saindo da lamparina imaginária da jangada
  if (night > 0.35) {
    const glow = ctx.createRadialGradient(charX + 30, raftY - 10, 4, charX + 30, raftY - 10, 90);
    glow.addColorStop(0, `rgba(255, 196, 110, ${0.16 * night})`);
    glow.addColorStop(1, 'rgba(255, 196, 110, 0)');
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, CANVAS_W, CANVAS_H);
  }
}

export { CANVAS_W, CANVAS_H };
