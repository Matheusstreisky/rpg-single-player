# Ferramentas da Mesa

## `fim-de-sessao.ps1` — Gravação em lote ao fim de sessão

Disparado automaticamente pelo hook `rpg-fim-de-sessao` quando o jogador começa
uma mensagem com a frase-gatilho ("fim de sessão" e variações). Não é chamado
manualmente — o hook cuida disso.

### O que faz

Lê os três arquivos de agentes em `/agentes/` e combina suas instruções num
prompt único, que é injetado no contexto do Kiro via stdout. O Kiro então executa
os três passos em ordem:

1. **rpg-acontecimentos** — registra em `mundo/acontecimentos.md` todos os turnos
   da sessão ainda não gravados
2. **rpg-memorias** — registra em cada `memorias.md` a perspectiva individual de
   cada personagem por turno
3. **rpg-estado** — sobrescreve cada `estado.md` com o estado ao fim do último turno
   e atualiza campos mecânicos da `ficha.md` quando necessário

### Para personalizar o comportamento

Edite os arquivos em `/agentes/` — eles são a fonte da verdade de cada passo.
O script em si não precisa ser alterado para mudanças de regras ou formato.

---

## `rolar.ps1` — Rolador de dados (Call of Cthulhu 7ª Edição)

Rola d100 e aplica as regras de grau de sucesso definidas em `config.md`.

> **O rolador é opcional.** É uma conveniência, não um requisito. O jogador pode
> sempre rolar seus próprios dados (físicos ou de qualquer app) e informar o
> resultado ao Guardião — a mesa funciona 100% assim. Use o script quando quiser
> que o sistema role (por exemplo, rolagens ocultas do Guardião) ou por preferência
> pessoal. A escolha de usar ou não é sempre do jogador. Ver a seção
> "Como as rolagens acontecem" em `config.md`.

### Como rodar (Windows) — bypass por chamada

O Windows bloqueia scripts `.ps1` por padrão. Este projeto usa **bypass por chamada**:
você roda o script prefixando `powershell -ExecutionPolicy Bypass -File`, o que vale
**apenas para aquela execução** e **não altera nada** na sua máquina. Assim o projeto
fica portátil — ninguém precisa configurar nada.

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pericia 45 -Nome "Investigar"
```

> **Não é preciso (nem recomendado) alterar a execution policy da máquina.** O bypass
> por chamada resolve sem deixar pegada. Em macOS/Linux, rodar `.ps1` exige PowerShell
> Core (`pwsh`); sem ele, basta informar as rolagens manualmente (o rolador é opcional).

### Exemplos

Teste de perícia:

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pericia 45 -Nome "Investigar"
```

Com dado penalidade (ex: Xunda escutando cansado, no escuro):

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pericia 55 -Nome "Escutar" -Penalidade 1
```

Com dado bônus:

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Pericia 45 -Nome "Investigar" -Bonus 1
```

Rolagem genérica de dados (dano, características, tabelas):

```powershell
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Dados "2d6+6"
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Dados "1d4"
powershell -ExecutionPolicy Bypass -File .\rolar.ps1 -Dados "3d6*5"
```

### Parâmetros

| Parâmetro | Descrição |
|---|---|
| `-Pericia` | Valor % da perícia/característica a testar (1–100) |
| `-Nome` | Nome da perícia, só para exibição (opcional) |
| `-Bonus` | Quantidade de dados bônus (0–3) |
| `-Penalidade` | Quantidade de dados penalidade (0–3) |
| `-Dados` | Rolagem genérica no formato `NdX+M` / `NdX*M` (ignora `-Pericia`) |

Dados bônus e penalidade se cancelam entre si (regra da 7ª edição).

### Graus de sucesso aplicados

- **Sucesso extremo:** resultado ≤ um quinto da perícia
- **Sucesso difícil:** resultado ≤ metade da perícia
- **Sucesso normal:** resultado ≤ perícia
- **Falha:** acima da perícia
- **Fumble:** 96–100 (ou apenas 100 se a perícia for ≥ 50%)

### Se aparecer erro de "running scripts is disabled"

Isso acontece quando o script é chamado sem o bypass. Use sempre o prefixo
`powershell -ExecutionPolicy Bypass -File` mostrado acima — ele roda o script
apenas naquela vez, sem alterar nenhuma configuração da máquina.

> **Nota sobre o eco do terminal:** em alguns terminais o comando digitado aparece
> repetido/embaralhado antes da saída. Isso é o terminal ecoando o comando, não um
> erro do script — a saída do rolador (as linhas com o grau de sucesso) sai sempre
> limpa, independentemente do eco.
