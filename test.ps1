Import-Module .\StorageOperation.psm1 -Force
Import-Module .\lib\SetAzAD.psm1 -Force

$config = Get-Content -Path .\config.json -Raw | ConvertFrom-Json
$clientCredType = 'client_credentials'
$clientResource = 'https://management.azure.com'

$AzAdInfo = SetAzAD -tenant $config.AzureAD.tenant -subscription $config.AzureAD.subscription
$AzAdInfo.setToken($clientCredType, $config.AzureAD.clientId, $config.AzureAD.clientSecret, $clientResource)

## Get Storage Shared Key with AD access_token
$StorageTable = StorageTableFromAD -azAdInfo $azAdInfo `
                                   -storageAccoutResourceGroup $config.Storage.StorageAccountResourceGroup `
                                   -storageAccoutName $config.Storage.StorageAccountName

## Get Storage
$StorageTableByKey = StorageTable -storageAccoutName $config.Storage.StorageAccountName `
                                  -key $config.Storage.StorageAccountSharedKey


## Storage Operation
$createStorage = $StorageTable.createTable('Sample')
$createStorage2 = $StorageTableByKey.createTable('Sample2')


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
    "PartitionKey":"mypartitionkey4",
    "RowKey":"myrowkey"
}'
$insertData = $StorageTable.insertData('Sample', $data)
$insertData2 = $StorageTableByKey.insertData('Sample2', $data)

$insertData

$query = "RowKey eq 'myrowkey' and NumberOfOrders eq 255"
$queryResult = $StorageTable.selectByQuery('Sample', $query) | ConvertFrom-Json
$queryResult.value

$updateData = '{  
    "Address":"Mountain View",
    "Age":25,
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

$StorageTable.updateDataByQuery("Sample", $query, $updateData)
$query = "RowKey eq 'myrowkey' and NumberOfOrders eq 255"
$queryResult = $StorageTable.selectByQuery('Sample', $query) | ConvertFrom-Json
$queryResult.value


$StorageTable.deleteDataByTable('Sample')
$StorageTable.deleteDataByTable('Sample2')


$StorageTable.deleteDataByQuery('Sample', $query)
$StorageTable.selectByTable('Sample')


$deleteTable = $StorageTable.deleteTable('Sample')
$deleteTable2 = $StorageTable.deleteTable('Sample2')