# Maré 🎣

Um widget de pesca cozy pra área de trabalho — fica ancorado num canto da tela,
sempre por cima das outras janelas, e você vai lá de vez em quando pra pescar,
subir de rank, desbloquear locais novos e trocar o visual do seu personagem.

Inspirado na "alma" de jogos mobile de pesca-clicker idle (tipo *A Girl Adrift*):
clicar/puxar pra pescar, evolução de personagem, cosméticos, loja com NPC,
auto-fish com ganhos offline. **Toda a arte é original**, gerada por código
(pixel art bem simples desenhada em `<canvas>`) — nada foi copiado do jogo de
referência, só a ideia geral da mecânica.

## Rodando

```bash
npm install
npm start
```

Isso abre a janelinha (340×540) já ancorada no canto inferior direito da tela.

Clique com o botão direito no ícone da bandeja (tray) pra:
- Mostrar/ocultar a janela
- Ativar "clique-atravessa" (a janela para de capturar o mouse, então você
  consegue clicar em coisas *atrás* dela sem precisar fechá-la)
- Mover pra outro canto da tela
- Sair de verdade

Você também pode arrastar a janela livremente pela barra de cima (funciona
mesmo sem moldura, via `-webkit-app-region: drag`).

## Empacotando um instalador

```bash
npm run dist:win     # gera instalador .exe (NSIS)
npm run dist:mac     # gera .dmg
npm run dist:linux   # gera AppImage
```

(Isso baixa o binário do Electron pra sua plataforma na primeira vez — precisa
de internet.)

## Estrutura

```
main.js              janela transparente/sempre-no-topo, bandeja, salvar/carregar em disco
preload.js            ponte segura (contextBridge) entre a UI e o processo principal
index.html / style.css  casca da UI (barra superior, canvas do jogo, painéis)
src/
  state.js            formato do save + valores padrão
  data/                "planilhas" de conteúdo (só dados, sem lógica)
    fish.js            peixes por localização, raridade, valor, xp
    locations.js        mapa: locais, NPC vendedor, custo de desbloqueio
    cosmetics.js        chapéus/roupas/acessórios equipáveis
    equipment.js         varas, iscas, o "assistente de pesca" (auto-fish)
    events.js            eventos aleatórios temporários (bônus passageiros)
  systems/             lógica de jogo pura (funções que recebem/alteram o state)
    fishing.js          máquina de estados: lançar → esperar → puxar → pegar/fugir
    economy.js           moeda, xp, subida de rank
    shop.js               vender peixe, comprar vara/isca/auto-fish
    cosmetics.js          comprar/equipar cosméticos
    map.js                 desbloquear/viajar entre locais
    eventsEngine.js       sorteia e expira eventos
    autoFish.js            pescaria automática (online, quando ligada)
    offline.js              calcula o que o auto-fish "teria pescado" enquanto o app estava fechado
    save.js                  salvar/carregar (fala com preload.js, ou localStorage se rodar fora do Electron)
    effects.js                leitura central dos efeitos do evento ativo (raridade, xp, valor, espera)
  render/               tudo que desenha na tela
    pixelSprites.js       personagem chibi em blocos + ícone de peixe (vetorial)
    scene.js               céu com ciclo dia/noite real, água, jangada, personagem, NPC
  renderer.js            entrypoint: junta os sistemas, o game loop e a UI
```

## Como estender

Sempre que possível, adicionar conteúdo é só **editar um arquivo em `src/data/`**
— a lógica em `src/systems/` já sabe ler qualquer entrada nova automaticamente.

- **Novo peixe**: adicione uma entrada em `src/data/fish.js` com `location`
  apontando pra um dos ids em `locations.js`.
- **Novo local**: adicione em `src/data/locations.js` (defina `unlockRank`,
  `unlockCost`, paleta de céu/água e o NPC vendedor) e crie peixes pra ele em
  `fish.js`.
- **Novo cosmético**: adicione em `src/data/cosmetics.js` no slot certo
  (`hat`, `outfit`, `accessory`). A cor já é usada automaticamente pelo
  personagem em `render/scene.js`.
- **Novo evento**: adicione em `src/data/events.js`. Efeitos suportados hoje:
  `rareBonusPct`, `biteWaitMultiplier`, `valueMultiplier`, `xpMultiplier` — pra
  suportar um efeito novo, é só ler esse campo em `systems/fishing.js` ou
  `autoFish.js`.

## O que já funciona (v0.1)

- Pesca manual (lançar → esperar fisgada → cabo de guerra pra puxar)
- Rank/XP com subida em cascata
- Duas moedas: conchas (comum) e escamas (rara)
- Loja com venda de peixe + upgrades de vara/isca, NPC muda por local
- Cosméticos (chapéu/roupa/acessório) equipáveis, refletidos no personagem
- Mapa com 3 locais desbloqueáveis, cada um com peixes/NPC próprios
- Auto-fish (compra na loja) + cálculo de ganhos offline ao reabrir o app
- Eventos aleatórios temporários com bônus
- Ciclo dia/noite real (baseado no relógio do sistema) no cenário
- Save automático a cada 20s + ao fechar

## Ideias pra depois

- Sons (clique da isca, splash, sino de venda)
- Mais locais/peixes/cosméticos (o sistema já suporta, é só adicionar dados)
- Animação de "pose" por cosmético (hoje o cosmético só troca cor de um bloco)
- Conquistas / diário de peixes catalogados
- Diálogos do NPC vendedor mudando por afinidade (as falas em `locations.js`
  já existem, só falta uma UI de "balãozinho" pra mostrá-las de vez em quando)
