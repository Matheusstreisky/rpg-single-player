# Ferramentas da Mesa

## `rolar.ps1` — Rolador de dados (Vampiro: A Máscara 5ª Edição)

Rola um pool de d10 e conta sucessos aplicando as regras de V5 definidas em `config.md`.

> **O rolador é opcional.** É uma conveniência, não um requisito. O jogador pode
> sempre rolar seus próprios dados (físicos ou de qualquer app) e informar o
> resultado ao Narrador — a mesa funciona 100% assim. Use o script quando quiser
> que o sistema role (por exemplo, rolagens ocultas do Narrador) ou por preferência
> pessoal. A escolha de usar ou não é sempre do jogador. Ver a seção
> "Como as rolagens acontecem" em `config.md`.

### Como rodar (Windows) — bypass por chamada

O Windows bloqueia scripts `.ps1` por padrão. Este projeto usa **bypass por chamada**:
você roda o script prefixando `powershell -ExecutionPolicy Bypass -File`, o que vale
**apenas para aquela execução** e **não altera nada** na sua máquina. Assim o projeto
fica portátil — ninguém precisa configurar nada.

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 5 -Nome "Destreza + Atletismo"
```

> **Não é preciso (nem recomendado) alterar a execution policy da máquina.** O bypass
> por chamada resolve sem deixar pegada. Em macOS/Linux, rodar `.ps1` exige PowerShell
> Core (`pwsh`); sem ele, basta informar as rolagens manualmente (o rolador é opcional).

### Exemplos

Teste simples (pool de 5 dados):

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 5 -Nome "Destreza + Atletismo"
```

Com Dados de Fome (2 dos dados do pool são vermelhos):

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 6 -Fome 2 -Nome "Força + Briga"
```

Com dificuldade (número de sucessos exigido):

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pool 6 -Fome 2 -Dificuldade 3 -Nome "Força + Briga"
```

### Parâmetros

| Parâmetro | Descrição |
|---|---|
| `-Pool` | Total de dados do teste (atributo + habilidade + modificadores), 1–30 |
| `-Fome` | Quantos dos dados do pool são Dados de Fome (d10 vermelhos). Padrão 0 — não pode exceder o Pool |
| `-Dificuldade` | Número de sucessos exigido pelo teste (opcional); indica vitória ou falha |
| `-Nome` | Nome do teste, só para exibição (opcional) |

### Regras aplicadas (V5)

- **Sucesso:** cada dado com resultado **6 ou mais**
- **Crítico:** cada **10**; cada **par de 10s** vale **+2 sucessos** (mesclagem crítica) — ou seja, dois 10s somam 4 sucessos no total
- **Dados de Fome:** fazem parte do mesmo pool e contam sucessos normalmente, mas:
  - um Dado de Fome com **1** → **Falha de Bestialidade** (risco de frenesi)
  - um Dado de Fome com **10** → **Êxtase** (sucesso com efeito colateral narrativo)
- **Falha crítica (bestial):** metade ou mais de todos os dados mostram **1** e não há nenhum sucesso

### Se aparecer erro de "running scripts is disabled"

Isso acontece quando o script é chamado sem o bypass. Use sempre o prefixo
`powershell -ExecutionPolicy Bypass -File` mostrado acima — ele roda o script
apenas naquela vez, sem alterar nenhuma configuração da máquina.

> **Nota sobre o eco do terminal:** em alguns terminais o comando digitado aparece
> repetido/embaralhado antes da saída. Isso é o terminal ecoando o comando, não um
> erro do script — a saída do rolador (as linhas com os sucessos) sai sempre limpa,
> independentemente do eco.
