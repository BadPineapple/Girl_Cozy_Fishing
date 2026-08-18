// main.js — processo principal do Electron
// Cria a janelinha "widget" sem moldura, transparente, sempre no topo,
// cuida da bandeja (tray), do modo "click-through" e do save/load em disco.

const { app, BrowserWindow, Tray, Menu, screen, ipcMain, shell, nativeImage } = require('electron');
const path = require('path');
const fs = require('fs');

const WINDOW_W = 340;
const WINDOW_H = 540;
const SAVE_FILE = path.join(app.getPath('userData'), 'mare-save.json');
const SAVE_TMP = SAVE_FILE + '.tmp';
const MAX_SAVE_BYTES = 2 * 1024 * 1024; // save legítimo tem alguns KB; acima disso é lixo/corrupção

let mainWindow = null;
let tray = null;
let clickThrough = false;
let currentCorner = 'bottom-right';
let quitting = false;

// Duas instâncias apontando pro mesmo arquivo de save se sobrescrevem e o
// progresso de uma some. A segunda só traz a primeira pra frente.
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
} else {
  app.on('second-instance', () => {
    if (mainWindow) {
      mainWindow.show();
      mainWindow.focus();
    }
  });
}

function cornerPosition(corner, workArea) {
  const margin = 16;
  const positions = {
    'bottom-right': { x: workArea.x + workArea.width - WINDOW_W - margin, y: workArea.y + workArea.height - WINDOW_H - margin },
    'bottom-left': { x: workArea.x + margin, y: workArea.y + workArea.height - WINDOW_H - margin },
    'top-right': { x: workArea.x + workArea.width - WINDOW_W - margin, y: workArea.y + margin },
    'top-left': { x: workArea.x + margin, y: workArea.y + margin },
  };
  return positions[corner] || positions['bottom-right'];
}

function moveToCorner(corner) {
  if (!mainWindow) return;
  currentCorner = corner;
  const { workArea } = screen.getPrimaryDisplay();
  const { x, y } = cornerPosition(corner, workArea);
  mainWindow.setPosition(Math.round(x), Math.round(y));
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: WINDOW_W,
    height: WINDOW_H,
    frame: false,
    transparent: true,
    resizable: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    hasShadow: false,
    backgroundColor: '#00000000',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true,
      webviewTag: false,
      backgroundThrottling: false, // continua "pescando" mesmo minimizado/sem foco
    },
  });

  mainWindow.setAlwaysOnTop(true, 'screen-saver');
  mainWindow.setVisibleOnAllWorkspaces(true, { visibleOnFullScreen: true });
  mainWindow.loadFile('index.html');
  moveToCorner(currentCorner);

  // O jogo é 100% local: nada aqui deve abrir janela nova nem navegar pra fora.
  // Se um dia entrar um link, ele vai pro navegador do sistema em vez de virar
  // uma janela Electron sem as travas de segurança.
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (/^https?:\/\//i.test(url)) shell.openExternal(url);
    return { action: 'deny' };
  });
  mainWindow.webContents.on('will-navigate', (event, url) => {
    if (url !== mainWindow.webContents.getURL()) event.preventDefault();
  });

  // Fechar (Alt+F4) só esconde: o app vive na bandeja. Assim o assistente de
  // pesca continua e o botão da bandeja volta a funcionar.
  mainWindow.on('close', (event) => {
    if (quitting) return;
    event.preventDefault();
    mainWindow.hide();
  });
  mainWindow.on('closed', () => { mainWindow = null; });
}

function ensureWindow() {
  if (!mainWindow || mainWindow.isDestroyed()) createWindow();
  return mainWindow;
}

function toggleWindow() {
  const win = ensureWindow();
  if (!win) return;
  if (win.isVisible()) win.hide();
  else { win.show(); win.focus(); }
}

function setClickThrough(enabled) {
  clickThrough = !!enabled;
  if (mainWindow && !mainWindow.isDestroyed()) {
    // forward:true deixa o mouse "vazar" pra janela de baixo, mas ainda
    // recebe eventos de mousemove pra podermos religar quando quisermos.
    mainWindow.setIgnoreMouseEvents(clickThrough, { forward: true });
  }
  if (tray) buildTrayMenu();
}

function buildTrayMenu() {
  const cornerLabel = {
    'bottom-right': 'Inferior direito',
    'bottom-left': 'Inferior esquerdo',
    'top-right': 'Superior direito',
    'top-left': 'Superior esquerdo',
  };
  const contextMenu = Menu.buildFromTemplate([
    { label: 'Maré — pesca cozy', enabled: false },
    { type: 'separator' },
    { label: 'Mostrar/Ocultar', click: toggleWindow },
    {
      label: clickThrough ? 'Desativar clique-atravessa' : 'Ativar clique-atravessa (não atrapalha o mouse)',
      click: () => setClickThrough(!clickThrough),
    },
    {
      label: 'Mover para canto',
      submenu: Object.keys(cornerLabel).map((corner) => ({
        label: cornerLabel[corner],
        type: 'radio',
        checked: corner === currentCorner,
        click: () => moveToCorner(corner),
      })),
    },
    { type: 'separator' },
    { label: 'Sair', click: () => { quitting = true; app.quit(); } },
  ]);
  tray.setContextMenu(contextMenu);
}

function createTray() {
  let icon = nativeImage.createFromPath(path.join(__dirname, 'assets', 'tray-icon.png'));
  // Tray com imagem vazia quebra no Windows; um 1x1 transparente segura a onda
  // e o app continua acessível pela bandeja.
  if (icon.isEmpty()) {
    icon = nativeImage.createFromDataURL(
      'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='
    );
  }
  tray = new Tray(icon);
  tray.setToolTip('Maré — pesca cozy');
  buildTrayMenu();
  tray.on('click', toggleWindow);
}

// --- persistência ---
// Escrita atômica: grava num .tmp e só então renomeia. Um desligamento no meio
// de um writeFileSync direto deixava o save truncado (= progresso perdido).
function writeSave(data) {
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    return { ok: false, error: 'payload inválido' };
  }
  let json;
  try {
    json = JSON.stringify(data);
  } catch (err) {
    return { ok: false, error: String(err) };
  }
  if (!json || json.length > MAX_SAVE_BYTES) return { ok: false, error: 'save inválido ou grande demais' };
  try {
    fs.writeFileSync(SAVE_TMP, json, 'utf-8');
    fs.renameSync(SAVE_TMP, SAVE_FILE);
    return { ok: true };
  } catch (err) {
    try { if (fs.existsSync(SAVE_TMP)) fs.unlinkSync(SAVE_TMP); } catch (_) { /* ignora */ }
    return { ok: false, error: String(err) };
  }
}

function readSave() {
  try {
    if (!fs.existsSync(SAVE_FILE)) return { ok: true, data: null };
    if (fs.statSync(SAVE_FILE).size > MAX_SAVE_BYTES) return { ok: false, error: 'save grande demais' };
    const raw = fs.readFileSync(SAVE_FILE, 'utf-8');
    const data = JSON.parse(raw);
    if (!data || typeof data !== 'object' || Array.isArray(data)) throw new Error('formato inesperado');
    return { ok: true, data };
  } catch (err) {
    // Save ilegível: guarda uma cópia pro caso de dar pra recuperar à mão e
    // começa do zero em vez de travar o jogo na abertura.
    try { fs.renameSync(SAVE_FILE, SAVE_FILE + '.corrupt'); } catch (_) { /* ignora */ }
    return { ok: false, error: String(err) };
  }
}

ipcMain.handle('mare:save-state', async (_evt, data) => writeSave(data));
ipcMain.handle('mare:load-state', async () => readSave());

// Versão síncrona: usada no beforeunload, onde uma chamada assíncrona não
// chega a completar antes da janela morrer.
ipcMain.on('mare:save-state-sync', (evt, data) => {
  evt.returnValue = writeSave(data);
});

ipcMain.handle('mare:set-click-through', async (_evt, enabled) => {
  setClickThrough(enabled);
  return { ok: true, clickThrough };
});

ipcMain.handle('mare:hide-window', async () => {
  if (mainWindow && !mainWindow.isDestroyed()) mainWindow.hide();
  return { ok: true };
});

if (gotLock) {
  app.whenReady().then(() => {
    createWindow();
    createTray();

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) createWindow();
      else toggleWindow();
    });
  });
}

app.on('before-quit', () => { quitting = true; });

app.on('window-all-closed', () => {
  // No Windows/Linux o app continua vivo na bandeja mesmo sem janelas:
  // é o que mantém o auto-fish rodando. Pra sair de verdade, menu da bandeja.
});
