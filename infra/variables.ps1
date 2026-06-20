# Yandex Cloud IDs — managed by setup.ps1
$FOLDER_ID    = "b1g8t842p2ib5lpude7u"
$CLOUD_ID     = "b1gueeq8a77gl08ajgqh"

$SA_NAME      = "guestbook-sa"
$SA_ID        = ""
$REGISTRY_ID  = ""
$CONTAINER_ID = ""
$FUNCTION_ID  = ""
$GATEWAY_ID   = ""
$GATEWAY_URL  = ""   # https://<GATEWAY_ID>.apigw.yandexcloud.net

$YDB_ENDPOINT = ""   # grpcs://ydb.serverless.yandexcloud.net:2135
$YDB_DATABASE = ""   # /ru-central1/<cloud-id>/<db-id>

$BUCKET_NAME  = "guestbook-frontend"
$IMAGE_NAME   = "cr.yandex/$REGISTRY_ID/guestbook-backend:latest"
