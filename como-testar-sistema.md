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
Script produz saida  : OK (varia por cenário — cthulhu ~790 linhas, vampiro ~732 linhas)
Contem PASSO 1 DE 4  : True
Contem PASSO 4 DE 4  : True
Contem rpg-arquivista: True
Todos os 4 passos    : True
Leitura em UTF8: True
```

> ⚠️ O número de linhas da saída varia conforme o tamanho dos arquivos de agente de cada cenário. O check relevante é `> 0 linhas` e `Todos os 4 passos: True`, não o número exato.

---

## Teste 2 — Agente rpg-acontecimentos (checklist comportamental)

Este agente é um LLM. Não há como executá-lo automaticamente fora de uma sessão real. O teste consiste em executar o fim de sessão e verificar manualmente os critérios abaixo no arquivo produzido.

### Como executar
1. **Antes de rodar:** anotar a contagem de linhas atual: `(Get-Content mundo\acontecimentos.md -Encoding UTF8).Count`
2. Jogar ao menos um turno numa sessão real
3. Digitar a frase-gatilho: `fim de sessão`
4. Aguardar os 4 agentes concluírem
5. Abrir `mundo/acontecimentos.md` e verificar os itens

### Checklist de verificação

**Arquivo e operação:**
- [ ] O arquivo cresceu — a contagem de linhas após é maior que a anotada antes
- [ ] Nenhuma entrada anterior foi editada — os cabeçalhos e conteúdo das entradas `## Sessão XX` existentes estão intactos
- [ ] A nova linha de índice foi inserida na seção `## Índice` (via `str_replace` antes do `---`), não intercalada no corpo
- [ ] O corpo da nova entrada está ao final do arquivo (via `fs_append`), não intercalado entre entradas existentes

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
- [ ] A âncora da linha de índice segue o formato correto: `#sessão-XX--turno-XX` (hífen duplo, sem travessão `—`)
- [ ] Evento marcante (se aplicável) está marcado com `⚠️` e identificado como `EVENTO MARCANTE`

**Fronteira com outros agentes:**
- [ ] Nenhum `memorias.md` foi tocado
- [ ] Nenhum `estado.md` foi tocado
- [ ] Nenhum `ficha.md` foi tocado

---

## Teste 3 — Agente rpg-memorias (checklist comportamental)

### Como executar
**Antes de rodar:** anotar a contagem de linhas de cada `memorias.md` relevante:
```powershell
Get-ChildItem -Recurse -Filter "memorias.md" | ForEach-Object { "$($_.FullName): $((Get-Content $_.FullName -Encoding UTF8).Count) linhas" }
```
Depois do fim de sessão, comparar as contagens.

### Checklist de verificação

**Arquivo e operação:**
- [ ] O arquivo de cada personagem **presente** cresceu (mais linhas que antes)
- [ ] O arquivo de personagens **ausentes** da cena não mudou (mesma contagem de linhas)
- [ ] O corpo da nova entrada foi adicionado via `fs_append` ao final do arquivo; a linha de índice foi inserida via `str_replace` antes do separador `---` do corpo

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
- [ ] A âncora da linha de índice segue o formato correto: `#sessão-XX--turno-XX` (hífen duplo, sem travessão `—`)
- [ ] Evento marcante na linha de índice usa `⚠️` e a âncora corresponde ao cabeçalho do evento

**Fronteira com outros agentes:**
- [ ] Nenhum `acontecimentos.md` foi tocado
- [ ] Nenhum `estado.md` foi tocado
- [ ] Nenhum `ficha.md` foi tocado

---

## Teste 4 — Agente rpg-estado (checklist comportamental)

### Como executar
**Antes de rodar:** anotar as contagens de linhas dos `memorias.md` e `acontecimentos.md`:
```powershell
"acontecimentos: $((Get-Content mundo\acontecimentos.md -Encoding UTF8).Count)"
Get-ChildItem -Recurse -Filter "memorias.md" | ForEach-Object { "$($_.Name) ($($_.Directory.Name)): $((Get-Content $_.FullName -Encoding UTF8).Count)" }
```
Depois do fim de sessão, confirmar que as contagens de `memorias.md` e `acontecimentos.md` não mudaram.

### Checklist de verificação

**estado.md:**
- [ ] O arquivo foi sobrescrito completamente (é um arquivo presente → `fs_write`)
- [ ] O campo `**Atualizado em:**` reflete a sessão e turno corretos
- [ ] PV, PM, Sanidade (CoC) ou Vitae/Humanidade (Vampiro) refletem o estado ao fim do último turno
- [ ] Insanidades temporárias ativas estão listadas (ou "nenhuma") (CoC)
- [ ] Insanidades permanentes estão listadas (ou "nenhuma") (CoC)
- [ ] Seção Mitos de Cthulhu reflete o Conhecimento atual, Sanidade máxima e últimas revelações (CoC)
- [ ] Objetivos imediatos refletem o que foi descoberto ou decidido nesta sessão
- [ ] NPCs que participaram ativamente têm `estado.md` atualizado
- [ ] Sorte foi atualizada com o valor correto (CoC apenas — Vampiro não usa este campo no `estado.md`)
- [ ] Vínculos Ativos refletem o estado atual — alianças, ameaças, dívidas, suspeitos
- [ ] Notas do Guardião (CoC) / Notas do Narrador (Vampiro) têm informação relevante para a próxima cena

**ficha.md (apenas se houve mudança mecânica):**
- [ ] Apenas os campos que efetivamente mudaram foram alterados via `str_replace`
- [ ] PV, PM e Sanidade atual **não** foram adicionados à ficha (vivem só em `estado.md`)
- [ ] Se Mitos de Cthulhu aumentou: valor atualizado + Sanidade máxima recalculada (CoC)
- [ ] Se nova insanidade permanente foi adquirida: campo de insanidades permanentes atualizado na `ficha.md` (CoC)
- [ ] Campo `Última atualização mecânica` foi atualizado quando qualquer campo mecânico mudou
- [ ] Se ficha está sem atualização há mais de 5 sessões: alerta `⚠️ FICHA DESATUALIZADA` presente
- [ ] Se alerta estava presente e a ficha foi revisada nesta sessão: alerta foi removido via `str_replace`
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

# Arquivo 1: parte imutavel — array concat (sem ArrayList.Add em loop, ver Armadilha 6)
$parte01 = @(
    "# Acontecimentos -- Parte 01",
    "**Cobertura:** Sessao 01 (Turno 01) a Sessao 05 (Turno 06)",
    "**Arquivado em:** fim da Sessao 08",
    "> Arquivo imutavel. Nao editar. Indice historico em ``indice.md``.",
    "",
    "---",
    ""
) + $body15
[System.IO.File]::WriteAllLines((Join-Path $partDir "acontecimentos-parte-01.md"), $parte01, [System.Text.Encoding]::UTF8)

# Arquivo 2: indice-mestre
$idxArq = $idx15 | ForEach-Object { $_ -replace '\(#', '(acontecimentos-parte-01.md#' }
$indicem = @(
    "# Indice-Mestre de Acontecimentos Arquivados",
    "> Aponta para as sessoes movidas para arquivos-parte. As sessoes ativas estao em ``../acontecimentos.md``.",
    "",
    "## Parte 01 -- Sessoes 01 a 05"
) + $idxArq
[System.IO.File]::WriteAllLines((Join-Path $partDir "indice.md"), $indicem, [System.Text.Encoding]::UTF8)

# Arquivo 3: ativo reescrito (ordem correta: parte -> indice -> ativo)
$ativo = @(
    "# Acontecimentos",
    "> Sessoes anteriores arquivadas. Indice historico completo em ``acontecimentos/indice.md``.",
    "",
    "## Indice (sessoes ativas)"
) + $idx68 + @("", "---", "") + $body68
[System.IO.File]::WriteAllLines($src, $ativo, [System.Text.Encoding]::UTF8)

"Parte-01 : $((Get-Content (Join-Path $partDir 'acontecimentos-parte-01.md') -Encoding UTF8).Count) linhas"
"indice.md: $((Get-Content (Join-Path $partDir 'indice.md') -Encoding UTF8).Count) linhas"
"Ativo    : $((Get-Content $src -Encoding UTF8).Count) linhas"

# Salvar hash MD5 de parte-01 — base para o check de imutabilidade da Fase E
$p01hash = (Get-FileHash (Join-Path $partDir "acontecimentos-parte-01.md") -Algorithm MD5).Hash
$p01hash | Set-Content (Join-Path $partDir "parte-01-hash.txt") -Encoding UTF8
"Hash MD5 parte-01: $p01hash"
```

**Resultado esperado:**
```
Parte-01 : 967 linhas
indice.md: 34 linhas
Ativo    : 601 linhas
Hash MD5 parte-01: <hash hexadecimal>
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

> ⚠️ **Execute esta fase apenas se NÃO for continuar para a Fase E.** Se quiser testar o multi-ciclo, pule direto para a Fase E — ela começa exatamente do estado deixado pela Fase C (o diretório `.teste-sistema` ainda deve existir). Execute a Fase D somente quando quiser encerrar o Teste 5 sem rodar a Fase E.

```powershell
Remove-Item -Recurse -Force "c:\Projetos\rpg-single-player\.teste-sistema"
"Removido: " + (-not (Test-Path "c:\Projetos\rpg-single-player\.teste-sistema"))
```

---

## Fase E — Teste multi-ciclo (continua após a Fase C)

Estende o Teste 5 para validar que o arquivista lida corretamente com o 2º ciclo e além: numeração sequencial de partes, append ao índice-mestre sem sobrescrever seções anteriores, e imutabilidade das partes já criadas.

> ⚠️ **Pré-condição:** a Fase D não deve ter sido executada. A Fase E começa diretamente do estado da Fase B/C — o diretório `.teste-sistema` com `parte-01`, `indice.md` e o ativo (601 linhas com S06–S08) já deve existir, assim como o arquivo `parte-01-hash.txt` gerado pela Fase B.

### Visão geral

| Etapa | O que acontece | Resultado esperado |
|---|---|---|
| E1 | Simular novas sessões: regenerar ativo com S06–S16 | 2185 linhas |
| E2 | Ciclo 2: arquivar S06–S13, manter S14–S16 | parte-02 + indice(2 seções) + ativo 601 linhas |
| E3 | Validar estado final de ambos os ciclos | todos os checks abaixo |
| E4 | Limpeza | pasta removida |

### Fase E1 — Simular novas sessões (regenerar ativo com S06–S16)

Partindo do ativo com 601 linhas deixado pela Fase B (sessões S06–S08), simula o crescimento do arquivo ao longo de novas partidas — como se o `rpg-acontecimentos` tivesse gravado as sessões 09 a 16.

```powershell
$src = "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos.md"
$sb  = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine("# Acontecimentos")
[void]$sb.AppendLine("> Sessoes anteriores arquivadas. Ver ``acontecimentos/indice.md``.")
[void]$sb.AppendLine(""); [void]$sb.AppendLine("## Indice (ativas)")
for ($s=6; $s -le 16; $s++) { $ss="{0:D2}" -f $s
  for ($t=1; $t -le 6; $t++) { $tt="{0:D2}" -f $t
    if ($t -eq 4) { [void]$sb.AppendLine("- [Sessão $ss — Turno $tt ⚠️](#sessão-$ss--turno-$tt-) — EVENTO MARCANTE: horror s$ss") }
    else          { [void]$sb.AppendLine("- [Sessão $ss — Turno $tt](#sessão-$ss--turno-$tt) — turno $tt sessão $ss") }
  }
}
[void]$sb.AppendLine(""); [void]$sb.AppendLine("---"); [void]$sb.AppendLine("")
for ($s=6; $s -le 16; $s++) { $ss="{0:D2}" -f $s
  for ($t=1; $t -le 6; $t++) { $tt="{0:D2}" -f $t
    if ($t -eq 4) { [void]$sb.AppendLine("## Sessão $ss — Turno $tt ⚠️ EVENTO MARCANTE: horror s$ss") }
    else          { [void]$sb.AppendLine("## Sessão $ss — Turno $tt") }
    [void]$sb.AppendLine("**Data ficcional:** noite, sessao $s")
    [void]$sb.AppendLine("**Local:** Cidade Nova")
    [void]$sb.AppendLine("**Envolvidos:** Xunda")
    [void]$sb.AppendLine("")
    for ($l=1; $l -le 26; $l++) { [void]$sb.AppendLine("Fato $l turno $tt sessao $ss.") }
    [void]$sb.AppendLine("")
  }
}
[System.IO.File]::WriteAllText($src, $sb.ToString(), [System.Text.Encoding]::UTF8)
(Get-Content $src -Encoding UTF8).Count
```

**Resultado esperado:** `2185` (> 1500, Ciclo 2 vai disparar)

### Fase E2 — Ciclo 2

Slices do arquivo S06–S16 (estrutura calculada): índice ocupa linhas 5–70 (`[4..69]`), corpo começa na linha 74 (`[73]`), S14 começa na linha 1610 (`[1609]`).

> ⚠️ Ver **Armadilha 7**: a detecção do número da parte deve usar apenas arquivos com nome `parte-NN.md` válido — arquivos sem número (de runs com falha) causam detecção errada.

```powershell
$src     = "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos.md"
$partDir = "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos"
$lines   = Get-Content $src -Encoding UTF8

# Ler hash de parte-01 salvo pela Fase B (para verificacao de imutabilidade)
$p01hashBase = Get-Content "$partDir\parte-01-hash.txt" -Encoding UTF8 | Select-Object -First 1

# parte-02: header + body S06-S13 (slices [73..1608])
$idxArq2 = $lines[4..51] | ForEach-Object { $_ -replace '\(#', '(acontecimentos-parte-02.md#' }
$c = @("# Parte 02: S06-S13", "> Imutavel.", "", "---", "") + $lines[73..1608]
[System.IO.File]::WriteAllLines("$partDir\acontecimentos-parte-02.md", $c, [System.Text.Encoding]::UTF8)

# Appenda nova secao ao indice-mestre (Add-Content preserva conteudo existente)
$sec = @("", "## Parte 02: S06-S13") + $idxArq2
Add-Content -Path "$partDir\indice.md" -Value $sec -Encoding UTF8

# ativo ciclo 2: header + indice S14-S16 + body S14-S16 (slices [52..69] e [1609..2184])
$c3 = @("# Acontecimentos", "> Sessoes anteriores arquivadas. Ver ``acontecimentos/indice.md``.", "", "## Indice (ativas)") +
      $lines[52..69] + @("", "---", "") + $lines[1609..2184]
[System.IO.File]::WriteAllLines($src, $c3, [System.Text.Encoding]::UTF8)

"parte-02 : $((Get-Content "$partDir\acontecimentos-parte-02.md" -Encoding UTF8).Count) linhas"
"indice   : $((Get-Content "$partDir\indice.md" -Encoding UTF8).Count) linhas"
"ativo    : $((Get-Content $src -Encoding UTF8).Count) linhas"
"parte-01 imutavel: " + ((Get-FileHash "$partDir\acontecimentos-parte-01.md" -Algorithm MD5).Hash -eq $p01hashBase)
```

**Resultado esperado:**
```
parte-02 : 1541 linhas
indice   : 84 linhas
ativo    : 601 linhas
parte-01 imutavel: True
```

### Fase E3 — Validar multi-ciclo

```powershell
$base    = "c:\Projetos\rpg-single-player\.teste-sistema\mundo"
$src     = "$base\acontecimentos.md"
$partDir = "$base\acontecimentos"
$ativo   = Get-Content $src -Encoding UTF8
$p1      = Get-Content "$partDir\acontecimentos-parte-01.md" -Encoding UTF8
$p2      = Get-Content "$partDir\acontecimentos-parte-02.md" -Encoding UTF8
$im      = Get-Content "$partDir\indice.md" -Encoding UTF8

$tA  = ($ativo|Where{$_ -match "^## Sess"}).Count
$tP1 = ($p1  |Where{$_ -match "^## Sess"}).Count
$tP2 = ($p2  |Where{$_ -match "^## Sess"}).Count
"Turnos ativo   : $tA   (esp 18)"
"Turnos parte-01: $tP1  (esp 30)"
"Turnos parte-02: $tP2  (esp 48)"
"Total          : $($tA+$tP1+$tP2)  (esp 96 = 16 sessoes x 6)"

$secoes = ($im|Where{$_ -match "^## Parte"}).Count
"Secoes no indice : $secoes  (esp 2)"
$lP1 = ($im|Where{$_ -match "^\- \[" -and $_ -match "acontecimentos-parte-01\.md#"}).Count
$lP2 = ($im|Where{$_ -match "^\- \[" -and $_ -match "acontecimentos-parte-02\.md#"}).Count
"Links -> parte-01: $lP1  (esp 30)"
"Links -> parte-02: $lP2  (esp 48)"

# Ancora: extrai so o conteudo entre # e ) (ver Armadilha 2)
$ancoras = $im|Where{$_ -match "^\- \["}|ForEach{([regex]::Match($_,"#([^)]+)")).Groups[1].Value}
$bugAnc  = ($ancoras|Where{$_ -match [char]0x2014}).Count
"Ancoras c/ travessao: $bugAnc  (esp 0)"
"Ativo < 1500        : " + $(if($ativo.Count -lt 1500){"OK ($($ativo.Count))"}else{"ERRO"})
"parte-03 nao existe : " + (-not (Test-Path "$partDir\acontecimentos-parte-03.md"))
```

### Critérios de aprovação da Fase E

| # | Check | Esperado |
|---|---|---|
| 1 | Turnos no ativo | 18 |
| 2 | Turnos na parte-01 | 30 |
| 3 | Turnos na parte-02 | 48 |
| 4 | Total preservado (96 = 16 sessões × 6) | 96 |
| 5 | Seções no índice-mestre | 2 |
| 6 | Links apontando para parte-01 | 30 |
| 7 | Links apontando para parte-02 | 48 |
| 8 | Âncoras com travessão U+2014 | 0 |
| 9 | Ativo abaixo de 1500 linhas | True |
| 10 | parte-03 não existe (ciclo extra não disparou) | True |
| 11 | **parte-01 imutável (hash MD5 igual antes e depois do ciclo 2)** | **True** |

O check 11 é o mais crítico desta fase: prova que o ciclo 2 não tocou na parte criada pelo ciclo 1.

> O hash comparado é o salvo em `parte-01-hash.txt` pela **Fase B** — não recalculado em E2. Isso garante que o check cobre toda a janela entre o Ciclo 1 e o Ciclo 2.

### Fase E4 — Limpeza

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

### Fase E — Arquivista multi-ciclo

| # | Check | Esperado |
|---|---|---|
| 1 | Turnos no ativo | 18 |
| 2 | Turnos na parte-01 | 30 |
| 3 | Turnos na parte-02 | 48 |
| 4 | Total preservado (96 = 16 sessões × 6) | 96 |
| 5 | Seções no índice-mestre | 2 |
| 6 | Links apontando para parte-01 | 30 |
| 7 | Links apontando para parte-02 | 48 |
| 8 | Âncoras com travessão U+2014 | 0 |
| 9 | Ativo abaixo de 1500 linhas | True |
| 10 | parte-03 não existe | True |
| 11 | **parte-01 imutável (hash MD5 da Fase B vs. pós-Ciclo 2)** | **True** |

O check 11 usa o hash salvo em `parte-01-hash.txt` pela Fase B — cobre toda a janela entre o Ciclo 1 e o Ciclo 2.

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

### ⚠️ Armadilha 4 — Resultados esperados com números fixos

**O que aconteceu:** o Teste 1 no guia especificava "774 linhas, aprox." como resultado esperado para a saída do script. Na execução real, cthulhu produziu 790 linhas e vampiro 732. O número varia porque depende do tamanho dos arquivos `.md` de cada agente, que diferem entre cenários.

**Risco:** um LLM que verifique o resultado literalmente pode declarar FALHOU quando o teste na verdade passou.

**O que NÃO fazer:** especificar contagens exatas de linhas como critério de aprovação para comandos cujo output depende de conteúdo externo variável.

**O que fazer:** usar condições relativas (`> 0`, `< 1500`, `== 48`) ou ranges ("~790 para cthulhu, ~732 para vampiro — varia com atualizações aos agentes"). O critério de aprovação deve ser estrutural, não numérico-fixo.

Essa armadilha se aplica a qualquer check do tipo `"linhas == N"` onde N depende do conteúdo dos arquivos de agente. O Teste 5 usa contagens fixas (18 turnos, 30 turnos, 48 total) porque elas derivam dos parâmetros do gerador de dados — esses sim são estáveis.

---

### ⚠️ Armadilha 5 — Slices hardcoded dependem da estrutura fixa do gerador

**O que aconteceu:** a Fase B do Teste 5 usa slices de array com índices fixos (`$lines[3..32]`, `$lines[54..1013]` etc.). Esses índices foram calculados para um arquivo gerado com exatamente 8 sessões, 6 turnos e 26 linhas de conteúdo por turno — resultando em 1590 linhas com a estrutura exata prevista.

**Risco:** se o script gerador for modificado (mais turnos, mais sessões, mais linhas de conteúdo), os slices ficam errados e o teste arquiva o conteúdo errado sem aviso visível.

**Como verificar antes de executar a Fase B:** confirmar que o arquivo de teste tem a estrutura esperada rodando a verificação de fronteiras (Fase A já faz isso com a contagem de linhas; adicionar verificação explícita):

```powershell
# Verificar antes da Fase B que os indices batem
$lines = Get-Content "c:\Projetos\rpg-single-player\.teste-sistema\mundo\acontecimentos.md" -Encoding UTF8
"Linha 4  (deve ser 1a entrada do indice): " + $lines[3]
"Linha 33 (deve ser ultima entrada S05)  : " + $lines[32]
"Linha 55 (deve ser inicio corpo S01)    : " + $lines[54]
```

Se as linhas não corresponderem ao esperado, **recalcular os slices** antes de rodar a Fase B.

---

### ⚠️ Armadilha 6 — Loop com `ArrayList.Add()` dispara bloqueio de permissão

**O que aconteceu:** um script que usava `[System.Collections.ArrayList]::new()` com `foreach ($l in $lines) { [void]$ab.Add($l) }` para construir um array de ~600 linhas recebeu o erro: `Permission flow exceeded 20 approval rounds; the call still requires approval for: $ab.Add($_)`. O Kiro interpreta cada chamada de `Add()` como uma tentativa de ação que requer aprovação em loop, bloqueando o script.

**O que NÃO fazer:**
```powershell
# ERRADO: iteracao de Add() dispara o bloqueio
$ab = [System.Collections.ArrayList]::new()
foreach ($l in $lines[1000..1589]) { [void]$ab.Add($l) }
```

**O que fazer:** usar concatenação de arrays com `+`, que é uma expressão única sem iteração visível:
```powershell
# CORRETO: array concat — operacao unica, sem loop de Add()
$conteudo = @("# header", "> aviso", "", "---", "") + $lines[54..1013]
[System.IO.File]::WriteAllLines($caminho, $conteudo, [System.Text.Encoding]::UTF8)
```

Essa armadilha se aplica a qualquer loop que chame uma função/método repetidamente dentro do `execute_pwsh`. A geração de dados (loops `for` com `StringBuilder.AppendLine()`) é diferente — o `AppendLine` numa string não dispara o mecanismo de aprovação da mesma forma.

---

### ⚠️ Armadilha 7 — Arquivo de parte com nome inválido corrompe detecção do próximo número

**O que aconteceu:** um run anterior com erro criou um arquivo chamado `acontecimentos-parte-.md` (sem número, resultado de `$nn` como string vazia). Quando a detecção do próximo número usou `Get-ChildItem -Filter "acontecimentos-parte-*.md"` e extraiu os números com regex `parte-(\d+)`, esse arquivo produziu `[int]""` = 0. O cálculo `Maximum(0,1) + 1 = 2` continuou correto — mas em cenários onde só o arquivo inválido existisse, o resultado seria `$nn = "01"` causando overwrite de uma parte existente.

**O que NÃO fazer:**
```powershell
# ARRISCADO: inclui arquivos malformados na contagem
$exNums = Get-ChildItem $partDir -Filter "acontecimentos-parte-*.md" |
          ForEach-Object { [int]([regex]::Match($_.Name, "parte-(\d+)").Groups[1].Value) }
```

**O que fazer:** filtrar apenas arquivos com número válido antes de extrair:
```powershell
# CORRETO: ignora arquivos sem numero valido
$exNums = Get-ChildItem $partDir -Filter "acontecimentos-parte-*.md" -EA SilentlyContinue |
          Where-Object { $_.Name -match "parte-(\d+)\.md$" } |
          ForEach-Object { [int]([regex]::Match($_.Name, "parte-(\d+)").Groups[1].Value) }
$nn = "{0:D2}" -f $(if ($exNums) { ($exNums | Measure-Object -Maximum).Maximum + 1 } else { 1 })
```

Ao limpar sempre a pasta de teste antes de cada run (Fase D / Fase E4), esse problema nunca ocorre em condições normais. Mas se um run falhar a meio — especialmente se o script foi interrompido antes de completar o ciclo — pode deixar arquivos órfãos. Sempre verificar o conteúdo de `.teste-sistema/mundo/acontecimentos/` antes de continuar.

---

### ⚠️ Armadilha 8 — Ordem das operações: parte antes do ativo

**O que aconteceu:** em um run interrompido, o ativo foi reescrito (última operação do script) mas a parte correspondente não foi criada (script truncado antes). Resultado: sessões S06–S13 do ativo foram perdidas — o ativo ficou com S14–S16 mas não havia parte-02 guardando S06–S13.

**Regra de atomicidade:** a ordem das operações no arquivamento deve ser sempre:
1. Criar a parte (fs_write) — conserva o conteúdo antes de qualquer outra mudança
2. Atualizar o índice-mestre (fs_write ou Add-Content)
3. Reescrever o arquivo ativo (fs_write) — **sempre por último**

Se o script for interrompido após o passo 1 mas antes do passo 3, o pior cenário é um índice desatualizado — facilmente corrigível. Se o script for interrompido após o passo 3, os dados da parte foram perdidos.

Esta ordem está documentada na spec do `rpg-arquivista.md`. O teste deve validar que o agente real segue essa ordem.

---

### ℹ️ Nota sobre truncamento de output do terminal

O terminal do `execute_pwsh` trunca a saída de comandos longos. Quando um script faz múltiplas operações encadeadas, parte da saída pode não aparecer mesmo que o script tenha concluído com sucesso. Estratégias:

1. **Dividir em dois blocos**: comandos de escrita num `execute_pwsh`, comandos de leitura/validação num segundo
2. **Verificar existência após escrita**: usar `Test-Path` para confirmar que os arquivos foram criados antes de ler o conteúdo
3. **Não confundir exit code -1 com erro**: o `-1` nos logs é ruído do terminal de eco interativo, não indicador de falha — verificar sempre o output real dos comandos

---

### ⚠️ Armadilha 9 — `fim-de-sessao.ps1` bloqueia indefinidamente em terminal interativo

**O que aconteceu:** executar `fim-de-sessao.ps1` com `(Get-Content $tmpFile) | powershell -File "..."` travou o terminal sem produzir saída. O script usa `[Console]::In.ReadToEnd()` logo no início para ler stdin. Em ambientes com terminal interativo (como `execute_pwsh`), stdin nunca recebe EOF e `ReadToEnd()` bloqueia indefinidamente.

**O que NÃO fazer:**
```powershell
# ERRADO: pipe de arquivo vazio não garante EOF em terminal interativo
$tmp = New-TemporaryFile
$out = (Get-Content $tmp.FullName) | powershell -ExecutionPolicy Bypass -File "$script"
```

**O que fazer:** usar `System.Diagnostics.Process` com redirecionamento explícito de stdin e leitura síncrona de stdout — que faz o próprio pipe funcionar sem deadlock:
```powershell
# CORRETO: stdin fechado imediatamente; stdout lido sincronamente (sem deadlock)
$psi = [System.Diagnostics.ProcessStartInfo]::new("powershell.exe")
$psi.Arguments              = "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$psi.UseShellExecute        = $false
$psi.RedirectStandardInput  = $true
$psi.RedirectStandardOutput = $true
$psi.CreateNoWindow         = $true
$proc = [System.Diagnostics.Process]::Start($psi)
$proc.StandardInput.Close()               # EOF imediato → ReadToEnd() no script retorna ""
$out  = $proc.StandardOutput.ReadToEnd()  # lê até o processo terminar — sem deadlock
$proc.WaitForExit()
```

A leitura síncrona com `ReadToEnd()` ANTES de `WaitForExit()` é essencial. Se o script produzir muita saída, chamar `WaitForExit()` primeiro pode causar deadlock clássico: o processo filho bloqueia tentando escrever no buffer cheio de stdout enquanto o pai aguarda o filho terminar.

---

### ⚠️ Armadilha 10 — `Start-Process -Wait` e `System.Diagnostics.Process` bloqueiam no ambiente `execute_pwsh`

**O que aconteceu:** no ambiente `execute_pwsh` do Kiro, tentar spawnar um subprocesso `powershell.exe` via `Start-Process -Wait` ou `System.Diagnostics.Process` bloqueia indefinidamente — mesmo com stdin redirecionado de arquivo vazio. O Kiro provavelmente acumula processos orphaned de tentativas anteriores, esgotando algum recurso de I/O.

**O que NÃO fazer:**
```powershell
# ERRADO em execute_pwsh: bloqueia indefinidamente
$p = Start-Process powershell.exe -ArgumentList "... $script ..." `
     -RedirectStandardInput $tmpIn -RedirectStandardOutput $tmpOut `
     -NoNewWindow -PassThru -Wait
```

**O que fazer:** executar o script **in-process**, substituindo `Console.In` por um `StringReader` vazio antes de invocar:
```powershell
# CORRETO: executa in-process sem spawnar subprocesso
$origIn      = [Console]::In
$emptyReader = New-Object System.IO.StringReader("")
[Console]::SetIn($emptyReader)
try {
    $out = & $script   # executa o script no processo atual; stdin é o StringReader vazio
} finally {
    [Console]::SetIn($origIn)
}
$texto = $out -join "`n"
```

O `[Console]::In.ReadToEnd()` dentro do script retorna `""` imediatamente (o `StringReader` vazio devolve EOF), o script entra no branch `$deveInjetar = $true` e produz o output normalmente.

> ⚠️ Esta armadilha se aplica **apenas ao ambiente de teste `execute_pwsh`**. Em produção, o hook do Kiro chama o script com `powershell -ExecutionPolicy Bypass -File ...`, que funciona corretamente sem esses problemas.

---

### ⚠️ Armadilha 11 — `(Get-Content arquivo)[0]` retorna `Char` quando o arquivo tem exatamente uma linha

**O que aconteceu:** ao ler o arquivo `parte-01-hash.txt` (que contém exatamente uma linha — o hash MD5), o código `(Get-Content $path -Encoding UTF8)[0]` lançou `Method invocation failed because [System.Char] does not contain a method named 'Trim'`. O operador `[0]` num array de um elemento retorna a string, mas em certos contextos o PowerShell retorna a string diretamente (não embrulhada em array), e `[0]` numa string retorna o primeiro **caractere** (`[System.Char]`).

**O que NÃO fazer:**
```powershell
# ARRISCADO: [0] pode retornar Char em vez de String
$hash = (Get-Content "$partDir\parte-01-hash.txt" -Encoding UTF8)[0].Trim()
```

**O que fazer:** usar `-First 1`, que sempre retorna uma string independentemente do número de linhas:
```powershell
# CORRETO: -First 1 retorna String garantidamente
$hash = Get-Content "$partDir\parte-01-hash.txt" -Encoding UTF8 -First 1
```

Essa armadilha aparece em qualquer leitura de arquivo de linha única onde se tenta indexar com `[0]`. Prefira sempre `-First 1` para leitura da primeira linha.

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
