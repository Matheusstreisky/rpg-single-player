# fim-de-sessao.ps1
# Disparado pelo hook rpg-fim-de-sessao ao detectar a frase-gatilho do jogador.
# Le os 3 arquivos de agentes e combina as instrucoes num prompt unico,
# injetado no contexto do Kiro via stdout (exit 0).
#
# Tambem verifica o conteudo do stdin (JSON com contexto da sessao) para
# confirmar que a mensagem atual contem a frase-gatilho antes de injetar.
# Isso evita falsos positivos caso o matcher do hook avalie contexto mais amplo.

param()

# --- Verificacao secundaria via stdin ---
$deveInjetar = $false
try {
    $stdinRaw = [Console]::In.ReadToEnd()
    if ($stdinRaw -and $stdinRaw.Trim() -ne "") {
        $ctx = $stdinRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
        # Tenta extrair o texto da mensagem atual em campos comuns
        $msgTexto = ""
        if ($ctx.PSObject.Properties["message"])      { $msgTexto = $ctx.message }
        elseif ($ctx.PSObject.Properties["userMessage"]) { $msgTexto = $ctx.userMessage }
        elseif ($ctx.PSObject.Properties["prompt"])   { $msgTexto = $ctx.prompt }
        elseif ($ctx.PSObject.Properties["content"])  { $msgTexto = $ctx.content }

        if ($msgTexto -imatch "fim\s+da?\s+sess[aã]o|encerrar(\s+a)?\s+sess[aã]o|finalizar(\s+a)?\s+sess[aã]o") {
            $deveInjetar = $true
        }
    } else {
        # Sem stdin util: confia no matcher do hook e injeta
        $deveInjetar = $true
    }
} catch {
    # Falha ao ler/parsear stdin: confia no matcher do hook e injeta
    $deveInjetar = $true
}

if (-not $deveInjetar) {
    # Nao e uma mensagem de fim de sessao — nao injeta nada
    exit 0
}

# --- Leitura dos arquivos de agentes ---
$raiz = Split-Path -Parent $PSScriptRoot

$passo1 = Get-Content "$raiz\agentes\rpg-acontecimentos.md" -Raw -Encoding UTF8
$passo2 = Get-Content "$raiz\agentes\rpg-memorias.md"      -Raw -Encoding UTF8
$passo3 = Get-Content "$raiz\agentes\rpg-estado.md"        -Raw -Encoding UTF8

# --- Saida combinada para o Kiro ---
$prompt = @"
O jogador sinalizou o fim de sessao. Execute os tres agentes de memoria em lote, na ordem abaixo.
Processe TODOS os turnos desta sessao ainda nao registrados nos arquivos — nao apenas o ultimo turno.

================================================================
PASSO 1 DE 3 — AGENTE: rpg-acontecimentos
================================================================
$passo1

================================================================
PASSO 2 DE 3 — AGENTE: rpg-memorias
================================================================
$passo2

================================================================
PASSO 3 DE 3 — AGENTE: rpg-estado
================================================================
$passo3

================================================================
Ao concluir os 3 passos, informe de forma compacta:
- Quais arquivos foram atualizados
- Quais turnos foram registrados (ou que ja estavam em dia)
Confirme o encerramento da sessao ao jogador.
================================================================
"@

Write-Output $prompt
exit 0
