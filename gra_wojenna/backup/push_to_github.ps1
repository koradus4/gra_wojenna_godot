# Script do eksportu projektu Godot na GitHub
# Uruchom z poziomu folderu gra_wojenna

param(
    [string]$CommitMessage = "",
    [string]$Branch = "",
    [string]$Remote = "origin",
    [switch]$Force,
    [switch]$ForcePush
)

if ([string]::IsNullOrWhiteSpace($CommitMessage)) {
    $CommitMessage = "Auto backup: " + (Get-Date -Format "yyyy-MM-dd_HH-mm-ss")
}

Write-Host "=== Eksport projektu Godot na GitHub ===" -ForegroundColor Cyan

function RunGit {
    param(
        [string]$Args,
        [switch]$Silent
    )
    Write-Host "> git $Args" -ForegroundColor DarkGray
    $output = Invoke-Expression "git $Args"
    if (-not $Silent -and $output) { $output }
    return $LASTEXITCODE
}

if (-not (Test-Path ".git")) {
    Write-Host "Nie znaleziono repozytorium git – uruchom skrypt w katalogu głównym projektu." -ForegroundColor Red
    exit 1
}

if (-not $Branch) {
    $Branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    if (-not $Branch) { $Branch = "main" }
}
Write-Host "Gałąź: $Branch" -ForegroundColor Cyan

Write-Host "`nStatus repozytorium:" -ForegroundColor Green
git status

function WorkingTreeDirty {
    $status = git status --porcelain
    return [bool]$status
}

$dirty = WorkingTreeDirty
if ($dirty) {
    Write-Host "Dodawanie zmian (git add -A)..." -ForegroundColor Green
    RunGit "add -A" | Out-Null
} else {
    Write-Host "Brak zmian w working tree." -ForegroundColor Yellow
}

$staged = (git diff --cached --name-only).Trim()
if ($staged) {
    $commitSafe = $CommitMessage -replace "'","''"
    Write-Host "Tworzenie commita: $CommitMessage" -ForegroundColor Green
    RunGit "commit -m '$commitSafe'" | Out-Null
} elseif ($ForcePush) {
    Write-Host "ForcePush bez staged zmian – commit pominięty." -ForegroundColor Yellow
} else {
    Write-Host "Brak staged zmian – nic do commitowania." -ForegroundColor Yellow
}

$remoteList = (git remote) -split "`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ }
if ($remoteList -notcontains $Remote) {
    Write-Host "Remote '$Remote' nie istnieje. Skonfiguruj go poleceniem: git remote add $Remote <twoj_URL>" -ForegroundColor Red
    exit 1
}

$pushCmd = "push $Remote $Branch"
if ($Force) { $pushCmd += " --force-with-lease" }
Write-Host "Wysyłanie: git $pushCmd" -ForegroundColor Green
RunGit $pushCmd | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Push zakończony sukcesem" -ForegroundColor Green
} else {
    Write-Host "✗ Push nieudany – sprawdź log powyżej" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "Ostatni commit:" -ForegroundColor Cyan
git log -1 --oneline
