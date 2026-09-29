# Mapa das mecanicas basicas - Slime Land Farm

Este documento define o que significa "base jogavel completa" antes de voltar a expandir os slimes.

## 1. Controle e locomocao
- [x] movimento cardinal e diagonal
- [x] facing em quatro direcoes
- [x] animacao idle/caminhada
- [x] colisao com casa, arvores, pedras e objetos principais
- [x] limites externos do mapa
- [x] bloqueio da area tecnica das minas
- [x] camera seguindo o player
- [x] interacao separada de uso de ferramenta

## 2. Tempo, dia e calendario
- [x] relogio correndo em tempo real
- [x] virada automatica as 02:00
- [x] desmaio as 02:00 retorna o player para casa com energia parcial
- [x] dormir manualmente recupera energia completa
- [x] 28 dias por estacao
- [x] quatro estacoes
- [x] mudanca de ano
- [x] calendario e eventos
- [x] ciclo visual amanhecer/dia/entardecer/noite
- [x] sono tardio reduz gradualmente a energia do dia seguinte
- [x] autosave na virada do dia

## 3. Clima
- [x] sol, nublado, chuva e neve
- [x] clima deterministico por data
- [x] previsao do dia seguinte
- [x] chuva rega solo arado e faz a cultura avancar normalmente
- [x] clima altera pesos do forrageio diario
- [x] clima externo oculto nas minas

## 4. Energia e alimentacao
- [x] energia maxima e atual
- [x] ferramentas consomem energia
- [x] bloqueio quando energia e insuficiente
- [x] sono restaura energia
- [x] comida/forrageaveis restauram energia
- [x] exaustao reduz velocidade de movimento ate recuperar energia

## 5. Agricultura
- [x] solo aravel
- [x] rega
- [x] plantio
- [x] sementes consumiveis
- [x] crescimento somente em dia regado
- [x] estagios visuais de crescimento
- [x] cultura pronta para colher
- [x] cultura morre ao mudar para estacao incompatível
- [x] bloqueio de colheita com inventario cheio
- [x] quantidade de colheita deterministica e variavel
- [x] culturas de rebrota
- [x] culturas multiestacao
- [x] solo abandonado retorna naturalmente para grama
- [x] fertilizante basico persistente
- [x] qualidade Normal/Prata/Ouro por stack
- [x] qualidade altera o valor de venda
- [x] persistencia completa da horta no save
- [ ] plantacoes gigantes/especiais (conteudo avancado)

## 6. Inventario e hotbar
- [x] 12 slots
- [x] teclas 1-0 e scroll
- [x] stacks
- [x] mover
- [x] trocar
- [x] mesclar
- [x] dividir stack
- [x] organizar
- [x] soltar 1 item ou stack no mundo
- [x] ferramentas essenciais protegidas contra descarte
- [x] selecao persistente
- [x] save/load da ordem
- [x] stacks de qualidades diferentes permanecem separados
- [x] qualidade preservada em mover/dividir/organizar/save
- [x] protecao contra perda/duplicacao em inventario cheio

## 7. Ferramentas
- [x] enxada
- [x] regador
- [x] machado
- [x] picareta
- [x] carga por tempo
- [x] areas maiores por upgrade
- [x] agua limitada
- [x] recarga do regador
- [x] niveis 0-5
- [x] custo progressivo de upgrade
- [x] obstaculos por requisito de nivel

## 8. Recursos naturais
- [x] arvores destrutiveis
- [x] pedras destrutiveis
- [x] arvores e pedras naturais regeneram em ciclos semanais
- [x] layout semanal deterministico com persistencia da destruicao no mesmo ciclo
- [x] drops fisicos
- [x] coleta automatica por proximidade
- [x] rendimento variavel e deterministico de madeira/pedra
- [x] cobre, ferro, prata e ouro
- [x] jazidas recompostas no novo dia
- [x] jazida destruida permanece destruida no save do mesmo dia

## 9. Mundo vivo e spawn
- [x] gerenciador diario de spawns
- [x] pontos seguros de spawn
- [x] seed deterministica por ano/estacao/dia
- [x] quantidade diaria limitada
- [x] flor silvestre
- [x] fruta silvestre
- [x] cogumelo silvestre
- [x] raiz silvestre
- [x] madeira e pedra como achados naturais
- [x] sementes silvestres da estacao correta
- [x] persistencia de spawns no save/load
- [x] novo conjunto de spawns a cada novo dia
- [x] spawns nao coletados persistem entre dias
- [x] expiracao natural por tipo de recurso
- [x] limite global evita acumulo infinito
- [x] sem reroll diferente ao recarregar o mesmo dia
- [ ] biomas adicionais com tabelas proprias (expansao de mapa)
- [ ] raridades especiais/eventos de spawn (conteudo avancado)

## 10. Economia
- [x] carteira de Ouro
- [x] compra de sementes
- [x] multiplas ofertas por estacao
- [x] validacao de dinheiro antes da compra
- [x] validacao de espaco antes da compra
- [x] caixa de remessa
- [x] venda paga na manha seguinte
- [x] remessa persiste no save
- [x] pagamento ocorre uma unica vez
- [x] itens de forrageio possuem valor de venda
- [x] adubo vendido como insumo permanente
- [x] qualidade Prata/Ouro aumenta valor da remessa
- [x] stacks descartados preservam qualidade no mundo e no save

## 11. Minas
- [x] Mina Rasa
- [x] Mina Profunda
- [x] Mina Abissal
- [x] requisito de picareta por tier
- [x] ferro/prata/ouro por profundidade
- [x] entrada e saida
- [x] camera acompanha transicao
- [x] save/load dentro das minas
- [x] persistencia de veios destruidos
- [ ] layouts procedurais (fase de exploracao avancada)
- [ ] recompensas especiais de andar (conteudo avancado)

## 12. Save e seguranca de estado
- [x] save JSON versionado
- [x] save temporario atomico
- [x] backup automatico
- [x] fallback para backup corrompido
- [x] save v7 com migracao aditiva de v5/v6
- [x] inventario
- [x] player
- [x] ferramentas
- [x] energia/agua
- [x] fazenda
- [x] economia
- [x] drops
- [x] spawns diarios
- [x] recursos do mundo
- [x] posicao dentro das minas

## 13. UI e bloqueio de jogo
- [x] HUD
- [x] hotbar
- [x] inventario
- [x] calendario
- [x] loja
- [x] status de mina
- [x] feedback de interacao
- [x] feedback sonoro procedural para ferramentas, materiais e transacoes
- [x] menus pausam o mundo
- [x] fechamento restaura o tempo
- [x] ESC fecha menus

## 14. Validacao obrigatoria da base
- [x] CI Godot 4.7.2
- [x] parse do projeto
- [x] smoke da cena principal
- [x] colisoes essenciais
- [x] compra com inventario cheio
- [x] colheita com inventario cheio
- [x] remessa + save/load + pagamento unico
- [x] progressao pelas tres minas
- [x] save/load dentro da Mina Abissal
- [x] manipulacao de stacks conserva quantidades
- [x] sete viradas de dia automatizadas
- [x] spawn diario deterministico
- [x] rebrota e rendimento variavel de culturas
- [x] fertilizante, qualidade e valor de venda
- [x] desmaio as 02:00 e penalidade de exaustao
- [x] ecologia persistente com expiracao/cap
- [x] regeneracao semanal de arvores/pedras com save
- [x] ciclo visual dia/noite
- [x] descarte/recoleta preservando qualidade
- [ ] campanha manual completa em gameplay real

## Fora da definicao de "mecanica basica v1"
Esses sistemas continuam importantes, mas pertencem a fases seguintes:
- NPCs, amizade e romance
- quests e historia
- pesca
- cozinha
- crafting amplo
- construcoes e expansao da fazenda
- automacao
- sprinklers
- maquinas avancadas
- combate
- layouts procedurais completos
- conteudo especial de festivais
- expansao dos slimes, genetica e breeding
