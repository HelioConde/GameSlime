# Slime Land Farm

Jogo 2D top-down de fazenda desenvolvido em Godot 4 com GDScript.

## Identidade

O núcleo combina fazenda, progressão de base e slimes trabalhadoras semi-autônomas. A base é o centro da progressão e as slimes podem trabalhar automaticamente ou receber comandos diretos do jogador.

A reconstrução atual segue a direção mais nova do projeto: arquitetura modular, automação de base e comando direto sem transformar o jogo em action RPG.

## Estado atual

A branch `feat/rebuild-core` contém a primeira fundação executável:

- BaseCore com raio de trabalho e limite de slimes
- StorageNetwork compartilhado por base
- SlimeWorker com energia, movimento e comandos
- modos AUTO, FOLLOW, WAIT, MOVE_TO, FORCE_TASK, ASSIGNED_ZONE e REST
- TaskManager com Chop, Mine, Harvest, Plant, Haul e Build
- seleção de slime pelo mouse
- criação de tarefas pelo jogador
- HUD de debug
- cena de demonstração sem dependência de assets externos

## Controles

- WASD / Setas: mover
- Clique esquerdo: selecionar slime
- G: AUTO
- F: FOLLOW
- H: WAIT
- R: REST
- M: MOVE_TO ate o mouse
- T: forcar a melhor tarefa disponivel
- 1: criar CHOP
- 2: criar MINE
- 3: criar HARVEST
- 4: criar PLANT
- 5: criar HAUL
- 6: criar BUILD
- Esc: limpar selecao

## Proximo marco

Transformar as tarefas abstratas em acoes reais no mundo: recursos de arvore/pedra, drops, carrying/hauling ate o storage e depois o primeiro ciclo completo de agricultura.

Veja `docs/ROADMAP.md`.
