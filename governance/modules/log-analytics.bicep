// ============================================================================
// 中央 Log Analytics ワークスペース モジュール
// FISC安全対策基準に対応するログ集約・分析基盤を構築
// ============================================================================

targetScope = 'resourceGroup'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '実25: アクセスログ等の取得、保管、分析'
    '実26: ログの改竄防止'
    '統20: クラウドサービス利用時の監視体制'
  ]
  description: '中央ログ基盤として、730日間のログ保持とSentinel統合を提供する'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('デプロイ先のリージョン')
param location string = 'japaneast'

@description('Log Analytics ワークスペース名')
param workspaceName string

@description('ログ保持期間（日数）。FISC実25では長期保持が要求される')
@minValue(365)
@maxValue(730)
param retentionInDays int = 730

@description('リソースに付与するタグ')
param tags object = {}

@description('Private Link スコープ名')
param privateLinkScopeName string = 'ampls-fsi-logs'

@description('Application Insights 名')
param appInsightsName string = ''

// ============================================================================
// リソース: Log Analytics ワークスペース
// FISC 実25: ログの集約・長期保管
// ============================================================================
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: workspaceName
  location: location
  tags: union(tags, {
    'fisc-control': '実25'
    purpose: 'central-logging'
  })
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: retentionInDays
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
      disableLocalAuth: true
    }
  }
}

// ============================================================================
// リソース: SecurityInsights (Microsoft Sentinel) ソリューション
// FISC 実25: セキュリティイベントの高度な分析
// ============================================================================
resource sentinelSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'SecurityInsights(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityInsights'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ============================================================================
// リソース: SecurityCenterFree ソリューション
// Defender for Cloud 無料プランの統合
// ============================================================================
resource securityCenterFreeSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'SecurityCenterFree(${logAnalyticsWorkspace.name})'
  location: location
  tags: tags
  plan: {
    name: 'SecurityCenterFree(${logAnalyticsWorkspace.name})'
    publisher: 'Microsoft'
    product: 'OMSGallery/SecurityCenterFree'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: logAnalyticsWorkspace.id
  }
}

// ============================================================================
// リソース: Azure Monitor Private Link Scope (AMPLS)
// FISC 実7: 閉域網でのログ収集
// ============================================================================
resource privateLinkScope 'Microsoft.Insights/privateLinkScopes@2021-09-01' = {
  name: privateLinkScopeName
  location: 'global'
  tags: union(tags, {
    'fisc-control': '実7'
    purpose: 'private-link-logging'
  })
  properties: {
    accessModeSettings: {
      ingestionAccessMode: 'PrivateOnly'
      queryAccessMode: 'PrivateOnly'
    }
  }
}

// ============================================================================
// リソース: AMPLS と Log Analytics ワークスペースの関連付け
// ============================================================================
resource privateLinkScopeConnection 'Microsoft.Insights/privateLinkScopes/scopedResources@2021-09-01' = {
  parent: privateLinkScope
  name: '${workspaceName}-connection'
  properties: {
    linkedResourceId: logAnalyticsWorkspace.id
  }
}

// ============================================================================
// リソース: ワークスペースベースの Application Insights
// FISC 実25: アプリケーションレベルのログ・テレメトリ
// ============================================================================
resource appInsights 'Microsoft.Insights/components@2020-02-02' = if (!empty(appInsightsName)) {
  name: !empty(appInsightsName) ? appInsightsName : 'appi-placeholder'
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    publicNetworkAccessForIngestion: 'Disabled'
    publicNetworkAccessForQuery: 'Disabled'
    RetentionInDays: 90
  }
}

// ============================================================================
// リソース: データ収集ルール - Windows セキュリティイベント
// FISC 実25: セキュリティイベントの収集
// ============================================================================
resource dcrWindowsSecurity 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: 'dcr-${workspaceName}-security'
  location: location
  tags: union(tags, {
    'fisc-control': '実25'
    purpose: 'security-event-collection'
  })
  properties: {
    description: 'FISC実25: Windowsセキュリティイベントの収集ルール'
    dataSources: {
      windowsEventLogs: [
        {
          streams: [
            'Microsoft-SecurityEvent'
          ]
          xPathQueries: [
            'Security!*[System[(EventID=4624 or EventID=4625 or EventID=4648 or EventID=4672 or EventID=4688 or EventID=4698 or EventID=4720 or EventID=4726 or EventID=4732 or EventID=4756)]]'
          ]
          name: 'securityEvents'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'centralWorkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-SecurityEvent'
        ]
        destinations: [
          'centralWorkspace'
        ]
      }
    ]
  }
}

// ============================================================================
// リソース: データ収集ルール - Syslog
// FISC 実25: Linux システムログの収集
// ============================================================================
resource dcrSyslog 'Microsoft.Insights/dataCollectionRules@2024-03-11' = {
  name: 'dcr-${workspaceName}-syslog'
  location: location
  tags: union(tags, {
    'fisc-control': '実25'
    purpose: 'syslog-collection'
  })
  properties: {
    description: 'FISC実25: Syslogの収集ルール'
    dataSources: {
      syslog: [
        {
          streams: [
            'Microsoft-Syslog'
          ]
          facilityNames: [
            'auth'
            'authpriv'
            'daemon'
            'kern'
            'syslog'
          ]
          logLevels: [
            'Warning'
            'Error'
            'Critical'
            'Alert'
            'Emergency'
          ]
          name: 'syslogDataSource'
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspace.id
          name: 'centralWorkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-Syslog'
        ]
        destinations: [
          'centralWorkspace'
        ]
      }
    ]
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('Log Analytics ワークスペースのリソースID')
output workspaceId string = logAnalyticsWorkspace.id

@description('Log Analytics ワークスペースの顧客ID')
output workspaceCustomerId string = logAnalyticsWorkspace.properties.customerId

@description('Log Analytics ワークスペース名')
output workspaceName string = logAnalyticsWorkspace.name

@description('Private Link Scope のリソースID')
output privateLinkScopeId string = privateLinkScope.id

@description('Application Insights のリソースID（作成された場合）')
output appInsightsId string = !empty(appInsightsName) ? appInsights.id : ''

@description('セキュリティイベントDCRのリソースID')
output securityDcrId string = dcrWindowsSecurity.id

@description('Syslog DCRのリソースID')
output syslogDcrId string = dcrSyslog.id
