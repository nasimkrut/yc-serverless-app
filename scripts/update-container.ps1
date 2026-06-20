param(
    [string]$Tag = "latest"
)

. "$PSScriptRoot\..\infra\variables.ps1"
$IMAGE = "cr.yandex/$REGISTRY_ID/guestbook-backend:$Tag"

Write-Host "==> Building Docker image: $IMAGE"
docker build -t $IMAGE "$PSScriptRoot\..\backend"
if ($LASTEXITCODE -ne 0) { Write-Error "Docker build failed"; exit 1 }

Write-Host "==> Authenticating with Container Registry..."
yc container registry configure-docker
if ($LASTEXITCODE -ne 0) { Write-Error "Registry auth failed"; exit 1 }

Write-Host "==> Pushing image..."
docker push $IMAGE
if ($LASTEXITCODE -ne 0) { Write-Error "Docker push failed"; exit 1 }

Write-Host "==> Deploying new container revision..."
yc serverless container revision deploy `
    --container-id $CONTAINER_ID `
    --image $IMAGE `
    --cores 1 `
    --memory 256MB `
    --concurrency 4 `
    --execution-timeout 15s `
    --service-account-id $SA_ID `
    --environment YDB_ENDPOINT=$YDB_ENDPOINT `
    --environment YDB_DATABASE=$YDB_DATABASE
if ($LASTEXITCODE -ne 0) { Write-Error "Container deploy failed"; exit 1 }

Write-Host "==> Done! Backend container updated."
