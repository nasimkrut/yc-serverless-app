# Guestbook — Serverless на Yandex Cloud

Гостевая книга на ASP.NET Core 8 + plain JS, задеплоенная в Yandex Cloud с использованием serverless-технологий.

**Ссылка на приложение:** https://d5danb3cf8iu9172n5fi.6brbn2wz.apigw.yandexcloud.net

## Архитектура

```
Браузер
  └── API Gateway (HTTPS)
        ├── GET /          → Object Storage (index.html)
        ├── GET /{file}    → Object Storage (app.js, config.js, version.js)
        └── /api/{proxy+}  → Serverless Container (ASP.NET Core)
                                  └── Serverless YDB
```

- **Фронтенд** — статические файлы в Object Storage, раздаются через API Gateway
- **Бэкенд** — ASP.NET Core 8 в Serverless Container, несколько реплик за API Gateway
- **База данных** — Serverless YDB
- **UI показывает** версию фронта, версию бэкенда и ID инстанса (для демонстрации балансировки)

## Структура репозитория

```
├── backend/
│   ├── GuestbookApi/          # ASP.NET Core 8 Web API
│   ├── Ydb.Sdk.Yc.Auth/       # Shim для IAM-аутентификации в YDB
│   └── Dockerfile
├── frontend/
│   ├── index.html
│   ├── app.js
│   ├── version.js
│   └── config.js              # Генерируется при деплое (в .gitignore)
├── infra/
│   ├── api-gateway-spec.yaml  # Спецификация API Gateway
│   └── variables.ps1          # ID ресурсов YC
├── scripts/
│   ├── update-container.ps1   # Пересборка и деплой бэкенда
│   ├── update-function.ps1    # Деплой YDB init функции
│   └── init-ydb.ps1           # Создание схемы в YDB
└── ydb-init-function/         # Node.js функция создания схемы
```

## Необходимые роли сервисного аккаунта

| Роль | Зачем |
|------|-------|
| `ydb.editor` | Контейнер читает и пишет сообщения |
| `serverless.containers.invoker` | API Gateway вызывает контейнер |
| `container-registry.images.puller` | Контейнер скачивает образ |
| `storage.viewer` | API Gateway читает файлы фронтенда из бакета |

## Переменные в infra/variables.ps1

| Переменная | Описание |
|------------|----------|
| `$FOLDER_ID` | ID каталога YC |
| `$SA_ID` | ID сервисного аккаунта |
| `$REGISTRY_ID` | ID Container Registry |
| `$CONTAINER_ID` | ID Serverless Container |
| `$FUNCTION_ID` | ID Cloud Function (YDB init) |
| `$GATEWAY_ID` | ID API Gateway |
| `$GATEWAY_URL` | URL API Gateway |
| `$YDB_ENDPOINT` | Эндпоинт YDB |
| `$YDB_DATABASE` | Путь к базе данных |
| `$BUCKET_NAME` | Имя бакета Object Storage |

## Скрипты деплоя

Перед запуском добавь `yc` в PATH:
```powershell
$env:PATH += ";$env:USERPROFILE\yandex-cloud\bin"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Обновление бэкенда (Serverless Container)
```powershell
.\scripts\update-container.ps1
```
Собирает Docker-образ, пушит в Container Registry, деплоит новую ревизию контейнера.

### Обновление YDB init функции (Serverless Function)
```powershell
.\scripts\update-function.ps1
```
Устанавливает зависимости, архивирует функцию, загружает в Object Storage и деплоит.

### Создание схемы в YDB
```powershell
.\scripts\init-ydb.ps1
```
Вызывает Cloud Function, которая создаёт таблицу `messages` в YDB. Безопасно запускать повторно — если таблица уже существует, ничего не сломается.

### Загрузка фронтенда
```powershell
# Записать URL Gateway в config.js
"const API_URL = '$GATEWAY_URL';" | Out-File frontend\config.js -Encoding utf8

# Загрузить файлы в бакет
yc storage s3api put-object --bucket $BUCKET_NAME --key index.html --body frontend\index.html --content-type "text/html; charset=utf-8"
yc storage s3api put-object --bucket $BUCKET_NAME --key app.js     --body frontend\app.js     --content-type "application/javascript"
yc storage s3api put-object --bucket $BUCKET_NAME --key config.js  --body frontend\config.js  --content-type "application/javascript"
yc storage s3api put-object --bucket $BUCKET_NAME --key version.js --body frontend\version.js --content-type "application/javascript"
```

## Доступ для проверяющих

Каталог YC: https://console.yandex.cloud/folders/b1g8t842p2ib5lpude7u

Для добавления проверяющего:
```powershell
$userId = (yc iam user-account get <login> --format json | ConvertFrom-Json).id
yc resource-manager cloud add-access-binding --id b1gueeq8a77gl08ajgqh --role resource-manager.clouds.member --subject "userAccount:$userId"
yc resource-manager folder add-access-binding --id b1g8t842p2ib5lpude7u --role admin --subject "userAccount:$userId"
```
