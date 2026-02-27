// ============================================================================
// リソースグループ作成モジュール（ヘルパー）
// ============================================================================

targetScope = 'subscription'

@description('リソースグループ名')
param resourceGroupName string

@description('デプロイ先のリージョン')
param location string

@description('リソースに付与するタグ')
param tags object = {}

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

@description('リソースグループのリソースID')
output resourceGroupId string = rg.id

@description('リソースグループ名')
output resourceGroupName string = rg.name
