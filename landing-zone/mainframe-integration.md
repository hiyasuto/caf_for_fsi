# メインフレーム連携・移行 ランディングゾーン

> メインフレームとの連携（データレプリケーション/メッセージング/ファイル転送）およびモダナイゼーション移行の Azure 設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、メインフレーム（IBM z/OS、富士通 MSP、日立 VOS3、NEC ACOS-4 等）と Azure 間のデータ連携、およびメインフレームアプリケーションの Azure への移行（モダナイゼーション）を対象としています。
- メインフレーム連携パターン（データレプリケーション / メッセージング / ファイル転送）と、移行パターン（リホスト / リファクター / リプラットフォーム）の両方を記載しています。
- オンプレミスのメインフレーム環境から Azure への接続は ExpressRoute による閉域網接続を前提としています。
- 本ドキュメントで言及するパートナー製品（Precisely、Raincode、HULFT 等）の動作を Azure が保証するものではありません。各製品の前提条件・詳細は提供元にお問い合わせください。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | メインフレーム連携・移行基盤 |
| 主な機能 | データレプリケーション、メッセージング連携、ファイル転送、アプリケーション移行 |
| FISC外部性 | **連携先システムの外部性に準ずる** — 勘定系連携の場合は Tier 1 相当 |
| 重要度 | 連携先に依存（Tier 1〜3） |
| 処理特性 | リアルタイム CDC、バッチ ETL、メッセージキューイング |
| 可用性要件 | 連携先システムの SLA に準ずる |

## ユースケース

- メインフレーム上の勘定系・情報系データを Azure のデータレイク/DWH にニアリアルタイムでレプリケーションし、分析・AI/ML に活用する
- メインフレームと Azure 上のシステム間で IBM MQ / Service Bus によるメッセージング連携を行う
- HULFT / SFTP によるメインフレーム ↔ Azure 間のファイル転送を実現する
- COBOL / PL/I アプリケーションを Java / .NET にリファクタリングし、Azure 上のクラウドネイティブ環境へ移行する
- メインフレームの段階的縮退（ストラングラーパターン）により、リスクを最小化しながらクラウド移行を進める
- Azure Logic Apps の組込みコネクタ（CICS / IMS / IBM MQ / Host Files）によりメインフレームトランザクションを直接呼び出す

## FISC基準上の位置づけ

メインフレーム連携・移行は、連携先システムの FISC 基準レベルに準拠します。特に勘定系との連携はデータの完全性・可用性・機密性の最高レベルが要求されます。

**適用される主な基準**:
- 統20〜統24: 外部委託管理（パートナー製品の利用に関する管理）
- 実1〜実19: 技術的安全対策（データ暗号化・アクセス制御）
- 実25〜実30: サイバーセキュリティ対策（連携経路の保護）
- 実34〜実45: 運用管理・バックアップ（データ整合性の担保）
- 実75〜実101: 開発プロセス（移行時のテスト・品質管理）
- 実71, 実73: DR・コンティンジェンシープラン（連携停止時の業務継続）

---

## パート1: メインフレーム連携

### 1. データレプリケーション

メインフレーム上のデータベース（Db2 for z/OS、IMS/DB、VSAM 等）のデータを Azure にニアリアルタイムでレプリケーションし、分析やサービス構築に活用します。

#### アーキテクチャ図

```
┌──────────────────────────────────────────────────────────────────────┐
│                    オンプレミス (メインフレーム)                        │
│                                                                      │
│  ┌──────────────────┐                                                │
│  │ IBM z/OS          │                                                │
│  │ ┌──────────────┐ │    CDC Agent        ┌────────────────────────┐ │
│  │ │ Db2 for z/OS │─┼──(ログベース)──→   │ Precisely Connect      │ │
│  │ └──────────────┘ │                     │ Publisher Agent        │ │
│  │ ┌──────────────┐ │                     │ (Active/Standby)       │ │
│  │ │ IMS/DB       │─┼──────────────────→  └──────────┬─────────────┘ │
│  │ └──────────────┘ │                                │               │
│  │ ┌──────────────┐ │                                │               │
│  │ │ VSAM         │─┼──────────────────→             │               │
│  │ └──────────────┘ │                                │               │
│  └──────────────────┘                                │               │
└──────────────────────────────────────────────────────┼───────────────┘
                                                       │ ExpressRoute
                                                       │ (閉域網)
┌──────────────────────────────────────────────────────┼───────────────┐
│                    Azure                              │               │
│                                                       ▼               │
│  ┌──────────────────────────────────────────────────────────────────┐│
│  │ Precisely Connect Apply Agent (Azure VM, Multi-AZ)               ││
│  │ ┌──────────────────────────────────────────────────────────────┐ ││
│  │ │ ・Worker プロセス並列化によるスループット拡大                   │ ││
│  │ │ ・EBCDIC → ASCII / データ型変換                              │ ││
│  │ │ ・COBOL コピーブックによるスキーママッピング                   │ ││
│  │ └──────────────────────────────────────────────────────────────┘ ││
│  └───────────────┬───────────────────────┬──────────────────────────┘│
│                  │                       │                           │
│                  ▼                       ▼                           │
│  ┌──────────────────────┐  ┌──────────────────────────────────────┐ │
│  │ Azure Event Hubs      │  │ Azure データプラットフォーム           │ │
│  │ (ストリーミング)       │  │ ┌──────────┐  ┌──────────────────┐ │ │
│  │                       │  │ │ SQL MI    │  │ Cosmos DB         │ │ │
│  │                       │  │ └──────────┘  └──────────────────┘ │ │
│  │                       │  │ ┌──────────┐  ┌──────────────────┐ │ │
│  └───────────┬───────────┘  │ │ Synapse   │  │ Fabric           │ │ │
│              │              │ │ Analytics │  │ (Lakehouse/DWH)  │ │ │
│              ▼              │ └──────────┘  └──────────────────┘ │ │
│  ┌──────────────────────┐  └──────────────────────────────────────┘ │
│  │ Azure Data Factory /  │                                          │
│  │ Fabric Data Pipeline  │                                          │
│  │ (ETL/ELT 処理)       │                                          │
│  └──────────────────────┘                                           │
└─────────────────────────────────────────────────────────────────────┘
```

#### レプリケーション方式の比較

| 方式 | ツール | 特徴 | 対応ソース | 推奨ユースケース |
|------|-------|------|-----------|----------------|
| **CDC (ログベース)** | Precisely Connect | 本番 DB への影響極小、ニアリアルタイム | Db2, IMS/DB, VSAM | リアルタイム分析、イベント駆動連携 |
| **CDC (ログベース)** | RDRS (Rocket Software) | UDT ベースのエージェントレス CDC も対応 | Db2, IMS/DB, VSAM, Adabas | Fabric 直接連携、多様なターゲット |
| **Azure Logic Apps** | Host Files コネクタ | Azure ネイティブ、HIS デザイナーでスキーマ定義 | VSAM, フラットファイル | 小〜中規模のファイルレベル連携 |
| **バッチ ETL** | Azure Data Factory + HIS | スケジュール実行、大量データ移行 | Db2, VSAM, フラットファイル | 日次バッチ連携、初期データ移行 |

> **設計ポイント**: CDC レプリケーションではメインフレームのアプリケーションやデータを変更せず、ログからの変更キャプチャによりAzure側でのデータ活用を促進します。メインフレームへの負荷影響は最小限です。

### 2. メッセージング連携

メインフレームと Azure 間の非同期メッセージ連携を実現します。

#### IBM MQ 連携アーキテクチャ

```
┌─────────────────────────┐          ┌─────────────────────────────────┐
│ オンプレミス (z/OS)       │          │ Azure                           │
│                         │          │                                 │
│ ┌─────────────────────┐ │          │ ┌─────────────────────────────┐ │
│ │ アプリケーション      │ │          │ │ Azure VM (Multi-AZ)         │ │
│ │ (COBOL/CICS)        │ │          │ │ ┌─────────────────────────┐ │ │
│ └────────┬────────────┘ │          │ │ │ IBM MQ                  │ │ │
│          │ PUT           │          │ │ │ キューマネージャー QM#2  │ │ │
│          ▼               │          │ │ │ (複数インスタンス構成)   │ │ │
│ ┌─────────────────────┐ │  MQ Ch.  │ │ │                         │ │ │
│ │ キューマネージャー    │─┼─────────┼→│ │ 常用系 ←─ EFS ──→ 待機系│ │ │
│ │ QM#1                │ │          │ │ └──────────┬──────────────┘ │ │
│ └─────────────────────┘ │          │ └────────────┼────────────────┘ │
│                         │          │              │ GET              │
│                         │          │              ▼                  │
│                         │          │ ┌─────────────────────────────┐ │
│                         │          │ │ Azure アプリケーション       │ │
│                         │          │ │ (AKS / Container Apps)      │ │
│                         │          │ └─────────────────────────────┘ │
└─────────────────────────┘          └─────────────────────────────────┘
```

#### メッセージング方式の比較

| 方式 | 実装 | 特徴 | 推奨ユースケース |
|------|------|------|----------------|
| **IBM MQ on Azure VM** | 複数インスタンス QM (Azure Files/EFS 共有) | 既存 MQ 資産の活用、フェイルオーバー対応 | 既存 MQ チャネル構成の延伸 |
| **Azure Logic Apps MQ コネクタ** | Logic Apps 組込みコネクタ | Azure ネイティブ、ローコード | MQ メッセージのルーティング・変換 |
| **Azure Logic Apps CICS コネクタ** | HIS デザイナー + CICS コネクタ | CICS トランザクションの直接呼出し | オンライントランザクション連携 |
| **Azure Logic Apps IMS コネクタ** | HIS デザイナー + IMS Program Call | IMS トランザクションの直接呼出し | IMS/DC 連携 |
| **Azure Service Bus ブリッジ** | MQ → Service Bus 変換 | クラウドネイティブなメッセージング | 新規開発アプリケーションとの連携 |

> **Azure Logic Apps の優位性**: Microsoft は 1990 年代から Host Integration Server (HIS) によるメインフレーム連携技術を提供しており、Azure Logic Apps にはこの技術が組込みコネクタとして統合されています。CICS、IMS、IBM MQ、Host Files への接続を Azure ネイティブのワークフローから直接実行できるため、独自の連携プログラム開発が不要です。

### 3. ファイル転送

メインフレームと Azure 間のファイル転送を実現します。

#### ファイル転送方式の比較

| 方式 | ツール | 特徴 | 推奨ユースケース |
|------|-------|------|----------------|
| **HULFT** | HULFT on Azure VM | EBCDIC↔ASCII 変換、ジョブ連携、クラスタリング対応 | 既存 HULFT 資産の活用、日本の金融機関で標準的 |
| **FTP/SFTP** | Azure Storage SFTP / Azure VM | JCL からの直接転送、低コスト | シンプルなファイル転送 |
| **Azure Data Factory** | FTP/SFTP コネクタ + Self-hosted IR | ETL パイプライン統合、スケジュール実行 | 大量データのバッチ転送・変換 |
| **AzCopy** | Azure CLI ツール | 高速大容量転送 | 初期データ移行 |

#### HULFT 連携アーキテクチャ

```
┌─────────────────────────┐          ┌─────────────────────────────────┐
│ オンプレミス (z/OS)       │          │ Azure                           │
│                         │          │                                 │
│ ┌─────────────────────┐ │          │ ┌─────────────────────────────┐ │
│ │ HULFT for z/OS       │ │  HULFT   │ │ HULFT on Azure VM           │ │
│ │ ・配信前/後ジョブ     │─┼─────────┼→│ ・Active/Standby 構成        │ │
│ │ ・EBCDIC → ASCII 変換│ │ (暗号化) │ │ ・クラスタリング SW         │ │
│ │ ・バイナリ転送対応    │ │          │ │ ・S3 on Outposts 相当:      │ │
│ └─────────────────────┘ │          │ │   Azure Blob Storage        │ │
│                         │          │ └──────────────┬──────────────┘ │
│                         │          │                │                │
│                         │          │                ▼                │
│                         │          │ ┌─────────────────────────────┐ │
│                         │          │ │ Azure Blob Storage / ADLS   │ │
│                         │          │ │ ・GRS レプリケーション        │ │
│                         │          │ │ ・ストレージクラス最適化     │ │
│                         │          │ └─────────────────────────────┘ │
└─────────────────────────┘          └─────────────────────────────────┘
```

### メインフレーム連携の Azure サービス構成

| カテゴリ | サービス | SKU / 構成 | 用途 |
|---------|---------|-----------|------|
| データレプリケーション | Azure VM (Apply Agent) | D-series, Multi-AZ | Precisely / RDRS Agent 稼働 |
| ストリーミング | Azure Event Hubs | Premium / Dedicated | CDC イベントストリーム |
| ETL/ELT | Azure Data Factory | Managed VNet IR | バッチデータ連携・変換 |
| メッセージング | Azure VM (IBM MQ) | D-series, Multi-AZ | IBM MQ キューマネージャー |
| メッセージング | Azure Logic Apps | Standard | CICS/IMS/MQ/Host Files コネクタ |
| ファイル転送 | Azure VM (HULFT) | D-series, Active/Standby | HULFT 稼働 |
| ファイル転送 | Azure Storage | SFTP 有効化 / Blob | ファイル受信・保管 |
| データストア | SQL MI / Cosmos DB / Synapse | 用途に応じて選択 | レプリケーション先 |
| 分析基盤 | Microsoft Fabric | Lakehouse / Warehouse | 分析・BI 活用 |
| コード変換 | Host Integration Server | — | EBCDIC↔ASCII、コピーブック解析 |

---

## パート2: メインフレーム移行（モダナイゼーション）

### 移行戦略の選択

メインフレームアプリケーションの Azure 移行には複数のアプローチがあり、リスク・コスト・スピードのバランスに応じて選択します。

#### 移行パターン比較

| パターン | 概要 | リスク | コスト | 期間 | 推奨ケース |
|---------|------|--------|--------|------|-----------|
| **リホスト** | COBOL/PL/I コードをそのまま Azure VM 上で再コンパイル実行 | 低 | 低 | 短 | 迅速なメインフレーム撤去、ビジネスロジック変更不要 |
| **リファクター** | COBOL → Java / .NET に自動変換し、クラウドネイティブ化 | 中 | 中 | 中 | DevOps 導入、クラウドサービス活用、段階的近代化 |
| **リプラットフォーム** | ミドルウェアを Azure マネージドサービスに置換 | 中 | 中 | 中 | DB 移行（Db2 → SQL MI）、バッチ基盤の近代化 |
| **リビルド** | ビジネス要件から再設計・再開発 | 高 | 高 | 長 | レガシー技術の完全脱却、マイクロサービス化 |

### リホスト（Lift & Shift）

COBOL/PL/I のソースコードを変更せず、Azure VM 上の互換ランタイムで再コンパイル・実行します。

#### リホスト用パートナーソリューション

| パートナー | 製品 | 対応言語 | 実行環境 | 特徴 |
|-----------|------|---------|---------|------|
| Micro Focus (OpenText) | Enterprise Server | COBOL, PL/I, JCL | Azure VM / AKS | CICS/IMS/JES 互換、.NET 統合 |
| Raincode | Raincode Compiler | COBOL, PL/I, ASM | Azure VM / AKS (.NET) | ソースコード変更ゼロ、.NET Core 対応 |
| Astadia | — | COBOL | Azure VM | Unisys 系メインフレームの移行 |

### リファクター（自動コード変換）

COBOL/PL/I のソースコードを Java または .NET に自動変換し、Azure 上のクラウドネイティブ環境で実行します。

#### リファクター アーキテクチャ

```
┌────────────────────────────────────────────────────────────────────┐
│                    Azure (リファクター後)                            │
│                                                                    │
│  ┌──────────────┐    ┌──────────────────────────────────────────┐  │
│  │ ExpressRoute  │    │ Azure Load Balancer                      │  │
│  │ / VPN GW      │───→│ (L4/L7 負荷分散)                        │  │
│  └──────────────┘    └───────────┬──────────────────────────────┘  │
│                                  │                                  │
│                    ┌─────────────┼─────────────┐                   │
│                    ▼                           ▼                   │
│  ┌──────────────────────────┐  ┌──────────────────────────────┐   │
│  │ AKS クラスタ              │  │ Azure VM (代替構成)           │   │
│  │ ┌──────────────────────┐ │  │ ┌──────────────────────────┐ │   │
│  │ │ Java App Server       │ │  │ │ リファクタ App Server     │ │   │
│  │ │ (Quarkus / Spring)    │ │  │ │ (Micro Focus / Raincode)  │ │   │
│  │ ├──────────────────────┤ │  │ ├──────────────────────────┤ │   │
│  │ │ 変換後 Java サービス   │ │  │ │ COBOL → .NET 変換       │ │   │
│  │ │ (COBOL → Java 変換)   │ │  │ │                          │ │   │
│  │ └──────────────────────┘ │  │ └──────────────────────────┘ │   │
│  └──────────────────────────┘  └──────────────────────────────┘   │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ データ層                                                      │  │
│  │ ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐│  │
│  │ │ SQL MI    │  │ SQL Database  │  │ Azure Blob Storage       ││  │
│  │ │ (Db2 移行)│  │ (新規)        │  │ (VSAM/フラットファイル)   ││  │
│  │ └──────────┘  └──────────────┘  └──────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │ 共通サービス                                                   │  │
│  │ ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐│  │
│  │ │ Key Vault │  │ Entra ID      │  │ Azure Monitor / App     ││  │
│  │ │          │  │ (認証認可)     │  │ Insights                ││  │
│  │ └──────────┘  └──────────────┘  └──────────────────────────┘│  │
│  └──────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

### AI を活用した移行支援

#### GitHub Copilot によるコード理解・変換支援

GitHub Copilot はメインフレーム移行において以下の場面で活用できます。

| 活用場面 | 説明 |
|---------|------|
| **Code to Doc（コード→文書化）** | COBOL ソースコードを読み込み、ビジネスロジックの自然言語ドキュメントを自動生成。数十年にわたり蓄積された暗黙知を明示化 |
| **Doc to Code（文書→コード）** | 生成されたビジネスロジック文書をもとに、Java / C# / Python のモダンコードを生成 |
| **テストケース生成** | COBOL プログラムの入出力仕様からテストケースを自動生成し、移行後の回帰テストを効率化 |
| **コードレビュー** | 変換後のコードを GitHub Copilot がレビューし、パフォーマンスや安全性の問題を検出 |

#### Legacy Modernization Agents（オープンソースフレームワーク）

[Legacy Modernization Agents](https://github.com/Azure-Samples/Legacy-Modernization-Agents) は、Microsoft が公開しているオープンソースの移行フレームワークです。AI エージェントを活用した COBOL → Java / C# .NET の変換を実現します。

> **注意**: 本フレームワークはオープンソースのデモ・フレームワークであり、プロダクション利用を保証するものではありません。移行プロジェクトの参考実装としてご活用ください。

| 機能 | 説明 |
|------|------|
| **マルチエージェント変換** | Microsoft Agent Framework による複数 AI エージェントが協調して COBOL を分析・変換 |
| **リバースエンジニアリング** | COBOL コードの依存関係グラフ（Neo4j）を自動生成し、プログラム構造を可視化 |
| **スマートチャンキング** | 大規模 COBOL ファイルを意味的な単位で分割し、並列変換を実行 |
| **変換先選択** | Java (Quarkus) または C# .NET への変換を選択可能 |
| **移行レポート** | 変換結果の詳細レポートと品質メトリクスを自動生成 |
| **対話型ポータル** | 移行進捗の可視化、依存関係グラフ、AI チャットによるコードベースへの Q&A |

### 段階的移行アプローチ（ストラングラーパターン）

メインフレームの全面移行ではなく、機能単位で段階的にクラウドへ移行する**ストラングラーフィグパターン**を推奨します。

```
Phase 1: 共存（連携基盤構築）
┌──────────────────┐     ┌──────────────────────────────────┐
│ メインフレーム     │ CDC │ Azure                            │
│ ┌──────────────┐ │────→│ ┌──────────────────────────────┐ │
│ │ 勘定系 (既存) │ │     │ │ DWH/BI (新規)                │ │
│ │ 情報系 (既存) │ │ MQ  │ │ AI/ML 基盤 (新規)            │ │
│ │ チャネル(既存)│ │←───→│ │ 新チャネル (新規)             │ │
│ └──────────────┘ │     │ └──────────────────────────────┘ │
└──────────────────┘     └──────────────────────────────────┘

Phase 2: 段階的移行（ストラングラーパターン）
┌──────────────────┐     ┌──────────────────────────────────┐
│ メインフレーム     │     │ Azure                            │
│ ┌──────────────┐ │ API │ ┌──────────────────────────────┐ │
│ │ 勘定系 (既存) │ │←───→│ │ 情報系 (移行済)               │ │
│ │              │ │     │ │ チャネル (移行済)              │ │
│ └──────────────┘ │     │ │ DWH/BI                       │ │
│                  │     │ │ AI/ML 基盤                    │ │
└──────────────────┘     └──────────────────────────────────┘

Phase 3: 完全移行（オプション）
                         ┌──────────────────────────────────┐
                         │ Azure                            │
                         │ ┌──────────────────────────────┐ │
                         │ │ 勘定系 (移行済/リビルド)       │ │
                         │ │ 情報系                        │ │
                         │ │ チャネル                      │ │
                         │ │ DWH/BI                       │ │
                         │ │ AI/ML 基盤                    │ │
                         │ └──────────────────────────────┘ │
                         └──────────────────────────────────┘
```

| Phase | 期間目安 | 内容 | リスク |
|-------|---------|------|--------|
| Phase 1 | 6-12ヶ月 | CDC/MQ/HULFT による連携基盤構築、新規システムを Azure で構築 | 低 |
| Phase 2 | 1-3年 | 情報系・チャネル系から段階的に移行、API ゲートウェイによるルーティング | 中 |
| Phase 3 | 3-5年 | 勘定系のリビルド/リファクター（オプション、ビジネス判断） | 高 |

---

## 可用性・DR設計

### 連携基盤の可用性

| コンポーネント | 可用性構成 | 障害時の動作 |
|-------------|----------|------------|
| Precisely Apply Agent | Multi-AZ (2台以上) | Worker 間のフェイルオーバー |
| IBM MQ on Azure | 複数インスタンス QM + Azure Files 共有 | 自動フェイルオーバー、MQ クライアント自動再接続 |
| HULFT on Azure | Active/Standby + クラスタリング SW | フェイルオーバー、転送リトライ |
| Azure Logic Apps | Standard プラン (Zone Redundant) | プラットフォームレベルの HA |
| Event Hubs | Premium / Dedicated (Zone Redundant) | 自動フェイルオーバー |

### DR 設計

| シナリオ | RTO | RPO | 方式 |
|---------|-----|-----|------|
| Apply Agent 障害 | 数分 | CDC ログ位置から再開（データロスなし） | Multi-AZ フェイルオーバー |
| Azure リージョン障害 | 4-8時間 | CDC ログ位置に依存 | ペアリージョンへの Agent 再構築 |
| メインフレーム側障害 | MF 復旧に依存 | — | Azure 側のキャッシュデータで縮退運転 |

## ネットワーク設計

| コンポーネント | VNet CIDR | 接続方式 |
|-------------|-----------|---------|
| メインフレーム連携 Spoke (東日本) | 10.35.0.0/16 | Hub Peering + ExpressRoute |
| メインフレーム連携 Spoke (西日本) | 10.36.0.0/16 | Hub Peering + ExpressRoute |

### サブネット設計

| サブネット | CIDR | 用途 |
|----------|------|------|
| snet-replication | 10.35.1.0/24 | Precisely / RDRS Apply Agent |
| snet-messaging | 10.35.2.0/24 | IBM MQ on Azure VM |
| snet-filetransfer | 10.35.3.0/24 | HULFT on Azure VM |
| snet-logicapps | 10.35.4.0/24 | Logic Apps VNet 統合 |
| snet-private-endpoints | 10.35.5.0/24 | Event Hubs / Storage / SQL MI Private Endpoint |

## 監視・オブザーバビリティ

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| CDC レプリケーション遅延 | Azure Monitor + カスタムメトリクス | 遅延 > 閾値（連携先 SLA に応じて設定） |
| MQ キュー深度 | Azure Monitor + MQ エクスポータ | キュー深度 > 閾値（メッセージ滞留） |
| HULFT 転送エラー | HULFT 管理コンソール + Azure Monitor | 転送失敗 / リトライ超過 |
| Apply Agent 稼働状態 | Azure Monitor (VM メトリクス) | CPU > 80% / Agent プロセス停止 |
| データ整合性 | Azure Data Factory データ品質ルール | ソース-ターゲット間の件数/ハッシュ不一致 |
| Logic Apps 実行状態 | Azure Monitor (Logic Apps メトリクス) | 実行失敗 / 遅延 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | GitHub Actions による自動デプロイ |
| 連携 Agent | Azure VM 上の Precisely / RDRS Agent は Ansible / Chef で構成管理 |
| IBM MQ | Azure VM 上の MQ は コンテナ (AKS) またはクラスタリング SW で管理 |
| HULFT | Azure VM 上の HULFT は手動セットアップ + 構成バックアップ |
| Logic Apps | Bicep によるワークフロー定義、HIS メタデータ (HIDX) は成果物として管理 |
| 移行テスト | Azure Load Testing による性能検証、データ比較ツールによる整合性確認 |

## 関連リソース

### メインフレーム連携

- [Azure Logic Apps: メインフレーム・ミッドレンジのモダナイゼーション](https://learn.microsoft.com/azure/logic-apps/mainframe-modernization-overview)
- [Azure Logic Apps: CICS コネクタ](https://learn.microsoft.com/azure/connectors/integrate-cics-apps-ibm-mainframe)
- [Azure Logic Apps: IMS コネクタ](https://learn.microsoft.com/azure/connectors/integrate-ims-apps-ibm-mainframe)
- [Azure Logic Apps: IBM MQ コネクタ](https://learn.microsoft.com/azure/connectors/connectors-create-api-mq)
- [Azure Logic Apps: Host Files コネクタ](https://learn.microsoft.com/azure/logic-apps/mainframe-modernization-overview)
- [Microsoft Host Integration Server (HIS)](https://learn.microsoft.com/host-integration-server/what-is-his)
- [金融サービス向けメインフレームモダナイゼーションツール](https://learn.microsoft.com/industry/financial-services/modernization-tools-mainframe)
- [メインフレームファイルのレプリケーションと同期](https://learn.microsoft.com/azure/architecture/solution-ideas/articles/mainframe-azure-file-replication)
- [Precisely Connect によるメインフレームデータレプリケーション](https://learn.microsoft.com/azure/architecture/example-scenario/mainframe/mainframe-data-replication-azure-precisely)
- [RDRS (Rocket Software) によるメインフレームデータレプリケーション](https://learn.microsoft.com/azure/architecture/example-scenario/mainframe/mainframe-data-replication-azure-rdrs)

### メインフレーム移行

- [メインフレームリファクタリング（汎用）](https://learn.microsoft.com/azure/architecture/example-scenario/mainframe/general-mainframe-refactor)
- [メインフレームリホスト（汎用）](https://learn.microsoft.com/azure/architecture/example-scenario/mainframe/mainframe-rehost-architecture-azure)
- [Raincode コンパイラによるリホスト](https://learn.microsoft.com/azure/architecture/reference-architectures/app-modernization/raincode-reference-architecture)
- [Azure Migrate: アプリケーション・コード評価](https://learn.microsoft.com/azure/migrate/appcat/dotnet)

### AI 活用移行支援

- [Legacy Modernization Agents（オープンソースフレームワーク）](https://github.com/Azure-Samples/Legacy-Modernization-Agents) — AI エージェントによる COBOL → Java / C# 変換フレームワーク
- [GitHub Copilot](https://github.com/features/copilot) — Code to Doc / Doc to Code によるレガシーコードの理解・変換支援
- [Azure Migrate application and code assessment with GitHub Copilot](https://devblogs.microsoft.com/dotnet/azure-migrate-application-and-code-assessment-march-2024-update/)

### パートナー事例

- [IBM Consulting と Microsoft Azure による米国銀行のメインフレームモダナイゼーション](https://www.ibm.com/blog/how-a-us-bank-modernized-its-mainframe-applications-with-ibm-consulting-and-microsoft-azure/)
- [IBM と Microsoft によるメインフレームアプリケーションモダナイゼーションの加速](https://techcommunity.microsoft.com/blog/azuremigrationblog/accelerate-mainframe-application-modernization-with-ibm-and-microsoft/3691322)
