. "$PSScriptRoot\..\infra\variables.ps1"

$FUNC_DIR = "$PSScriptRoot\..\ydb-init-function"
$ZIP_PATH = "$env:TEMP\ydb-init-function.zip"

Write-Host "==> Installing npm dependencies..."
Push-Location $FUNC_DIR
npm install --omit=dev
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "npm install failed"; exit 1 }
Pop-Location

Write-Host "==> Packaging function..."
if (Test-Path $ZIP_PATH) { Remove-Item $ZIP_PATH }
Compress-Archive -Path "$FUNC_DIR\*" -DestinationPath $ZIP_PATH
if ($LASTEXITCODE -ne 0) { Write-Error "Archive failed"; exit 1 }

Write-Host "==> Deploying new function version..."
yc serverless function version create `
    --function-id $FUNCTION_ID `
    --runtime nodejs18 `
    --entrypoint index.handler `
    --memory 128MB `
    --execution-timeout 30s `
    --source-path $ZIP_PATH `
    --service-account-id $SA_ID `
    --environment YDB_ENDPOINT=$YDB_ENDPOINT `
    --environment YDB_DATABASE=$YDB_DATABASE
if ($LASTEXITCODE -ne 0) { Write-Error "Function deploy failed"; exit 1 }

Remove-Item $ZIP_PATH
Write-Host "==> Done! YDB init function updated."
