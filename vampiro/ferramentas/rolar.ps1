<#
.SYNOPSIS
    Rolador de dados para Vampiro: A Mascara 5a Edicao (V5).

.DESCRIPTION
    Rola um conjunto (pool) de d10 e conta sucessos pelas regras da 5a edicao
    definidas em config.md:
      - 6 ou mais            : sucesso
      - 10                   : critico
      - cada PAR de 10s      : +2 sucessos extra (mesclagem critica);
                               ou seja, dois 10s valem 4 sucessos no total
      - Falha de Bestialidade: um Dado de Fome mostra 1
      - Extase               : um Dado de Fome mostra 10
      - Falha critica (bestial): metade ou mais dos dados mostram 1 E nenhum sucesso

    O pool se divide em dados comuns (-Pool) e Dados de Fome (-Fome). Os Dados de
    Fome fazem parte do mesmo pool e contam sucessos normalmente; a diferenca e
    que seus 1s e 10s tem consequencias narrativas (Bestialidade / Extase).

    Opcionalmente, uma Dificuldade (-Dificuldade) numero minimo de sucessos para
    o teste passar; o script indica se o teste foi vencido.

.PARAMETER Pool
    Total de dados do teste (atributo + habilidade + modificadores). 1-30.

.PARAMETER Fome
    Quantos dos dados do pool sao Dados de Fome (d10 vermelhos). Padrao 0.
    Nao pode exceder o Pool.

.PARAMETER Dificuldade
    Numero de sucessos exigido pelo teste (opcional). Quando informado, o script
    diz se o teste passou.

.PARAMETER Nome
    Nome do teste, so para exibicao (opcional).

.EXAMPLE
    .\rolar.ps1 -Pool 5 -Nome "Destreza + Atletismo"

.EXAMPLE
    .\rolar.ps1 -Pool 6 -Fome 2 -Dificuldade 3 -Nome "Forca + Briga"
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateRange(1, 30)]
    [int]$Pool,

    [Parameter(Position = 1)]
    [ValidateRange(0, 30)]
    [int]$Fome = 0,

    [ValidateRange(1, 30)]
    [int]$Dificuldade = 0,

    [string]$Nome = "Teste"
)

if ($Fome -gt $Pool) {
    Write-Error "Os Dados de Fome ($Fome) nao podem exceder o Pool total ($Pool)."
    exit 1
}

function Get-D10 { return Get-Random -Minimum 1 -Maximum 11 }  # 1..10

$normais = $Pool - $Fome
$rollsNormais = @(for ($i = 0; $i -lt $normais; $i++) { Get-D10 })
$rollsFome    = @(for ($i = 0; $i -lt $Fome;    $i++) { Get-D10 })
$todos        = @($rollsNormais + $rollsFome)

# Sucessos: 6+ conta 1. Pares de 10 adicionam +2 (mesclagem critica).
$sucessosBase = ($todos | Where-Object { $_ -ge 6 }).Count
$dezes        = ($todos | Where-Object { $_ -eq 10 }).Count
$paresDezes   = [math]::Floor($dezes / 2)
$sucessos     = $sucessosBase + ($paresDezes * 2)

# Sinais dos Dados de Fome
$fomeUns   = ($rollsFome | Where-Object { $_ -eq 1 }).Count
$fomeDezes = ($rollsFome | Where-Object { $_ -eq 10 }).Count

# Falha critica (bestial): metade ou mais de TODOS os dados sao 1 e nenhum sucesso
$totalUns = ($todos | Where-Object { $_ -eq 1 }).Count
$falhaCritica = ($sucessos -eq 0) -and ($totalUns -ge [math]::Ceiling($Pool / 2))

Write-Host ""
Write-Host "  $Nome  (pool $Pool, fome $Fome)" -ForegroundColor Cyan
if ($normais -gt 0) {
    Write-Host "  Dados comuns: $($rollsNormais -join ', ')" -ForegroundColor DarkGray
}
if ($Fome -gt 0) {
    Write-Host "  Dados fome  : $($rollsFome -join ', ')" -ForegroundColor DarkRed
}
if ($paresDezes -gt 0) {
    Write-Host "  Criticos    : $dezes dez(es) -> $paresDezes mesclagem(ns) critica(s) (+$($paresDezes * 2))" -ForegroundColor Magenta
}

Write-Host "  SUCESSOS    : $sucessos" -ForegroundColor White

if ($Dificuldade -gt 0) {
    if ($sucessos -ge $Dificuldade) {
        Write-Host "  >>> VITORIA (dif. $Dificuldade)" -ForegroundColor Green
    }
    else {
        Write-Host "  >>> FALHA (dif. $Dificuldade)" -ForegroundColor Yellow
    }
}

if ($falhaCritica) {
    Write-Host "  >>> FALHA CRITICA (bestial)" -ForegroundColor Red
}
if ($fomeDezes -gt 0) {
    Write-Host "  !!! EXTASE: $fomeDezes dado(s) de fome com 10 — sucesso com efeito colateral" -ForegroundColor DarkYellow
}
if ($fomeUns -gt 0) {
    Write-Host "  !!! FALHA DE BESTIALIDADE: $fomeUns dado(s) de fome com 1 — risco de frenesi" -ForegroundColor Red
}
Write-Host ""
