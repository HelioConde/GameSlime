# Slime Land Farm / GameSlime

Projeto 2D top-down desenvolvido para Godot Engine 4.7.x, mirando Godot 4.7.2.

## Direcao de design

A fundacao segue os principios que fazem Stardew Valley funcionar bem:

- controle simples e preciso
- mundo organizado em tiles
- usar ferramenta separado de interagir
- tempo limitado por dia
- energia limitando produtividade
- agricultura em etapas
- inventario limitado
- ferramentas melhores diminuindo trabalho repetitivo
- recursos fisicos no mundo
- automacao somente depois que o jogador aprendeu o trabalho manual

O objetivo nao e clonar Stardew Valley. O farming loop deve parecer familiar e forte; os slimes entram depois como o principal diferencial.

## Estado jogavel atual

### Fazenda
- relogio 06:00 -> 02:00
- 10 minutos de jogo / 7 segundos reais
- energia inicial 270
- sono e virada do dia
- terra normal/arado/molhado
- sementes consumiveis
- crescimento somente se a planta foi regada
- crescimento processado na virada do dia
- colheita entrando no inventario

### Ferramentas
- enxada carregavel
- regador carregavel
- machado de acao rapida
- picareta de acao rapida
- carga em estagios de 0,45 s
- areas de 1 tile ate 5x5 preparadas
- regador com reservatorio limitado
- ponto de agua para reabastecer
- machado com reducao de golpes por nivel
- picareta com reducao de golpes por nivel

### Recursos
- arvores com colisao
- pedras com colisao
- arvore inicial exige 10 golpes de machado nivel 0
- pedra inicial exige 5 golpes de picareta nivel 0
- madeira e pedra aparecem como drops fisicos
- aproximar do drop tenta coleta-lo
- se nao houver espaco no inventario, o drop permanece no mundo

### Inventario
- 12 slots
- hotbar visivel
- teclas 1-0 para os dez primeiros slots
- roda do mouse percorre todos os slots
- stacks
- limite por item
- verificacao de espaco antes de colher

## Inventario inicial

1. Enxada
2. Regador
3. Machado
4. Picareta
5. 15 Sementes de Nabo
6-12. Vazios

Madeira, pedra e nabos colhidos ocupam os slots disponiveis.

## Controles

- WASD / setas: mover
- 1-0: selecionar hotbar
- roda do mouse: trocar slot
- clique esquerdo / ESPACO:
  - enxada/regador: segurar e soltar
  - machado/picareta: golpe imediato
  - semente: plantar
- E / clique direito:
  - colher
  - dormir perto da cama
  - encher regador perto da agua
  - consultar tile agricola

## Prototipo

Todas as ferramentas agora iniciam no nivel 0. A bancada de ferramentas perto da casa consome Madeira e Pedra para liberar os niveis seguintes. Enxada e Regador passam de 1 tile para areas maiores conforme os upgrades; Machado e Picareta reduzem a quantidade de golpes e liberam obstaculos de nivel.

## Validacao

O repositorio possui GitHub Actions usando Godot 4.7.2 em modo headless para importar o projeto e executar um smoke test da cena principal.

## Proximo passo

Completar o Marco 2 com upgrades compraveis, obstaculos que exigem nivel de ferramenta e mais feedback. Depois: calendario, estacoes, clima e save da virada do dia.


## Primeiro sistema de Slimes

A fundacao Stardew-first agora ja suporta o primeiro ciclo de criaturas:

- dois slimes iniciais: Broto e Gota
- passeio autonomo dentro do habitat
- saciedade
- energia propria
- humor
- afeto
- idade em dias
- personalidade
- sexo biologico
- genes de tamanho, metabolismo, vitalidade e producao
- alimentar com colheitas/alimentos selecionados
- carinho uma vez por dia
- producao de Gel de Slime quando bem cuidado
- painel contextual ao aproximar
- habitat com capacidade
- ninho de reproducao controlada
- requisitos de idade, cuidado, afeto e sexo oposto para breeding
- filhote com heranca dos genes e cor dos pais + pequena variacao
- filhotes persistem no save
- Bestiario Genetico com registro de individuos e descobertas
- tecla B abre o bestiario

O objetivo nesta etapa e tratar o slime primeiro como criatura viva da fazenda. Automacao/trabalho dos slimes continua reservada para uma fase posterior.
