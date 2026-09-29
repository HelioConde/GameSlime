# Smoke Test - Godot 4.7.2

Execute `scenes/world/main.tscn`.

## 1. Movimento e animacao
1. Use WASD e setas.
2. Confirme movimento diagonal.
3. Confirme idle e caminhada nas quatro direcoes.
4. Confirme pixel art sem filtro borrado.

## 2. Agricultura
1. Selecione slot 1 - Enxada.
2. Are alguns tiles.
3. Confirme a animacao da enxada ao soltar a ferramenta.
4. Selecione slot 5 - Semente de Nabo.
5. Plante e confirme que a quantidade diminui.
6. Selecione slot 2 - Regador.
7. Regue e confirme animacao do regador.
8. Durma/interaja junto a porta da casa usando E.
9. Repita rega + sono ate o quarto dia de crescimento.
10. Use E na planta madura.
11. Confirme que Nabo do Vale aparece no inventario.

## 3. Carga
1. Use Enxada ou Regador.
2. Clique rapido: 1 tile.
3. Segure aproximadamente 0,45 s: 3x1.
4. Segure aproximadamente 0,90 s: 5x1.
5. Confirme que o preview aumenta antes de soltar.
6. Confirme que ainda e possivel mover durante a carga.
7. Confirme breve pausa enquanto a animacao final da ferramenta toca.

## 4. Agua
1. Regue ate reduzir o reservatorio.
2. Aproxime-se da fonte de agua.
3. Pressione E.
4. Confirme reservatorio cheio.

## 5. Arvore
1. Selecione slot 3 - Machado.
2. Aproxime-se de uma arvore.
3. Golpeie olhando para ela.
4. Confirme animacao de machado.
5. Machado nivel 0 deve exigir 10 golpes.
6. Confirme drop de Madeira.
7. Aproxime-se do drop.
8. Confirme coleta.

## 6. Pedra
1. Selecione slot 4 - Picareta.
2. Aproxime-se de uma pedra.
3. Confirme animacao de picareta.
4. Picareta nivel 0 deve exigir 5 golpes.
5. Confirme drop de Pedra e coleta.

## 7. Energia
1. Use ferramentas repetidamente.
2. Confirme reducao de energia.
3. Durma.
4. Confirme recuperacao total.

## 8. Inventario / Hotbar
1. Confirme 12 slots visuais.
2. Confirme icones de Enxada, Regador, Machado e Picareta.
3. Teste teclas 1-0.
4. Teste roda do mouse.
5. Confirme stacks de sementes, madeira, pedra e cultivo.

## 9. Calendario
1. Confirme no HUD: Primavera 1, Ano 1.
2. Durma e confirme que o dia da estacao aumenta.
3. O calendario deve ter 28 dias por estacao.
4. Depois do dia 28 deve avancar para Verao.
5. Depois de Inverno 28 deve voltar para Primavera e incrementar o ano.

## 10. Clima
1. Confirme o clima atual no HUD.
2. Dia 1 deve iniciar ensolarado.
3. Em dias de chuva, confirme o efeito visual.
4. Em dia chuvoso, tiles arados devem ficar regados automaticamente.
5. No Inverno, confirme que dias de neve podem ocorrer.

## 11. Cultura sazonal
1. O Nabo do Vale inicial e cultura de Primavera.
2. Na Primavera ele deve poder ser plantado.
3. Em outra estacao, tentar plantar deve exibir em quais estacoes a cultura cresce.
4. A semente nao deve ser consumida quando o plantio for recusado.

## 12. Save / Load
1. Are e plante alguns tiles.
2. Regue.
3. Quebre ao menos uma arvore ou pedra.
4. Mude o slot selecionado e gaste energia/agua.
5. Durma junto a casa.
6. Confirme mensagem de jogo salvo.
7. Feche e abra novamente o jogo.
8. Confirme data, inventario, energia, agua, posicao e horta restaurados.
9. Confirme que recursos ja destruidos continuam ausentes.

## 13. Casa
1. Confirme que a casa usa os sprites do Sprout Lands.
2. A antiga casa geometrica nao deve aparecer.
3. A interacao de sono deve funcionar junto a porta.
