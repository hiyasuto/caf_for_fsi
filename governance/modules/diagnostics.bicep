// ============================================================================
// 診断設定モジュール
// FISC安全対策基準に対応するアクティビティログの転送・アーカイブ
// ============================================================================

targetScope = 'subscription'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '実25: アクセスログ等の取得、保管、分析'
    '実26: ログの改竄防止（WORM保管）'
    '統20: クラウドサービス利用時の監査証跡'
  ]
  description: 'アクティビティログをLog Analyticsとストレージに転送し、改竄防止を確保する'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('Log Analytics ワークスペースのリソースID')
param logAnalyticsWorkspaceId string

@description('アーカイブ用ストレージアカウントのリソースID。WORM保管に使用（空文字の場合はストレージへの転送をスキップ）')
param archiveStorageAccountId string = ''

@description('デプロイ先のリージョン')
param location string = 'japaneast'

@description('リソースに付与するタグ')
param tags object = {}

@description('アーカイブ用ストレージアカウントを作成するリソースグループ名')
param storageResourceGroupName string = ''

@description('アーカイブ用ストレージアカウント名')
param archiveStorageAccountName string = ''

@description('イミュータブルポリシーの保持期間（日数）')
@minValue(365)
param immutabilityPeriodInDays int = 730

// ============================================================================
// 変数
// ============================================================================

var createArchiveStorage = !empty(archiveStorageAccountName) && !empty(storageResourceGroupName)

// ============================================================================
// リソース: アクティビティログの診断設定
// FISC 実25: アクティビティログをLog Analyticsに転送
// ============================================================================
resource activityLogDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'fisc-activity-log-diagnostics'
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    storageAccountId: !empty(archiveStorageAccountId) ? archiveStorageAccountId : null
    logs: [
      {
        // FISC 実25: セキュリティ関連のアクティビティ
        category: 'Security'
        enabled: true
      }
      {
        // FISC 実25: 管理操作の追跡
        category: 'Administrative'
        enabled: true
      }
      {
        // FISC 実25: サービス正常性の監視
        category: 'ServiceHealth'
        enabled: true
      }
      {
        // FISC 実25: アラートの記録
        category: 'Alert'
        enabled: true
      }
      {
        // FISC 統20: 推奨事項の追跡
        category: 'Recommendation'
        enabled: true
      }
      {
        // FISC 統20: ポリシー準拠状況の追跡
        category: 'Policy'
        enabled: true
      }
      {
        // 自動スケーリングの記録
        category: 'Autoscale'
        enabled: true
      }
      {
        // リソース正常性の監視
        category: 'ResourceHealth'
        enabled: true
      }
    ]
  }
}

// ============================================================================
// モジュール: アーカイブ用ストレージアカウント（WORM保管）
// FISC 実26: ログの改竄防止
// リソースグループスコープでデプロイ
// ============================================================================
module archiveStorageModule 'audit-storage.bicep' = if (createArchiveStorage) {
  name: 'deploy-audit-storage'
  scope: resourceGroup(storageResourceGroupName)
  params: {
    storageAccountName: archiveStorageAccountName
    location: location
    tags: tags
    immutabilityPeriodInDays: immutabilityPeriodInDays
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('アクティビティログ診断設定のリソースID')
output diagnosticSettingId string = activityLogDiagnostics.id

@description('アーカイブストレージアカウントのリソースID')
output archiveStorageId string = createArchiveStorage ? archiveStorageModule.outputs.storageAccountId! : ''

@description('転送先カテゴリ一覧')
output enabledCategories array = [
  'Security'
  'Administrative'
  'ServiceHealth'
  'Alert'
  'Recommendation'
  'Policy'
  'Autoscale'
  'ResourceHealth'
]
