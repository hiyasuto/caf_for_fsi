# AI・生成AIエージェント基盤 ランディングゾーン

> 金融機関におけるAI/生成AI/AIエージェント活用基盤のAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、金融機関における生成AI活用基盤およびAIエージェントプラットフォームを対象としています。個別業務システム（AML/KYC、融資審査等）のAI機能は各システム別ランディングゾーンを参照してください。
- 本アーキテクチャは [Azure AI Foundry](https://learn.microsoft.com/azure/ai-foundry/what-is-foundry) を中核プラットフォームとし、[Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/overview) によるエージェント運用基盤を構築します。
- [Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/identity-platform/what-is-agent-id) によるAIエージェントのID管理・ガバナンスを前提としています。
- [Azure AI Content Safety](https://learn.microsoft.com/azure/ai-services/content-safety/) による多層ガードレールと、[Microsoft Defender for Cloud AI脅威保護](https://learn.microsoft.com/azure/defender-for-cloud/ai-threat-protection) によるセキュリティ監視を組み合わせた設計としています。
- 全サービスは Private Endpoint 経由でのアクセスとし、オンプレミス環境との接続は Hub VNet 経由の ExpressRoute 閉域網接続を前提としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | AI・生成AIエージェント基盤 |
| 主な機能 | 社内文書検索（RAG）、顧客対応支援、融資審査支援、レポート生成、AIエージェント（自律タスク実行）、コード生成支援 |
| FISC外部性 | 用途により異なる（社内利用は外部性なし、顧客向けサービス提供時は要判断） |
| 重要度 | **Tier 3**（基盤全体） / **Tier 2**（顧客向けサービス提供時） |
| 処理特性 | 推論API（リアルタイム）、エージェントオーケストレーション（非同期）、ファインチューニング（バッチ） |
| 可用性要件 | 99.9%以上（基盤全体） / 99.95%以上（顧客向けサービス） |
| 適用FISC基準 | **実150〜実153（第13版新設 AI安全管理）** |

## ユースケース

### 生成AIアプリケーション

| ユースケース | Azure構成 | 金融機関固有の考慮事項 |
|------------|----------|-------------------|
| 社内文書検索・Q&A（RAG） | Azure OpenAI + AI Search | 機密文書のアクセス制御、秘密区分に応じたインデックス分離 |
| 顧客対応チャットボット | Foundry Agent Service + OpenAI | 回答の正確性検証（Groundedness Detection）、Human-in-the-Loop |
| 融資審査支援 | Azure ML + OpenAI | 公平性・説明可能性（実150）、与信判断の最終責任は人間 |
| レポート・議事録自動生成 | Azure OpenAI + Power BI | ハルシネーション防止、著作権フィルタ、Protected Material Detection |
| 不正取引検知補助 | Azure ML + Stream Analytics | モデルドリフト監視、Responsible AI ダッシュボード |
| コード生成支援 | GitHub Copilot Enterprise | コードセキュリティスキャン、ライセンスコンプライアンス |

### AIエージェント

| ユースケース | 構成 | 金融機関固有の考慮事項 |
|------------|------|-------------------|
| 稟議・承認フロー自動化 | Foundry Agent Service + MCP (SharePoint/SAP連携) | エージェントの権限範囲制限、監査証跡、承認は人間が最終判断 |
| 契約書レビュー・要点抽出 | Foundry Agent + Document Intelligence + AI Search | 法務文書の機密性保護、DLP連携 |
| 規制報告書の自動作成 | Foundry Agent + A2A (データ取得エージェント + 文書生成エージェント) | 報告先規制要件への正確性確保、Human Review 必須 |
| 顧客オンボーディング支援 | Foundry Agent + Entra External ID + Document Intelligence | KYCプロセスとの連携、エージェント動作の説明可能性 |
| マルチエージェントワークフロー | A2A Protocol + MCP + Foundry Agent Service | エージェント間の権限分離、最小権限原則の適用 |

## FISC基準上の位置づけ

AI・生成AI基盤は用途によりTier 2〜3に位置づけられ、FISC第13版で新設された **AI安全管理基準（実150〜実153）** が全面的に適用されます。AIエージェントの導入にあたっては、自律的に業務判断を行うエージェントに対する統制・監査の仕組みが求められます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（AI利用方針を含む）
- 実1〜実19: 技術的安全対策（ネットワーク・アクセス制御）
- 実3: **蓄積データの保護** — RAG 用データ・学習データの暗号化（Private Endpoint + CMK）
- 実14: **不正侵入防止** — AI エンドポイントの保護（WAF / API 認証 / レート制限）
- 実39〜実45: バックアップ
- **実150: AI利用方針策定・態勢整備** — AI利用ポリシー、責任者指定、リスクアセスメント
- **実151: AI運用管理** — モデルのライフサイクル管理、バージョン管理、監視・ログ管理
- **実152: AI安全対策** — 入出力フィルタリング、データ保護、バイアス対策、プロンプトインジェクション対策
- **実153: AI教育・注意喚起** — 利用者への研修、ガイドライン周知、AIリテラシー向上

### FISC実150〜153 への設計対応

| 基準 | 要件 | 設計への反映 |
|------|------|------------|
| 実150 | 方針策定・態勢整備 | AI利用ポリシー策定、CISO/CDO配下にAI安全管理責任者を設置、Responsible AI ダッシュボードによるリスク可視化 |
| 実151 | 運用管理方法 | Azure AI Foundry によるモデルバージョン管理・評価・デプロイ管理、モデルドリフト監視、A/Bテスト |
| 実152 | 安全対策 | Content Safety（Prompt Shields + Groundedness Detection + PII検出）、Defender for AI脅威保護、DLP連携 |
| 実153 | 教育・注意喚起 | AI利用ガイドライン策定、ハルシネーションリスクの周知、エージェント利用時の監査証跡確認手順 |

## アーキテクチャの特徴

### Azure AI Foundry を中核としたエージェントプラットフォーム

**Microsoft Foundry** を統合プラットフォームとし、**Foundry Agent Service** がエージェントの開発・デプロイ・運用を一元管理します。Agent Service はモデル、ツール、フレームワーク、ガバナンスを単一のランタイムに統合し、会話管理、ツールオーケストレーション、コンテンツ安全の適用、ID・ネットワーク・オブザーバビリティとの統合を担います。

> **参考**: [What is Foundry Agent Service?](https://learn.microsoft.com/azure/ai-foundry/agents/overview) — エージェントの構築からプロダクション運用まで

### MCP / A2A によるエージェント連携

**Model Context Protocol（MCP）** と **Agent-to-Agent（A2A）Protocol** の2つのオープンプロトコルを活用し、エージェントの外部ツール接続と多エージェント間連携を実現します。

| プロトコル | 役割 | 金融機関での活用 |
|-----------|------|---------------|
| **MCP** | エージェントと外部ツール・データソースの標準接続 | 社内SharePoint/SAP/基幹系APIへの安全なアクセス、MCP Server経由でのデータ取得 |
| **A2A** | エージェント間の安全な通信・タスク委譲 | 調査エージェント→分析エージェント→報告エージェントのワークフロー連携 |

MCP Server は Agent Identity Token（Entra Agent ID）で認証し、各エージェントが必要最小限のリソースにのみアクセスできるよう制御します。

> **参考**: [Model Context Protocol (MCP)](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/model-context-protocol) / [Agent-to-Agent (A2A)](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/agent-to-agent)

### Entra Agent ID によるエージェントID管理

**Microsoft Entra Agent ID** により、すべてのAIエージェントに固有のデジタルIDを付与し、人間のユーザーと同等のZero Trust原則でガバナンスを適用します。

| 機能 | 説明 |
|------|------|
| **固有ID付与** | 各エージェントに一意のAgent Identity（サービスプリンシパルの拡張）を割り当て |
| **最小権限アクセス** | 条件付きアクセスポリシー、スコープ制限による必要最小限の権限付与 |
| **ライフサイクル管理** | エージェントの作成・有効化・無効化・削除をスポンサー（人間）が管理 |
| **監査証跡** | エージェントの全アクションをAgent IDに紐づけてログ記録 |
| **特権ロール制限** | エージェントには特権管理者ロールの割り当て不可（セキュリティ境界） |

> **参考**: [What are agent identities?](https://learn.microsoft.com/entra/agent-id/identity-platform/what-is-agent-id) / [Governing Agent Identities](https://learn.microsoft.com/entra/id-governance/agent-id-governance-overview)

### Agent365 によるエンタープライズエージェント統制

**Microsoft Agent 365** を企業全体のAIエージェント統制プレーン（コントロールプレーン）として活用し、Copilot Studio・Azure AI Foundry・サードパーティツールで作成されたすべてのエージェントを一元管理します。

- **エージェントレジストリ**: Entra と連携し、全エージェントを台帳管理。未承認エージェント（シャドーAI）の即時検出・隔離
- **アクセス制御**: エージェントごとにアダプティブリスクベースのアクセスポリシーを適用
- **可視化ダッシュボード**: エージェントの利用状況、セキュリティリスク、コンプライアンス状況、ROI指標を一元可視化
- **相互運用性**: Microsoft 365アプリ（Word, Excel, Teams, SharePoint）およびサードパーティツールとの統合

### 閉域ネットワーク構成

金融機関のネットワークセキュリティ要件に対応するため、Azure AI Foundry の **Bring Your Own VNet（BYO VNet）** モデルを採用し、エンドツーエンドの閉域ネットワーク構成とします。

- 全サービスのパブリックネットワークアクセスを無効化
- Azure OpenAI Service、AI Search、Cosmos DB、Storage はすべて Private Endpoint 経由
- Agent Service のコンピュートは専用サブネットに委任（`Microsoft.App/environments`）
- DNS 解決はプライベート DNS ゾーンで完結

### Azure OpenAI のデータプライバシー

| 項目 | Azure OpenAI の保証 |
|------|-------------------|
| 入力データの学習利用 | **使用されない**（顧客データはモデル改善に使用されない） |
| データ所在地 | 日本リージョン指定可能（Japan East） |
| 不正利用フィルタ | 30日以内に削除（オプトアウト申請によりフィルタ自体の免除も可能） |
| 暗号化 | 保存時（AES-256）・転送時（TLS 1.2+）暗号化 |
| アクセス制御 | Azure RBAC + Private Endpoint + Entra ID 認証 |
| コンプライアンス | SOC 2 Type 2, ISO 27001, ISO 27018, FISC 準拠 |

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────┐
│  オンプレミス DC        │
│  ┌────────────────┐   │
│  │ 既存系・社内NW   │   │
│  └───────┬────────┘   │
└──────────┼────────────┘
           │ ExpressRoute (冗長2回線)
┌──────────┼──────────────────────────────────────────────────────────┐
│ Azure    │                                                          │
│  ┌───────▼────────┐                                                 │
│  │  Hub VNet       │                                                 │
│  │  Azure Firewall │                                                 │
│  │  ExpressRoute GW│                                                 │
│  └──┬──────────┬──┘                                                 │
│     │ Peering  │ Peering                                             │
│     ▼          ▼                                                     │
│  ┌───────────────────────────────┐  ┌──────────────────────────────┐ │
│  │ 東日本リージョン (Primary)       │  │ 西日本リージョン (DR)          │ │
│  │                               │  │                              │ │
│  │ ┌───────────────────────────┐ │  │ ┌──────────────────────────┐ │ │
│  │ │ APIM (Premium)            │ │  │ │ APIM (Premium)           │ │ │
│  │ │ 内部VNet統合               │ │  │ │ (Standby)                │ │ │
│  │ │ ・レート制限・利用量管理    │ │  │ └──────────┬───────────────┘ │ │
│  │ │ ・APIバージョン管理         │ │  │            │                │ │
│  │ └──────────┬────────────────┘ │  │ ┌──────────▼───────────────┐ │ │
│  │            │                   │  │ │ Azure AI Foundry         │ │ │
│  │ ┌──────────▼────────────────┐ │  │ │ (Standby Project)        │ │ │
│  │ │ Azure AI Foundry           │ │  │ │                          │ │ │
│  │ │ ┌──────────────────────┐  │ │  │ │ ┌──────────────────────┐ │ │ │
│  │ │ │ Foundry Agent Service │  │ │  │ │ │ Foundry Agent Service│ │ │ │
│  │ │ │ ・エージェントランタイム│  │ │  │ │ │ (Warm Standby)       │ │ │ │
│  │ │ │ ・MCP / A2A 連携      │  │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ │ ・Content Safety統合  │  │ │  │ │                          │ │ │
│  │ │ └──────────────────────┘  │ │  │ │ ┌──────────────────────┐ │ │ │
│  │ │ ┌──────────────────────┐  │ │  │ │ │ Azure OpenAI Service │ │ │ │
│  │ │ │ Azure OpenAI Service  │  │ │  │ │ │ (Secondary Deploy)   │ │ │ │
│  │ │ │ ・GPT-4o / o3-mini   │  │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ │ ・Embedding (ada-002)│  │ │  │ │                          │ │ │
│  │ │ │ (Private Endpoint)   │  │ │  │ │ ┌──────────────────────┐ │ │ │
│  │ │ └──────────────────────┘  │ │  │ │ │ Azure AI Search      │ │ │ │
│  │ │ ┌──────────────────────┐  │ │  │ │ │ (Replica)            │ │ │ │
│  │ │ │ Azure AI Search       │  │ │  │ │ └──────────────────────┘ │ │ │
│  │ │ │ ・ベクトル検索 + Hybrid│  │ │  │ └──────────────────────────┘ │ │
│  │ │ │ ・セマンティックランカー│  │ │  │                              │ │
│  │ │ │ (Private Endpoint)    │  │ │  │ ┌──────────────────────────┐ │ │
│  │ │ └──────────────────────┘  │ │  │ │ Cosmos DB               │ │ │
│  │ └───────────────────────────┘ │  │ │ (グローバルテーブル)      │ │ │
│  │                               │  │ └──────────────────────────┘ │ │
│  │ ┌───────────────────────────┐ │  └──────────────────────────────┘ │
│  │ │ ガードレール層              │ │                                  │
│  │ │ ┌───────────────────────┐ │ │                                  │
│  │ │ │ AI Content Safety     │ │ │                                  │
│  │ │ │ ・Prompt Shields      │ │ │                                  │
│  │ │ │ ・Groundedness Det.   │ │ │                                  │
│  │ │ │ ・PII検出             │ │ │                                  │
│  │ │ │ ・Protected Material  │ │ │                                  │
│  │ │ └───────────────────────┘ │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ ML基盤層                   │ │                                  │
│  │ │ ┌──────────┐ ┌──────────┐│ │                                  │
│  │ │ │ Azure ML  │ │Databricks││ │                                  │
│  │ │ │ ・モデル管理│ │・特徴量   ││ │                                  │
│  │ │ │ ・RAI     │ │ エンジ   ││ │                                  │
│  │ │ └──────────┘ └──────────┘│ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Cosmos DB (会話・状態管理)  │ │                                  │
│  │ │ (グローバルテーブル)         │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  └───────────────────────────────┘                                  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │               セキュリティ・ガバナンス (グローバル)                │  │
│  │  Entra Agent ID | Agent365 | Defender for AI                   │  │
│  │  Purview AI Hub (DLP/分類) | Key Vault (APIキー/CMK管理)        │  │
│  └────────────────────────────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │               監視・自動化 (グローバル)                           │  │
│  │  Log Analytics | Application Insights | Microsoft Sentinel      │  │
│  │  Azure Monitor (外形監視) | Azure Automation (FO自動化)          │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| エージェントランタイム | Foundry Agent Service | BYO VNet、Private Endpoint | エージェントの実行基盤、MCP/A2A対応、Content Safety統合 |
| アプリケーション基盤 | Azure Container Apps / AKS | 可用性ゾーン、専用サブネット委任 | カスタムUIアプリ、MCP Serverホスティング |
| API Gateway | Azure API Management (Premium) | 内部VNet統合、可用性ゾーン | レート制限・認証・利用量管理・APIバージョン管理 |
| バッチ処理 | Azure Batch / AKS Job | GPU対応ノードプール | ファインチューニング、大規模バッチ推論 |

### AI / 生成AIサービス

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 生成AI | Azure OpenAI Service | Private Endpoint、Japan East、複数デプロイ（GPT-4o / o3-mini / Embedding） | 推論API、RAG、エージェントの推論エンジン |
| プロジェクト管理 | Azure AI Foundry | Hub + Project構成、BYO VNet | モデル評価・A/Bテスト・Red Teaming・デプロイ管理 |
| RAG検索 | Azure AI Search (Standard S2) | ベクトル検索 + Hybrid検索 + セマンティックランカー、Private Endpoint | 社内文書・規程・マニュアルのインデックス |
| ML基盤 | Azure Machine Learning | マネージド VNet、Responsible AI ダッシュボード | 従来型MLモデル管理、公平性・説明可能性評価 |
| 特徴量基盤 | Azure Databricks | Unity Catalog、VNet Injection | 特徴量エンジニアリング、モデル学習、MLflow連携 |

### データベース・ストレージ

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| 会話・状態管理 | Azure Cosmos DB (NoSQL) | グローバルテーブル（マルチリージョン） | Agent Serviceの会話履歴・状態管理。リージョン切替時にDB切替不要 |
| ドキュメントストア | Azure Blob Storage (ZRS) | Private Endpoint、WORM ポリシー | RAGソースドキュメント、学習データ、監査ログの長期保存 |
| キャッシュ | Azure Cache for Redis Enterprise | Active Geo-Replication | プロンプトキャッシュ、セッション管理 |

### セキュリティ・ガバナンス

| コンポーネント | Azureサービス | 対応基準 |
|-------------|-------------|---------|
| コンテンツ安全 | Azure AI Content Safety | 実152（Prompt Shields / Groundedness / PII / Protected Material） |
| AI脅威保護 | Microsoft Defender for Cloud (AI workloads) | 実152（プロンプトインジェクション・データ漏洩・Jailbreak検出） |
| AIセキュリティ態勢管理 | Defender for Cloud AI-SPM | 実150（AI資産の脆弱性・攻撃経路分析） |
| エージェントID管理 | Microsoft Entra Agent ID | 実150（エージェントの認証・認可・ライフサイクル管理） |
| エージェント統制 | Microsoft Agent 365 | 実150（エージェントレジストリ・シャドーAI検出） |
| データガバナンス | Microsoft Purview AI Hub | 実152（AI利用時のDLP・機密データ分類・リネージ） |
| 暗号鍵管理 | Azure Key Vault (Premium) | 実13（APIキー・CMK管理、FIPS 140-2 Level 2） |

## セキュリティ設計（実152対応）

### 多層ガードレールアーキテクチャ

```
利用者/エージェント
    │
    ▼
┌──────────────────────────────────────────────────────────────────┐
│ Layer 1: ID・認証 (Entra ID / Entra Agent ID)                     │
│  ├─ 人間ユーザー: MFA + 条件付きアクセス                            │
│  ├─ AIエージェント: Agent Identity + スコープ制限                    │
│  └─ エージェント特権ロール割り当て禁止                               │
├──────────────────────────────────────────────────────────────────┤
│ Layer 2: API管理 (API Management)                                 │
│  ├─ レート制限（ユーザー/エージェント別）                             │
│  ├─ 利用量クォータ管理（トークン上限/月）                             │
│  ├─ APIバージョン管理・ルーティング                                  │
│  └─ 全API呼出しの監査ログ記録                                      │
├──────────────────────────────────────────────────────────────────┤
│ Layer 3: 入力フィルタ (Content Safety)                             │
│  ├─ Prompt Shields（Jailbreak / Indirect Attack検出）             │
│  ├─ PII検出・マスキング（口座番号・マイナンバー等）                    │
│  ├─ カスタムカテゴリフィルタ（金融商品勧誘・投資助言制限）             │
│  └─ Purview DLP連携（機密文書の入力ブロック）                       │
├──────────────────────────────────────────────────────────────────┤
│ Layer 4: LLM推論 (Azure OpenAI Service)                           │
│  ├─ システムプロンプトによる行動制約                                  │
│  ├─ RAGによるグラウンディング（Azure AI Search）                    │
│  └─ Function Calling / MCP による制御された外部アクセス              │
├──────────────────────────────────────────────────────────────────┤
│ Layer 5: 出力フィルタ (Content Safety)                             │
│  ├─ Groundedness Detection（ハルシネーション検出）                   │
│  ├─ Protected Material Detection（著作権コンテンツ検出）             │
│  ├─ PII出力フィルタ                                               │
│  └─ カスタム出力フィルタ（金融規制対応）                              │
├──────────────────────────────────────────────────────────────────┤
│ Layer 6: AI脅威保護 (Defender for AI)                              │
│  ├─ リアルタイム脅威検出（プロンプトインジェクション・データ漏洩）       │
│  ├─ AI-SPM（AIパイプライン全体の脆弱性・攻撃経路分析）               │
│  ├─ シャドーAI検出（未承認AI利用の検出・ブロック）                    │
│  └─ Defender XDR との統合アラート・インシデント対応                   │
├──────────────────────────────────────────────────────────────────┤
│ Layer 7: データガバナンス (Purview AI Hub)                          │
│  ├─ AI利用時の機密データフロー監視                                   │
│  ├─ 秘密区分ラベルに基づくアクセス制御                               │
│  ├─ 学習データのリネージ・分類                                      │
│  └─ 監査・eDiscovery・コンプライアンスレポート                       │
└──────────────────────────────────────────────────────────────────┘
```

### AIエージェント固有のセキュリティ対策

| リスク | 対策 | Azure実装 |
|-------|------|----------|
| エージェントスプロール（野良AI） | エージェントレジストリ・一元管理 | Agent365 + Entra Agent ID |
| エージェントの過剰権限 | 最小権限 + 特権ロール禁止 | Entra Agent ID（条件付きアクセス + スコープ制限） |
| エージェント間の不正通信 | A2A認証 + ネットワーク分離 | A2A Protocol（Entra ID認証）+ NSG |
| MCP経由の不正アクセス | Agent Identity Token認証 | MCP Server認証（AgenticIdentityToken） |
| プロンプトインジェクション | 多層入力検証 | Content Safety Prompt Shields + Defender for AI |
| ハルシネーション | RAG + 出力検証 | AI Search + Groundedness Detection |
| 機密データ漏洩 | DLP + PII検出 | Purview AI Hub + Content Safety PII |
| モデルドリフト | 継続的評価 | AI Foundry 評価パイプライン + Responsible AI ダッシュボード |
| シャドーAI利用 | 検出・ブロック | Defender for Cloud Apps + Agent365 |

## Responsible AI（実150対応）

金融機関におけるAI利用は、公平性・説明可能性・透明性の確保が不可欠です。

### 公平性（Fairness）

| 対策 | 実装 |
|------|------|
| バイアス検出 | Azure ML Responsible AI ダッシュボードによる公平性メトリクス評価 |
| 偏りのモニタリング | デモグラフィック属性（性別・年齢・地域）別の出力品質監視 |
| 定期レビュー | 四半期ごとのバイアス評価レポート作成・是正 |

### 説明可能性（Explainability）

| 対策 | 実装 |
|------|------|
| RAGの引用表示 | AI Searchの検索結果（ソースドキュメント・ページ番号）をユーザーに提示 |
| Groundedness検証 | Content Safety Groundedness Detection（Reasoning Mode）で根拠を説明 |
| 意思決定の記録 | エージェントの推論過程（ツール呼出し・中間結果）を全てログに記録 |

### Human-in-the-Loop

| 対策 | 実装 |
|------|------|
| 金融判断の最終責任 | 融資審査・投資助言等の重要判断はAIが補助し、人間が最終決定 |
| エスカレーション | エージェントの確信度が閾値以下の場合、人間にエスカレーション |
| 承認フロー | エージェントの外部送信・契約関連アクションには人間の承認を必須化 |

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 30分（エージェント基盤）/ < 1時間（ML基盤） |
| **RPO** | < 5分（会話履歴・状態）/ < 1時間（学習データ・モデル） |

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | Container Apps / AKS セルフヒーリング | < 1分 | 0 |
| 可用性ゾーン障害 | AZ間自動フェイルオーバー | < 5分 | 0 |
| Azure OpenAI 容量制限 | 複数デプロイ間の自動ルーティング（APIM） | 即時 | 0 |
| リージョン障害 | 西日本リージョンへの自動切替（後述） | < 30分 | < 5分 |
| AI基盤全面停止 | 人的対応へのフォールバック手順 | 業務判断 | N/A |

### リージョン切替の自動化フロー

```
┌─ 外形監視（東日本 + 西日本 + 東南アジアから実施）─┐
│  Application Insights 可用性テスト                │
│  (AI API の合成推論リクエスト)                      │
└──────────────────┬───────────────────────────────┘
                   │ 異常検知（複数ロケーション失敗）
                   ▼
┌──────────────────────────────────────────┐
│  Azure Monitor アラート → Action Group    │
│  ※2拠点以上の外形監視失敗で発火            │
└──────────────────┬───────────────────────┘
                   │
                   ▼
┌──────────────────────────────────────────┐
│  Azure Automation Runbook (西日本で実行)   │
│                                          │
│  Step 1: アプリケーション閉塞              │
│    → APIM でインバウンドリクエストを遮断    │
│    → 処理中のエージェントタスク完了を待機    │
│                                          │
│  Step 2: 状態確認                         │
│    → Cosmos DB グローバルテーブル同期確認   │
│    → AI Search インデックス同期確認         │
│                                          │
│  Step 3: 西日本環境の本番昇格              │
│    → Foundry Agent Service 西日本の有効化  │
│    → OpenAI Service 西日本デプロイへの切替  │
│                                          │
│  Step 4: トラフィック切替                   │
│    → APIM の閉塞解除（西日本側）            │
│    → DNS / Front Door のバックエンド変更    │
│                                          │
│  Step 5: 正常性確認                        │
│    → AI APIの推論テスト実行                 │
│    → エージェントのヘルスチェック            │
│    → 切替完了通知                          │
└──────────────────────────────────────────┘
```

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| RAGデータ | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー |
| 会話履歴 | Cosmos DB 継続的バックアップ（PITR 30日） |
| モデル・設定 | AI Foundry プロジェクト設定のIaC管理（Git管理） |
| AISearchインデックス | インデックス定義のIaC管理 + ソースデータからの再構築手順 |
| 不変バックアップ | Azure Backup Immutable Vault（コンプライアンスモード） |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio（OpenAI エンドポイント障害注入）月次実施 |
| リージョン切替訓練 | 西日本への計画的フェイルオーバーを四半期毎に実施 |
| AI固有テスト | プロンプトインジェクション Red Team テストを四半期毎に実施 |
| フォールバック訓練 | AI基盤停止時の人的対応手順の訓練を半期毎に実施 |

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: AI基盤 東日本 (10.20.0.0/16)
│               ├── snet-apim         (10.20.0.0/24)  — API Management
│               ├── snet-agent        (10.20.1.0/24)  — Foundry Agent Service（サブネット委任）
│               ├── snet-app          (10.20.2.0/24)  — Container Apps / AKS（MCP Server等）
│               ├── snet-openai-pe    (10.20.3.0/24)  — Azure OpenAI Private Endpoint
│               ├── snet-search-pe    (10.20.4.0/24)  — AI Search Private Endpoint
│               ├── snet-cosmos-pe    (10.20.5.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-storage-pe   (10.20.6.0/24)  — Storage Private Endpoint
│               ├── snet-ml           (10.20.7.0/24)  — Azure ML マネージドVNet
│               ├── snet-databricks   (10.20.8.0/23)  — Databricks VNet Injection（/23）
│               ├── snet-pe           (10.20.10.0/24) — その他 Private Endpoint
│               └── snet-batch        (10.20.11.0/24) — GPU バッチ処理ノード
│
└── Peering ──▶ Spoke VNet: AI基盤 西日本 (10.21.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- Agent Service サブネット: Microsoft.App/environments 委任、専用 NSG
- OpenAI / AI Search: Private Endpoint 経由のみ（パブリックアクセス無効）
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | AI推論APIへの疑似リクエスト（テスト用プロンプト送信→応答確認） |
| テスト頻度 | 1〜5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### AIワークロード固有の監視

| 監視項目 | ツール | 内容 |
|---------|-------|------|
| トークン使用量 | Azure Monitor + APIM Analytics | 入力/出力トークン数、モデル別・ユーザー別集計、コスト可視化 |
| レート制限ヒット | APIM Metrics | 429エラー（TPM/RPM超過）の発生頻度・傾向 |
| 推論レイテンシ | Application Insights | P50/P95/P99レイテンシ、モデル別・プロンプト長別 |
| Content Safetyブロック | Azure Monitor | 入出力フィルタによるブロック件数・カテゴリ別集計 |
| Groundedness スコア | Content Safety Metrics | ハルシネーション検出率・推移 |
| エージェント実行状態 | Foundry Agent Service Metrics | タスク成功/失敗率、ツール呼出し回数、平均実行時間 |
| モデルドリフト | Azure ML Monitor | 入力データ分布の変化、出力品質メトリクスの推移 |
| Shadow AI検出 | Defender for Cloud Apps | 未承認AIサービスの利用検出 |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 推論応答時間 | Application Insights | P99 > 10秒 |
| トークン使用量 | APIM + Azure Monitor | 月間クォータの80%超過 |
| Content Safety ブロック急増 | Azure Monitor | ブロック件数が通常の3倍以上 |
| Defender for AI アラート | Defender for Cloud | プロンプトインジェクション・データ漏洩検出 |
| エージェント異常終了 | Foundry Agent Service | 失敗率 > 5% |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| Groundedness 低下 | Content Safety | Ungrounded率 > 10%（要調査閾値） |

### 監査ログ

| 項目 | 内容 |
|------|------|
| 全API呼出し | APIM診断ログ（リクエスト/レスポンスヘッダー、トークン数） |
| プロンプト・応答 | Log Analytics（機密データマスキング後、保持期間7年） |
| エージェントアクション | Agent ID に紐づく全ツール呼出し・MCP/A2A通信ログ |
| セキュリティイベント | Microsoft Sentinel（AI脅威アラート統合分析） |
| データアクセス | Purview AI Hub（機密データフロー追跡） |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| AI Foundry設定 | Hub/Project/Connection/Model Deployment の IaC管理 |
| モデルデプロイ | Azure AI Foundry のモデルデプロイメント（Blue-Green対応） |
| RAGインデックス | AI Search インデックス定義のIaC管理 + CI/CDパイプラインでの自動更新 |
| ガードレール | Content Safety フィルター設定のIaC管理 |
| Red Teaming | AI Foundry Red Teaming ツールによる定期的な脆弱性テスト |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| テスト統合 | CI/CD パイプラインに Groundedness 評価テストを統合 |

## 関連リソース

- [What is Microsoft Foundry?](https://learn.microsoft.com/azure/ai-foundry/what-is-foundry)
- [Foundry Agent Service overview](https://learn.microsoft.com/azure/ai-foundry/agents/overview)
- [Baseline Foundry chat reference architecture](https://learn.microsoft.com/azure/architecture/ai-ml/architecture/baseline-microsoft-foundry-chat)
- [Model Context Protocol (MCP) tool](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/model-context-protocol)
- [Agent-to-Agent (A2A) tool](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/tools/agent-to-agent)
- [Agent identity concepts in Microsoft Foundry](https://learn.microsoft.com/azure/ai-foundry/agents/concepts/agent-identity)
- [What are agent identities? — Microsoft Entra Agent ID](https://learn.microsoft.com/entra/agent-id/identity-platform/what-is-agent-id)
- [Governing Agent Identities (Preview)](https://learn.microsoft.com/entra/id-governance/agent-id-governance-overview)
- [Set up private networking for Foundry Agent Service](https://learn.microsoft.com/azure/ai-foundry/agents/how-to/virtual-networks)
- [Azure AI Content Safety overview](https://learn.microsoft.com/azure/ai-services/content-safety/)
- [Prompt Shields](https://learn.microsoft.com/azure/ai-services/content-safety/concepts/jailbreak-detection)
- [Groundedness detection](https://learn.microsoft.com/azure/ai-services/content-safety/concepts/groundedness)
- [AI threat protection — Microsoft Defender for Cloud](https://learn.microsoft.com/azure/defender-for-cloud/ai-threat-protection)
- [AI security posture management](https://learn.microsoft.com/azure/defender-for-cloud/ai-security-posture)
- [Microsoft Purview AI Hub](https://learn.microsoft.com/purview/ai-microsoft-purview)
- [Azure OpenAI Service data privacy](https://learn.microsoft.com/legal/cognitive-services/openai/data-privacy)
- [Azure ML Responsible AI dashboard](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai-dashboard)
