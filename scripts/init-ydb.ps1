. "$PSScriptRoot\..\infra\variables.ps1"

Write-Host "==> Invoking YDB init function to create schema..."
$result = yc serverless function invoke $FUNCTION_ID --format json | ConvertFrom-Json
Write-Host "==> Result: $($result.response.body)"
Write-Host "==> Done! YDB schema initialized."
