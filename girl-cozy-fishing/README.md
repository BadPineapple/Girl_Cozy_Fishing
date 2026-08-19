# Maré 🎣 — versão Godot

Porte do widget Electron (que fica na raiz deste repositório) para **Godot 4.7**.
Mesma janelinha ancorada num canto da tela, sempre por cima das outras, com o
céu transparente deixando a área de trabalho aparecer atrás da personagem.

Toda a arte continua sendo original e gerada por código — não há um único
arquivo de imagem: a personagem, a água e os ícones de peixe são desenhados em
`_draw()`.

## Rodando

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
- **`–`** minimiza. Diferente do Electron, aqui a janela volta pela barra de
  tarefas — o Godot não expõe ícone de bandeja (veja *Diferenças* abaixo).

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
  systems/              lógica pura (funções estáticas que recebem/alteram o estado)
    game_state.gd        autoload: formato do save, defaults e a validação da leitura
    save_system.gd        autoload: grava/lê user://mare-save.json com troca segura
    effects.gd             leitura central dos efeitos do evento ativo
    economy.gd             moeda, xp, subida de rank
    fishing_session.gd     máquina de estados: lançar → esperar → puxar → pegar/fugir
    shop_system.gd         vender peixe, comprar vara/isca/assistente
    cosmetics_system.gd    comprar/equipar cosméticos
    map_system.gd          viajar entre locais e abrir estabelecimentos
    events_engine.gd       sorteia e expira eventos
    auto_fish.gd           pescaria automática (conta pelo relógio de parede)
    offline_earnings.gd    o que o assistente rendeu com o jogo fechado
  render/
    pixel_sprites.gd       personagem em blocos + ícone de peixe
    scene_view.gd          água, jangada, personagem, ciclo dia/noite
    fish_icon.gd            Control que desenha um peixe (usado no Bolso)
  ui/
    ui_kit.gd              paleta, fontes e as peças de interface (o antigo CSS)
    main.gd                monta a tela, roda o game loop e liga tudo
tests/
  smoke_test.gd          checagem das regras, sem janela
```

## Como estender

Igual à versão web: adicionar conteúdo é **editar um arquivo em `scripts/data/`**.

- Peixe novo → uma entrada em `FishData.FISH` com o `location` de onde ele vive.
- Lugar novo → uma entrada em `LocationsData.LOCATIONS`.
- Loja/ateliê novo → um item no array `venues` do local.
- Cosmético novo → uma entrada em `CosmeticsData.COSMETICS`.

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
