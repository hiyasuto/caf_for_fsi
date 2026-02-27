// ============================================================================
// Azure Policy 割り当てモジュール
// FISC安全対策基準に対応するポリシーを管理グループレベルで割り当て
// ============================================================================

targetScope = 'managementGroup'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '実1: アクセス制御'
    '実7: ネットワークセキュリティ'
    '実13: 暗号化'
    '実25: ログ管理'
    '実39: バックアップ'
    '実150: AI ガバナンス'
    '統20: クラウドガバナンス'
  ]
  description: 'FISC安全対策基準に基づくAzure Policyの割り当て'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('ポリシーを割り当てる管理グループ名')
param targetManagementGroupName string

@description('許可する Azure リージョンの一覧')
param allowedLocations array = [
  'japaneast'
  'japanwest'
]

@description('Log Analytics ワークスペースのリソースID（ログ転送先）')
param logAnalyticsWorkspaceId string

// ============================================================================
// 変数: 組み込みポリシー定義ID
// ============================================================================

// Microsoft Cloud Security Benchmark (MCSB) イニシアティブ
var mcsbInitiativeId = tenantResourceId('Microsoft.Authorization/policySetDefinitions', '1f3afdf9-d0c9-4c3d-847f-89da613e70a8')

// FISC 統20: 許可されたリージョンの制限（日本リージョンのみ）
var allowedLocationsDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e56962a6-4747-49cd-b67b-bf8b01975c4c')

// FISC 実7: サブネットにNSGを関連付ける
var nsgOnSubnetsDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', 'e71308d3-144b-4262-b144-efdc3cc90517')

// FISC 実7: ストレージアカウントのネットワークアクセスを制限
var storageNetworkAccessDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '34c877ad-507e-4c82-993e-3452a6e0ad3c')

// FISC 実13: ストレージアカウントの暗号化（CMK）
var storageCmkDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '6fac406b-40ca-413b-bf8e-0bf964659c25')

// FISC 実13: SQL Database の透過的データ暗号化
var sqlTdeDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '86a912f6-9a06-4e26-b447-11b16ba8659f')

// FISC 実25: アクティビティログの365日以上保持
var activityLogRetentionDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', 'b02aacc0-b073-424e-8298-42b22829ee0a')

// FISC 実25: リソースログの有効化（Key Vault）
var keyVaultDiagnosticsDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', 'cf820ca0-f99e-4f3e-84fb-66e913812d21')

// FISC 実39: 仮想マシンの Azure Backup 有効化
var vmBackupDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '013e242c-8828-4970-87b3-ab247555486d')

// FISC 実150: Azure AI サービスのネットワークアクセス制限
var aiNetworkAccessDefinitionId = tenantResourceId('Microsoft.Authorization/policyDefinitions', '037eea7a-bd0a-46c5-9a66-03bbe78381d1')

// 管理グループスコープ
var managementGroupScope = tenantResourceId(
  'Microsoft.Management/managementGroups',
  targetManagementGroupName
)

// ============================================================================
// リソース: Microsoft Cloud Security Benchmark (MCSB) イニシアティブ割り当て
// FISC全般: Microsoft推奨のセキュリティベースライン
// ============================================================================
resource mcsbAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'mcsb-baseline'
  properties: {
    displayName: 'Microsoft Cloud Security Benchmark (FISC ベースライン)'
    description: 'FISC安全対策基準に対応するMicrosoft Cloud Security Benchmarkイニシアティブ'
    policyDefinitionId: mcsbInitiativeId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実1', '実7', '実13', '実25', '統20']
      category: 'Security'
    }
  }
}

// ============================================================================
// リソース: FISC 統20 - 許可されたリージョンの制限
// クラウド利用において、データの所在地を日本国内に限定する
// ============================================================================
resource allowedLocationsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-c20-locations'
  properties: {
    displayName: 'FISC 統20: 許可リージョンの制限（日本リージョンのみ）'
    description: 'FISC統20に基づき、リソースのデプロイ先を日本リージョンに限定する'
    policyDefinitionId: allowedLocationsDefinitionId
    enforcementMode: 'Default'
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
    metadata: {
      fiscControls: ['統20']
      category: 'General'
    }
  }
}

// ============================================================================
// リソース: FISC 実7 - サブネットにNSGを関連付ける
// ネットワーク境界の防御を強制する
// ============================================================================
resource nsgOnSubnetsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p7-nsg'
  properties: {
    displayName: 'FISC 実7: サブネットへのNSG関連付け'
    description: 'FISC実7に基づき、全サブネットにネットワークセキュリティグループの関連付けを強制する'
    policyDefinitionId: nsgOnSubnetsDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実7']
      category: 'Network'
    }
  }
}

// ============================================================================
// リソース: FISC 実7 - ストレージアカウントのネットワークアクセス制限
// ============================================================================
resource storageNetworkAccessAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p7-storage-net'
  properties: {
    displayName: 'FISC 実7: ストレージアカウントのネットワークアクセス制限'
    description: 'FISC実7に基づき、ストレージアカウントのネットワークアクセスを制限する'
    policyDefinitionId: storageNetworkAccessDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実7']
      category: 'Storage'
    }
  }
}

// ============================================================================
// リソース: FISC 実13 - ストレージアカウントのCMK暗号化
// 保存データの暗号化をカスタマーマネージドキーで実施
// ============================================================================
resource storageCmkAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p13-storage-cmk'
  properties: {
    displayName: 'FISC 実13: ストレージアカウントのCMK暗号化'
    description: 'FISC実13に基づき、ストレージアカウントでカスタマーマネージドキーによる暗号化を要求する'
    policyDefinitionId: storageCmkDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実13']
      category: 'Encryption'
    }
  }
}

// ============================================================================
// リソース: FISC 実13 - SQL Database TDE
// SQL Database の透過的データ暗号化を有効化
// ============================================================================
resource sqlTdeAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p13-sql-tde'
  properties: {
    displayName: 'FISC 実13: SQL Database の透過的データ暗号化'
    description: 'FISC実13に基づき、SQL Databaseの透過的データ暗号化を有効にする'
    policyDefinitionId: sqlTdeDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実13']
      category: 'SQL'
    }
  }
}

// ============================================================================
// リソース: FISC 実25 - アクティビティログの保持期間
// 365日以上のログ保持を強制
// ============================================================================
resource activityLogRetentionAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p25-log-retain'
  properties: {
    displayName: 'FISC 実25: アクティビティログの365日以上保持'
    description: 'FISC実25に基づき、アクティビティログを365日以上保持する'
    policyDefinitionId: activityLogRetentionDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実25']
      category: 'Monitoring'
    }
  }
}

// ============================================================================
// リソース: FISC 実25 - Key Vault のリソースログ有効化
// ============================================================================
resource keyVaultDiagnosticsAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p25-kv-diag'
  properties: {
    displayName: 'FISC 実25: Key Vault のリソースログ有効化'
    description: 'FISC実25に基づき、Key Vaultのリソースログを有効にする'
    policyDefinitionId: keyVaultDiagnosticsDefinitionId
    enforcementMode: 'Default'
    parameters: {
      effect: {
        value: 'AuditIfNotExists'
      }
    }
    metadata: {
      fiscControls: ['実25']
      category: 'Monitoring'
    }
  }
}

// ============================================================================
// リソース: FISC 実39 - 仮想マシンの Azure Backup
// データバックアップ体制の確保
// ============================================================================
resource vmBackupAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p39-vm-backup'
  properties: {
    displayName: 'FISC 実39: 仮想マシンの Azure Backup 有効化'
    description: 'FISC実39に基づき、仮想マシンのAzure Backupを有効にする'
    policyDefinitionId: vmBackupDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実39']
      category: 'Backup'
    }
  }
}

// ============================================================================
// リソース: FISC 実150 - Azure AI サービスのネットワークアクセス制限
// AI利用におけるガバナンス強化
// ============================================================================
resource aiNetworkAccessAssignment 'Microsoft.Authorization/policyAssignments@2024-04-01' = {
  name: 'fisc-p150-ai-net'
  properties: {
    displayName: 'FISC 実150: Azure AI サービスのネットワークアクセス制限'
    description: 'FISC実150に基づき、Azure AIサービスのネットワークアクセスを制限する'
    policyDefinitionId: aiNetworkAccessDefinitionId
    enforcementMode: 'Default'
    metadata: {
      fiscControls: ['実150']
      category: 'AI'
    }
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('MCSBポリシー割り当てID')
output mcsbAssignmentId string = mcsbAssignment.id

@description('許可リージョンポリシー割り当てID')
output allowedLocationsAssignmentId string = allowedLocationsAssignment.id

@description('割り当て済みポリシー数')
output totalPolicyAssignments int = 10

@description('Log Analytics ワークスペースID（参照用）')
output logAnalyticsWorkspaceIdRef string = logAnalyticsWorkspaceId

@description('対象管理グループスコープ')
output targetScope string = managementGroupScope
