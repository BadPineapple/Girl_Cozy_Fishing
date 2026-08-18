// preload.js — ponte segura entre o processo principal e a UI (renderer).
// A UI nunca toca em `fs`/`ipcRenderer` diretamente; só usa `window.mareApi`.

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('mareApi', {
  saveState: (data) => ipcRenderer.invoke('mare:save-state', data),
  // Só pro beforeunload: o invoke assíncrono não termina antes da janela sumir.
  saveStateSync: (data) => ipcRenderer.sendSync('mare:save-state-sync', data),
  loadState: () => ipcRenderer.invoke('mare:load-state'),
  setClickThrough: (enabled) => ipcRenderer.invoke('mare:set-click-through', enabled),
  hideWindow: () => ipcRenderer.invoke('mare:hide-window'),
});
