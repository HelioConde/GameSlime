# Roadmap - Stardew-first

## Marco 0 - estabilizacao jogavel (PRIORIDADE ATUAL)
- [x] congelar expansao de slimes temporariamente
- [x] CI Godot 4.7.2 com parse + smoke da cena
- [x] teste automatico de jogabilidade basica
- [x] corrigir respawn de jazidas antes do autosave
- [x] autosave tambem na virada natural das 02:00
- [x] fallback jogavel quando save esta ausente/invalido
- [x] migracao segura de saves v5 para v6
- [x] limites fisicos externos impedem o player de sair da area jogavel
- [x] banca, caixa de remessa, ferreiro e fonte de agua bloqueiam passagem
- [ ] campanha de testes manuais sem slimes
- [ ] validar 7 dias consecutivos sem softlock
- [ ] validar save/load repetido em fazenda e minas
- [ ] validar inventario cheio em compra/colheita/coleta
- [ ] validar todos os menus e ESC sem prender o jogo
- [ ] validar economia sem duplicacao/perda de itens
- [ ] validar Minas Rasa/Profunda/Abissal ida e volta
- [ ] corrigir bugs encontrados antes de qualquer feature nova

Regra deste marco:
**nenhuma feature grande e nenhuma expansao de slime ate o loop principal passar nos testes de estabilidade.**


## Marco 1 - sensacao de jogo e agricultura basica
- [x] movimento do player
- [x] facing cardinal
- [x] preview do tile da ferramenta
- [x] separar usar ferramenta de interagir
- [x] relogio e passagem do tempo
- [x] sono e virada do dia
- [x] energia
- [x] solo aravel
- [x] rega
- [x] plantio
- [x] crescimento por dia
- [x] colheita
- [x] ferramenta com toque/segurar/soltar
- [x] padroes de area para upgrades
- [x] agua limitada no regador
- [x] ponto de recarga de agua
- [x] inventario com 12 slots
- [x] hotbar
- [x] sementes consumiveis
- [x] colheita entrando no inventario
- [x] bloqueio de colheita quando inventario esta cheio
- [x] feedback visual simples de acao
- [x] CI Godot 4.7.2
- [x] sprite real do player
- [x] animacao direcional do player
- [x] animacoes de uso das ferramentas
- [ ] feedback sonoro
- [x] particulas de farming/colheita
- [x] agua animada com Sprout Lands
- [x] plantacoes usando atlas real
- [x] arvore e pedra usando sprites reais
- [x] grama e solo arado usando tiles reais
- [x] hotbar visual com icones de ferramentas
- [x] painel completo de inventario
- [x] drag-and-drop de slots

## Marco 2 - ferramentas e recursos do mapa
- [x] machado
- [x] picareta
- [x] arvores com quantidade de golpes por upgrade
- [x] pedras com quantidade de golpes por upgrade
- [x] drops fisicos
- [x] coleta automatica por proximidade
- [x] madeira e pedra integradas ao inventario
- [x] upgrades de ferramenta por tiers: Cobre -> Ferro -> Prata -> Ouro -> Cristal de Slime
- [x] obstaculos que exigem nivel de ferramenta
- [x] Cobre com jazida diaria
- [x] Ferro com jazida diaria
- [x] Prata com jazida diaria
- [x] Ouro com jazida diaria
- [ ] feedback sonoro por material
- [x] particulas de impacto


## Marco 2B - exploracao e progressao da mina
- [x] entrada de mina com requisito de Picareta
- [x] teleporte entre areas sem trocar a cena principal
- [x] camera acompanha as areas de mina
- [x] clima externo oculto dentro das cavernas
- [x] Mina Rasa - Picareta Nv.1
- [x] Minerio de Ferro na Mina Rasa
- [x] Mina Profunda - Picareta Nv.2
- [x] Minerio de Prata na Mina Profunda
- [x] Mina Abissal - Picareta Nv.3
- [x] Minerio de Ouro na Mina Abissal
- [x] HUD identifica area da mina e minérios carregados
- [x] minérios da mina recompõem no novo dia
- [x] save do mesmo dia preserva veios destruidos
- [x] upgrade Nv.5 exige Cristal de Slime
- [x] progressao manual de ferramenta Nv.0 -> Nv.5 fechada
- [ ] andares procedurais / layout variavel
- [ ] recompensas especiais de exploracao

## Marco 3 - calendario vivo
- [x] 28 dias por estacao
- [x] primavera/verao/outono/inverno
- [x] culturas por estacao
- [x] clima
- [x] previsao do tempo
- [x] calendario
- [x] eventos por dia
- [x] salvamento na virada do dia


## Marco 3B - economia manual da fazenda
- [x] carteira / Ouro
- [x] precos de compra e venda por item
- [x] caixa de remessa
- [x] pagamento das vendas na manha seguinte
- [x] economia persistida no save
- [x] banca de sementes
- [x] oferta de semente muda por estacao
- [x] Nabo do Vale - Primavera
- [x] Tomate Solar - Verao
- [x] Abobora Ambar - Outono
- [x] Raiz de Gelo - Inverno
- [x] Minerio de Cobre
- [x] jazida de Cobre se recompõe no novo dia
- [x] ferreiro consome Ouro + Cobre
- [x] menu de loja com multiplos produtos por estacao
- [x] primeiro processamento manual de produtos
- [x] primeiro produto artesanal: Cristal de Slime

## Marco 4 - slimes como identidade central (CONGELADO)
- [x] slime base
- [x] fome
- [x] humor
- [x] afeto
- [x] energia propria
- [x] idade
- [x] sexo/genetica
- [x] cor herdavel
- [x] personalidade
- [x] habitat
- [x] producao de recursos

## Marco 5 - breeding e descobertas (CONGELADO)
- [x] reproducao controlada no ninho
- [x] heranca dos pais
- [x] mutacoes por ambiente
- [x] raridades condicionais / tiers de raridade
- [x] bestiario genetico
- [x] descobertas geneticas registradas
- [x] especies especiais por clima/horario/bioma

## Marco 6 - progressao e automacao
- [ ] sprinklers
- [ ] alimentadores
- [ ] coletores
- [ ] maquinas
- [ ] processamento
- [ ] slimes ajudando tarefas
- [ ] logistica
- [ ] gerenciamento em massa

Principio de progressao:

manual -> eficiente -> automatizado -> especializado -> dominado
