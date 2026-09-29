# Sprout Lands Asset Map

Fonte: Sprout Lands Premium Pack, por Cup Nooble.

Licenca completa: `assets/sprout_lands/LICENSE.txt`  
Creditos do projeto: `ASSET_CREDITS.md`

## Assets integrados

### Player

Arquivo:
`assets/sprout_lands/characters/player_premium.png`

Dimensoes:
- imagem: 384x1152
- grade usada: 8 colunas x 24 linhas
- frame: 48x48

Mapeamento inicial:
- linha 0: movimento/idle para baixo
- linha 1: movimento/idle para cima
- linha 2: movimento/idle para esquerda
- linha 3: movimento/idle para direita
- 8 frames por direcao
- frame 0 usado quando parado

As demais linhas contem acoes/ferramentas e serao mapeadas separadamente antes de serem usadas.

### Culturas

Arquivo:
`assets/sprout_lands/crops/farming_plants.png`

Dimensoes:
- imagem: 80x240
- grade: 5 colunas x 15 linhas
- tile: 16x16

Convencao no GameSlime:
- cada linha representa uma cultura visual
- as 5 colunas representam os estagios 0..4
- `CropDefinition.sprite_row` escolhe a linha

O cultivo inicial usa linha 0 durante a fase de prototipo.

### Agua

Arquivos:
- `water_1.png`
- `water_2.png`
- `water_3.png`
- `water_4.png`

Cada frame: 16x16.

O `WaterSource` percorre os quatro frames em loop.

## Assets extraidos e ainda nao mapeados

### Ferramentas
`assets/sprout_lands/tools/tools.png`
- 96x96

### Efeito do regador
`assets/sprout_lands/tools/watering_effect.png`
- 432x144

### Itens
`assets/sprout_lands/items/all_items.png`
- 128x240

### Arvores / arbustos
`assets/sprout_lands/world/trees_bushes.png`
- 192x112
- atlas irregular; recortes devem ser confirmados antes de substituir os placeholders

### Pedras / flora
`assets/sprout_lands/world/stones_flora.png`
- 192x80
- atlas irregular; recortes devem ser confirmados antes de substituir os placeholders

### Terreno
`assets/sprout_lands/tiles/grass_tiles.png`
- 176x112

`assets/sprout_lands/tiles/tilled_dirt.png`
- 176x112

Esses tilesets possuem composicao/autotile e nao devem ser tratados como grade simples ate o TileSet do Godot ser configurado.

## Regra de integracao

Nao substituir um placeholder funcional por um recorte incerto. Primeiro confirmar:
1. tamanho do frame/regiao;
2. orientacao;
3. origem visual;
4. escala no grid;
5. colisao;
6. CI Godot 4.7.2.

Depois integrar.
