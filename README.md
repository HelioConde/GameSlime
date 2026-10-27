# GameSlime — arquivo histórico

Este repositório preserva o contexto dos primeiros experimentos que inspiraram **Slimekeepers**. Não é um jogo jogável, tampouco distribui sprites premium.

## Apresentação estática

A página `index.html` é uma vitrine histórica em HTML/CSS/JavaScript, sem conta nem banco de dados, apropriada ao GitHub Pages.

- [Slimekeepers: Lost Valley / Slime-Harvest](https://github.com/HelioConde/Slime-Harvest) — jogo em desenvolvimento.
- [Slimekeepers-Lost-Valley](https://github.com/HelioConde/Slimekeepers-Lost-Valley) — experiências relacionadas.

Para rodar localmente, inicie `python -m http.server 4173` e acesse `http://localhost:4173`.

## Licenciamento dos arquivos de terceiros

O antigo arquivo `sprites/Sprout Lands - Sprites - premium pack.zip` **foi retirado do HEAD deste repositório**. A licença do autor **Cup Nooble** não permite redistribuir o pacote premium isoladamente. Os termos originais permanecem em [sprites/read_me.txt](sprites/read_me.txt).

**Importante:** a remoção do ZIP do branch atual **não apaga cópias de commits anteriores, forks ou caches**. A revisão do histórico e possíveis procedimentos adicionais devem ser feitos com cuidado pelo mantenedor, sem reescrever indiscriminadamente o histórico de desenvolvimento.

Não reutilize assets premium sem conferir licença e atribuição. Não os use para treinamento de IA ou NFTs, conforme os termos incluídos.

## Design e QA

- Tokens, acessibilidade, carousel com teclado e suporte a `prefers-reduced-motion` em [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md).
- Capturas Playwright e testes responsivos em `tests/`, via GitHub Actions.
- GitHub Pages: publicar com GitHub Actions ou pela branch `gh-pages` na pasta `/(root)`, quando Pages estiver habilitado. O teste em 27/10/2026 passou, mas o deploy automático foi bloqueado porque a integração não podia habilitar Pages; configurar em Settings → Pages é uma etapa do proprietário.

Arquivado por [Hélio Conde](https://github.com/HelioConde); assets de Sprout Lands: **Cup Nooble**.


## Status de publicação no GitHub Pages

Em 27/10/2026, o teste de interface Playwright foi aprovado, mas o deploy foi bloqueado antes do envio dos arquivos. A mensagem do GitHub foi `Create Pages site failed: Resource not accessible by integration`. O token automático do workflow não pode habilitar o Pages em nome do administrador.

A partir deste ajuste, `qa` permanece obrigatório e grava capturas de tela em todas as alterações; `pages-readiness` distingue **Pages ainda não habilitado** de um deploy real; `deploy` só executa quando a API confirma a configuração. Um workflow de QA verde com `deploy` pulado **não significa que a página esteja publicada**.

Para ativar a publicação uma única vez, acesse **Settings → Pages → Build and deployment → Source: GitHub Actions**. Depois, execute o workflow manualmente ou faça um novo push em `main`. A versão gerada é apenas HTML/CSS/JS sem banco de dados, autenticação ou redistribuição do pacote premium. Não é necessário alterar a visibilidade dos outros repositórios.
