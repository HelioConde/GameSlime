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


## 21. Mutacoes ambientais
1. O breeding deve continuar funcionando normalmente em qualquer clima elegivel.
2. Em dias de Chuva existe uma chance rara de filhote receber mutacao Chuva.
3. No Inverno com Neve existe chance de mutacao Neve.
4. No Verao ensolarado existe chance de mutacao Solar.
5. No Outono existe chance rara de mutacao Outono.
6. Quando ocorrer uma mutacao, confirme mudanca visual de cor/genes.
7. Abra B e confirme registro "Mutacao: <tipo>" nas descobertas geneticas.
8. Salve/reabra e confirme persistencia da mutacao.


## 22. Economia / Caixa de remessa
1. Confirme HUD iniciando com 500g.
2. Colha um Nabo do Vale.
3. Selecione o Nabo e interaja com a caixa de remessa usando E.
4. Confirme que o stack sai do inventario e o HUD mostra valor em Remessa.
5. Feche e abra o jogo antes de dormir.
6. Confirme que a remessa pendente continua salva.
7. Durma.
8. Confirme pagamento no novo dia e mensagem "Vendas: +Xg".
9. Confirme Remessa voltando para 0g.

## 23. Banca de sementes sazonal
1. Na Primavera, interaja com a banca e confirme Semente de Nabo por 20g.
2. Confirme desconto no Ouro e entrada no inventario.
3. Avance ate o Verao e confirme oferta de Tomate Solar por 35g.
4. No Outono, confirme Abobora Ambar por 60g.
5. No Inverno, confirme Raiz de Gelo por 45g.
6. Tente comprar sem Ouro suficiente e confirme bloqueio.
7. Tente comprar com inventario cheio e confirme bloqueio sem perder Ouro.

## 24. Culturas por estacao
1. Primavera: Nabo do Vale, 4 dias, venda 35g.
2. Verao: Tomate Solar, 6 dias, venda 55g.
3. Outono: Abobora Ambar, 8 dias, venda 100g.
4. Inverno: Raiz de Gelo, 7 dias, venda 80g.
5. Em cada estacao, confirme que a cultura correta planta e cresce.
6. Tente usar semente fora da estacao e confirme que ela nao e consumida.

## 25. Cobre e ferreiro
1. Quebre a jazida de cobre com Picareta nivel 0.
2. Confirme drop de Minerio de Cobre e coleta.
3. Destrua um veio, salve/reabra no mesmo dia e confirme que ele continua destruido.
4. Durma e confirme que a jazida se recompõe no novo dia.
5. Selecione uma ferramenta na hotbar e aproxime-se do ferreiro.
6. Nivel 0 -> 1 deve exigir 200g + 5 Cobre.
7. Confirme consumo de Ouro/Cobre e nivel atualizado no HUD.
8. Confirme custos crescentes nos niveis seguintes.


## 26. Inventario completo
1. Pressione I.
2. Confirme que o mundo pausa.
3. Confirme grade 4x3 com os mesmos 12 slots da hotbar.
4. Clique em um slot e confirme que ele vira o slot selecionado da hotbar.
5. Arraste um stack para um slot vazio e confirme a movimentacao completa.
6. Arraste dois stacks do mesmo item um sobre o outro e confirme mesclagem ate o max_stack.
7. Arraste itens diferentes entre si e confirme troca de posicao.
8. Clique direito em um stack com quantidade > 1.
9. Clique direito em um slot vazio e confirme divisao aproximada pela metade.
10. Use Organizar stacks e confirme stacks iguais mesclados e espacos vazios compactados.
11. Confirme que a selecao da ferramenta/item continua coerente apos organizar.
12. Feche com o botao Fechar ou pressione I novamente.
13. Salve/reabra e confirme que a nova ordem dos slots persiste.


## 27. Loja sazonal com multiplas ofertas
1. Aproxime-se da banca de sementes e pressione E.
2. Confirme que o mundo pausa e o painel da loja abre.
3. Confirme o saldo de Ouro no topo.
4. Na Primavera devem existir:
   - Semente de Nabo
   - Semente de Baga da Primavera
5. No Verao:
   - Semente de Tomate Solar
   - Semente de Milho Dourado
6. No Outono:
   - Semente de Abobora Ambar
   - Semente de Berinjela Roxa
7. No Inverno:
   - Semente de Raiz de Gelo
   - Semente de Couve de Neve
8. Cada oferta deve mostrar dias de crescimento, custo e valor de venda.
9. Comprar 1 deve descontar o valor correto e adicionar 1 semente.
10. Comprar 5 deve validar espaco e Ouro antes de descontar.
11. Sem Ouro suficiente, o botao correspondente deve ficar desabilitado.
12. Pressione Esc e confirme fechamento do painel e retorno do tempo.


## 28. Cristalizador de Slime
1. Tenha pelo menos 3 Gel de Slime e 1 Minerio de Cobre.
2. Selecione Gel de Slime na hotbar.
3. Aproxime-se do Cristalizador perto da casa.
4. O HUD deve mostrar "Cristalizador · vazio · receita: 3 Gel + 1 Cobre".
5. Pressione E.
6. Confirme consumo de 3 Gel + 1 Cobre.
7. Confirme mensagem de processamento por 4 horas.
8. Aproxime-se durante o processo e confirme tempo restante no HUD.
9. Salve/reabra antes de terminar e confirme que o tempo/estado continua.
10. Avance 4 horas de jogo ou durma tempo suficiente.
11. Confirme HUD "PRONTO PARA COLETAR".
12. Pressione E e confirme Cristal de Slime x1 no inventario.
13. Com inventario cheio, a coleta deve ser bloqueada sem perder o produto.
14. Envie o Cristal pela caixa de remessa e confirme valor de 240g.


## 29. Particulas / game feel
1. Use a Enxada em solo valido e confirme burst marrom no tile.
2. Use o Regador e confirme burst azul.
3. Plante uma semente e confirme burst verde.
4. Colha uma cultura madura e confirme burst usando a cor do item.
5. Acerte uma arvore com Machado e confirme pequenas particulas de impacto.
6. Acerte pedra/cobre com Picareta e confirme particulas na cor do recurso.
7. No golpe que destrui o recurso, confirme burst maior.
8. Confirme que os efeitos somem sozinhos e nao deixam nodes permanentes.
