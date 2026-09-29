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
- ferramentas que evoluem de trabalho manual para eficiencia
- repeticao que futuramente pode ser automatizada

O objetivo nao e clonar Stardew Valley. Slimes serao o diferencial principal do projeto, entrando depois que o loop basico de fazenda estiver forte.

## Primeira fundacao jogavel

A branch atual implementa:

- movimento 8 direcoes com aceleracao e desaceleracao
- direcao/facing cardinal
- preview permanente do tile atingido pela ferramenta
- movimento permitido enquanto a ferramenta carrega
- entrada separada para ferramenta e interacao
- relogio: 06:00 ate 02:00
- 10 minutos de jogo a cada 7 segundos reais
- energia inicial de 270
- enxada
- regador
- carga por estagios em intervalos de 0,45 s
- padroes 1 tile, 3x1, 5x1, 3x3, 3x5 e 5x5 preparados
- solo normal, arado e molhado
- plantio de cultura de teste
- crescimento na virada do dia somente quando regada
- colheita
- cama/sono para avancar o dia
- HUD de tempo, energia, ferramenta e carga

## Controles do prototipo

- WASD ou setas: mover
- 1: Enxada
- 2: Regador
- Clique esquerdo ou ESPACO: segurar para carregar, soltar para usar
- E ou clique direito: interagir / plantar / colher / dormir

## Observacao de prototipo

Na cena de teste, enxada e regador estao temporariamente configurados no nivel 2 para permitir testar imediatamente a mecanica de carga. No jogo final, ferramentas iniciais comecarao no nivel 0 e atingirao apenas 1 tile ate receberem upgrades.

A semente da cultura inicial tambem e infinita por enquanto; inventario, sementes consumiveis e economia entram em marcos posteriores.
