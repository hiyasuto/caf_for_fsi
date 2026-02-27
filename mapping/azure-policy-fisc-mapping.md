# Azure Policy × FISC 安全対策基準 マッピング

## はじめに

本ドキュメントは、Azure の組み込みポリシー（Built-in Policy）、Microsoft Cloud Security Benchmark（MCSB）、およびカスタムポリシーを FISC 安全対策基準（第13版）にマッピングしたものです。

Azure Policy は、Azure 環境に対する自動化されたガードレールを提供し、FISC 準拠に必要な統制・実務基準の継続的な遵守を支援します。金融機関は Azure Policy を活用することで、リソースのデプロイ時点から FISC 要件に沿ったセキュリティ統制を自動的に適用し、コンプライアンス状態をリアルタイムに可視化できます。

> **参考**: MCSB（旧 Azure Security Benchmark）は、Microsoft Defender for Cloud のデフォルトポリシーイニシアティブとして提供されており、420以上の Azure Policy 定義を含みます。FISC 対応の基盤として、まず MCSB イニシアティブを全サブスクリプションに割り当てることを推奨します。

---

## 1. Microsoft Cloud Security Benchmark（MCSB）と FISC の対応

MCSB は、CIS Controls、NIST SP 800-53、PCI-DSS 等の国際基準に基づくクラウドセキュリティのベストプラクティスフレームワークです。MCSB の各コントロールドメインを FISC 安全対策基準にマッピングすることで、既存の Azure Policy イニシアティブを活用した効率的な FISC 対応が可能になります。

| MCSB コントロール | コントロール名 | FISC 対応基準 | 概要 |
|---|---|---|---|
| NS | Network Security | 実7〜実12 | ネットワーク境界防御、通信制御、不正アクセス防止 |
| IM | Identity Management | 実1〜実6 | 利用者認証、アクセス制御、ID管理 |
| PA | Privileged Access | 実1, 実3, 実4 | 特権アクセス管理、最小権限の原則 |
| DP | Data Protection | 実13〜実19 | データ暗号化、鍵管理、情報漏洩防止 |
| AM | Asset Management | 統10, 統11 | IT資産管理、構成管理 |
| LT | Logging and Threat Detection | 実25〜実30 | ログ管理、不正検知、セキュリティ監視 |
| IR | Incident Response | 実31〜実33 | インシデント対応、報告、復旧 |
| PV | Posture and Vulnerability Management | 実75, 実76 | 脆弱性管理、セキュリティ態勢管理 |
| ES | Endpoint Security | 実7, 実8 | エンドポイント保護、マルウェア対策 |
| BR | Backup and Recovery | 実39〜実45 | バックアップ、災害復旧、事業継続 |
| DS | DevOps Security | 実75〜実101 | 開発セキュリティ、コード管理 |
| GS | Governance and Strategy | 統1〜統28 | ガバナンス戦略、組織体制、方針策定 |

> **MCSB v2 イニシアティブ ID**: `/providers/Microsoft.Authorization/policySetDefinitions/1f3afdf9-d0c9-4c3d-847f-89da613e70a8`（[Preview] Microsoft cloud security benchmark v2）

---

## 2. FISC 統制基準 × Azure Policy マッピング

統制基準は、金融機関の情報システムにおけるガバナンス体制・管理方針を定義する上位基準です。Azure Policy およびガバナンスサービスとの対応を以下に示します。

| FISC基準 | 基準概要 | Azure Policy / 対策 | ポリシー定義ID / リソース |
|---|---|---|---|
| 統1 | 情報セキュリティ方針の策定 | MCSB イニシアティブの割り当て、Defender for Cloud 規制コンプライアンスダッシュボード | `1f3afdf9-d0c9-4c3d-847f-89da613e70a8` |
| 統2 | 情報セキュリティ管理体制 | Azure Management Group 階層構造、RBAC による責務分離 | Management Groups + RBAC |
| 統3 | 情報セキュリティリスク管理 | Defender for Cloud セキュアスコア、推奨事項の継続監視 | Microsoft Defender for Cloud |
| 統5 | 情報セキュリティ教育・訓練 | Azure AD Identity Protection リスクレポート | Entra ID + トレーニング管理 |
| 統10 | 情報資産の管理 | リソースタグの必須化、許可されたリソースの種類 | `871b6d14-10aa-478d-b590-94f262ecfa99`（タグ必須）, `a08ec900-254a-4555-9bf5-e42af04b5c5c`（許可リソース種類） |
| 統11 | 構成管理 | Azure Resource Graph、Change Analysis | Resource Graph + Change Tracking |
| 統15 | コンティンジェンシープラン | Azure Site Recovery ポリシー、Backup ポリシー | `013e242c-8828-4970-87b3-ab247555486d`（VM バックアップ） |
| 統20 | 外部委託先管理 | 許可された場所（日本リージョンのみ）、CMK 要件 | `e56962a6-4747-49cd-b67b-bf8b01975c4c`（許可場所）|
| 統24 | クラウドサービス利用に関する方針 | 許可されたサービス、リソースプロバイダーの制限 | `a08ec900-254a-4555-9bf5-e42af04b5c5c`（許可リソース種類） |
| 統25 | 委託先の監督 | Azure Lighthouse によるマルチテナント管理、アクティビティログ監査 | Activity Log + Lighthouse |
| 統28 | サプライチェーンセキュリティ | Defender for DevOps、依存関係スキャン、SBOM 管理 | Defender for DevOps |

---

## 3. FISC 実務基準 × Azure Policy マッピング（詳細）

実務基準は、具体的な技術的・運用的セキュリティ対策を定義する基準です。以下にカテゴリ別の詳細マッピングを示します。

### 3.1 アクセス管理（実1〜実6）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実1 | アクセス制御 | Accounts with owner permissions on Azure resources should be MFA enabled | `e3e008c3-56b9-4133-8fd7-d3347377402a` | サブスクリプション | AuditIfNotExists |
| 実1 | アクセス制御 | Azure RBAC を使用した Kubernetes の認可 | `b2093030-a8b5-4b62-8559-3e3e0e5a0702` | リソースグループ | Audit |
| 実1 | アクセス制御 | Management ports should be closed on your virtual machines | `22730e10-96f6-4aac-ad84-9383d35b5917` | サブスクリプション | AuditIfNotExists |
| 実2 | 利用者認証 | MFA should be enabled on accounts with write permissions | `9297c21d-2ed6-4474-b48f-163f75654ce3` | サブスクリプション | AuditIfNotExists |
| 実2 | 利用者認証 | Service Fabric clusters should only use Azure Active Directory for client authentication | `b54ed75b-3e1a-44ac-a333-05ba39b99ff0` | リソースグループ | Audit |
| 実3 | 特権管理 | There should be more than one owner assigned to your subscription | `09024ccc-0c5f-474e-9509-f1ccfbe64c3c` | サブスクリプション | AuditIfNotExists |
| 実3 | 特権管理 | A maximum of 3 owners should be designated for your subscription | `4f11b553-d42e-4e3a-89be-32ca364cad4c` | サブスクリプション | AuditIfNotExists |
| 実3 | 特権管理 | Blocked accounts with owner permissions on Azure resources should be removed | `0cfea604-3201-4e14-88fc-fae4c427a6c5` | サブスクリプション | AuditIfNotExists |
| 実4 | アクセス権管理 | Role-Based Access Control (RBAC) should be used on Kubernetes Services | `ac4a19c2-fa67-49b4-8ae5-0b2e78c49457` | リソースグループ | Audit |
| 実4 | アクセス権管理 | Azure Key Vault should use RBAC permission model | `12d4fa5e-1f9f-4c21-97a9-b99b3c6611b5` | リソースグループ | Audit |
| 実5 | 利用者ID管理 | Guest accounts with owner permissions on Azure resources should be removed | `339353f6-2387-4a45-abe4-7f529d121046` | サブスクリプション | AuditIfNotExists |
| 実5 | 利用者ID管理 | External accounts with write permissions should be removed from your subscription | `5c607a2e-c700-4744-8254-d77e7c9eb5e4` | サブスクリプション | AuditIfNotExists |
| 実6 | 認証情報管理 | Key Vault secrets should have an expiration date | `98728c90-32c7-4049-8429-847dc0f4fe37` | リソースグループ | Audit |
| 実6 | 認証情報管理 | Key Vault keys should have an expiration date | `152b15f7-8e1f-4c1f-ab71-8c010ba5dbc0` | リソースグループ | Audit |
| 実6 | 認証情報管理 | Key vaults should have soft delete enabled | `1e66c121-a66a-4b1f-9b83-0fd99bf0fc2d` | リソースグループ | Audit |
| 実6 | 認証情報管理 | Key vaults should have deletion protection enabled | `0b60c0b2-2dc2-4e1c-b5c9-abbed971de53` | リソースグループ | Audit |

### 3.2 ネットワークセキュリティ（実7〜実12）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実7 | 通信制御 | Subnets should be associated with a Network Security Group | `e71308d3-144b-4262-b144-efdc3cc90517` | リソースグループ | AuditIfNotExists |
| 実7 | 通信制御 | Storage accounts should restrict network access | `34c877ad-507e-4c82-993e-3452a6e0ad3c` | リソースグループ | Audit |
| 実7 | 通信制御 | Azure Key Vaults should use private link | `a6abeaec-4d90-4a02-805f-6b26c4d3fbe9` | リソースグループ | Audit |
| 実7 | 通信制御 | Storage accounts should use private link | `6edd7eda-6dd8-40f7-810d-67160c639cd9` | リソースグループ | AuditIfNotExists |
| 実8 | 不正アクセス防止 | Web Application Firewall (WAF) should be enabled for Application Gateway | `564feb30-bf6a-4854-b4bb-0d2d2d1e6c66` | リソースグループ | Audit |
| 実8 | 不正アクセス防止 | Azure DDoS Protection should be enabled | `a7aca53f-2ed4-4466-a25e-0b45ade68efd` | サブスクリプション | AuditIfNotExists |
| 実8 | 不正アクセス防止 | Network Watcher flow logs should have traffic analytics enabled | `2f080164-9f4d-497e-9db6-416dc9f7b48a` | リソースグループ | Audit |
| 実9 | 境界防御 | All Internet traffic should be routed via your deployed Azure Firewall | `fc5e4038-4584-4632-8c85-c0448d374b2c` | リソースグループ | AuditIfNotExists |
| 実9 | 境界防御 | Virtual machines should not have public IPs directly attached | カスタムポリシー推奨 | リソースグループ | Deny |
| 実10 | 無線LAN管理 | クラウド環境では直接該当なし（オフィスネットワークは別途対応） | — | — | — |
| 実11 | リモートアクセス管理 | Management ports of virtual machines should be protected with just-in-time network access control | `b0f33259-77d7-4c9e-aac6-3aabcfae693c` | サブスクリプション | AuditIfNotExists |
| 実11 | リモートアクセス管理 | RDP access from the Internet should be blocked | `e372f825-a257-4fb8-9175-797a8a8627d6` | リソースグループ | Audit |
| 実11 | リモートアクセス管理 | SSH access from the Internet should be blocked | `2c89a2e5-7285-40fe-afe0-ae8654b92fab` | リソースグループ | Audit |
| 実12 | インターネット接続管理 | Network interfaces should not have public IPs | `83a86a26-fd1f-447c-b59d-e51f44264114` | リソースグループ | Deny |
| 実12 | インターネット接続管理 | Public network access should be disabled for PaaS services | 各サービス別ポリシー（後述） | リソースグループ | Audit/Deny |

### 3.3 暗号化（実13〜実19）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実13 | データ暗号化 | Storage accounts should use customer-managed key for encryption | `6fac406b-40ca-413b-bf8e-0bf964659c25` | リソースグループ | Audit |
| 実13 | データ暗号化 | Transparent Data Encryption on SQL databases should be enabled | `17k78e20-9358-41c9-923c-fb736d382a4d` | リソースグループ | AuditIfNotExists |
| 実13 | データ暗号化 | Azure Cosmos DB accounts should use customer-managed keys to encrypt data at rest | `1f905d99-2ab7-462c-a6b0-f709acca6c8f` | リソースグループ | Audit |
| 実13 | データ暗号化 | Managed disks should use a specific set of disk encryption sets | `d461a302-a187-421a-89ac-84acdb4edc04` | リソースグループ | Audit |
| 実14 | 暗号鍵管理 | Key Vault keys should have an expiration date | `152b15f7-8e1f-4c1f-ab71-8c010ba5dbc0` | リソースグループ | Audit |
| 実14 | 暗号鍵管理 | Azure Key Vault Managed HSM should have purge protection enabled | `c39ba22d-4428-4149-b981-70acb31fc383` | リソースグループ | Audit |
| 実14 | 暗号鍵管理 | Keys should be backed by a hardware security module (HSM) | `587c79fe-dd04-4a5e-9d0b-f89598c7261b` | リソースグループ | Audit |
| 実15 | 電子署名 | Certificates should use allowed key types | `1151cede-290b-4ba0-8b38-0ad145ac888f` | リソースグループ | Audit |
| 実15 | 電子署名 | Certificates should have the specified maximum validity period | `0a075868-4c26-42ef-914c-5bc007359560` | リソースグループ | Audit |
| 実16 | 暗号化通信 | Latest TLS version should be used in your API App | `8cb6aa8b-9e41-4f4e-aa25-089a7ac2581e` | リソースグループ | AuditIfNotExists |
| 実16 | 暗号化通信 | Secure transfer to storage accounts should be enabled | `404c3081-a854-4457-ae30-26a93ef643f9` | リソースグループ | Audit |
| 実17 | 暗号化の適用範囲 | Storage account encryption scopes should use CMK | `b5ec538c-daa0-4006-8596-35468b9148e8` | リソースグループ | Audit |
| 実18 | 暗号化ポリシー管理 | SQL servers should use customer-managed keys to encrypt data at rest | `0a370ff3-6cab-4e85-8995-295fd854c5b8` | リソースグループ | Audit |
| 実19 | 暗号化アルゴリズム | Keys using RSA cryptography should have a specified minimum key size | `82067dbb-e53b-4e06-b631-546d197452d9` | リソースグループ | Audit |
| 実19 | 暗号化アルゴリズム | Keys using elliptic curve cryptography should have the specified curve names | `ff25f3c8-b739-4538-9d07-3d6d25cfb255` | リソースグループ | Audit |

### 3.4 監視・ログ管理（実25〜実30）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実25 | ログ取得 | Resource logs in Azure Key Vault Managed HSM should be enabled | `a2a5b911-5617-447e-a49e-59dbe0e0571b` | リソースグループ | AuditIfNotExists |
| 実25 | ログ取得 | Resource logs in Search services should be enabled | `b4330a05-a843-4bc8-bf4a-cedc1a3f2caa` | リソースグループ | AuditIfNotExists |
| 実25 | ログ取得 | Auditing on SQL server should be enabled | `a6fb4358-5bf4-4ad7-ba82-2cd2f41ce5e9` | リソースグループ | AuditIfNotExists |
| 実25 | ログ取得 | Activity log should be retained for at least one year | `b02aacc0-b073-424e-8298-42b22829ee0a` | サブスクリプション | AuditIfNotExists |
| 実26 | ログ保全 | Storage accounts should have infrastructure encryption | `4733ea7b-a883-42fe-8cac-97e672e8ce77` | リソースグループ | Audit |
| 実26 | ログ保全 | Immutable storage（WORM ポリシー）の適用 | カスタムポリシー推奨 | リソースグループ | Audit |
| 実27 | 不正検知 | Microsoft Defender for Cloud should be enabled | 各サービス別（後述） | サブスクリプション | AuditIfNotExists |
| 実27 | 不正検知 | Azure Defender for SQL servers on machines should be enabled | `6581d072-105e-4418-827f-bd446d56421b` | サブスクリプション | AuditIfNotExists |
| 実27 | 不正検知 | Microsoft Defender for Storage should be enabled | `640d2586-54d2-465f-877f-9ffc1d2109f4` | サブスクリプション | AuditIfNotExists |
| 実28 | 監視 | Azure Monitor log profile should collect logs for categories 'write,' 'delete,' and 'action' | `1a4e592a-6a6e-44a5-9814-e36264ca96e7` | サブスクリプション | AuditIfNotExists |
| 実28 | 監視 | Azure Monitor should collect activity logs from all regions | `41388f1c-2db0-4c25-95b2-35d7f5ccbfa9` | サブスクリプション | AuditIfNotExists |
| 実29 | アラート管理 | An activity log alert should exist for specific Security operations | `3b980d31-7904-4bb7-8575-5665739a8052` | サブスクリプション | AuditIfNotExists |
| 実29 | アラート管理 | An activity log alert should exist for specific Administrative operations | `b954148f-4c11-4c38-8221-be76711e194a` | サブスクリプション | AuditIfNotExists |
| 実30 | セキュリティ監視 | Microsoft Defender for Cloud の有効化（全プラン） | Defender for Cloud 各プラン | サブスクリプション | AuditIfNotExists |
| 実30 | セキュリティ監視 | Microsoft Sentinel の構成・ログ統合 | Sentinel ワークスペース | サブスクリプション | — |

### 3.5 バックアップ・DR（実39〜実45）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実39 | バックアップの実施 | Azure Backup should be enabled for Virtual Machines | `013e242c-8828-4970-87b3-ab247555486d` | リソースグループ | AuditIfNotExists |
| 実39 | バックアップの実施 | Geo-redundant backup should be enabled for Azure Database for MySQL | `82339799-d096-41ae-8538-b108eb31ad36` | リソースグループ | Audit |
| 実39 | バックアップの実施 | Geo-redundant backup should be enabled for Azure Database for PostgreSQL | `48af4db5-9b8b-401a-882f-b385c5c876e8` | リソースグループ | Audit |
| 実40 | バックアップ管理 | Azure Recovery Services vaults should use private link | `11e3da8c-1d68-4392-badd-0ff3c43ab5b0` | リソースグループ | Audit |
| 実40 | バックアップ管理 | Immutable vault の有効化（Recovery Services） | カスタムポリシー推奨 | リソースグループ | Audit |
| 実41 | リストア | リストアテスト手順の確立（運用対策として実施） | 運用手順書 | — | — |
| 実42 | バックアップ媒体管理 | Long-term geo-redundant backup should be enabled for Azure SQL Databases | `d38fc420-0735-4ef3-ac11-c806f651a570` | リソースグループ | AuditIfNotExists |
| 実43 | データ保全 | Soft delete should be enabled for Backup Vaults | `9798d31d-6028-4dee-8643-46102185c3e3` | リソースグループ | Audit |
| 実44 | DR計画 | Azure Site Recovery の構成、RTO/RPO 要件の定義 | Azure Site Recovery | — | — |
| 実45 | 事業継続管理 | マルチリージョン冗長構成の監査 | カスタムポリシー推奨 | サブスクリプション | Audit |

### 3.6 脆弱性管理・開発セキュリティ（実75〜実101）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実75 | 脆弱性管理 | Vulnerability assessment should be enabled on SQL Managed Instance | `1b7aa243-30e4-4c9e-bca8-d0d3022b634a` | リソースグループ | AuditIfNotExists |
| 実75 | 脆弱性管理 | A vulnerability assessment solution should be enabled on your virtual machines | `501541f7-f7e7-4cd6-868c-4190fdad3ac9` | サブスクリプション | AuditIfNotExists |
| 実76 | パッチ管理 | System updates should be installed on your machines | `86b3d65f-7626-441e-b690-81a8b71cff60` | サブスクリプション | AuditIfNotExists |
| 実76 | パッチ管理 | Machines should be configured to periodically check for missing system updates | `bd876905-5b84-4f73-ab2d-2e7a7c4568d9` | サブスクリプション | AuditIfNotExists |
| 実80 | セキュア開発 | Container images should be deployed from trusted registries only | カスタムポリシー推奨 | リソースグループ | Deny |
| 実85 | テスト環境管理 | テスト環境と本番環境の分離（Management Group 構造） | Management Group | — | — |
| 実90 | 変更管理 | Azure DevOps ブランチポリシー、承認フロー | Azure DevOps | — | — |

### 3.7 AI安全対策（実150〜実153）

| FISC基準 | 基準概要 | Azure Policy（ビルトイン） | ポリシー定義ID | 適用スコープ | 効果 |
|---|---|---|---|---|---|
| 実150 | AIガバナンス | Azure AI Services resources should restrict network access | `037eea7a-7571-4b54-ab1d-cedc7436f47e` | リソースグループ | Audit |
| 実150 | AIガバナンス | Azure AI services should have key access disabled | `71ef260a-8f18-47b7-abcb-62d0673d94dc` | リソースグループ | Audit |
| 実150 | AIガバナンス | Cognitive Services accounts should disable public network access | `0725b4dd-7e76-479c-a735-68e7ee23d5ca` | リソースグループ | Audit |
| 実151 | AI利用方針 | Azure AI Content Safety の有効化 | Azure AI Content Safety | リソースグループ | — |
| 実151 | AI利用方針 | Cognitive Services accounts should use private link | `cddd188c-4b82-4c48-a19d-ddf74ee66a01` | リソースグループ | Audit |
| 実152 | AIリスク管理 | Defender for AI（AI-SPM）の有効化 | Microsoft Defender for Cloud | サブスクリプション | — |
| 実152 | AIリスク管理 | プロンプトインジェクション対策（Azure AI Content Safety Prompt Shields） | Azure AI Content Safety | — | — |
| 実153 | AI監査 | Azure AI サービスの診断ログ有効化 | カスタムポリシー推奨 | リソースグループ | AuditIfNotExists |
| 実153 | AI監査 | Azure Machine Learning ワークスペースのモデルレジストリ管理 | `e413671e-09f5-4779-baf7-051e5914b0d5` | リソースグループ | Audit |

---

## 4. カスタムポリシー推奨

FISC 準拠に必要であるが、Azure 組み込みポリシーとして提供されていない要件に対しては、カスタムポリシーの作成を推奨します。

### 4.1 推奨カスタムポリシー一覧

| カスタムポリシー名 | 対応する FISC 基準 | 効果 | 概要 |
|---|---|---|---|
| 日本リージョン限定デプロイ | 統20 | Deny | japaneast / japanwest 以外へのデプロイを拒否 |
| PaaS サービスの Private Endpoint 必須化 | 実7, 実9 | Deny | Storage / SQL / Cosmos DB / Key Vault 等に Private Endpoint を必須化 |
| TLS 1.2 最小バージョンの強制 | 実16 | Deny | TLS 1.2 未満の通信を拒否 |
| 全リソースへの診断設定必須化 | 実25 | DeployIfNotExists | 対象リソースへ自動的に診断設定を適用 |
| PaaS サービスのパブリックアクセス拒否 | 実9, 実12 | Deny | Storage / SQL / Cosmos DB のパブリックネットワークアクセスを拒否 |
| リソースタグの必須化（分類/所有者） | 統10 | Deny | classification, owner タグのないリソース作成を拒否 |
| マネージドディスクの暗号化必須 | 実13 | Deny | 暗号化されていないマネージドディスクの作成を拒否 |

### 4.2 カスタムポリシー定義例

#### 例1: 日本リージョン限定デプロイ

```json
{
  "properties": {
    "displayName": "FISC: 日本リージョンのみ許可",
    "description": "FISC 統20 準拠 - japaneast および japanwest 以外のリージョンへのリソースデプロイを拒否します。",
    "mode": "Indexed",
    "metadata": {
      "category": "FISC Compliance",
      "version": "1.0.0"
    },
    "parameters": {
      "effect": {
        "type": "String",
        "defaultValue": "Deny",
        "allowedValues": ["Audit", "Deny", "Disabled"],
        "metadata": {
          "displayName": "効果",
          "description": "ポリシーの効果を指定します"
        }
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "location",
            "notIn": ["japaneast", "japanwest", "global"]
          },
          {
            "field": "location",
            "notEquals": ""
          }
        ]
      },
      "then": {
        "effect": "[parameters('effect')]"
      }
    }
  }
}
```

#### 例2: Storage Account パブリックネットワークアクセス拒否

```json
{
  "properties": {
    "displayName": "FISC: Storage Account のパブリックネットワークアクセスを拒否",
    "description": "FISC 実9/実12 準拠 - Storage Account のパブリックネットワークアクセスを無効化します。",
    "mode": "Indexed",
    "metadata": {
      "category": "FISC Compliance",
      "version": "1.0.0"
    },
    "parameters": {
      "effect": {
        "type": "String",
        "defaultValue": "Deny",
        "allowedValues": ["Audit", "Deny", "Disabled"],
        "metadata": {
          "displayName": "効果",
          "description": "ポリシーの効果を指定します"
        }
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Storage/storageAccounts"
          },
          {
            "anyOf": [
              {
                "field": "Microsoft.Storage/storageAccounts/publicNetworkAccess",
                "notEquals": "Disabled"
              },
              {
                "field": "Microsoft.Storage/storageAccounts/networkAcls.defaultAction",
                "notEquals": "Deny"
              }
            ]
          }
        ]
      },
      "then": {
        "effect": "[parameters('effect')]"
      }
    }
  }
}
```

#### 例3: TLS 1.2 最小バージョンの強制（Storage Account）

```json
{
  "properties": {
    "displayName": "FISC: Storage Account の最小 TLS バージョンを 1.2 に強制",
    "description": "FISC 実16 準拠 - Storage Account の最小 TLS バージョンが 1.2 未満の場合にデプロイを拒否します。",
    "mode": "Indexed",
    "metadata": {
      "category": "FISC Compliance",
      "version": "1.0.0"
    },
    "parameters": {
      "effect": {
        "type": "String",
        "defaultValue": "Deny",
        "allowedValues": ["Audit", "Deny", "Disabled"],
        "metadata": {
          "displayName": "効果",
          "description": "ポリシーの効果を指定します"
        }
      }
    },
    "policyRule": {
      "if": {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Storage/storageAccounts"
          },
          {
            "field": "Microsoft.Storage/storageAccounts/minimumTlsVersion",
            "notEquals": "TLS1_2"
          }
        ]
      },
      "then": {
        "effect": "[parameters('effect')]"
      }
    }
  }
}
```

---

## 5. ポリシー適用アーキテクチャ

### 5.1 Management Group 階層とポリシー割り当て

Azure Policy は Management Group 階層に沿って継承されます。金融機関向けに以下の階層構造でのポリシー適用を推奨します。

```
Tenant Root Group
└── fsi-root（MCSB イニシアティブ + FISC 共通ポリシー）
    │   ├── 日本リージョン限定（Deny）
    │   ├── TLS 1.2 必須（Deny）
    │   └── リソースタグ必須（Deny）
    │
    ├── fsi-platform（プラットフォーム管理ポリシー）
    │   ├── Hub ネットワーク NSG 必須
    │   ├── Azure Firewall 必須
    │   └── Log Analytics ワークスペース必須
    │
    ├── fsi-workloads（ワークロードポリシー）
    │   ├── fsi-tier1（最厳格: 勘定系・決済系）
    │   │   ├── パブリックアクセス全拒否（Deny）
    │   │   ├── CMK 暗号化必須（Deny）
    │   │   ├── Private Endpoint 必須（Deny）
    │   │   └── Defender for Cloud 全プラン有効（DeployIfNotExists）
    │   │
    │   ├── fsi-tier2（標準: 情報系・チャネル系）
    │   │   ├── Private Endpoint 必須（Deny）
    │   │   ├── パブリックアクセス制限（Audit）
    │   │   └── 診断設定必須（DeployIfNotExists）
    │   │
    │   └── fsi-tier3（緩和: 社内ツール・非顧客データ）
    │       ├── パブリックアクセス制限（Audit）
    │       └── 診断設定推奨（Audit）
    │
    └── fsi-sandbox（監査のみ: 開発・検証環境）
        └── 全ポリシー Audit モード
```

### 5.2 ポリシー適用の優先順位

1. **Deny ポリシー**: 最も制限の厳しいポリシーを上位 Management Group に配置し、下位で緩和不可にする
2. **DeployIfNotExists ポリシー**: 自動修復が必要なポリシー（診断設定、Defender 有効化等）
3. **Audit ポリシー**: コンプライアンス状態の可視化のみ（段階的導入時に使用）
4. **Append ポリシー**: リソースプロパティの自動追加（タグ継承等）

### 5.3 イニシアティブ構成

FISC 対応に特化したカスタムイニシアティブとして、以下の構成を推奨します。

| イニシアティブ名 | 含まれるポリシー数 | 対象基準 |
|---|---|---|
| FISC-Access-Control | 16 | 実1〜実6 |
| FISC-Network-Security | 12 | 実7〜実12 |
| FISC-Data-Protection | 14 | 実13〜実19 |
| FISC-Monitoring | 10 | 実25〜実30 |
| FISC-Backup-DR | 8 | 実39〜実45 |
| FISC-AI-Security | 6 | 実150〜実153 |
| FISC-Governance | 10 | 統1〜統28 |

---

## 6. Defender for Cloud との統合

### 6.1 規制コンプライアンスダッシュボード

Microsoft Defender for Cloud の規制コンプライアンスダッシュボードで、FISC 対応状況をリアルタイムに監視できます。MCSB イニシアティブを基盤として、カスタムイニシアティブを追加することで、FISC 固有の要件も含めた包括的なコンプライアンスビューを実現します。

### 6.2 Defender プラン別 FISC 対応

| Defender プラン | FISC 対応基準 | ポリシー定義ID |
|---|---|---|
| Defender for Servers | 実75, 実76, 実8 | `8e7da0a5-0a0e-4bbc-bfc0-7773c018b616` |
| Defender for SQL | 実25, 実27, 実75 | `6581d072-105e-4418-827f-bd446d56421b` |
| Defender for Storage | 実27, 実13 | `640d2586-54d2-465f-877f-9ffc1d2109f4` |
| Defender for Key Vault | 実6, 実14, 実27 | `1f725891-01c0-420a-9059-4fa46cb770b7` |
| Defender for Containers | 実80, 実75 | `c9ddb292-b203-4738-aead-18e2716e858f` |
| Defender for AI | 実150, 実152 | Defender for Cloud 設定 |

---

## 7. 次のステップ

### 7.1 関連ドキュメント

本マッピングドキュメントと合わせて、以下の関連資料を参照してください。

| ドキュメント | パス | 概要 |
|---|---|---|
| Azure サービス × FISC マッピング | `mapping/fisc-to-azure-services.md` | Azure サービス単位での FISC 対応一覧 |
| セキュリティアーキテクチャ | `docs/03-security.md` | ゼロトラストセキュリティの全体設計 |
| クラウドガバナンス | `docs/07-cloud-governance.md` | Azure ガバナンスの全体設計と運用 |
| ガバナンス Bicep テンプレート | `governance/` | Policy 定義・イニシアティブの IaC テンプレート |
| ランディングゾーン設計 | `docs/02-landing-zone.md` | Management Group 階層とサブスクリプション設計 |

### 7.2 実装ステップ

1. **MCSB イニシアティブの割り当て**: Tenant Root Group に MCSB v2 イニシアティブを Audit モードで割り当て
2. **コンプライアンスベースラインの確認**: Defender for Cloud でコンプライアンス状態を確認
3. **FISC カスタムイニシアティブの作成**: 本ドキュメントを基に FISC 固有のカスタムイニシアティブを作成
4. **段階的な Deny モードへの移行**: Audit → Deny への段階的移行（fsi-sandbox → fsi-tier3 → fsi-tier2 → fsi-tier1）
5. **継続的モニタリング**: Defender for Cloud + Sentinel による継続的なコンプライアンス監視

### 7.3 参考リンク

- [Microsoft Cloud Security Benchmark v2](https://learn.microsoft.com/security/benchmark/azure/overview)
- [Azure Policy 組み込み定義一覧](https://learn.microsoft.com/azure/governance/policy/samples/built-in-policies)
- [Azure Policy 組み込みイニシアティブ一覧](https://learn.microsoft.com/azure/governance/policy/samples/built-in-initiatives)
- [Defender for Cloud 規制コンプライアンス](https://learn.microsoft.com/azure/defender-for-cloud/regulatory-compliance-dashboard)
- [Azure ランディングゾーン セキュリティコントロールマッピング](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/control-mapping/security-control-mapping)
- [FISC 安全対策基準（金融情報システムセンター）](https://www.fisc.or.jp/)
