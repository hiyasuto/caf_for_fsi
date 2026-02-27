using '../main.bicep'

// ============================================================================
// 本番環境パラメータファイル
// FISC安全対策基準準拠 Azure ガバナンスベースライン
// ============================================================================

// 組織設定
param organizationPrefix = 'fsi'
param environment = 'prod'

// リージョン設定（FISC統20: 日本国内リージョンのみ）
param primaryLocation = 'japaneast'
param drLocation = 'japanwest'

// 管理グループ設定
param tenantRootGroupId = '<テナントルートグループIDを指定>'

// サブスクリプション設定
param managementSubscriptionId = '<管理用サブスクリプションIDを指定>'
param managementResourceGroupName = 'rg-fsi-management-prod'

// Log Analytics 設定（FISC実25: 730日保持）
param logAnalyticsWorkspaceName = 'law-fsi-central-prod'
param logRetentionInDays = 730

// セキュリティ連絡先（FISC実25: インシデント通知先）
param securityContactEmail = '<security-team@example.com>'
param securityContactPhone = '<+81-3-xxxx-xxxx>'

// Application Insights
param appInsightsName = 'appi-fsi-central-prod'

// アーカイブストレージ（FISC実26: WORM保管）
param archiveStorageAccountName = 'stfsiauditarchiveprod'

// 共通タグ
param tags = {
  environment: 'prod'
  managedBy: 'bicep'
  complianceFramework: 'FISC'
  organization: 'fsi'
  costCenter: '<コストセンターを指定>'
  owner: '<オーナーチーム名を指定>'
}
