# Guia de Testes — Sistema de Agentes RPG

Este documento define como testar o sistema de agentes de memória de forma sistemática. Deve ser consultado após atualizações nos agentes, no script de orquestração, nas estruturas de arquivos ou na correção de bugs.

O sistema é idêntico para todos os cenários (`cthulhu`, `vampiro`, futuros). Os exemplos usam `cthulhu`.

---

## O que o sistema compreende

```
Hook (UserPromptSubmit)
    → fim-de-sessao.ps1   — lê os 4 agentes e injeta as instruções no contexto
        ↓
    [1] rpg-acontecimentos — fs_append em acontecimentos.md
    [2] rpg-memorias       — fs_append em memorias.md de cada personagem/NPC
    [3] rpg-estado         — fs_write em estado.md; str_replace em ficha.md
    [4] rpg-arquivista     — fs_write em arquivos ativos e partes (acima de 1500 linhas)
```

**Matriz de permissões de arquivo** (o teste valida que cada agente respeita isso):

| Agente | `acontecimentos.md` | `memorias.md` | `estado.md` | `ficha.md` | Partes arquivadas |
|---|---|---|---|---|---|
| rpg-acontecimentos | `fs_append` ✓ | ✗ | ✗ | ✗ | ✗ |
| rpg-memorias | ✗ | `fs_append` ✓ | ✗ | ✗ | ✗ |
| rpg-estado | ✗ | ✗ | `fs_write` ✓ | `str_replace` ✓ (campos específicos) | ✗ |
| rpg-arquivista | `fs_write` ✓ (só ao arquivar) | `fs_write` ✓ (só ao arquivar) | ✗ | ✗ | `fs_write` ✓ (cria e nunca reabre) |

---

## Tipos de teste

O sistema tem dois tipos de componentes, com formas diferentes de testar:

| Componente | Tipo | Como testar |
|---|---|---|
| Hook + script (`fim-de-sessao.ps1`) | Infraestrutura | Automatizado — PowerShell |
| Agentes 1–3 (acontecimentos, memorias, estado) | Comportamental (LLM) | Checklist de verificação pós-execução |
| Agente 4 (arquivista) | Lógico + estrutural | Automatizado — dados sintéticos + validação PowerShell |

---

## Teste 1 — Infraestrutura: hook e script

Verifica que o `fim-de-sessao.ps1` lê os 4 agentes, produz os 4 passos no prompt combinado e escreve os arquivos em UTF-8.

### Pré-condição
Os arquivos em `agentes/` devem existir: `rpg-acontecimentos.md`, `rpg-memorias.md`, `rpg-estado.md`, `rpg-arquivista.md`.

### Script de validação

```powershell
$cenario = "cthulhu"   # trocar para "vampiro" para testar o outro cenário
$raiz    = "c:\Projetos\rpg-single-player\$cenario"

# 1. Sintaxe do .ps1
$tokens = $null; $erros = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    "$raiz\ferramentas\fim-de-sessao.ps1", [ref]$tokens, [ref]$erros) | Out-Null
"Sintaxe do script: " + $(if ($erros.Count -eq 0) {"OK"} else {"ERRO: $($erros[0].Message)"})

# 2. Sintaxe do JSON do hook
try {
    Get-Content "$raiz\.kiro\hooks\rpg-fim-de-sessao.json" -Raw | ConvertFrom-Json | Out-Null
    "Hook JSON valido: OK"
} catch { "Hook JSON ERRO: $($_.Exception.Message)" }

# 3. Executar o script com stdin vazio (simula fallback sem frase-gatilho no stdin)
$tmp = New-TemporaryFile
$out = (Get-Content $tmp.FullName) | powershell -ExecutionPolicy Bypass -File "$raiz\ferramentas\fim-de-sessao.ps1"
Remove-Item $tmp.FullName
$texto = $out -join "`n"
"Script produz saida  : " + $(if ($out.Count -gt 0)  {"OK ($($out.Count) linhas)"} else {"VAZIO"})
"Contem PASSO 1 DE 4  : " + ($texto -match "PASSO 1 DE 4")
"Contem PASSO 4 DE 4  : " + ($texto -match "PASSO 4 DE 4")
"Contem rpg-arquivista: " + ($texto -match "rpg-arquivista")
"Todos os 4 passos    : " + ($texto -match "PASSO 1 DE 4" -and $texto -match "PASSO 2 DE 4" -and $texto -match "PASSO 3 DE 4" -and $texto -match "PASSO 4 DE 4")

# 4. Verificar que o script lê os 4 agentes em UTF-8
"Leitura em UTF8: " + (Select-String -Path "$raiz\ferramentas\fim-de-sessao.ps1" -Pattern "Encoding UTF8" -Quiet)
```

### Resultados esperados

```
Sintaxe do script: OK
Hook JSON valido: OK
Script produz saida  : OK (774 linhas, aprox.)
Contem PASSO 1 DE 4  : True
Contem PASSO 4 DE 4  : True
Contem rpg-arquivista: True
Todos os 4 passos    : True
Leitura em UTF8: True
```

---

## Teste 2 — Agente rpg-acontecimentos (checklist comportamental)

Este agente é um LLM. Não há como executá-lo automaticamente fora de uma sessão real. O teste consiste em executar o fim de sessão e verificar manualmente os critérios abaixo no arquivo produzido.

### Como executar
1. Jogar ao menos um turno numa sessão real
2. Digitar a frase-gatilho: `fim de sessão`
3. Aguardar os 4 agentes concluírem
4. Abrir `mundo/acontecimentos.md` e verificar os itens

### Checklist de verificação

**Arquivo e operação:**
- [ ] O arquivo cresceu (nova entrada foi adicionada ao final)
- [ ] Nenhum conteúdo anterior foi alterado ou removido
- [ ] A entrada usa `fs_append` — verificar que entradas anteriores permanecem intactas

**Conteúdo da nova entrada:**
- [ ] O cabeçalho segue o formato `## Sessão XX — Turno XX`
- [ ] Os campos `**Data ficcional:**`, `**Local:**` e `**Envolvidos:**` estão presentes
- [ ] O tom é neutro e objetivo — sem emoções, sem perspectiva de personagem ("Xunda sentiu..." → incorreto)
- [ ] Apenas fatos observáveis foram registrados
- [ ] Pensamentos internos e intenções não verbalizadas estão ausentes
- [ ] Se houve fenômeno sobrenatural: descreveu o observável, não a interpretação
- [ ] Falas ditas em voz alta estão entre aspas com atribuição

**Índice:**
- [ ] Uma nova linha foi adicionada ao `## Índice` no topo do arquivo
- [ ] A âncora da linha de índice aponta para o cabeçalho recém-adicionado
- [ ] Evento marcante (se aplicável) está marcado com `⚠️` e identificado como `EVENTO MARCANTE`

**Fronteira com outros agentes:**
- [ ] Nenhum `memorias.md` foi tocado
- [ ] Nenhum `estado.md` foi tocado
- [ ] Nenhum `ficha.md` foi tocado

---

## Teste 3 — Agente rpg-memorias (checklist comportamental)

### Como executar
Mesmo fluxo do Teste 2. Verificar os `memorias.md` de cada personagem e NPC presente na sessão.

### Checklist de verificação

**Arquivo e operação:**
- [ ] O arquivo de cada personagem presente cresceu
- [ ] Personagens ausentes da cena não receberam nova entrada
- [ ] Nenhum conteúdo anterior foi alterado

**Conteúdo das novas entradas:**
- [ ] A entrada reflete a perspectiva individual — o que aquele personagem poderia saber e sentir
- [ ] Informações a que o personagem não tinha acesso estão ausentes da sua entrada
- [ ] Se houve mentira ou omissão:
  - [ ] Na memória de quem mentiu: "Disse X para [fulano], mas a verdade é Y"
  - [ ] Na memória de quem ouviu: apenas "fulano disse X" — sem indicação de falsidade
- [ ] Perdas de sanidade (CoC) ou de Humanidade (Vampiro) estão registradas com peso emocional
- [ ] Evento marcante (se aplicável) usa o formato `⚠️ EVENTO MARCANTE` com seção narrativa

**Índice:**
- [ ] Linha de índice adicionada no `## Índice` do arquivo
- [ ] Evento marcante na linha de índice usa `⚠️` e aponta para o cabeçalho correto

**Fronteira com outros agentes:**
- [ ] Nenhum `acontecimentos.md` foi tocado
- [ ] Nenhum `estado.md` foi tocado
- [ ] Nenhum `ficha.md` foi tocado

---

## Teste 4 — Agente rpg-estado (checklist comportamental)

### Como executar
Mesmo fluxo. Verificar `estado.md` e `ficha.md` dos personagens e NPCs presentes.

### Checklist de verificação

**estado.md:**
- [ ] O arquivo foi sobrescrito completamente (é um arquivo presente → `fs_write`)
- [ ] O campo `**Atualizado em:**` reflete a sessão e turno corretos
- [ ] PV, PM, Sanidade (CoC) ou Vitae/Humanidade (Vampiro) refletem o estado ao fim do último turno
- [ ] Insanidades temporárias ativas estão listadas (ou "nenhuma")
- [ ] Objetivos imediatos refletem o que foi descoberto ou decidido nesta sessão
- [ ] NPCs que participaram ativamente têm `estado.md` atualizado

**ficha.md (apenas se houve mudança mecânica):**
- [ ] Apenas os campos que efetivamente mudaram foram alterados via `str_replace`
- [ ] PV, PM e Sanidade atual **não** foram adicionados à ficha (vivem só em `estado.md`)
- [ ] Se Mitos de Cthulhu aumentou: valor atualizado + Sanidade máxima recalculada
- [ ] Se ficha está sem atualização há mais de 5 sessões: alerta `⚠️ FICHA DESATUALIZADA` presente
- [ ] Se NPC teve agenda alterada: campo `## Agenda Atual` atualizado na ficha do NPC

**Fronteira com outros agentes:**
- [ ] Nenhum `memorias.md` foi tocado
- [ ] Nenhum `acontecimentos.md` foi tocado

---

## Teste 5 — Agente rpg-arquivista (automatizado)

Este é o único agente com lógica completamente automática e verificável sem sessão real. O teste usa dados sintéticos.

### Visão geral

| Parâmetro | Valor |
|---|---|
| Arquivo testado | `acontecimentos.md` |
| Sessões geradas | 8 (6 turnos cada, evento marcante no turno 4) |
| Linhas geradas | ~1590 (acima do limite de 1500) |
| Sessões arquivadas | 01–05 |
| Sessões mantidas ativas | 06–08 |
| Ativo esperado após arquivamento | ~600 linhas |

### Fase A — Gerar dados de teste

> ⚠️ Executar **sempre como inline** via `execute_pwsh`. Nunca salvar como `.ps1`. Ver **Armadilhas** ao final deste documento.

```powershell
$dir = "c:\Projetos\rpg-single-player\.teste-sistema\mundo"
New-Item -ItemType Directory -Path $dir -Force | Out-Null

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Acontecimentos")
[void]$sb.AppendLine("")
[void]$sb.AppendLine("## Índice")

for ($s=1; $s -le 8; $s++) {
  $ss = "{0:D2}" -f $s
  for ($t=1; $t -le 6; $t++) {
    $tt = "{0:D2}" -f $t
    if ($t -eq 4) {
      [void]$sb.AppendLine("- [Sessão $ss — Turno $tt ⚠️](#sessão-$ss--turno-$tt-) — EVENTO MARCANTE: primeiro horror da sessão $ss")
    } else {
      [void]$sb.AppendLine("- [Sessão $ss — Turno $tt](#sessão-$ss--turno-$tt) — investigação — turno $tt da sessão $ss")
    }
  }
}
[void]$sb.AppendLine("")
[void]$sb.AppendLine("---")
[void]$sb.AppendLine("")

for ($s=1; $s -le 8; $s++) {
  $ss = "{0:D2}" -f $s
  for ($t=1; $t -le 6; $t++) {
    $tt = "{0:D2}" -f $t
    if ($t -eq 4) {
      [void]$sb.AppendLine("## Sessão $ss — Turno $tt ⚠️ EVENTO MARCANTE: primeiro horror da sessão $ss")
    } else {
      [void]$sb.AppendLine("## Sessão $ss — Turno $tt")
    }
    [void]$sb.AppendLine("**Data ficcional:** noite do dia $t, semana $s")
    [void]$sb.AppendLine("**Local:** Cidade Nova (Klabin) — ponto de teste $s-$t")
    [void]$sb.AppendLine("**Envolvidos:** Xunda")
    [void]$sb.AppendLine("")
    for ($l=1; $l -le 26; $l++) {
      [void]$sb.AppendLine("Xunda observou o fato número $l neste turno ($tt) desta sessão ($ss), registrado de forma objetiva e neutra pelo arquivista.")
    }
    [void]$sb.AppendLine("")
  }
}

$path = Join-Path $dir "acontecimentos.md"
[System.IO.File]::WriteAllText($path, $sb.ToString(), [System.Text.Encoding]::UTF8)
"Linhas: " + (Get-Content $path -Encoding UTF8).Count
```

**Resultado esperado:** `Linhas: 1590`

### Fase B — Executar o arquivamento

```powershell
$src     = "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos.md"
$partDir = "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos"
New-Item -ItemType Directory -Path $partDir -Force | Out-Null

$lines = Get-Content $src -Encoding UTF8
$idx15  = $lines[3..32]
$idx68  = $lines[33..50]
$body15 = $lines[54..1013]
$body68 = $lines[1014..1589]

# Arquivo 1: parte imutavel
$p = [System.Collections.ArrayList]::new()
[void]$p.Add("# Acontecimentos — Parte 01")
[void]$p.Add("**Cobertura:** Sessão 01 (Turno 01) a Sessão 05 (Turno 06)")
[void]$p.Add("**Arquivado em:** fim da Sessão 08")
[void]$p.Add("> Arquivo imutável. Não editar. Índice histórico em ``indice.md``.")
[void]$p.Add("")
[void]$p.Add("---")
[void]$p.Add("")
foreach ($l in $body15) { [void]$p.Add($l) }
[System.IO.File]::WriteAllLines((Join-Path $partDir "acontecimentos-parte-01.md"), $p, [System.Text.Encoding]::UTF8)

# Arquivo 2: indice-mestre
$im = [System.Collections.ArrayList]::new()
[void]$im.Add("# Índice-Mestre de Acontecimentos Arquivados")
[void]$im.Add("> Aponta para as sessões movidas para arquivos-parte. As sessões ativas estão em ``../acontecimentos.md``.")
[void]$im.Add("")
[void]$im.Add("## Parte 01 — Sessões 01 a 05")
foreach ($l in $idx15) {
    [void]$im.Add(($l -replace '\(#', '(acontecimentos-parte-01.md#'))
}
[System.IO.File]::WriteAllLines((Join-Path $partDir "indice.md"), $im, [System.Text.Encoding]::UTF8)

# Arquivo 3: ativo reescrito
$a = [System.Collections.ArrayList]::new()
[void]$a.Add("# Acontecimentos")
[void]$a.Add("> Sessões anteriores arquivadas. Índice histórico completo em ``acontecimentos/indice.md``.")
[void]$a.Add("")
[void]$a.Add("## Índice (sessões ativas)")
foreach ($l in $idx68) { [void]$a.Add($l) }
[void]$a.Add("")
[void]$a.Add("---")
[void]$a.Add("")
foreach ($l in $body68) { [void]$a.Add($l) }
[System.IO.File]::WriteAllLines($src, $a, [System.Text.Encoding]::UTF8)

"Parte-01 : $((Get-Content (Join-Path $partDir 'acontecimentos-parte-01.md') -Encoding UTF8).Count) linhas"
"indice.md: $((Get-Content (Join-Path $partDir 'indice.md') -Encoding UTF8).Count) linhas"
"Ativo    : $((Get-Content $src -Encoding UTF8).Count) linhas"
```

**Resultado esperado:**
```
Parte-01 : 967 linhas
indice.md: 34 linhas
Ativo    : 601 linhas
```

### Fase C — Validar (bloco A: tamanhos e integridade)

```powershell
$base  = "c:\Projetos\rpg-single-player\.teste-sistema\mundo"
$ativo = Get-Content (Join-Path $base "acontecimentos.md")                         -Encoding UTF8
$p1    = Get-Content (Join-Path $base "acontecimentos\acontecimentos-parte-01.md") -Encoding UTF8
$im    = Get-Content (Join-Path $base "acontecimentos\indice.md")                  -Encoding UTF8

"Ativo linhas: $($ativo.Count)  (esperado < 1500)"
$ta = ($ativo|Where{$_ -match "^## Sess"}).Count
$tp = ($p1   |Where{$_ -match "^## Sess"}).Count
"Turnos ativo  : $ta  (esperado 18)"
"Turnos parte  : $tp  (esperado 30)"
"Total         : $($ta+$tp)  (esperado 48)"
$ea = ($ativo|Where{$_ -match "Envolvidos:"}).Count
$ep = ($p1   |Where{$_ -match "Envolvidos:"}).Count
"Blocos completos: $($ea+$ep)  (esperado 48)"
"S05 no ativo: " + $(if(($ativo|Where{$_ -match "## Sess.{1,2}o 05"}).Count -eq 0){"NAO (correto)"}else{"SIM (ERRO)"})
"S06 na parte: " + $(if(($p1   |Where{$_ -match "## Sess.{1,2}o 06"}).Count -eq 0){"NAO (correto)"}else{"SIM (ERRO)"})
"Parte cabecalho: " + $(if($p1[0]   -match "Parte 01")             {"OK"}else{"ERRO"})
"Parte imutavel : " + $(if($p1[3]   -match "imut")                 {"OK"}else{"ERRO"})
"Ativo -> indice: " + $(if($ativo[1]-match "acontecimentos/indice") {"OK"}else{"ERRO"})
```

### Fase C — Validar (bloco B: âncoras — teste crítico)

> ⚠️ Executar em chamada separada do bloco A (o terminal trunca comandos longos).

```powershell
$base = "c:\Projetos\rpg-single-player\.teste-sistema\mundo"
$im   = Get-Content (Join-Path $base "acontecimentos\indice.md") -Encoding UTF8
$ativo = Get-Content (Join-Path $base "acontecimentos.md")       -Encoding UTF8

# IMPORTANTE: extrair so a ancora (entre # e ) ), nunca a linha inteira
# Ver Armadilha 2 — regex errado na validacao de ancoras
$ancoras  = $im | Where{$_ -match "^\- \["} | ForEach{ ([regex]::Match($_,"#([^)]+)")).Groups[1].Value }
$nLinks   = $ancoras.Count
$bugTrav  = ($ancoras | Where{ $_ -match [char]0x2014 }).Count
$comDuplo = ($ancoras | Where{ $_ -match "--" }).Count
$semArq   = ($im | Where{$_ -match "^\- \[" -and $_ -notmatch "acontecimentos-parte-01\.md#"}).Count

"Links no indice-mestre       : $nLinks   (esperado 30)"
"Ancoras com travessao U+2014 : $bugTrav  (esperado 0  — seria o bug)"
"Ancoras com hifen duplo (--)  : $comDuplo (esperado 30)"
"Links sem arquivo-alvo       : $semArq   (esperado 0)"

$s15 = ($ativo|Where{$_ -match "^\- \[Sess.{1,3}o 0[1-5]"}).Count
$s68 = ($ativo|Where{$_ -match "^\- \[Sess.{1,3}o 0[6-8]"}).Count
"Sess 1-5 no indice ativo: $s15  (esperado 0)"
"Sess 6-8 no indice ativo: $s68  (esperado 18)"

""; "--- Amostra visual: 4 primeiros links do indice-mestre ---"
$im | Where{$_ -match "^\- \["} | Select -First 4
```

### Fase D — Limpeza

```powershell
Remove-Item -Recurse -Force "c:\Projetos\rpg-single-player\.teste-sistema"
"Removido: " + (-not (Test-Path "c:\Projetos\rpg-single-player\.teste-sistema"))
```

---

## Critérios de aprovação consolidados

### Teste 1 — Infraestrutura

| Check | Esperado |
|---|---|
| Sintaxe do `.ps1` | OK (0 erros de parse) |
| Hook JSON válido | OK |
| Script produz saída | OK (> 0 linhas) |
| Todos os 4 passos presentes | True |
| Leitura com UTF-8 explícito | True |

### Testes 2, 3 e 4 — Agentes comportamentais

Todos os itens dos checklists das seções correspondentes marcados como ✓.

### Teste 5 — Arquivista

| # | Check | Esperado |
|---|---|---|
| 1 | Ativo abaixo de 1500 linhas | < 1500 |
| 2 | Turnos no ativo | 18 |
| 3 | Turnos na parte | 30 |
| 4 | Total preservado | 48 |
| 5 | Blocos completos (Envolvidos) | 48 |
| 6 | Sessão 05 não no ativo | 0 ocorrências |
| 7 | Sessão 06 não na parte | 0 ocorrências |
| 8 | Parte com cabeçalho de cobertura | OK |
| 9 | Parte com nota de imutabilidade | OK |
| 10 | Ativo aponta para índice-mestre | OK |
| 11 | Total de links no índice-mestre | 30 |
| 12 | **Âncoras sem travessão U+2014** | **0** |
| 13 | **Âncoras com hífen duplo `--`** | **30** |
| 14 | Links apontando para parte-01 | 30 |
| 15 | Índice do ativo: sessões 1–5 | 0 |
| 16 | Índice do ativo: sessões 6–8 | 18 |

Os checks 12 e 13 são os mais críticos: verificam o bug de âncora identificado e corrigido durante os testes de desenvolvimento.

---

## Armadilhas documentadas

Esta seção registra os erros cometidos durante os testes de desenvolvimento e como evitá-los. Ler antes de executar qualquer teste.

---

### ⚠️ Armadilha 1 — Salvar o script de geração como `.ps1`

**O que aconteceu:** o script de geração de dados foi salvo como arquivo `.ps1` via ferramenta de escrita de arquivos e depois executado com `powershell -File`. O Windows PowerShell 5.1 lê arquivos `.ps1` sem BOM (Byte Order Mark) como ANSI. Caracteres acentuados (`ã`, `é`, `ç`) e o travessão `—` no código-fonte do script foram interpretados como ANSI, corrompendo o texto e quebrando o parser com erros como `Missing ')' in method call` e `Unexpected token`.

**O que NÃO fazer:**
```powershell
# ERRADO: salvar como .ps1 e executar
# fs_write("meu-script.ps1", conteudo_com_acentos)
# powershell -ExecutionPolicy Bypass -File "meu-script.ps1"
```

**O que fazer:** executar **sempre como PowerShell inline** via `execute_pwsh`. O conteúdo vai diretamente para o interpretador em memória, sem leitura de arquivo com problema de encoding.

Para escrever arquivos UTF-8 a partir do inline, usar `.NET` com encoding explícito:
```powershell
# CORRETO
[System.IO.File]::WriteAllText($path, $conteudo, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllLines($path, $arrayDeLinhas, [System.Text.Encoding]::UTF8)
```

---

### ⚠️ Armadilha 2 — Regex errado na validação de âncoras

**O que aconteceu:** o check de "âncoras sem travessão" usou o regex `parte-01\.md#.*—`. O resultado foi **30 matches** onde se esperava 0 — um falso positivo de FALHOU.

**O motivo:** cada linha do índice-mestre tem o formato:
```
- [Sessão 01 — Turno 01](acontecimentos-parte-01.md#sessão-01--turno-01) — investigação — turno 01 da sessão 01
```
O regex `parte-01\.md#.*—` captura tudo após `#`, incluindo o texto de descrição depois do `)`. Esse texto contém `—` como separador, causando o falso positivo. A âncora real (`sessão-01--turno-01`) estava correta e não continha `—`.

**O que NÃO fazer:**
```powershell
# ERRADO: captura a linha inteira incluindo texto apos a ancora
$bugCount = ($im | Where-Object { $_ -match "parte-01\.md#.*—" }).Count
```

**O que fazer:** extrair **somente o conteúdo entre `#` e `)`** antes de qualquer verificação sobre a âncora:
```powershell
# CORRETO: extrai so a ancora, descarta tudo apos o )
$ancoras = $im | Where{ $_ -match "^\- \[" } | ForEach{
    ([regex]::Match($_, "#([^)]+)")).Groups[1].Value
}
$bugTrav = ($ancoras | Where{ $_ -match [char]0x2014 }).Count  # U+2014 = travessão
```

---

### ⚠️ Armadilha 3 — Recalcular âncoras em vez de reaproveitar

**O que aconteceu:** no script de simulação, as âncoras do índice-mestre foram geradas recalculando a partir dos cabeçalhos dos turnos. O algoritmo manteve o travessão `—` na âncora (`-—-`) em vez de removê-lo (que deveria gerar `--`).

**O motivo do erro:** o travessão `—` (U+2014) tem espaços dos dois lados (` — `). A regra correta de geração de âncora (estilo GitHub) é: remover pontuação (incluindo `—`) e substituir espaços por hífens. Como `—` tem dois espaços adjacentes, ao removê-lo sobram dois espaços → dois hífens `--`. Um algoritmo que apenas "troca espaços por hífens sem remover o `—`" gera `-—-` (errado).

**Referência de âncoras corretas:**

| Cabeçalho | Âncora correta | Âncora errada |
|---|---|---|
| `## Sessão 01 — Turno 01` | `#sessão-01--turno-01` | `#sessão-01-—-turno-01` |
| `## Sessão 01 — Turno 04 ⚠️` | `#sessão-01--turno-04-` | `#sessão-01--turno-04-️` |

**O que NÃO fazer:** gerar âncoras recalculando a partir dos cabeçalhos.

**O que fazer:** **reaproveitar as âncoras que já existem no índice do arquivo-fonte** e transformar apenas o destino:
```powershell
# CORRETO: copia ancora existente, muda so o destino
foreach ($l in $idx15) {
    [void]$im.Add(($l -replace '\(#', '(acontecimentos-parte-01.md#'))
}
# Antes: - [Sessão 01 — Turno 01](#sessão-01--turno-01) — desc
# Depois: - [Sessão 01 — Turno 01](acontecimentos-parte-01.md#sessão-01--turno-01) — desc
```

---

### ℹ️ Nota sobre truncamento de output do terminal

O terminal do `execute_pwsh` trunca a saída de comandos longos. Quando um script faz múltiplas operações encadeadas, parte da saída pode não aparecer mesmo que o script tenha concluído com sucesso. Estratégias:

1. **Dividir em dois blocos**: comandos de escrita num `execute_pwsh`, comandos de leitura/validação num segundo
2. **Verificar existência após escrita**: usar `Test-Path` para confirmar que os arquivos foram criados antes de ler o conteúdo
3. **Não confundir exit code -1 com erro**: o `-1` nos logs é ruído do terminal de eco interativo, não indicador de falha — verificar sempre o output real dos comandos

---

## Quando re-executar este teste

| Situação | Teste relevante |
|---|---|
| Alteração em qualquer `agentes/*.md` | Testes 2–5 (conforme o agente alterado) |
| Alteração em `ferramentas/fim-de-sessao.ps1` | Teste 1 |
| Alteração no hook `rpg-fim-de-sessao.json` | Teste 1 |
| Mudança no formato de cabeçalho `## Sessão XX — Turno XX` | Teste 5 completo + revisar âncoras |
| Correção de bug reportado em qualquer agente | Teste do agente afetado + Teste 1 |
| Mudança no limite de linhas do arquivista (atualmente 1500) | Teste 5 — ajustar as 26 linhas por turno proporcionalmente para gerar ~100 linhas acima do novo limite |
| Adição de um novo cenário | Todos os testes — trocar `cthulhu` pelo novo cenário |
| Adição de novo tipo de arquivo append-only | Teste 5 — adaptar para o novo arquivo |
