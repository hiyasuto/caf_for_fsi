// ============================================================================
// Microsoft Defender for Cloud 構成モジュール
// FISC安全対策基準に対応する脅威検知・防御機能を有効化
// ============================================================================

targetScope = 'subscription'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '実7: ネットワークセキュリティ（侵入検知）'
    '実14: 不正プログラムへの対策'
    '実25: セキュリティイベントの監視・検知'
    '統20: クラウドサービス利用時のセキュリティ対策'
  ]
  description: 'Microsoft Defender for Cloudの全プランを有効化し、脅威検知体制を構築する'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('セキュリティ連絡先のメールアドレス')
param securityContactEmail string

@description('セキュリティ連絡先の電話番号')
param securityContactPhone string = ''

// ============================================================================
// リソース: Defender for Servers
// FISC 実14: サーバーの脅威検知・マルウェア対策
// ============================================================================
resource defenderServers 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'VirtualMachines'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'P2'
  }
}

// ============================================================================
// リソース: Defender for Storage
// FISC 実13/実14: ストレージの脅威検知
// ============================================================================
resource defenderStorage 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'StorageAccounts'
  properties: {
    pricingTier: 'Standard'
    subPlan: 'DefenderForStorageV2'
  }
}

// ============================================================================
// リソース: Defender for SQL
// FISC 実13: データベースの脅威検知
// ============================================================================
resource defenderSql 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'SqlServers'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for SQL on VMs
// ============================================================================
resource defenderSqlVm 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'SqlServerVirtualMachines'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for App Service
// FISC 実7: Webアプリケーションの脅威検知
// ============================================================================
resource defenderAppService 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'AppServices'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for Key Vault
// FISC 実13: 暗号鍵管理の脅威検知
// ============================================================================
resource defenderKeyVault 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'KeyVaults'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for ARM
// FISC 統20: 管理プレーンの脅威検知
// ============================================================================
resource defenderArm 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'Arm'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for DNS
// FISC 実7: DNS関連の脅威検知
// ============================================================================
resource defenderDns 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'Dns'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for Containers
// FISC 実14: コンテナワークロードの脅威検知
// ============================================================================
resource defenderContainers 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'Containers'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: Defender for AI
// FISC 実150: AIサービスの脅威検知
// ============================================================================
resource defenderAi 'Microsoft.Security/pricings@2024-01-01' = {
  name: 'AI'
  properties: {
    pricingTier: 'Standard'
  }
}

// ============================================================================
// リソース: セキュリティ連絡先
// FISC 実25: セキュリティインシデントの通知先
// ============================================================================
resource securityContact 'Microsoft.Security/securityContacts@2023-12-01-preview' = {
  name: 'default'
  properties: {
    emails: securityContactEmail
    phone: securityContactPhone
    isEnabled: true
    notificationsSources: [
      {
        sourceType: 'Alert'
        minimalSeverity: 'Medium'
      }
      {
        sourceType: 'AttackPath'
        minimalRiskLevel: 'High'
      }
    ]
    notificationsByRole: {
      state: 'On'
      roles: [
        'Owner'
        'ServiceAdmin'
      ]
    }
  }
}

// ============================================================================
// リソース: Log Analytics への自動プロビジョニング
// FISC 実25: ログ収集の自動化
// ============================================================================
resource autoProvisionLogAnalytics 'Microsoft.Security/autoProvisioningSettings@2017-08-01-preview' = {
  name: 'default'
  properties: {
    autoProvision: 'On'
  }
}

// ============================================================================
// 注: 継続的エクスポート設定（Microsoft.Security/automations）は
// リソースグループスコープでのデプロイが必要です。
// main.bicep から別モジュールとしてデプロイするか、
// Azure Portal > Defender for Cloud > 環境設定 > 継続的エクスポート
// から設定してください。
// ============================================================================

// ============================================================================
// 出力
// ============================================================================

@description('有効化されたDefenderプラン一覧')
output enabledPlans array = [
  'VirtualMachines (P2)'
  'StorageAccounts (DefenderForStorageV2)'
  'SqlServers'
  'SqlServerVirtualMachines'
  'AppServices'
  'KeyVaults'
  'Arm'
  'Dns'
  'Containers'
  'AI'
]
