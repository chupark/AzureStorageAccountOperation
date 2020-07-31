# Azure Storage Account의 API를 사용한 Storage Operation

## 컨텐츠
현재는 주로 NoSQL 형식의 Storage Table을 위주로 작성되었습니다.
1. [Table 사용 방법](#table-%EC%82%AC%EC%9A%A9-%EB%B0%A9%EB%B2%95)
    * [Storage Account 인증](#1-storage-account-%EC%9D%B8%EC%A6%9D)

## Table 사용 방법
RDB에서 말하는 Row는 Azure Storage Table에선 Entity 라고 부릅니다. Entity의 최대 크기는 1MB이며, Azure Cosmos DB사용시 2MB까지 지정할 수 있습니다.
Entity의 속성은 최대 255개를 입력할 수 있으며 "PartitionKey", "RowKey"는 반드시 입력해야 할 시스템 속성 입니다. 또 다른 시스템 속성으로 timestamp로 사용자가 직접 지정하거나 데이터가 입력된 시간으로 지정됩니다.
- PartitionKey(PK) : 데이터가 저장될 파티션
- RowKey(RK) : 인덱스

Table Storage는 데이터베이스인 만큼 성능 향상을 고려하여 PartitionKey를 사용자가 수동으로 입력해야 합니다. 모든 데이터에 다른 파티션키를 입력해도 안되고, 모든 데이터에 같은 파티션 키를 입력해도 안됩니다. 아래 설명과 예시를 통해서 PartitionKey와 RowKey를 어떻게 디자인 할 수 있는지 설명하겠습니다.
- 초고속 : PartitionKey와 RowKey를 직접 지정하여 쿼리, 이 경우는 Table Storage에게 데이터의 정확한 주소를 지정함으로써 가장 빠른 쿼리 속도를 보여줍니다.
- 고속 : PartitionKey를 지정하여 쿼리, 이 경우 Table Storage에게 데이터가 어느 파티션에 저장되어있는지 알려줌으로써 빠른 쿼리 속도를 보여줍니다.
- 양호 : RowKey만 사용, 이 경우 Table Storage는 데이터가 어느 파티션에 저장되어있는지 모르므로 모든 파티션, 모든 Storage 노드를 조회할 수 있으므로 쿼리 속도가 느리지만, 여전히 고유한 인덱스로 데이터를 조회하므로 속도가 양호합니다.   

<br>

따라서 최적의 속도를 만들어내기 위한 디자인이 필요하다. 아래는 예시   
![테이블 디자인](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/1.%20Table_design.png)   

출처 : [https://blog.maartenballiauw.be/post/2012/10/08/what-partitionkey-and-rowkey-are-for-in-windows-azure-table-storage.html](https://blog.maartenballiauw.be/post/2012/10/08/what-partitionkey-and-rowkey-are-for-in-windows-azure-table-storage.html)   

- 기본사항 더 추가 예정 

<br>

기본 사항을 알아봤으니 이제 이 모듈을 어떻게 사용할 수 있는지 알아봅니다.   

<br>

### 1. Storage Account 인증
Storage Account는 이름에 Account가 들어간 리소스 답게 Azure AD인증이 아닌 Storage Account이름, Shared Key 를 사용하여 인증 헤더를 만듭니다.
따라서 인증 헤더를 암호화할 Storage Account의 Shared Key정보를 입력해야 합니다.
자세한 정보 : [공유키로 권한 부여](https://docs.microsoft.com/ko-kr/rest/api/storageservices/authorize-with-shared-key)

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

### 2. 테이블 생성
인증 정보 입력이 완료됐으므로 모듈을 사용하여 Table 저장소를 만듭니다.

```powershell
$createStorage = $StorageTable.createTable('Sample')
$createStorage2 = $StorageTableByKey.createTable('Sample2')
```


![생성된 테이블](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/2.%20creat_table.png)   
<br>

### 3. 데이터 입력
테이블을 만들었으니 데이터를 입력할 차례 입니다. JSON 포맷으로 작성해야하며, PartitionKey, RowKey는 필수로 포함시켜야 합니다.

```powershell
$data = '{  
    "Address":"Mountain View",
    "Age":23,
    "AmountDue":200.23,
    "CustomerCode@odata.type":"Edm.Guid",
    "CustomerCode":"c9da6455-213d-42c9-9a79-3e9149a57833",
    "CustomerSince@odata.type":"Edm.DateTime",
    "CustomerSince":"2008-07-10T00:00:00",
    "IsActive":true,
    "NumberOfOrders@odata.type":"Edm.Int64",
    "NumberOfOrders":"255",
    "PartitionKey":"mypartitionkey",
    "RowKey":"myrowkey"
}'
$insertData = $StorageTable.insertData('Sample', $data)
$insertData2 = $StorageTableByKey.insertData('Sample2', $data)
```

### 4. 데이터 조회

Odata protocol에 맞춰서 데이터를 조회할 수 있습니다.
````powershell
$StorageTable.updateDataByQuery("Sample", $query, $updateData)
$query = "RowKey eq 'myrowkey' and NumberOfOrders eq 255"
$queryResult = $StorageTable.selectByQuery('Sample', $query) | ConvertFrom-Json
$queryResult.value
````

![데이터 조회](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/4.%20query_result.png)


### 5. 데이터 업데이트
데이터 업데이트는 PartitionKey와 RowKey를 정확히 알아야 업데이트 할 수 있습니다. 이 모듈에선 먼저 Odata쿼리를 사용하여 데이터를 조회 후 PK와 RK를 추출하여 해당되는 Entity를 업데이트 합니다.   

![데이터 업데이트](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/5.%20update1.png)

![데이터 업데이트 결과](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/6.%20update2.png)


### 6. 쿼리를 사용한 데이터 삭제
데이터 삭제도 업데이트와 마찬가지로 PK와 RK를 모두 알아야 합니다. Select -> Delete 방법을 사용합니다.

![데이터 삭제](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/7.%20delete_query.png)   

![데이터 결과](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/8.%20delete_query2.png)   



### 7. 테이블의 데이터 모두 삭제

테이블의 모든 데이터를 조회한 후 데이터를 삭제하는 방법을 사용합니다.
![데이터 삭제](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/9.%20delete_byTable1.png)   

![데이터 결과](https://raw.githubusercontent.com/chupark/AzureStorageAccountOperation/master/images/9.%20delete_byTable2.png)   


### 8. 테이블 삭제
