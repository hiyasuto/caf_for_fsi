# AML/KYC系システム ランディングゾーン

> マネーロンダリング対策・本人確認を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、犯罪収益移転防止法（犯収法）・FATF 勧告に基づくマネーロンダリング対策（AML）および本人確認（KYC/eKYC）システムを対象としています。
- 取引モニタリング（リアルタイム + バッチ）、疑わしい取引の届出（STR）、制裁リスト照合、eKYC の各機能を統合的に設計しています。
- AI/ML による不正検知・ネットワーク分析を中核とし、**グラフ分析**による資金フロー可視化を含みます。
- 個人情報を大量に処理するため、FISC 基準上「機微性を有するシステム」として高いセキュリティレベルが要求されます。
- 複数金融機関間での AML 情報共有シナリオには、**Azure Confidential Computing**（機密コンピューティング）の活用を検討しています。

> **参考**: [Azure Confidential Computing — Anti-money laundering use case](https://learn.microsoft.com/azure/confidential-computing/use-cases-scenarios#anti-money-laundering) — 複数銀行間での機密データ共有による AML 分析

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | AML/KYCシステム（マネロン対策・本人確認） |
| 主な機能 | 取引モニタリング、疑わしい取引の検知・届出（STR）、eKYC、制裁リスト照合、グラフ分析 |
| FISC外部性 | **機微性を有する**（個人情報・取引情報を大量に処理） |
| 重要度 | **Tier 2（高）**（規制要件 — 取引モニタリング停止は規制違反リスク） |
| 処理特性 | リアルタイム検知 + バッチ分析 + AI/ML + グラフ分析 |
| 可用性要件 | 99.95%以上 |

## ユースケース

- **リアルタイム取引モニタリング**: 勘定系・為替決済系からの取引データをストリーム処理し、疑わしい取引パターンをリアルタイムで検知します。
- **バッチ分析**: 日次バッチで過去取引の包括的なパターン分析・リスクスコアリングを実施します。
- **疑わしい取引の届出 (STR)**: 検知した疑わしい取引を調査し、金融庁 JAFIC への届出を管理します。
- **eKYC（オンライン本人確認）**: 身分証（運転免許証・マイナンバーカード・パスポート等）の OCR 読取り・顔照合による本人確認を自動化します。
- **制裁リスト照合**: OFAC・EU・国連・日本の制裁リストとの顧客・取引先照合をリアルタイムで実施します。
- **グラフ分析**: 資金フロー・関係者ネットワークをグラフ構造で分析し、組織的な不正送金パターンを検出します。
- **銀行間情報共有 (将来)**: Confidential Computing を活用した複数銀行間での AML 分析データの安全な共有。

## FISC基準上の位置づけ

AML/KYC システムは個人情報を大量に処理し、規制当局への報告義務を伴うため、FISC 基準上「機微性を有するシステム」として高い安全対策レベルが要求されます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準適用）
- 統7: **データ管理** — 個人情報のライフサイクル管理・保存期間管理
- 実1〜実19: 技術的安全対策（全項目適用）
- 実3: **蓄積データの保護** — 個人情報・取引情報の暗号化
- 実10: **アクセス履歴管理** — 全照会・検知結果の監査ログ
- 実14: **不正侵入防止** — eKYC API エンドポイント・外部連携の保護（WAF / DDoS Protection）
- 実25: **アクセス権限管理** — 職務分離に基づくデータアクセス制御
- 実39〜実45: バックアップ（法定保存期間: 7年）

**AML/KYC固有の追加要件**:
- 実150〜実153: **AI の安全管理** — 不正検知 AI モデルの公平性・説明可能性・人間による監督
- 犯罪収益移転防止法: **取引記録の保存** — 取引記録 7 年、本人確認記録 7 年の保存義務
- FATF 勧告: **リスクベースアプローチ** — 顧客リスク評価に基づく監視強度の調整

## アーキテクチャの特徴

### リアルタイム取引モニタリング

勘定系・為替決済系からの取引データをリアルタイムでストリーム処理し、疑わしい取引パターンを即座に検知します。

```
勘定系 / 為替決済系
        │ Event Hubs (CDC / リアルタイム連携)
        ▼
┌─────────────────────────────────┐
│ Azure Stream Analytics          │
│ ・ルールベース検知                │
│   - 大口現金取引 (CTR)           │
│   - 構造化取引 (Structuring)     │
│   - 送金先制裁国                 │
│ ・時系列パターン分析              │
│   - 短期間の連続取引             │
│   - 異常な取引頻度・金額          │
└──────────┬──────────────────────┘
           │
     ┌─────┼─────────────┐
     ▼     ▼             ▼
 ┌──────┐ ┌──────────┐ ┌───────────────┐
 │即時   │ │Sentinel  │ │ Cosmos DB     │
 │アラート│ │相関分析  │ │ (検知結果保存) │
 └──────┘ └──────────┘ └───────────────┘
```

| 検知カテゴリ | 検知ルール例 | 検知方式 |
|------------|------------|---------|
| 大口現金取引 (CTR) | 200万円以上の現金取引 | ルールベース（即時） |
| 構造化取引 | 閾値未満に分割された連続取引 | 時系列パターン分析 |
| 送金先リスク | 制裁対象国・ハイリスク国への送金 | リスト照合 |
| 異常取引パターン | 過去の取引パターンからの逸脱 | ML 異常検知モデル |
| ネットワーク不正 | 環状送金・迂回送金パターン | グラフ分析 |

### AI/ML による高度不正検知

ルールベース検知では捕捉できない複雑な不正パターンを、AI/ML モデルで検出します。

| モデル | アルゴリズム | 入力データ | 出力 |
|-------|-----------|-----------|------|
| 異常取引検知 | Isolation Forest / AutoEncoder | 取引金額・頻度・時間帯・送金先 | 異常スコア (0-1) |
| 顧客リスクスコアリング | LightGBM / XGBoost | 顧客属性・取引履歴・関係者情報 | リスクスコア (Low/Med/High) |
| ネットワーク分析 | Graph Neural Network (GNN) | 送金ネットワーク（グラフ構造） | 不正ネットワーク候補 |
| テキスト分析 | Azure OpenAI (GPT-4o) | 送金メモ・取引備考 | 不審キーワード・文脈分析 |
| 画像偽造検知 | Custom Vision / Document Intelligence | eKYC 提出書類画像 | 偽造疑いスコア |

#### FISC 実150-153 AI 安全管理対応

| FISC基準 | 要件 | AML/KYC での実装 |
|---------|------|----------------|
| 実150 | AI 利用方針の策定 | AML/KYC 向け AI 利用ポリシーの策定・承認 |
| 実151 | AI の公平性確保 | Responsible AI ダッシュボードによる公平性メトリクス（性別・国籍・年齢等での偏りチェック） |
| 実152 | AI の説明可能性 | SHAP / LIME による検知理由の説明生成、調査員向け説明レポート |
| 実153 | 人間による監督 | AI 検知結果は必ず調査員がレビュー（Human-in-the-Loop）、自動届出は禁止 |

### グラフ分析（資金フロー・関係者ネットワーク）

マネーロンダリングの組織的パターン（環状送金・迂回送金・ストローマン取引等）を検出するため、**グラフ分析**を活用します。

| コンポーネント | Azure サービス | 用途 |
|-------------|--------------|------|
| グラフDB (トランザクション) | Cosmos DB for Apache Gremlin | 送金ネットワークのリアルタイムグラフ構築・クエリ |
| グラフ分析 (バッチ) | Fabric Graph / Azure Databricks (GraphX) | 大規模ネットワーク分析（コミュニティ検出、中心性分析） |
| グラフ可視化 | Linkurious / Cambridge Intelligence | 調査員向けのインタラクティブなネットワーク可視化 |

```
顧客A ──送金──▶ 顧客B ──送金──▶ 顧客C
  ▲                                │
  └────────送金（迂回）──────────────┘
     ↑ 環状送金パターンをグラフ分析で検出
```

> **参考**: [Azure Cosmos DB for Apache Gremlin](https://learn.microsoft.com/azure/cosmos-db/gremlin/overview) — プロパティグラフデータの格納・クエリ・走査

### eKYC（オンライン本人確認）

犯収法に基づく本人確認をオンラインで実施するため、Azure AI サービスを活用した eKYC 基盤を構築します。

| 確認方式 | Azure サービス | 処理内容 |
|---------|--------------|---------|
| 身分証 OCR | Azure AI Document Intelligence (prebuilt-idDocument) | 運転免許証・マイナンバーカード・パスポートの読取り |
| 顔照合 | Azure AI Face API | セルフィー画像と身分証写真の照合 |
| 生体検知 | Azure AI Face API (Liveness Detection) | なりすまし防止（写真・動画・マスクの検知） |
| 偽造検知 | Custom Vision + Document Intelligence | 身分証の偽造・改ざん検知 |
| データ検証 | カスタム API | 住所・氏名・生年月日の外部 DB 照合 |

```
┌──────────┐   ┌──────────────────┐   ┌──────────────────┐   ┌──────────┐
│ 顧客      │──▶│ Document Intel.  │──▶│ Face API         │──▶│ 判定     │
│ (スマホ/  │   │ ・身分証OCR      │   │ ・顔照合         │   │ ・自動承認│
│  ブラウザ) │   │ ・偽造検知       │   │ ・生体検知       │   │ ・手動審査│
└──────────┘   └──────────────────┘   └──────────────────┘   └──────────┘
```

> **参考**: [Document Intelligence ID document model](https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/id-document) — 身分証の OCR 読取りモデル

### 制裁リスト照合

OFAC（米国）・EU・国連・日本の制裁リストとの顧客・取引先照合を実施します。

| 項目 | 設計 |
|------|------|
| 照合エンジン | Azure AI Search（ファジーマッチング + スコアリング） |
| 照合タイミング | ① 口座開設時 ② 送金時（リアルタイム） ③ リスト更新時（全顧客バッチ） |
| リスト管理 | Azure SQL DB に制裁リストを格納、定期更新パイプライン |
| ファジーマッチング | 表記揺れ・アルファベット/カタカナ変換に対応したスコアリング |
| ヒット時対応 | ヒット → 調査キュー → 調査員レビュー → 取引停止 or 解除 |

### Confidential Computing による銀行間情報共有（将来構想）

複数金融機関間での AML 分析データの共有は、個人情報保護の観点から従来困難でした。**Azure Confidential Computing** により、各銀行の生データを互いに公開することなく、統合分析が可能になります。

| コンポーネント | Azure サービス | 用途 |
|-------------|--------------|------|
| Confidential VM | DCasv5 / ECasv5 (AMD SEV-SNP) | データを暗号化したまま処理 |
| Confidential Clean Room | Azure Confidential Clean Rooms (Preview) | 複数銀行間の安全なデータ共有環境 |
| 機密データベース | Azure SQL Always Encrypted with Secure Enclaves | 暗号化データに対するクエリ実行 |

> **参考**: [Cleanroom and Multi-party Data Analytics](https://learn.microsoft.com/azure/confidential-computing/multi-party-data) — Scotiabank の AML 事例を含む機密データ共有

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────┐
│  オンプレミス DC           │
│  ┌────────────────────┐  │
│  │ 既存系・基幹系接続    │  │
│  └─────────┬──────────┘  │
└────────────┼─────────────┘
             │ ExpressRoute (冗長2回線)
┌────────────┼────────────────────────────────────────────────────┐
│ Azure      │                                                    │
│  ┌─────────▼──────────┐                                         │
│  │  Hub VNet           │                                         │
│  │  Azure Firewall     │                                         │
│  │  ExpressRoute GW    │                                         │
│  └──┬──────────────┬──┘                                         │
│     │ Peering      │ Peering                                     │
│     ▼              ▼                                             │
│  ┌───────────────────────────┐    ┌────────────────────────────┐ │
│  │ 東日本リージョン (Primary)   │    │ 西日本リージョン (DR)        │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ リアルタイム検知層      │ │    │ │ リアルタイム検知層       │ │ │
│  │ │ Stream Analytics      │ │    │ │ (Warm Standby)         │ │ │
│  │ │ + Event Hubs          │ │    │ │                        │ │ │
│  │ └──────────┬────────────┘ │    │ └────────────────────────┘ │ │
│  │            │               │    │                            │ │
│  │ ┌──────────▼────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ AKS Private Cluster   │ │    │ │ AKS Private Cluster    │ │ │
│  │ │ (可用性ゾーン x3)      │ │    │ │ (Warm Standby)         │ │ │
│  │ │ ┌──────┐ ┌──────┐    │ │    │ │ ┌──────┐ ┌──────┐     │ │ │
│  │ │ │AML   │ │KYC   │    │ │    │ │ │AML   │ │KYC   │     │ │ │
│  │ │ │Engine│ │Engine│    │ │    │ │ │Engine│ │Engine│     │ │ │
│  │ │ └──────┘ └──────┘    │ │    │ │ └──────┘ └──────┘     │ │ │
│  │ │ ┌──────┐ ┌──────┐    │ │    │ │ ┌──────┐ ┌──────┐     │ │ │
│  │ │ │制裁   │ │調査   │    │ │    │ │ │制裁   │ │調査   │     │ │ │
│  │ │ │照合  │ │管理  │    │ │    │ │ │照合  │ │管理  │     │ │ │
│  │ │ └──────┘ └──────┘    │ │    │ │ └──────┘ └──────┘     │ │ │
│  │ └──────────┬────────────┘ │    │ └──────────┬─────────────┘ │ │
│  │            │               │    │            │                │ │
│  │ ┌──────────▼────────────┐ │    │ ┌──────────▼─────────────┐ │ │
│  │ │ Azure SQL DB          │ │非同期│ │ Azure SQL DB           │ │ │
│  │ │ Business Critical     │ │─────▶│ │ (Active Geo-Rep)       │ │ │
│  │ │ + Always Encrypted    │ │    │ │                        │ │ │
│  │ └──────────────────────┘  │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Cosmos DB Gremlin     │ │グロ │ │ Cosmos DB Gremlin      │ │ │
│  │ │ (グラフDB /            │ │ーバル│ │ (グローバル              │ │ │
│  │ │  ネットワーク分析)      │ │テー │ │  テーブル)              │ │ │
│  │ └───────────────────────┘ │ブル │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Azure ML / Fabric DS  │ │    │ │ (ML Endpoint replica)  │ │ │
│  │ │ (不正検知 ML モデル)    │ │    │ │                        │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ AI Document Intel.   │ │    │ │ AI Document Intel.     │ │ │
│  │ │ + Face API (eKYC)    │ │    │ │ (eKYC replica)         │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ AI Search (制裁リスト) │ │    │ │ AI Search (replica)    │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  │                           │    │                            │ │
│  │ ┌───────────────────────┐ │    │ ┌────────────────────────┐ │ │
│  │ │ Key Vault (Premium)  │ │    │ │ Key Vault (Premium)    │ │ │
│  │ │ Always Encrypted CMK │ │    │ │                        │ │ │
│  │ └───────────────────────┘ │    │ └────────────────────────┘ │ │
│  └───────────────────────────┘    └────────────────────────────┘ │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │ 共通サービス                                                 │  │
│  │ ┌──────────────┐ ┌──────────────┐ ┌─────────────────────┐ │  │
│  │ │ Log Analytics │ │ Sentinel     │ │ Purview            │ │  │
│  │ │ Workspace    │ │ (相関分析)    │ │ (個人情報ガバナンス) │ │  │
│  │ └──────────────┘ └──────────────┘ └─────────────────────┘ │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| AML/KYC エンジン | AKS Private Cluster | 可用性ゾーン x3 | マイクロサービスベースの検知・照合エンジン |
| リアルタイム検知 | Azure Stream Analytics | Event Hubs 統合 | 取引ストリームのリアルタイムパターン分析 |
| ルールエンジン / SIEM | Microsoft Sentinel | カスタム分析ルール | 疑わしい取引パターンの相関分析・検出 |
| eKYC | Azure AI Document Intelligence + Face API | プライベートエンドポイント | 身分証 OCR・顔照合・生体検知 |

### データベース

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| AML/KYC データ | Azure SQL DB Business Critical | Active Geo-Rep (東西)、Always Encrypted | ACID 保証 + 個人情報の列レベル暗号化 |
| グラフDB | Cosmos DB for Apache Gremlin | グローバルテーブル (東西) | 資金フロー・関係者ネットワークのグラフ分析 |
| 制裁リスト | Azure AI Search + Azure SQL DB | ファジーマッチング | 表記揺れ対応のリスト照合 |
| 検知結果・調査記録 | Cosmos DB (Session Consistency) | グローバルテーブル | 検知結果・調査ワークフローの管理 |

### AI/ML

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 不正検知 ML | Azure ML / Fabric Data Science | Managed Endpoint、MLflow | 異常検知・リスクスコアリングモデル |
| グラフ分析 (バッチ) | Azure Databricks (GraphX) / Fabric Graph | VNet Injection | 大規模ネットワーク分析 |
| テキスト分析 | Azure OpenAI Service (東日本) | プライベートエンドポイント | 送金メモ・備考の不審キーワード分析 |
| 身分証 OCR | Azure AI Document Intelligence | prebuilt-idDocument | 身分証の自動読取り |
| 顔照合・生体検知 | Azure AI Face API | Liveness Detection | eKYC の顔照合・なりすまし防止 |

### セキュリティ・ガバナンス

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 個人情報暗号化 | Always Encrypted + CMK (Key Vault) | 列レベル暗号化 | アプリ以外からの個人情報参照不可 |
| 本人確認画像保護 | Blob Storage (CMK + 不変ストレージ) | WORM ポリシー (7年) | 犯収法の保存義務対応 |
| データガバナンス | Microsoft Purview | 感度ラベル、DLP、リネージ | 個人情報のデータ分類・保護 |
| 特権アクセス管理 | Entra PIM + Break-Glass | JIT + 二人制オペレーション | FISC 実25, 実36 準拠 |
| 監査ログ | Blob Storage (RA-GRS) + WORM | 不変ストレージ (10年) | 全照会・検知結果の監査証跡 |

## セキュリティ設計

| 対策 | 実装 | FISC基準 |
|------|------|---------|
| 個人情報暗号化 | Always Encrypted + CMK（氏名・住所・マイナンバー等を列レベルで暗号化） | 実3 |
| 本人確認画像保護 | Blob Storage (CMK + 不変ストレージ) — 顔写真・身分証画像 | 実3 |
| データアクセス制御 | RBAC + 行レベルセキュリティ（調査員は担当案件のみ参照可） | 実25 |
| 職務分離 | 検知担当 / 調査担当 / 届出承認者の権限分離 | 実25, 実36 |
| 監査ログ | 全照会・検知結果・調査操作の不変ログ保存 | 実10 |
| AI 公平性 | Responsible AI ダッシュボード（検知モデルの偏りチェック） | 実150-153 |
| データ保持 | 法定保存期間（7年）の自動管理 + WORM ポリシー | 統7, 犯収法 |
| DLP | Purview DLP ポリシー（マイナンバー・口座番号の検知） | 実3 |

## 可用性・DR設計

### 目標値

| 指標 | リアルタイム検知 | バッチ分析 / eKYC |
|------|---------------|----------------|
| **可用性** | 99.95% | 99.9% |
| **RTO** | < 1時間 | < 4時間 |
| **RPO** | < 15分 | < 1時間 |

### 障害レベル別対応

| 障害レベル | 事象 | 対応 | RTO |
|-----------|------|------|-----|
| Level 1 | 単一コンポーネント障害 | AKS Pod 自動再起動、SQL DB AZ 内 FO | < 30秒 |
| Level 2 | 可用性ゾーン障害 | AKS の別 AZ へのトラフィック移行、SQL DB 同期レプリカ FO | < 2分 |
| Level 3 | リージョン障害 | 西日本への Runbook 自動切替 | < 1時間 |

### リージョン切替自動化フロー

```
┌──────────────────────────────────────────┐
│  Step 1: 障害検知                         │
│    外形監視 (3拠点) が東日本リージョン障害を   │
│    検知 → Azure Monitor アラート発火         │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 2: 自動判定                         │
│    Azure Automation Runbook (西日本で実行)  │
│    → 複数監視ソースの障害確認 (合意判定)       │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 3: データ層フェイルオーバー            │
│    SQL DB Active Geo-Rep → 西日本昇格       │
│    Cosmos DB → 書込リージョン切替             │
│    Event Hubs → Geo-DR フェイルオーバー       │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 4: ML エンドポイント切替              │
│    西日本の ML Managed Endpoint 有効化       │
│    Stream Analytics ジョブの西日本起動        │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 5: ヘルスチェック・通知               │
│    西日本環境の外形監視・ヘルスチェック        │
│    → 取引モニタリング再開確認                 │
│    → 切替完了通知 (社内・監督当局)            │
└──────────────────────────────────────────┘
```

> **設計ポイント**: 取引モニタリングの停止は犯収法違反リスクがあるため、フェイルオーバー後の取引モニタリング再開確認が最重要です。障害中に処理されなかった取引は、復旧後にバッチで遡及分析を実施します。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL DB PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| 本人確認記録 | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（7年保存） |
| 監査ログ | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（10年保存） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | SQL DB Active Geo-Replication の計画的フェイルオーバーを四半期毎に実施 |
| 取引モニタリング復旧訓練 | モニタリング停止→復旧→遡及分析の一連のフローを検証 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避）、個人情報は匿名化 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: AML/KYC系 東日本 (10.18.0.0/16)
│               ├── snet-app        (10.18.0.0/24)  — AKS AML/KYC エンジン
│               ├── snet-stream     (10.18.1.0/24)  — Stream Analytics / Event Hubs PE
│               ├── snet-db         (10.18.2.0/24)  — SQL DB Private Endpoint
│               ├── snet-cosmos     (10.18.3.0/24)  — Cosmos DB Gremlin PE
│               ├── snet-ml         (10.18.4.0/24)  — Azure ML Managed Endpoint PE
│               ├── snet-ai         (10.18.5.0/24)  — Document Intelligence / Face API PE
│               ├── snet-search     (10.18.6.0/24)  — AI Search PE (制裁リスト)
│               ├── snet-openai     (10.18.7.0/24)  — Azure OpenAI PE
│               ├── snet-pe         (10.18.8.0/24)  — その他 Private Endpoint
│               └── snet-source-pe  (10.18.9.0/24)  — 基幹系データソース PE
│
└── Peering ──▶ Spoke VNet: AML/KYC系 西日本 (10.19.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- snet-ai: AI サービスへの Private Endpoint 通信のみ許可
- snet-source-pe: 基幹系 SQL MI への通信のみ許可（最小権限）
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | 取引モニタリング API・制裁リスト照合 API のヘルスチェック |
| テスト頻度 | 1分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| 取引モニタリング遅延 | Stream Analytics メトリクス | 入力→出力の遅延 > 30秒 |
| 検知率異常 | カスタムメトリクス | 検知率の急増 or 急減（モデル異常の兆候） |
| ML モデルドリフト | Azure ML Monitor | 推論精度の閾値低下 |
| 制裁リスト照合遅延 | Application Insights | P99 > 500ms |
| eKYC 処理失敗率 | Application Insights | エラー率 > 5% |
| DB CPU使用率 | Azure Monitor | > 80% |
| 監査ログ書込み失敗 | Azure Monitor | 不変ストレージへの書込み失敗 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| 個人情報アクセス異常 | Microsoft Sentinel | 大量照会・異常時間帯のアクセス検知 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| ML モデルデプロイ | MLflow + Azure ML Managed Endpoint（ブルーグリーンデプロイ） |
| 検知ルール管理 | Git 版管理されたルール定義 + CI/CD による自動デプロイ |

## 関連リソース

- [Azure Confidential Computing — Anti-money laundering](https://learn.microsoft.com/azure/confidential-computing/use-cases-scenarios#anti-money-laundering)
- [Cleanroom and Multi-party Data Analytics](https://learn.microsoft.com/azure/confidential-computing/multi-party-data)
- [Azure Cosmos DB for Apache Gremlin](https://learn.microsoft.com/azure/cosmos-db/gremlin/overview)
- [Document Intelligence ID document model](https://learn.microsoft.com/azure/ai-services/document-intelligence/prebuilt/id-document)
- [Azure AI Face — Liveness Detection](https://learn.microsoft.com/azure/ai-services/computer-vision/tutorials/liveness)
- [Azure AI Search overview](https://learn.microsoft.com/azure/search/search-what-is-azure-search)
- [Azure Stream Analytics overview](https://learn.microsoft.com/azure/stream-analytics/stream-analytics-introduction)
- [Azure Machine Learning — Responsible AI](https://learn.microsoft.com/azure/machine-learning/concept-responsible-ai)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [FISC compliance on Microsoft Cloud](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
