// save.js — fininho de propósito: só conversa com a ponte exposta pelo
// preload.js. Se rodar fora do Electron (ex: abrindo o index.html direto
// no navegador pra testar), cai num fallback de localStorage.

const LOCAL_KEY = 'mare-save-fallback';

export async function loadSave() {
  try {
    if (window.mareApi) {
      const res = await window.mareApi.loadState();
      return res && res.ok ? res.data : null;
    }
    const raw = localStorage.getItem(LOCAL_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch (err) {
    // Save ilegível não pode impedir o jogo de abrir — começa do zero.
    console.warn('[mare] falha ao carregar o save:', err);
    return null;
  }
}

export async function persist(state) {
  try {
    if (window.mareApi) {
      await window.mareApi.saveState(state);
      return;
    }
    localStorage.setItem(LOCAL_KEY, JSON.stringify(state));
  } catch (err) {
    console.warn('[mare] falha ao salvar:', err);
  }
}

// Usado no beforeunload: um `invoke` assíncrono não chega a completar antes
// da janela fechar, e o progresso desde o último autosave se perdia.
export function persistSync(state) {
  try {
    if (window.mareApi && window.mareApi.saveStateSync) {
      window.mareApi.saveStateSync(state);
      return;
    }
    localStorage.setItem(LOCAL_KEY, JSON.stringify(state));
  } catch (err) {
    console.warn('[mare] falha ao salvar (sync):', err);
  }
}

export function startAutosave(getState, intervalMs = 20000) {
  return setInterval(() => { persist(getState()); }, intervalMs);
}
