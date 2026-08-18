// scene.js — desenha o "mundo": céu (com ciclo dia/noite real, baseado no
// relógio do sistema), água, a jangada, o personagem e o NPC vendedor.

import { drawChibi, drawBobber } from './pixelSprites.js';
import { COSMETICS } from '../data/cosmetics.js';
import { LOCATIONS } from '../data/locations.js';

const CANVAS_W = 308;
const CANVAS_H = 300;
const CHAR_SCALE = 7;

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
  const clean = hex.replace('#', '');
  const bigint = parseInt(clean, 16);
  return { r: (bigint >> 16) & 255, g: (bigint >> 8) & 255, b: bigint & 255 };
}

let starSeeds = null;
function getStars() {
  if (starSeeds) return starSeeds;
  starSeeds = Array.from({ length: 22 }, () => ({
    x: Math.random() * CANVAS_W,
    y: Math.random() * (CANVAS_H * 0.55),
    r: Math.random() * 1.4 + 0.4,
    tw: Math.random() * Math.PI * 2,
  }));
  return starSeeds;
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
  const now = new Date();
  const night = nightFactor(now);
  const t = performance.now() / 1000;

  ctx.clearRect(0, 0, CANVAS_W, CANVAS_H);
  ctx.imageSmoothingEnabled = false;

  // céu
  const skyTop = lerpColor(loc.sky.top, '#05070f', night * 0.6);
  const skyBottom = lerpColor(loc.sky.bottom, '#141225', night * 0.75);
  const grad = ctx.createLinearGradient(0, 0, 0, CANVAS_H * 0.6);
  grad.addColorStop(0, skyTop);
  grad.addColorStop(1, skyBottom);
  ctx.fillStyle = grad;
  ctx.fillRect(0, 0, CANVAS_W, CANVAS_H * 0.62);

  // estrelas (só aparecem à noite)
  if (night > 0.25) {
    ctx.globalAlpha = (night - 0.25) * 1.2;
    for (const s of getStars()) {
      const tw = 0.5 + 0.5 * Math.sin(t * 1.5 + s.tw);
      ctx.fillStyle = `rgba(255,255,255,${0.4 + 0.6 * tw})`;
      ctx.beginPath();
      ctx.arc(s.x, s.y, s.r, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }

  // sol/lua
  const sunX = CANVAS_W * 0.78;
  const sunY = CANVAS_H * 0.14 + 8 * Math.sin(t * 0.2);
  ctx.fillStyle = night > 0.5 ? '#f2e9e4' : '#ffe9b0';
  ctx.globalAlpha = 0.9;
  ctx.beginPath();
  ctx.arc(sunX, sunY, night > 0.5 ? 9 : 12, 0, Math.PI * 2);
  ctx.fill();
  ctx.globalAlpha = 1;

  // água
  const waterY = CANVAS_H * 0.6;
  const waterGrad = ctx.createLinearGradient(0, waterY, 0, CANVAS_H);
  waterGrad.addColorStop(0, lerpColor(loc.water, '#02040a', night * 0.55));
  waterGrad.addColorStop(1, lerpColor('#05141a', '#01030a', night * 0.4));
  ctx.fillStyle = waterGrad;
  ctx.fillRect(0, waterY, CANVAS_W, CANVAS_H - waterY);

  // ondulações simples
  ctx.strokeStyle = `rgba(255,255,255,${0.08 + 0.04 * Math.sin(t)})`;
  ctx.lineWidth = 1;
  for (let i = 0; i < 4; i++) {
    const ly = waterY + 14 + i * 16 + Math.sin(t * 0.8 + i) * 2;
    ctx.beginPath();
    ctx.moveTo(0, ly);
    for (let x = 0; x <= CANVAS_W; x += 12) {
      ctx.lineTo(x, ly + Math.sin(t * 1.4 + x * 0.08 + i) * 2.5);
    }
    ctx.stroke();
  }

  // jangada/doca
  const raftY = waterY - 6;
  ctx.fillStyle = '#6b4a2f';
  ctx.fillRect(CANVAS_W * 0.12, raftY, CANVAS_W * 0.76, 12);
  ctx.fillStyle = '#4a331f';
  for (let i = 0; i < 8; i++) {
    ctx.fillRect(CANVAS_W * 0.12 + i * (CANVAS_W * 0.76) / 8, raftY, 2, 12);
  }

  // NPC vendedor, sentado do lado direito da jangada
  const vendorBob = Math.sin(t * 1.1) * 1.5;
  drawChibi(ctx, {
    x: CANVAS_W * 0.62, y: raftY - 118, scale: CHAR_SCALE * 0.82,
    skin: '#e3bd93',
    hair: loc.vendor.palette[1],
    outfit: loc.vendor.palette[0],
    boot: loc.vendor.palette[2],
    bobOffset: vendorBob,
  });

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
    const bobberY = waterY + 10;
    ctx.strokeStyle = '#c9a35a';
    ctx.lineWidth = 1.4;
    ctx.beginPath();
    ctx.moveTo(rodTipX, rodTipY);
    ctx.lineTo(bobberX, bobberY);
    ctx.stroke();
    const bobberBob = phase === 'waiting' ? Math.sin(t * 6) * 2 : Math.sin(t * 2) * 1.5;
    drawBobber(ctx, bobberX, bobberY, bobberBob);
  }
}

export { CANVAS_W, CANVAS_H };
