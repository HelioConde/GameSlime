# Publicação no GitHub Pages — GameSlime

## Verificação em 27/10/2026
Houve um bloqueio inicial ao tentar habilitar Pages por integração, mas **a publicação por branch foi aprovada posteriormente** no [GitHub Actions #40481714642](https://github.com/HelioConde/GameSlime/actions/runs/40481714642). O QA completo passou em [#40482098932](https://github.com/HelioConde/GameSlime/actions/runs/40482098932). O site publicado usa apenas conteúdo estático e nenhum arquivo premium.

## Duas formas de publicar

### Método A — Deploy from a branch
1. Para consultar ou restaurar a configuração, acesse **Settings → Pages** do repositório GameSlime.
2. Em Build and deployment, escolha **Deploy from a branch**.
3. Selecione a branch **gh-pages** e a pasta **/(root)**.
4. Salve; acompanhe a publicação e confirme o endereço `https://helioconde.github.io/GameSlime/`.

A branch `gh-pages` tem só `index.html`, `styles.css`, `app.js`, `favicon.svg` e `.nojekyll`. Não há pacote premium, PHP, banco ou artefato sensível.

### Método B — GitHub Actions
1. Acesse **Settings → Pages** e escolha **GitHub Actions**.
2. Rode novamente o workflow `GameSlime — Qualidade e GitHub Pages` (ou faça commit em `main`).
3. Verifique QA e deploy com ambos os jobs aprovados.

Quando Pages não está habilitado, o workflow executa **QA** mas informa o bloqueio e não força um deploy que falharia. **QA verde não prova que a publicação aconteceu.**

## Licenciamento
O ZIP premium foi retirado de `main` e não existe na branch `gh-pages`; o histórico pode ter cópias e exige revisão separada.