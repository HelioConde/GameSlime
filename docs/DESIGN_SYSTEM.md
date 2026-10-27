# Design System — GameSlime (2026)

## Intenção
Uma vitrine histórica aconchegante, distinta do jogo completo. Nenhuma captura, sprite premium, implementação de jogo ou progresso de desenvolvimento é inventado.

## Taste Skill
- Espaçamento: `--space-1` (4), 2 (8), 3 (12), 4 (16), 6 (24), 8 (32), 12 (48px).
- Cores: fundo `#101b2a`, superfícies `#15273b`, destaques lima `#c2ee85` e menta `#96f2c5`, texto `#eff7ef`.
- Raio: 18px; caixa hero 30px; cartões 22px; container até 1190px.
- Hierarquia: hero curto, origem, repositórios ativos, atribuição de autoria.

## Web Design Guidelines
- Skip link, landmarks, botões reais para carrossel, descrição de região rolável, foco amarelo visível e links externos seguros.
- Carrossel acessível com `ArrowLeft`/`ArrowRight`, botões disabled nos extremos, touch scroll nativo e scroll-snap.
- `prefers-reduced-motion`: desliga animações e scroll suave; ilustração SVG/CSS sem parallax.
- Cards exibem status textual e não dependem só de cor.

## Awesome Design / Image to Code
- Desenho de slime é **ilustração CSS original** (sem pacote premium).
- A composição é implementada em HTML/CSS, sem alegar conversão fiel de imagem inexistente.
- Os cards remetem a repositórios verificáveis, não a builds jogáveis simuladas.

## Licenciamento
- O ZIP de Sprout Lands Premium não pode permanecer exposto como download separado; arquivo removido do branch atual.
- Os termos originais e crédito a Cup Nooble permanecem no repositório.
- O histórico Git requer revisão separada antes de afirmar remoção definitiva dos blobs.

## QA
Playwright: 390x844, 768x1024, 1366x768 e 1600x900; overflow, controles de carrossel, links, console, acessibilidade básica, screenshots. CI inclui inspeção que impede ZIP premium no HEAD.