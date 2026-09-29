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

## 3. Carga e upgrades
1. No inicio, Enxada e Regador nivel 0 devem afetar apenas 1 tile.
2. Colete Madeira e Pedra.
3. Selecione uma ferramenta e interaja com a bancada perto da casa usando E.
4. Confirme consumo de recursos e aumento do nivel no HUD.
5. No nivel 1, segure aproximadamente 0,45 s e confirme area 3x1.
6. No nivel 2, segure aproximadamente 0,90 s e confirme area 5x1.
7. Confirme que o preview aumenta antes de soltar.
8. Confirme que ainda e possivel mover durante a carga.
9. Confirme breve pausa enquanto a animacao final da ferramenta toca.

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

## 14. Obstaculos por nivel
1. Tente destruir o tronco grande com Machado nivel 0.
2. Confirme mensagem de nivel insuficiente.
3. Melhore o Machado para nivel 1.
4. Confirme que o tronco grande agora pode ser destruido.
5. Repita com a rocha grande e Picareta nivel 1.

## 15. Calendario de eventos
1. Pressione C.
2. Confirme que o mundo pausa.
3. Confirme grade de 28 dias.
4. O dia atual deve ter marcador *.
5. Dias com eventos devem ter marcador !.
6. Pressione C novamente e confirme retorno ao jogo.


## 16. Slime basico
1. Aproxime-se de Broto ou Gota.
2. Confirme painel com nome, sexo, personalidade, fome, energia, humor, afeto e idade.
3. Sem alimento selecionado, pressione E e confirme carinho.
4. Tente fazer carinho novamente no mesmo dia e confirme limite diario.
5. Selecione um Nabo do Vale e pressione E perto do slime.
6. Confirme consumo de 1 alimento e aumento de saciedade/humor.

## 17. Habitat
1. Confirme que Broto e Gota passeiam dentro da area cercada do habitat.
2. Confirme capacidade exibida pela logica do habitat.
3. Os slimes nao devem escolher destinos de passeio fora da zona.

## 18. Producao de Gel
1. Mantenha um slime com Saciedade >= 55% e Humor >= 55%.
2. Durma.
3. No novo dia, confirme um drop de Gel de Slime perto dele.
4. Aproxime-se e confirme coleta para o inventario.
5. Feche/reabra antes de coletar e confirme que o drop persiste no save.

## 19. Genetica / Breeding
1. Broto e Gota precisam ter pelo menos 3 dias de idade.
2. Cuide deles ate ambos terem Saciedade >= 60%, Energia >= 50%, Humor >= 60% e Afeto >= 8%.
3. Aproxime-se do ninho e pressione E.
4. Confirme nascimento do filhote.
5. Confirme cor intermediaria/variada.
6. Abra B e compare os genes do filhote com os pais.
7. Durma para salvar, feche e abra.
8. Confirme que o filhote continua existindo com os mesmos genes.

## 20. Bestiario genetico
1. Pressione B.
2. Confirme que o mundo pausa.
3. Confirme Broto e Gota na lista.
4. Confirme sexo, personalidade e os quatro genes.
5. Gere filhotes e verifique novos individuos.
6. Genes extremos devem registrar descobertas como Producao alta, Vitalidade alta ou Metabolismo eficiente.
7. Pressione B novamente para voltar ao jogo.
