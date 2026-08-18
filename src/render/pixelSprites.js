// pixelSprites.js — desenha personagens "chibi" blocados num grid 16x20
// (cada "unidade" vira um quadrado de `scale` pixels — dá o look pixel art
// sem depender de nenhum arquivo de imagem externo).

export function drawChibi(ctx, opts) {
  const {
    x, y, scale = 8,
    skin = '#e8c9a0',
    hair = '#4a2e1a',
    outfit = '#c97b52',
    boot = '#3a2718',
    accessory = null,
    hat = null,
    bobOffset = 0,
    flip = false,
  } = opts;

  ctx.save();
  ctx.imageSmoothingEnabled = false;

  const px = (u) => x + (flip ? (16 - u) : u) * scale;
  const py = (u) => y + u * scale + bobOffset;
  const rect = (ux, uy, uw, uh, color) => {
    if (!color) return;
    const left = flip ? px(ux) - uw * scale : px(ux);
    ctx.fillStyle = color;
    ctx.fillRect(left, py(uy), uw * scale, uh * scale);
  };

  rect(4, 3, 8, 4, hair);         // massa de cabelo atrás da cabeça
  rect(5, 6, 6, 5, skin);         // rosto
  rect(4, 6, 1, 6, hair);         // mecha lateral esquerda
  rect(11, 6, 1, 6, hair);        // mecha lateral direita
  rect(6, 8, 1, 1, '#2b2018');    // olho esquerdo
  rect(9, 8, 1, 1, '#2b2018');    // olho direito
  rect(5, 11, 6, 7, outfit);      // torso/roupa
  rect(6, 17, 1, 2, boot);        // pé esquerdo
  rect(9, 17, 1, 2, boot);        // pé direito
  if (accessory) rect(4, 11, 8, 1, accessory); // faixa/echarpe na gola
  if (hat) rect(4, 1, 8, 2, hat); // chapéu

  ctx.restore();
}

// Ícone simples de peixe pra inventário/loja — não é do grid, é vetorial
// mesmo (fica pequeno demais pra valer a pena "pixelar").
export function drawFishIcon(ctx, palette, x, y, size) {
  const [light, mid, dark] = palette;
  ctx.save();
  ctx.translate(x, y);

  // corpo
  ctx.fillStyle = mid;
  ctx.beginPath();
  ctx.ellipse(size * 0.45, size * 0.5, size * 0.42, size * 0.28, 0, 0, Math.PI * 2);
  ctx.fill();

  // barriga clara
  ctx.fillStyle = light;
  ctx.beginPath();
  ctx.ellipse(size * 0.45, size * 0.62, size * 0.3, size * 0.14, 0, 0, Math.PI * 2);
  ctx.fill();

  // cauda
  ctx.fillStyle = dark;
  ctx.beginPath();
  ctx.moveTo(size * 0.06, size * 0.5);
  ctx.lineTo(-size * 0.12, size * 0.3);
  ctx.lineTo(-size * 0.12, size * 0.7);
  ctx.closePath();
  ctx.fill();

  // olho
  ctx.fillStyle = '#20180f';
  ctx.beginPath();
  ctx.arc(size * 0.78, size * 0.46, size * 0.045, 0, Math.PI * 2);
  ctx.fill();

  ctx.restore();
}

export function drawBobber(ctx, x, y, bob = 0) {
  ctx.save();
  ctx.fillStyle = '#e8734a';
  ctx.beginPath();
  ctx.arc(x, y + bob, 5, 0, Math.PI * 2);
  ctx.fill();
  ctx.fillStyle = '#f2e9e4';
  ctx.beginPath();
  ctx.arc(x, y + bob - 3, 3, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();
}
