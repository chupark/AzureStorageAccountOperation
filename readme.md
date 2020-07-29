# Azure Storage Account의 API를 사용한 Storage Operation

## 컨텐츠
현재는 주로 NoSQL 형식의 Storage Table을 위주로 작성되었습니다.

## Table 사용 방법

### 1. Storage Account 인증
Storage Account는 이름에 Account가 들어간 리소스 답게 Azure AD인증이 아닌 Storage Account이름, Shared Key 를 사용하여 인증 헤더를 만듭니다.
따라서 인증 헤더를 암호화할 Storage Account의 Shared Key정보를 입력해야 합니다.

```powershell
## 모듈 불러오기
Import-Module .\StorageOperation.psm1 -Force
Import-Module .\lib\SetAzAD.psm1 -Force


## 전역 변수
$clientCredType = 'client_credentials'
$clientResource = 'https://management.azure.com'


## 환경 설정 json 파일 불러오기
$config = Get-Content -Path .\config.json -Raw | ConvertFrom-Json


## Azure AD access_token 발급받기
$AzAdInfo = SetAzAD -tenant $config.AzureAD.tenant -subscription $config.AzureAD.subscription
$AzAdInfo.setToken($clientCredType, $config.AzureAD.clientId, $config.AzureAD.clientSecret, $clientResource)


## access_token을 사용하여 Storage의 Shared Key를 조회하여 인증
$StorageTable = StorageTableFromAD -azAdInfo $azAdInfo `
                                   -storageAccoutResourceGroup $config.Storage.StorageAccountResourceGroup `
                                   -storageAccoutName $config.Storage.StorageAccountName

## Storage의 이름과 Shared Key를 직접 사용하여 인증
$StorageTableByKey = StorageTable -storageAccoutName $config.Storage.StorageAccountName `
                                  -key $config.Storage.StorageAccountSharedKey
```

#### 테이블 생성