<#
.SYNOPSIS
    Rolador de dados para Call of Cthulhu 7a Edicao.

.DESCRIPTION
    Rola d100 e compara com o valor de uma pericia, aplicando as regras
    da 7a edicao definidas em config.md:
      - Sucesso normal : resultado <= valor da pericia
      - Sucesso dificil: resultado <= metade do valor
      - Sucesso extremo: resultado <= um quinto do valor
      - Fumble         : 96-100 (ou 100 se a pericia for >= 50%)
      - Falha          : demais casos

    Dado bonus/penalidade: rola a dezena duas vezes.
      - Bonus     : usa a dezena MAIS BAIXA
      - Penalidade: usa a dezena MAIS ALTA
    Multiplos bonus e penalidades se cancelam.

    Tambem faz rolagens genericas de dados (ex: 1d6, 2d6+6, 1d4) via -Dados.

.PARAMETER Pericia
    Valor percentual da pericia/caracteristica a testar (1-100).

.PARAMETER Nome
    Nome da pericia, so para exibicao (opcional).

.PARAMETER Bonus
    Quantidade de dados bonus (padrao 0).

.PARAMETER Penalidade
    Quantidade de dados penalidade (padrao 0).

.PARAMETER Dados
    Rolagem generica no formato NdX+M (ex: "1d100", "2d6+6", "1d4", "3d6*5").
    Quando usado, ignora -Pericia e so mostra o total rolado.

.EXAMPLE
    .\rolar.ps1 -Pericia 45 -Nome "Investigar"

.EXAMPLE
    .\rolar.ps1 -Pericia 55 -Nome "Escutar" -Penalidade 1

.EXAMPLE
    .\rolar.ps1 -Dados "2d6+6"
#>
[CmdletBinding(DefaultParameterSetName = 'Pericia')]
param(
    [Parameter(ParameterSetName = 'Pericia', Position = 0)]
    [ValidateRange(1, 100)]
    [int]$Pericia,

    [Parameter(ParameterSetName = 'Pericia', Position = 1)]
    [string]$Nome = "Teste",

    [Parameter(ParameterSetName = 'Pericia')]
    [ValidateRange(0, 3)]
    [int]$Bonus = 0,

    [Parameter(ParameterSetName = 'Pericia')]
    [ValidateRange(0, 3)]
    [int]$Penalidade = 0,

    [Parameter(ParameterSetName = 'Dados', Mandatory = $true)]
    [string]$Dados
)

function Get-DieRoll {
    param([int]$Faces)
    return Get-Random -Minimum 1 -Maximum ($Faces + 1)
}

# ----------------------------------------------------------------------
# MODO 1: rolagem generica de dados (NdX+M, NdX*M)
# ----------------------------------------------------------------------
if ($PSCmdlet.ParameterSetName -eq 'Dados') {
    $expr = $Dados.Trim().ToLower() -replace '\s', ''
    if ($expr -notmatch '^(\d+)d(\d+)([\+\-\*]\d+)?$') {
        Write-Error "Formato invalido. Use algo como 1d100, 2d6+6, 3d6*5, 1d4."
        exit 1
    }
    $count    = [int]$Matches[1]
    $faces    = [int]$Matches[2]
    $modifier = $Matches[3]

    $rolls = for ($i = 0; $i -lt $count; $i++) { Get-DieRoll -Faces $faces }
    $sum   = ($rolls | Measure-Object -Sum).Sum

    $total = $sum
    if ($modifier) {
        $op  = $modifier[0]
        $val = [int]$modifier.Substring(1)
        switch ($op) {
            '+' { $total = $sum + $val }
            '-' { $total = $sum - $val }
            '*' { $total = $sum * $val }
        }
    }

    Write-Host ""
    Write-Host "  Rolagem: $Dados" -ForegroundColor Cyan
    Write-Host "  Dados  : $($rolls -join ', ')  (soma $sum)" -ForegroundColor DarkGray
    Write-Host "  TOTAL  : $total" -ForegroundColor White
    Write-Host ""
    exit 0
}

# ----------------------------------------------------------------------
# MODO 2: teste de pericia d100 (regras CoC 7e)
# ----------------------------------------------------------------------

# A dezena vai de 00 a 90; a unidade de 0 a 9. "00" na dezena + "0" = 100.
function Get-TensDie { return (Get-Random -Minimum 0 -Maximum 10) * 10 }  # 0,10,...,90
$unitDie = Get-Random -Minimum 0 -Maximum 10                              # 0..9

# Resolve dados bonus/penalidade: eles se cancelam.
$net = $Bonus - $Penalidade
$tensRolls = @(Get-TensDie)
for ($i = 1; $i -lt [math]::Abs($net); $i++) { $tensRolls += Get-TensDie }

if ($net -gt 0) {
    $chosenTens = ($tensRolls | Measure-Object -Minimum).Minimum   # bonus -> menor dezena
    $tipo = "$net dado(s) BONUS"
}
elseif ($net -lt 0) {
    $chosenTens = ($tensRolls | Measure-Object -Maximum).Maximum   # penalidade -> maior dezena
    $tipo = "$([math]::Abs($net)) dado(s) PENALIDADE"
}
else {
    $chosenTens = $tensRolls[0]
    $tipo = "normal"
}

# Monta o resultado. 0 + 0 = 100 (nao 00).
$result = $chosenTens + $unitDie
if ($result -eq 0) { $result = 100 }

# Limiares de sucesso
$dificil = [math]::Floor($Pericia / 2)
$extremo = [math]::Floor($Pericia / 5)

# Determina grau (fumble tem prioridade)
$fumbleFloor = if ($Pericia -ge 50) { 100 } else { 96 }
if ($result -ge $fumbleFloor -and $result -ge 96) {
    $grau = "FUMBLE (falha critica)"
    $cor  = "Red"
}
elseif ($result -le $extremo) {
    $grau = "SUCESSO EXTREMO"
    $cor  = "Green"
}
elseif ($result -le $dificil) {
    $grau = "SUCESSO DIFICIL"
    $cor  = "Green"
}
elseif ($result -le $Pericia) {
    $grau = "SUCESSO NORMAL"
    $cor  = "Green"
}
else {
    $grau = "FALHA"
    $cor  = "Yellow"
}

Write-Host ""
Write-Host "  $Nome ($Pericia%)" -ForegroundColor Cyan
if ($tipo -ne "normal") {
    Write-Host "  Modo    : $tipo  (dezenas roladas: $($tensRolls -join ', '))" -ForegroundColor DarkGray
}
Write-Host "  Limiares: dificil <=$dificil  |  extremo <=$extremo  |  fumble >=$fumbleFloor" -ForegroundColor DarkGray
Write-Host "  Rolagem : $result" -ForegroundColor White
Write-Host "  >>> $grau" -ForegroundColor $cor
Write-Host ""
