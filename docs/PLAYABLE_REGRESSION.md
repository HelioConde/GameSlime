# Regressao Jogavel - prioridade atual

Objetivo: validar o loop principal sem depender de slimes.

Regra:
- nao adicionar sistemas grandes durante esta fase
- nao expandir slimes, breeding, genetica ou habitats
- corrigir primeiro qualquer crash, softlock, perda/duplicacao de item, perda de Ouro ou falha de save

## Sessao A - novo jogo e controles
1. Iniciar sem save.
2. Confirmar Player, HUD, hotbar e 12 slots.
3. Mover nas quatro direcoes e diagonal.
4. Trocar slots por 1-0 e scroll.
5. Abrir I e fechar por I, botao e Esc.
6. Abrir calendario por C e fechar por C/Esc.
7. Confirmar que nenhum menu deixa o jogo pausado depois de fechar.
8. Caminhar contra os quatro limites externos e confirmar que o player nao sai da area visivel.
9. Tentar atravessar banca, caixa de remessa, ferreiro e fonte de agua; todos devem bloquear movimento sem impedir E/interacao.

## Sessao B - agricultura
1. Arar pelo menos 8 tiles.
2. Plantar sementes.
3. Regar.
4. Confirmar consumo de energia e agua.
5. Reabastecer regador.
6. Dormir e repetir ate a primeira colheita.
7. Colher com espaco no inventario.
8. Encher o inventario e confirmar que a colheita e bloqueada sem perder a planta.

## Sessao C - loja e economia
1. Abrir a banca.
2. Comprar 1 semente.
3. Comprar 5 sementes.
4. Confirmar desconto exato de Ouro.
5. Encher inventario.
6. Tentar comprar e confirmar que nenhum Ouro e gasto.
7. Enviar cultivo pela caixa de remessa.
8. Fechar/reabrir antes de dormir e confirmar remessa pendente.
9. Dormir e confirmar pagamento uma unica vez.

## Sessao D - recursos e ferramentas
1. Derrubar arvore e coletar Madeira.
2. Quebrar pedra e coletar Pedra.
3. Minerar Cobre.
4. Melhorar Picareta para Nv.1.
5. Confirmar que materiais e Ouro sao descontados uma unica vez.
6. Tentar upgrade sem recursos e confirmar que nada e consumido.

## Sessao E - minas
1. Tentar Mina Rasa com Picareta Nv.0 e confirmar bloqueio.
2. Entrar com Nv.1 e sair novamente.
3. Minerar Ferro.
4. Salvar/reabrir dentro da Mina Rasa.
5. Confirmar posicao e camera.
6. Evoluir ate Picareta Nv.2 e entrar na Mina Profunda.
7. Minerar Prata.
8. Evoluir ate Nv.3 e entrar na Mina Abissal.
9. Minerar Ouro.
10. Em chuva/neve, confirmar que o efeito externo nao aparece dentro das minas.

## Sessao F - save e virada do dia
1. Alterar inventario, Ouro, energia, agua e horta.
2. Dormir.
3. Fechar o jogo imediatamente apos o save.
4. Reabrir e conferir todos os estados.
5. Repetir por 7 dias consecutivos.
6. Em um dia, deixar o relogio chegar naturalmente as 02:00.
7. Fechar/reabrir e confirmar autosave do novo dia.
8. Confirmar que Cobre/Ferro/Prata/Ouro reaparecem no novo dia.
9. Quebrar veios, salvar/reabrir no mesmo dia e confirmar que continuam quebrados.

## Sessao G - inventario
1. Arrastar item para slot vazio.
2. Trocar dois itens diferentes.
3. Mesclar stacks iguais.
4. Dividir stack por clique direito.
5. Organizar inventario.
6. Salvar/reabrir e confirmar ordem.
7. Repetir operacoes com 12 slots ocupados.
8. Confirmar que nenhum item some ou duplica.


## Sessao H - mundo vivo e forrageio
1. Iniciar um novo dia e confirmar entre 4 e 7 spawns naturais.
2. Confirmar que os spawns aparecem somente em pontos seguros.
3. Salvar/reabrir e confirmar os mesmos itens/posicoes no mesmo dia.
4. Dormir e confirmar um novo conjunto diario.
5. Confirmar Flor/Fruta/Cogumelo/Raiz conforme a estacao.
6. Confirmar semente silvestre compativel com a estacao.
7. Encher o inventario e confirmar que o item no chao nao desaparece.
8. Liberar um slot e confirmar coleta normal.
9. Comer um forrageavel com energia baixa e confirmar recuperacao.
10. Vender um forrageavel e confirmar valor correto.

## Sessao I - crescimento avancado
1. Plantar uma cultura e nao regar no primeiro dia.
2. Dormir e confirmar crescimento = 0.
3. Regar diariamente ate amadurecer naturalmente.
4. Confirmar quantidade de colheita dentro do intervalo configurado.
5. Salvar/reabrir antes da colheita e confirmar o mesmo rendimento no mesmo dia.
6. Colher uma cultura de rebrota.
7. Confirmar que a planta permanece no solo e volta ao estado de crescimento.
8. Regar pelos dias de rebrota e confirmar nova colheita.
9. Avancar para estacao incompatível e confirmar murcha.
10. Confirmar que a banca muda para sementes da nova estacao.

## Sessao J - qualidade, descarte e feedback
1. Adubar um tile vazio antes de plantar e confirmar preview marrom.
2. Tentar adubar uma planta ja existente e confirmar bloqueio com mensagem clara.
3. Colher planta adubada e confirmar qualidade Prata/Ouro visivel no inventario.
4. Confirmar que stacks Normal/Prata/Ouro nao se misturam.
5. Enviar Prata/Ouro pela caixa e conferir valor maior que a qualidade Normal.
6. Soltar um item com Q e um stack com Shift+Q.
7. Confirmar que o item nao volta instantaneamente para o inventario.
8. Confirmar anel visual Prata/Ouro no item no chao.
9. Salvar/reabrir com item de qualidade no chao e confirmar qualidade preservada.
10. Tentar soltar ferramenta essencial e confirmar bloqueio.
11. Ouvir diferenca entre enxada/regador/machado/picareta, madeira/pedra e confirmacoes.

## Sessao K - tempo, luz e energia
1. Observar transicao visual 06:00 -> manha -> tarde -> entardecer -> noite.
2. Entrar na mina a noite e confirmar que o tint externo nao escurece a caverna novamente.
3. Dormir antes da meia-noite e confirmar energia completa.
4. Dormir depois da meia-noite e confirmar energia parcial proporcional ao horario.
5. Permanecer acordado ate 02:00 e confirmar retorno para casa com 65% de energia.
6. Zerar energia e confirmar movimento mais lento.
7. Comer um forrageavel e confirmar que a velocidade normal retorna ao recuperar energia.

## Sessao L - regeneracao natural
1. Conferir duas arvores e duas pedras naturais adicionais no mapa novo.
2. Derrubar/quebrar uma delas, salvar e reabrir no mesmo ciclo semanal.
3. Confirmar que o recurso destruido nao reaparece no load.
4. Avancar sete dias e confirmar renovacao do conjunto natural.
5. Confirmar que recursos remanescentes do ciclo anterior sao renovados sem dano parcial.
6. Confirmar que o layout semanal e consistente ao recarregar a mesma data.
7. Conferir que os forrageaveis nao coletados persistem ate expirar e nunca passam do limite global.
8. Em chuva, observar maior presenca de forrageio umido/cogumelos; em neve, maior peso de raizes.

## Criterio para liberar novas features
O jogo precisa completar:
- 7 dias seguidos
- pelo menos 3 save/load
- agricultura completa
- compra e venda
- Mina Rasa, Profunda e Abissal
- inventario cheio
- virada natural das 02:00

Sem:
- crash
- softlock
- perda de item
- duplicacao de item
- perda indevida de Ouro
- mundo permanentemente pausado
- player perdido fora dos limites do mapa
- objetos principais atravessaveis
- save corrompido sem recuperacao

Somente depois desse criterio voltamos a criar features grandes.
