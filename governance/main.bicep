// ============================================================================
// FISC準拠 Azure ガバナンスベース - メインオーケストレーション
// 金融機関向け Azure ランディングゾーンのガバナンス基盤を構築する
//
// このテンプレートは、FISC安全対策基準（第13版）に対応する
// Azure のガバナンス構成を管理グループスコープでデプロイします。
// ============================================================================

targetScope = 'managementGroup'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  version: '1.0.0'
  description: '金融機関向けAzureガバナンスベースライン'
  controls: [
    '実1: アクセス制御'
    '実7: ネットワークセキュリティ'
    '実13: 暗号化'
    '実25: ログ管理'
    '実26: ログ改竄防止'
    '実39: バックアップ'
    '実150: AIガバナンス'
    '統20: クラウドガバナンス'
  ]
}

// ============================================================================
// パラメータ
// ============================================================================

@description('組織の接頭辞。管理グループやリソースの命名規則に使用')
@minLength(2)
@maxLength(10)
param organizationPrefix string = 'fsi'

@description('環境名（prod / staging / dev）')
@allowed([
  'prod'
  'staging'
  'dev'
])
param environment string = 'prod'

@description('プライマリリージョン（東日本）')
param primaryLocation string = 'japaneast'

@description('DRリージョン（西日本）')
param drLocation string = 'japanwest'

@description('テナントルートグループの管理グループID')
param tenantRootGroupId string

@description('管理用サブスクリプションID（Log Analytics, Defender等のデプロイ先）')
param managementSubscriptionId string

@description('管理用リソースグループ名')
param managementResourceGroupName string = 'rg-${organizationPrefix}-management-${environment}'

@description('Log Analytics ワークスペース名')
param logAnalyticsWorkspaceName string = 'law-${organizationPrefix}-central-${environment}'

@description('ログ保持期間（日数）。FISC実25: 730日推奨')
@minValue(365)
@maxValue(730)
param logRetentionInDays int = 730

@description('セキュリティ連絡先メールアドレス')
param securityContactEmail string

@description('セキュリティ連絡先電話番号')
param securityContactPhone string = ''

@description('Application Insights 名（空文字で作成しない）')
param appInsightsName string = 'appi-${organizationPrefix}-central-${environment}'

@description('アーカイブ用ストレージアカウント名（WORM保管用）')
@minLength(3)
@maxLength(24)
param archiveStorageAccountName string

@description('デプロイタイムスタンプ（一意性確保用）')
param deploymentTimestamp string = utcNow()

@description('リソースに付与する共通タグ')
param tags object = {
  environment: environment
  managedBy: 'bicep'
  complianceFramework: 'FISC'
  organization: organizationPrefix
}

// ============================================================================
// モジュール: 管理グループ階層
// FISC 統20: クラウドガバナンス体制の確立
// ============================================================================
module managementGroups 'modules/management-groups.bicep' = {
  name: 'deploy-management-groups-${deploymentTimestamp}'
  scope: tenant()
  params: {
    organizationPrefix: organizationPrefix
    parentManagementGroupId: tenantRootGroupId
  }
}

// ============================================================================
// モジュール: Azure Policy 割り当て
// FISC 実1/実7/実13/実25/実39/実150/統20
// ============================================================================
module policyAssignments 'modules/policy-assignments.bicep' = {
  name: 'deploy-policy-assignments-${deploymentTimestamp}'
  scope: managementGroup()
  params: {
    targetManagementGroupName: managementGroups.outputs.rootManagementGroupName
    allowedLocations: [
      primaryLocation
      drLocation
    ]
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
  }
}

// ============================================================================
// モジュール: 管理リソースグループ作成
// Log Analytics やストレージアカウントのデプロイ先
// ============================================================================
module managementResourceGroup 'modules/resource-group.bicep' = {
  name: 'deploy-mgmt-rg-${deploymentTimestamp}'
  scope: subscription(managementSubscriptionId)
  params: {
    resourceGroupName: managementResourceGroupName
    location: primaryLocation
    tags: tags
  }
}

// ============================================================================
// モジュール: 中央 Log Analytics ワークスペース
// FISC 実25: ログの集約・長期保管
// ============================================================================
module logAnalytics 'modules/log-analytics.bicep' = {
  name: 'deploy-log-analytics-${deploymentTimestamp}'
  scope: resourceGroup(managementSubscriptionId, managementResourceGroupName)
  dependsOn: [
    managementResourceGroup
  ]
  params: {
    location: primaryLocation
    workspaceName: logAnalyticsWorkspaceName
    retentionInDays: logRetentionInDays
    tags: tags
    appInsightsName: appInsightsName
  }
}

// ============================================================================
// モジュール: Microsoft Defender for Cloud
// FISC 実7/実14/実25/統20: 脅威検知・防御
// ============================================================================
module defender 'modules/defender.bicep' = {
  name: 'deploy-defender-${deploymentTimestamp}'
  scope: subscription(managementSubscriptionId)
  params: {
    securityContactEmail: securityContactEmail
    securityContactPhone: securityContactPhone
  }
}

// ============================================================================
// モジュール: 診断設定
// FISC 実25/実26: アクティビティログ転送・アーカイブ
// ============================================================================
module diagnostics 'modules/diagnostics.bicep' = {
  name: 'deploy-diagnostics-${deploymentTimestamp}'
  scope: subscription(managementSubscriptionId)
  dependsOn: [
    managementResourceGroup
  ]
  params: {
    logAnalyticsWorkspaceId: logAnalytics.outputs.workspaceId
    location: primaryLocation
    tags: tags
    storageResourceGroupName: managementResourceGroupName
    archiveStorageAccountName: archiveStorageAccountName
    immutabilityPeriodInDays: logRetentionInDays
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('ルート管理グループID')
output rootManagementGroupId string = managementGroups.outputs.rootManagementGroupId

@description('Log Analytics ワークスペースID')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId

@description('有効化されたDefenderプラン')
output defenderPlans array = defender.outputs.enabledPlans

@description('診断設定ID')
output diagnosticSettingId string = diagnostics.outputs.diagnosticSettingId

@description('デプロイされた管理グループ一覧')
output managementGroupIds object = {
  root: managementGroups.outputs.rootManagementGroupId
  platform: managementGroups.outputs.platformManagementGroupId
  connectivity: managementGroups.outputs.connectivityManagementGroupId
  identity: managementGroups.outputs.identityManagementGroupId
  management: managementGroups.outputs.managementManagementGroupId
  workloads: managementGroups.outputs.workloadsManagementGroupId
  tier1: managementGroups.outputs.tier1ManagementGroupId
  tier2: managementGroups.outputs.tier2ManagementGroupId
  tier3: managementGroups.outputs.tier3ManagementGroupId
  sandbox: managementGroups.outputs.sandboxManagementGroupId
}
