# Slime Land Farm / GameSlime

Projeto 2D top-down desenvolvido para Godot Engine 4.7.x, com o desenvolvimento atual mirando Godot 4.7.2.

## Direcao de design

A base inicial do jogo segue os principios que fazem Stardew Valley funcionar bem:

- controle simples e preciso
- mundo em grade
- usar ferramenta separado de interagir
- dia com tempo limitado
- energia como limite de produtividade
- agricultura em etapas
- inventario limitado
- ferramentas que evoluem de trabalho manual para eficiencia
- repeticao que futuramente pode ser automatizada

O objetivo nao e clonar Stardew Valley. Slimes serao o diferencial principal do projeto, entrando depois que o loop basico de fazenda estiver forte.

## Estado jogavel atual

- movimento 8 direcoes com aceleracao/desaceleracao
- facing cardinal
- preview do tile/area da ferramenta
- movimento enquanto carrega ferramenta
- usar ferramenta separado de interagir
- relogio 06:00 -> 02:00
- 10 minutos de jogo a cada 7 segundos reais
- energia inicial 270
- sono e virada do dia
- grade agricola
- terra normal, arada e molhada
- plantio
- crescimento somente quando regado
- crescimento processado na virada do dia
- colheita
- enxada e regador carregaveis
- 0,45 s por estagio de carga
- areas preparadas de 1 tile ate 5x5
- inventario com 12 slots
- hotbar selecionavel
- sementes consumiveis
- colheita armazenada no inventario
- bloqueio de colheita com inventario cheio
- regador com reservatorio limitado
- consumo de agua por nivel de carga
- fonte de agua para reabastecimento
- HUD com hora, energia, item selecionado, agua e hotbar
- validacao automatica com Godot 4.7.2 no GitHub Actions

## Inventario inicial do prototipo

1. Enxada
2. Regador
3. 15 Sementes de Nabo
4-12. Vazios

A roda do mouse percorre os 12 slots. As teclas 1-0 acessam diretamente os dez primeiros.

## Controles

- WASD / setas: mover
- 1-0: selecionar hotbar
- roda do mouse: trocar slot
- clique esquerdo / ESPACO:
  - ferramenta: segurar para carregar e soltar para usar
  - semente: plantar
- E / clique direito:
  - colher
  - dormir perto da cama
  - encher regador perto da agua
  - consultar o tile quando nenhuma dessas acoes for possivel

## Prototipo de ferramenta

Enxada e regador estao temporariamente no nivel 2 para que seja possivel testar imediatamente 1 tile, 3x1 e 5x1.

No inicio real do jogo as ferramentas comecarao no nivel 0.

## Proximo marco

Machado + picareta + arvores + pedras + drops + coleta.

Depois disso entram calendario/estacoes/clima e, com o farming loop forte, os slimes passam a ser o sistema central que diferencia o jogo.
