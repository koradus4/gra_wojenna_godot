# Script do eksportu projektu Godot na GitHub
# Uruchom z poziomu folderu gra_wojenna

param(
    [string]$CommitMessage = "Update: Godot hex map implementation"
)

Write-Host "=== Eksport projektu Godot na GitHub ===" -ForegroundColor Cyan

# Sprawdź czy jesteśmy w repozytorium git
if (-not (Test-Path ".git")) {
    Write-Host "BŁĄD: Nie znaleziono repozytorium git!" -ForegroundColor Red
    Write-Host "Inicjalizuję nowe repozytorium..." -ForegroundColor Yellow
    git init
    Write-Host "Dodaj remote: git remote add origin <URL>" -ForegroundColor Yellow
    exit
}

# Sprawdź status
Write-Host "`nStatus repozytorium:" -ForegroundColor Green
git status

# Dodaj wszystkie pliki
Write-Host "`nDodawanie plików..." -ForegroundColor Green
git add .

# Commit
Write-Host "`nTworzenie commita: $CommitMessage" -ForegroundColor Green
git commit -m $CommitMessage

# Push
Write-Host "`nWysyłanie na GitHub..." -ForegroundColor Green
git push origin main

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Projekt pomyślnie wysłany na GitHub!" -ForegroundColor Green
} else {
    Write-Host "`n✗ Błąd podczas wysyłania. Sprawdź konfigurację remote." -ForegroundColor Red
    Write-Host "Użyj: git remote -v aby sprawdzić remote" -ForegroundColor Yellow
}

# Pokaż ostatni commit
Write-Host "`nOstatni commit:" -ForegroundColor Cyan
git log -1 --oneline
