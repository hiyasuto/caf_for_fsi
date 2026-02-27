// ============================================================================
// Management Group 階層構造モジュール
// 金融機関向け Azure ランディングゾーンの管理グループ階層を定義
// FISC 統20: クラウドガバナンス体制の確立
// ============================================================================

targetScope = 'tenant'

metadata fiscReference = {
  standard: 'FISC安全対策基準 第13版'
  controls: [
    '統20: クラウドサービスの利用におけるガバナンス'
    '統21: クラウドサービスの利用における管理体制'
  ]
  description: '金融機関向けの管理グループ階層を構築し、ガバナンス体制を確立する'
}

// ============================================================================
// パラメータ
// ============================================================================

@description('組織の接頭辞（例: fsi）')
param organizationPrefix string

@description('親管理グループのID')
param parentManagementGroupId string

// ============================================================================
// 変数
// ============================================================================

// 管理グループ名の定義
var managementGroups = {
  root: {
    name: '${organizationPrefix}-root'
    displayName: '${organizationPrefix}-root (金融機関ルート)'
  }
  platform: {
    name: '${organizationPrefix}-platform'
    displayName: '${organizationPrefix}-platform (プラットフォーム)'
  }
  connectivity: {
    name: '${organizationPrefix}-connectivity'
    displayName: '${organizationPrefix}-connectivity (ネットワーク)'
  }
  identity: {
    name: '${organizationPrefix}-identity'
    displayName: '${organizationPrefix}-identity (ID管理)'
  }
  management: {
    name: '${organizationPrefix}-management'
    displayName: '${organizationPrefix}-management (管理)'
  }
  workloads: {
    name: '${organizationPrefix}-workloads'
    displayName: '${organizationPrefix}-workloads (ワークロード)'
  }
  tier1: {
    name: '${organizationPrefix}-tier1'
    displayName: '${organizationPrefix}-tier1 (Tier1: 勘定系・決済系)'
  }
  tier2: {
    name: '${organizationPrefix}-tier2'
    displayName: '${organizationPrefix}-tier2 (Tier2: チャネル系・情報系)'
  }
  tier3: {
    name: '${organizationPrefix}-tier3'
    displayName: '${organizationPrefix}-tier3 (Tier3: 開発・検証)'
  }
  sandbox: {
    name: '${organizationPrefix}-sandbox'
    displayName: '${organizationPrefix}-sandbox (サンドボックス)'
  }
}

// ============================================================================
// リソース: 管理グループ階層
// ============================================================================

// Level 1: ルート管理グループ
resource mgRoot 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.root.name
  properties: {
    displayName: managementGroups.root.displayName
    details: {
      parent: {
        id: tenantResourceId('Microsoft.Management/managementGroups', parentManagementGroupId)
      }
    }
  }
}

// Level 2: プラットフォーム管理グループ
resource mgPlatform 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.platform.name
  properties: {
    displayName: managementGroups.platform.displayName
    details: {
      parent: {
        id: mgRoot.id
      }
    }
  }
}

// Level 2: ワークロード管理グループ
resource mgWorkloads 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.workloads.name
  properties: {
    displayName: managementGroups.workloads.displayName
    details: {
      parent: {
        id: mgRoot.id
      }
    }
  }
}

// Level 2: サンドボックス管理グループ
resource mgSandbox 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.sandbox.name
  properties: {
    displayName: managementGroups.sandbox.displayName
    details: {
      parent: {
        id: mgRoot.id
      }
    }
  }
}

// Level 3: ネットワーク管理グループ（プラットフォーム配下）
resource mgConnectivity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.connectivity.name
  properties: {
    displayName: managementGroups.connectivity.displayName
    details: {
      parent: {
        id: mgPlatform.id
      }
    }
  }
}

// Level 3: ID管理グループ（プラットフォーム配下）
resource mgIdentity 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.identity.name
  properties: {
    displayName: managementGroups.identity.displayName
    details: {
      parent: {
        id: mgPlatform.id
      }
    }
  }
}

// Level 3: 管理グループ（プラットフォーム配下）
resource mgManagement 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.management.name
  properties: {
    displayName: managementGroups.management.displayName
    details: {
      parent: {
        id: mgPlatform.id
      }
    }
  }
}

// Level 3: Tier1 管理グループ（ワークロード配下）- 勘定系・決済系
resource mgTier1 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.tier1.name
  properties: {
    displayName: managementGroups.tier1.displayName
    details: {
      parent: {
        id: mgWorkloads.id
      }
    }
  }
}

// Level 3: Tier2 管理グループ（ワークロード配下）- チャネル系・情報系
resource mgTier2 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.tier2.name
  properties: {
    displayName: managementGroups.tier2.displayName
    details: {
      parent: {
        id: mgWorkloads.id
      }
    }
  }
}

// Level 3: Tier3 管理グループ（ワークロード配下）- 開発・検証
resource mgTier3 'Microsoft.Management/managementGroups@2023-04-01' = {
  name: managementGroups.tier3.name
  properties: {
    displayName: managementGroups.tier3.displayName
    details: {
      parent: {
        id: mgWorkloads.id
      }
    }
  }
}

// ============================================================================
// 出力
// ============================================================================

@description('ルート管理グループのリソースID')
output rootManagementGroupId string = mgRoot.id

@description('プラットフォーム管理グループのリソースID')
output platformManagementGroupId string = mgPlatform.id

@description('ネットワーク管理グループのリソースID')
output connectivityManagementGroupId string = mgConnectivity.id

@description('ID管理グループのリソースID')
output identityManagementGroupId string = mgIdentity.id

@description('管理グループのリソースID')
output managementManagementGroupId string = mgManagement.id

@description('ワークロード管理グループのリソースID')
output workloadsManagementGroupId string = mgWorkloads.id

@description('Tier1管理グループのリソースID')
output tier1ManagementGroupId string = mgTier1.id

@description('Tier2管理グループのリソースID')
output tier2ManagementGroupId string = mgTier2.id

@description('Tier3管理グループのリソースID')
output tier3ManagementGroupId string = mgTier3.id

@description('サンドボックス管理グループのリソースID')
output sandboxManagementGroupId string = mgSandbox.id

@description('ルート管理グループ名')
output rootManagementGroupName string = mgRoot.name
