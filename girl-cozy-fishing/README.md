# Maré 🎣 — versão Godot

Porte do widget Electron (que fica na raiz deste repositório) para **Godot 4.7**.
Mesma janelinha ancorada num canto da tela, sempre por cima das outras, com o
céu transparente deixando a área de trabalho aparecer atrás da personagem.

Toda a arte continua sendo original e gerada por código — não há um único
arquivo de imagem: a personagem, a água e os ícones de peixe são desenhados em
`_draw()`.

## Rodando

A janela é uma faixa deitada de 460x230, ancorada no canto inferior direito.

Abra a pasta `girl-cozy-fishing/` no Godot 4.7 e dê play, ou pela linha de
comando:

```bash
godot --path girl-cozy-fishing
```

Interação:

- **Arrastar** a janela: clique e arraste em qualquer ponto da cena (a parte de
  cima, transparente, também funciona).
- **Botão direito** na cena abre o menu: clique-atravessa, mover para um canto
  da tela e sair.
- **Esc** fecha o painel aberto. Dentro de uma loja ou ateliê ele volta pro
  mapa (mesmo caminho do botão "fechar"), então dá pra sair de tudo só com Esc
  repetido.
- O botão de ação **cancela o lançamento** enquanto a isca está indo ou
  esperando: a linha é recolhida e você volta pro início. Quando um peixe
  escapa, a linha é recolhida do mesmo jeito, em vez de o anzol sumir.
- **`ajustes`** abre as configurações; **`–`** minimiza. Diferente do Electron,
  aqui a janela volta pela barra de tarefas — o Godot não expõe ícone de
  bandeja (veja *Diferenças* abaixo).

## Configurações

| | |
|---|---|
| Volume de efeitos | lançar, fisgar, vender |
| Volume de música | a ambiência de mar |
| Escala do quadro | 75%%, 100%%, 125%% ou 150%% |
| Ancorar no lugar | trava a janela: ela para de ser arrastada |

Tudo fica guardado no mesmo save, junto da posição da janela — reabrir devolve
o widget exatamente onde ele estava.

**O som é sintetizado em código**, igual à arte: não há arquivo de áudio no
projeto. Os efeitos são ondas curtas geradas na inicialização e a "música" é
uma ambiência de mar (ruído filtrado com uma maré lenta modulando por cima).
Cada slider mexe no seu barramento (`Efeitos` e `Musica`).

## O mundo

O **Ancoradouro** é a casa: é lá que fica a Oficina e é de lá que se sai pra
tudo. Cada continente tem um ponto, com peixário próprio e de verdade:

| Continente | Lugar | O que mora lá |
|---|---|---|
| Casa | Ancoradouro, Enseada dos Corais, Mar Aberto | lambari, robalo, corais, atum, o lendário da fossa |
| América do Sul | Rio Amazonas | tucunaré, piranha, tambaqui, pirarucu |
| América do Norte | Grandes Lagos | achigã, truta-arco-íris, lúcio, salmão-real |
| Europa | Fiordes da Noruega | arenque, bacalhau, salmão, halibute-gigante |
| África | Rio Nilo | tilápia, bagre-elétrico, perca-do-nilo, peixe-tigre |
| Ásia | Rio Mekong | peixe-arqueiro, carpa, bagre-gigante, koi ancestral |
| Oceania | Grande Barreira | peixe-palhaço, papagaio, barramundi, garoupa-batata |
| Antártida | Mar de Weddell | krill, bacalhau-antártico, peixe-de-gelo, lula-colossal |

**Viajar leva tempo.** Quanto mais longe, mais o barco demora — o tempo aparece
no próprio botão (`Zarpar (1min 24s)`), e em alto-mar não dá pra pescar. A
viagem é guardada com o horário de chegada, não com um contador: ela continua
correndo com o jogo fechado, então não dá pra ganhar tempo saindo do jogo.

## Tralha e a Oficina

Em qualquer água pode vir **tralha** no anzol: bota velha, lata amassada, meia
solitária, pneu, guarda-chuva torto, celular encharcado (com 41 notificações),
pato de borracha, dentadura, e — raramente — um carrinho de supermercado.

Vendida ela não vale quase nada. O valor dela é na **Oficina do Cais**, em casa:
desmonta tudo em **sucata**, e sucata paga melhoria permanente.

| Melhoria | O que faz |
|---|---|
| Molinete Reforçado | a barra da puxada cai mais devagar |
| Balde Isotérmico | peixe vale mais na venda |
| Casco Polido | viagens bem mais curtas |
| Amuleto de Escamas | mais chance de coisa rara morder |
| Rádio de Bordo | o assistente tenta com mais frequência |

## Capturando a tela

Pra conferir layout e cor sem ficar abrindo o jogo na mão:

```bash
godot --path girl-cozy-fishing tests/screenshot.tscn
godot --path girl-cozy-fishing tests/screenshot.tscn -- --panel=map
godot --path girl-cozy-fishing tests/screenshot.tscn -- --cast      # linha na água
godot --path girl-cozy-fishing tests/screenshot.tscn -- --retrieve  # recolhendo
godot --path girl-cozy-fishing tests/screenshot.tscn -- --esc       # confere o atalho
```

Salva um PNG (com o fundo transparente, como o widget é de verdade) em
`user://shot.png`. Precisa de janela — não roda em `--headless`.

## Teste de fumaça

Roda as regras do jogo sem abrir janela nenhuma e imprime o resultado:

```bash
godot --headless --path girl-cozy-fishing tests/smoke_test.tscn
```

Cobre o ciclo de pesca, o multiplicador de valor dos eventos, save corrompido,
o assistente automático, ganhos offline, compras sem saldo, o desbloqueio de
estabelecimentos e uma ida e volta real no arquivo de save (que é preservado:
rodar o teste não custa o progresso de ninguém).

## Estrutura

```
project.godot          janela sem moldura/transparente/sempre-no-topo + autoloads
main.tscn              cena raiz: um Control vazio; a interface é montada por código
scripts/
  data/                 "planilhas" de conteúdo (só dados, sem lógica)
    fish_data.gd         peixes por localização, raridade, valor, xp
    locations_data.gd     mapa: locais, NPC vendedor e os `venues` de cada um
    cosmetics_data.gd     chapéus/roupas/acessórios equipáveis
    equipment_data.gd     varas, iscas, o "assistente de pesca"
    events_data.gd        eventos aleatórios temporários
    upgrades_data.gd      as melhorias da Oficina
  systems/              lógica pura (funções estáticas que recebem/alteram o estado)
    state_format.gd      formato do save: defaults e a validação da leitura
    game_state.gd        autoload: a partida em andamento
    audio.gd              autoload: efeitos e ambiência sintetizados em código
    save_system.gd        autoload: grava/lê user://mare-save.json com troca segura
    effects.gd             leitura central dos efeitos do evento ativo
    economy.gd             moeda, xp, subida de rank
    fishing_session.gd     máquina de estados: lançar → esperar → puxar → pegar/fugir
                           (+ cancelar e recolher a linha)
    shop_system.gd         vender peixe, comprar vara/isca/assistente
    cosmetics_system.gd    comprar/equipar cosméticos
    map_system.gd          viagem com tempo e abertura de estabelecimentos
    workshop.gd            desmonta tralha em sucata e aplica os bônus das melhorias
    events_engine.gd       sorteia e expira eventos
    auto_fish.gd           pescaria automática (conta pelo relógio de parede)
    offline_earnings.gd    o que o assistente rendeu com o jogo fechado
  render/
    pixel_sprites.gd       personagem em blocos (com contorno) + ícones
    scene_view.gd          água, doca, personagem, ilha, ciclo dia/noite
    fish_icon.gd            Control que desenha um peixe (usado no Bolso)
    coin_icon.gd            Control que desenha concha/escama
  ui/
    ui_kit.gd              paleta, fontes e as peças de interface (o antigo CSS)
    main.gd                monta a tela, roda o game loop e liga tudo
tests/
  smoke_test.gd          checagem das regras, sem janela
  screenshot.gd           captura a interface num PNG
```

## Como estender

Igual à versão web: adicionar conteúdo é **editar um arquivo em `scripts/data/`**.

- Peixe novo → uma entrada em `FishData.FISH` com o `location` de onde ele vive.
- Tralha nova → mesma coisa, com `kind: "lixo"`, `scrap` e `location: "*"`
  (asterisco = aparece em qualquer água).
- Lugar novo → uma entrada em `LocationsData.LOCATIONS`, com `continent` e
  `distance` (a régua que define o tempo de viagem).
- Loja/ateliê/oficina novo → um item no array `venues` do local.
- Cosmético novo → uma entrada em `CosmeticsData.COSMETICS`.
- Melhoria nova → uma entrada em `UpgradesData.UPGRADES`.

Nada disso exige mexer em interface: as telas são geradas a partir dos dados.

## Diferenças em relação à versão Electron

| | Electron | Godot |
|---|---|---|
| Ícone de bandeja | sim, com menu | **não existe** — o menu virou botão direito na cena, e `–` minimiza |
| Fora da barra de tarefas | sim (`skipTaskbar`) | não — é ela que traz a janela de volta |
| Instância única | trava do Electron | não implementado (veja abaixo) |
| Save | `%APPDATA%/mare-cozy-fishing` | `user://` (`%APPDATA%/Godot/app_userdata/…`) |

O formato do save é o mesmo dos dois lados (mesmas chaves, mesmos ids), então um
progresso feito no widget Electron pode ser copiado pra cá e continua valendo.

**Instância única:** o Godot não tem uma trava pronta como a do Electron. Duas
cópias abertas ao mesmo tempo escrevem no mesmo arquivo e uma sobrescreve a
outra. A gravação em etapas (`.tmp` → `.bak` → definitivo) evita save corrompido,
mas não evita perder progresso nesse caso — então, por ora, abra um de cada vez.

## O que veio junto do porte

As correções feitas na versão Electron vieram todas para cá, não só o visual:

- Save validado na leitura (`sanitize_state`): id inexistente, número quebrado,
  moeda negativa ou cosmético no slot errado não entram no jogo.
- `xpToNext` zerado num save adulterado não trava mais a subida de rank em laço
  infinito.
- Gravação em etapas, com backup, em vez de escrever por cima do save.
- O evento "brisa da sorte" (multiplicador de valor) passou a ser aplicado de
  fato na venda — antes era calculado e descartado.
- O assistente de pesca conta pelo relógio de parede, então não para quando a
  janela é minimizada.
- A cena respeita a proporção original em vez de ser esticada.

## Direção de arte

O widget mora por cima de um papel de parede qualquer, e isso manda em tudo:

- **Faixa deitada, não telinha de celular.** 460x230 em vez de 340x450 — 31%%
  menos área e formato de canto de tela.
- **Uma barra de controle só.** Eram seis faixas empilhadas; o medidor de puxada
  virou o preenchimento do próprio botão de ação, o aviso de espera saiu (o
  botão já dizia), o assistente virou um botão que só aparece depois de comprado
  e o XP virou um fio na base da barra.
- **Contorno em tudo.** Cada bloco do sprite é desenhado duas vezes: escuro e
  inflado, depois colorido. É o que impede a personagem de sumir num fundo
  claro.
- **Um acento só.** Barra escura translúcida, texto creme e o coral reservado
  pro botão de ação. A carta bege grande de antes brigava com qualquer fundo.
- **Sem emoji.** As fontes pixel não têm esses glifos: apareciam como quadrados
  vazios.
