. "$PSScriptRoot\..\infra\variables.ps1"

$FUNC_DIR = "$PSScriptRoot\..\ydb-init-function"
$ZIP_PATH = "$env:TEMP\ydb-init-function.zip"
$OBJECT_KEY = "deploy/ydb-init-function.zip"

Write-Host "==> Installing npm dependencies..."
Push-Location $FUNC_DIR
npm install --omit=dev
if ($LASTEXITCODE -ne 0) { Pop-Location; Write-Error "npm install failed"; exit 1 }
Pop-Location

Write-Host "==> Packaging function..."
if (Test-Path $ZIP_PATH) { Remove-Item $ZIP_PATH }
Compress-Archive -Path "$FUNC_DIR\*" -DestinationPath $ZIP_PATH
if ($LASTEXITCODE -ne 0) { Write-Error "Archive failed"; exit 1 }

Write-Host "==> Uploading zip to Object Storage (size limit workaround)..."
yc storage s3api put-object `
    --bucket $BUCKET_NAME `
    --key    $OBJECT_KEY `
    --body   $ZIP_PATH
if ($LASTEXITCODE -ne 0) { Write-Error "Upload to bucket failed"; exit 1 }

Write-Host "==> Deploying new function version from bucket $BUCKET_NAME / $OBJECT_KEY ..."
yc serverless function version create `
    --function-id        $FUNCTION_ID `
    --runtime            nodejs18 `
    --entrypoint         index.handler `
    --memory             128MB `
    --execution-timeout  30s `
    --package-bucket-name $BUCKET_NAME `
    --package-object-name $OBJECT_KEY `
    --service-account-id $SA_ID `
    --environment        YDB_ENDPOINT=$YDB_ENDPOINT `
    --environment        YDB_DATABASE=$YDB_DATABASE
if ($LASTEXITCODE -ne 0) { Write-Error "Function deploy failed"; exit 1 }

Write-Host "==> Cleaning up zip from bucket..."
yc storage s3api delete-object --bucket $BUCKET_NAME --key $OBJECT_KEY 2>&1 | Out-Null

Remove-Item $ZIP_PATH -ErrorAction SilentlyContinue
Write-Host "==> Done! YDB init function updated."
