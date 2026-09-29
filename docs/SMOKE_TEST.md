# Smoke Test - Godot 4.7.2

Execute `scenes/world/main.tscn`.

## 1. Movimento
1. Use WASD e setas.
2. Confirme movimento diagonal.
3. Confirme que a linha amarela indica a direcao atual.

## 2. Agricultura
1. Selecione slot 1 - Enxada.
2. Are alguns tiles.
3. Selecione slot 5 - Semente de Nabo.
4. Plante e confirme que a quantidade diminui.
5. Selecione slot 2 - Regador.
6. Regue.
7. Durma na cama usando E.
8. Repita rega + sono ate o quarto dia de crescimento.
9. Use E na planta madura.
10. Confirme que Nabo do Vale aparece na hotbar/inventario.

## 3. Carga
1. Use Enxada ou Regador.
2. Clique rapido: 1 tile.
3. Segure aproximadamente 0,45 s: 3x1.
4. Segure aproximadamente 0,90 s: 5x1.
5. Confirme que o preview aumenta antes de soltar.

## 4. Agua
1. Regue ate reduzir o reservatorio.
2. Aproxime-se do circulo azul.
3. Pressione E.
4. Confirme reservatorio cheio.

## 5. Arvore
1. Selecione slot 3 - Machado.
2. Aproxime-se de uma arvore.
3. Golpeie olhando para ela.
4. Machado nivel 0 deve exigir 10 golpes.
5. Confirme drop de Madeira.
6. Aproxime-se do drop.
7. Confirme coleta.

## 6. Pedra
1. Selecione slot 4 - Picareta.
2. Aproxime-se de uma pedra.
3. Picareta nivel 0 deve exigir 5 golpes.
4. Confirme drop de Pedra e coleta.

## 7. Energia
1. Use ferramentas repetidamente.
2. Confirme reducao de energia.
3. Durma.
4. Confirme recuperacao total.

## 8. Inventario
1. Confirme 12 slots.
2. Teste teclas 1-0.
3. Teste roda do mouse.
4. Confirme stacks de sementes, madeira, pedra e cultivo.
