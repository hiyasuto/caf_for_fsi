// ============================================================================
// 監査ログアーカイブ用ストレージアカウント モジュール
// FISC 実26: ログの改竄防止（WORM保管）
// ============================================================================

targetScope = 'resourceGroup'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '実26: ログの改竄防止'
  ]
  description: 'イミュータブルストレージによる監査ログのWORM保管を提供する'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('ストレージアカウント名')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('デプロイ先のリージョン')
param location string = 'japaneast'

@description('リソースに付与するタグ')
param tags object = {}

@description('イミュータブルポリシーの保持期間（日数）')
@minValue(365)
param immutabilityPeriodInDays int = 730

// ============================================================================
// リソース: アーカイブ用ストレージアカウント（WORM保管）
// ============================================================================
resource archiveStorage 'Microsoft.Storage/storageAccounts@2025-01-01' = {
  name: storageAccountName
  location: location
  tags: union(tags, {
    'fisc-control': '実26'
    purpose: 'audit-log-archive'
  })
  kind: 'StorageV2'
  sku: {
    name: 'Standard_GRS'
  }
  properties: {
    accessTier: 'Cool'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
      bypass: 'AzureServices'
    }
    encryption: {
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

// ============================================================================
// リソース: Blob サービスの設定
// ============================================================================
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2025-01-01' = {
  parent: archiveStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 365
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 365
    }
  }
}

// ============================================================================
// リソース: 監査ログ用コンテナ（イミュータブルストレージ）
// FISC 実26: WORM（Write Once Read Many）による改竄防止
// ============================================================================
resource auditLogContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-01-01' = {
  parent: blobService
  name: 'audit-logs'
  properties: {
    publicAccess: 'None'
    immutableStorageWithVersioning: {
      enabled: true
    }
  }
}

// ============================================================================
// リソース: イミュータビリティポリシー
// FISC 実26: ログの改竄防止ポリシー（保持期間指定）
// ============================================================================
resource immutabilityPolicy 'Microsoft.Storage/storageAccounts/blobServices/containers/immutabilityPolicies@2025-01-01' = {
  parent: auditLogContainer
  name: 'default'
  properties: {
    immutabilityPeriodSinceCreationInDays: immutabilityPeriodInDays
    allowProtectedAppendWrites: true
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('ストレージアカウントのリソースID')
output storageAccountId string = archiveStorage.id

@description('監査ログコンテナ名')
output auditLogContainerName string = auditLogContainer.name
