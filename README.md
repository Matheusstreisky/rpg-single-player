# rpg-single-player

Mesas de RPG single-player gerenciadas pelo Kiro como mestre/guardião, com memória
persistida em arquivos markdown. Cada sistema fica em sua própria pasta:

- **`cthulhu/`** — Call of Cthulhu 7ª Edição (Guardião)
- **`vampiro/`** — Vampiro (Narrador)

Cada sistema traz suas regras (`config.md`), a arquitetura do sistema de memória
(`arquitetura.md`), os agentes de automação (`agentes/`), o guia de início
(`primeiros-passos.md`) e **fichas de exemplo** prontas para servir de modelo.

## Fichas de exemplo

O repositório acompanha dois personagens de exemplo em cada sistema:

- **Xunda** — personagem jogável (`personagens/xunda/`)
- **Jacinto** — NPC (`npcs/jacinto/`)

Eles existem para mostrar o formato esperado de `ficha.md`, `estado.md` e
`memorias.md`. Use-os como referência ao criar os seus.

## Ferramentas

Cada sistema traz um rolador de dados **opcional**, adequado às suas regras. O
projeto funciona 100% sem eles — o jogador sempre pode rolar os próprios dados
(físicos ou de qualquer app) e informar o resultado ao mestre.

- **`cthulhu/ferramentas/rolar.ps1`** — rolador de d100 para CoC 7e (graus de
  sucesso, dado bônus/penalidade). Veja `cthulhu/ferramentas/README.md`.
- **`vampiro/ferramentas/rolar.ps1`** — rolador de pool de d10 para V5 (contagem
  de sucessos, mesclagem crítica, Dados de Fome). Veja
  `vampiro/ferramentas/README.md`.

## Como o versionamento é organizado (importante)

A ideia é que **qualquer pessoa possa clonar e jogar**, e que **uma nova versão
do projeto nunca carregue a história da campanha de ninguém**. Para isso:

### 1. `.gitignore` — mantém a história fora do repositório

O `.gitignore` já ignora automaticamente as novas pastas de personagem
(`*/personagens/*/`) e de NPC (`*/npcs/*/`) criadas durante o jogo — **exceto**
os exemplos `xunda` e `jacinto`. Vale para os dois sistemas (`cthulhu/` e
`vampiro/`).

Ou seja: as fichas que você (ou os agentes) criarem durante uma campanha ficam
só na sua máquina.

### 2. `skip-worktree` — preserva os exemplos mesmo durante o jogo

Alguns arquivos de exemplo **já versionados** (as `ficha.md`, `estado.md` e
`memorias.md` de Xunda e Jacinto, além de `mundo/mundo.md` e
`mundo/acontecimentos.md`) são reescritos pelos agentes de memória durante uma
sessão. Como o `.gitignore` não afeta arquivos já versionados, usamos
`skip-worktree` para que o Git **ignore as alterações locais** nesses arquivos —
mantendo a versão-exemplo limpa no repositório.

Essa marca é **local** (não viaja no clone). Se você clonar o projeto e quiser o
mesmo comportamento, rode uma vez:

```powershell
git update-index --skip-worktree `
  cthulhu/mundo/acontecimentos.md cthulhu/mundo/mundo.md `
  cthulhu/personagens/xunda/estado.md cthulhu/personagens/xunda/memorias.md cthulhu/personagens/xunda/ficha.md `
  cthulhu/npcs/jacinto/estado.md cthulhu/npcs/jacinto/memorias.md cthulhu/npcs/jacinto/ficha.md `
  vampiro/mundo/acontecimentos.md vampiro/mundo/mundo.md `
  vampiro/personagens/xunda/estado.md vampiro/personagens/xunda/memorias.md vampiro/personagens/xunda/ficha.md `
  vampiro/npcs/jacinto/estado.md vampiro/npcs/jacinto/memorias.md vampiro/npcs/jacinto/ficha.md
```

Para voltar a rastrear um desses arquivos (por exemplo, se quiser atualizar o
exemplo no repositório), use `git update-index --no-skip-worktree <arquivo>`.
