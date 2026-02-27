# インターネットバンキング ランディングゾーン

> 個人・法人向けインターネットバンキングのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行の個人・法人顧客向けインターネットバンキング（IB）システムを対象としています。モバイルバンキングについては [mobile-banking.md](mobile-banking.md) を参照してください。
- 本アーキテクチャは [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) のガイダンスに準拠した設計としています。
- インターネットからのアクセスを受け付けるため、**多層防御（Defense in Depth）** を最重要設計原則としています。
- 勘定系システム（コアバンキング）への接続は Private Link 経由の閉域網接続とし、インターネット側からの直接アクセスを排除しています。
- 顧客認証には **Microsoft Entra External ID**（CIAM）を採用し、パスワードレス認証（FIDO2 / パスキー）を推奨しています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | インターネットバンキング（IB） |
| 主な機能 | 残高照会、振込・送金、振替、定期預金、各種届出、ローン申込、外貨預金 |
| FISC外部性 | 各金融機関の判断による（主要チャネルの場合は外部性大） |
| 重要度 | **Tier 2〜3** |
| 処理特性 | Web/API（HTTPS）、24時間365日運用、負荷変動大（給料日・月末ピーク） |
| 可用性要件 | 99.95%以上（年間ダウンタイム4.38時間以内） |

## ユースケース

- 個人顧客向けリテールバンキング（残高照会・振込・振替・定期預金・外貨預金等）を想定しています。
- 法人顧客向けビジネスバンキング（総合振込・給与振込・口座振替・外為送金等）も同一基盤で提供します。
- **24時間365日**の運用が求められ、メンテナンス窓口の確保が困難なため、ブルーグリーンデプロイによる無停止更新を採用します。
- 給料日・月末・賞与日等のピーク時には通常の **5〜10倍** のトラフィックが発生するため、自動スケーリングが必須です。

## FISC基準上の位置づけ

インターネットバンキングは FISC 基準の「ダイレクトチャネル」に分類されます。インターネット経由で顧客にサービスを提供するため、実112〜実117 のインターネット・モバイルサービス固有の基準が適用されます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準適用）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実112: **不正使用の防止** — MFA・リスクベース認証・不正ログイン検知
- 実113: **利用状況の確認手段** — ログイン履歴・取引履歴の表示
- 実115: **顧客対応方法の明確化** — FAQ・チャットボット・コールセンター連携
- 実117: **オンライン口座開設の本人確認** — eKYC 連携
- 実39〜実45: バックアップ
- 実71, 実73: DR・コンティンジェンシープラン

**IB固有の追加要件**:
- 実1: **パスワード等の保護** — パスワードレス認証（FIDO2 / パスキー）推奨
- 実8: **本人確認** — リスクベース認証（Entra ID Protection）
- 実9: **ID不正使用防止** — アカウントロックアウト + 異常検知
- 実14: **不正侵入防止** — WAF + DDoS Protection + Bot Protection の多層防御

## アーキテクチャの特徴

### 多層防御（Defense in Depth）

インターネットバンキングはインターネットに直接公開されるシステムであるため、**7層の防御**を設計しています。

```
Layer 1: Azure Front Door + DDoS Protection (L3/L4 DDoS防御)
    ↓
Layer 2: Azure WAF (L7防御 — SQLi, XSS, CSRF, OWASP Top 10)
    ↓
Layer 3: Bot Protection + Rate Limiting (不正ログイン試行・スクレイピング防御)
    ↓
Layer 4: 認証・認可 (Entra External ID + MFA + リスクベース認証)
    ↓
Layer 5: アプリケーション層 (入力検証・セッション管理・CSRF トークン)
    ↓
Layer 6: ネットワーク分離 (NSG + Private Link — 勘定系への閉域接続)
    ↓
Layer 7: データ保護 (TDE + CMK + TLS 1.3 + 保存時暗号化)
```

### 顧客認証基盤（Microsoft Entra External ID）

顧客向けの認証・認可基盤として **Microsoft Entra External ID**（旧 Azure AD B2C）を採用します。CIAM（Customer Identity and Access Management）専用の機能を提供し、大規模な顧客認証に対応します。

| 機能 | 実装 | FISC対応 |
|------|------|---------|
| パスワード認証 | Entra External ID ローカルアカウント | 実1 |
| **パスワードレス認証（推奨）** | FIDO2 / パスキー対応 | 実1（強化） |
| MFA | SMS / Authenticator アプリ / FIDO2 | 実112 |
| リスクベース認証 | Entra ID Protection + Conditional Access | 実8, 実9 |
| アカウントロックアウト | スマートロックアウト（IP ベース） | 実9 |
| セルフサービス登録 | カスタムユーザーフロー | 実117 |
| eKYC 連携 | カスタム API コネクタ経由 | 実117 |
| ブランディング | 企業ロゴ・カラー・テキストのカスタマイズ | — |

> **参考**: [Microsoft Entra External ID overview](https://learn.microsoft.com/entra/external-id/customers/overview-customers-ciam) — 顧客向け CIAM ソリューション

### Azure Front Door によるグローバルエッジ保護

Azure Front Door Premium を採用し、**エッジでのセキュリティ処理**と**コンテンツ配信**を統合します。

| 機能 | 構成 | 効果 |
|------|------|------|
| **WAF** | OWASP Core Rule Set 3.2 + カスタムルール | SQLi/XSS/CSRF 等の Web 攻撃防御 |
| **Bot Protection** | Bot Manager Rule Set | 不正ログイン試行・スクレイピング防御 |
| **Rate Limiting** | IP / セッション単位のレート制限 | ブルートフォース攻撃防御 |
| **Geo Filtering** | 日本国内のみ許可（法人向けは要件による） | 海外からの不正アクセス防御 |
| **DDoS Protection** | Front Door 組み込み DDoS + Azure DDoS Protection | L3/L4/L7 DDoS 防御 |
| **Private Link Origin** | App Service / AKS への Private Link 接続 | オリジンの非公開化 |
| **CDN** | 静的コンテンツのエッジキャッシュ | レスポンスタイム改善 |
| **TLS 1.3** | エッジでの TLS 終端 + マネージド証明書 | 暗号化通信 |

> **参考**: [Azure Front Door DDoS protection](https://learn.microsoft.com/azure/frontdoor/front-door-ddos) — Front Door の DDoS 保護機能と WAF の統合

### アプリケーション基盤

Web アプリケーションの実行基盤として、要件に応じて以下の選択肢を用意しています。

| 選択肢 | 特徴 | 推奨ケース |
|-------|------|-----------|
| **App Service (Premium v3)** | フルマネージド、自動スケール、VNet 統合 | シンプルな構成、運用負荷最小化 |
| **App Service Environment v3 (ASE v3)** | 完全分離、専用ハードウェア、VNet 内配置 | 最高レベルのネットワーク分離要件 |
| **AKS Private Cluster** | コンテナオーケストレーション、マイクロサービス | 複雑なアプリ構成、細粒度スケーリング |

いずれの選択肢でも、**可用性ゾーン × 3** に分散配置し、自動スケーリングを有効化します。

### 勘定系連携（Private Link）

インターネットバンキングから勘定系システム（コアバンキング）への接続は、**Private Link** 経由の閉域網接続とし、インターネット側からの直接アクセスを完全に排除します。

```
┌─────────────────────┐          ┌──────────────────────┐
│ IB系 Spoke VNet      │          │ 勘定系 Spoke VNet     │
│                     │          │                      │
│ App Service / AKS   │──Private──▶│ APIM (Internal)     │
│                     │  Link    │ → AKS (勘定系API)    │
│                     │          │ → SQL MI (勘定系DB)  │
└─────────────────────┘          └──────────────────────┘
```

| 設計項目 | 内容 |
|---------|------|
| 接続方式 | APIM (Internal VNet) の Private Endpoint 経由 |
| 認証 | Managed Identity + OAuth 2.0 Client Credentials |
| レート制限 | APIM で IB 向けの API レート制限を適用 |
| サーキットブレーカー | APIM ポリシーで勘定系障害時の自動切断 |

### セッション管理

| 項目 | 設計 |
|------|------|
| セッションストア | Azure Cache for Redis Enterprise (可用性ゾーン、Active Geo-Replication) |
| セッション有効期限 | 30分（操作なし時の自動タイムアウト） |
| OTP 管理 | Redis TTL によるワンタイムパスワードの有効期限管理 |
| セッション固定攻撃対策 | ログイン成功時にセッション ID 再生成 |
| 同時ログイン制御 | Redis による同一ユーザーの複数セッション検知・制御 |

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
                        インターネット
                             │
                    ┌────────▼────────┐
                    │ Azure Front Door │
                    │ Premium          │
                    │ ・WAF (OWASP)    │
                    │ ・Bot Protection │
                    │ ・Rate Limiting  │
                    │ ・Geo Filtering  │
                    │ ・DDoS Protection│
                    │ ・CDN            │
                    └───┬─────────┬───┘
                        │         │
          Private Link  │         │ Private Link
                        ▼         ▼
┌───────────────────────────┐ ┌────────────────────────────┐
│ 東日本リージョン (Primary)   │ │ 西日本リージョン (Standby)   │
│                           │ │                            │
│ ┌───────────────────────┐ │ │ ┌────────────────────────┐ │
│ │ App Service / AKS     │ │ │ │ App Service / AKS      │ │
│ │ (可用性ゾーン x3)      │ │ │ │ (Warm Standby)         │ │
│ │ ┌──────┐ ┌──────┐    │ │ │ │ ┌──────┐ ┌──────┐     │ │
│ │ │Web UI│ │API   │    │ │ │ │ │Web UI│ │API   │     │ │
│ │ │SPA   │ │Layer │    │ │ │ │ │SPA   │ │Layer │     │ │
│ │ └──────┘ └──────┘    │ │ │ │ └──────┘ └──────┘     │ │
│ │ ┌──────────────────┐ │ │ │ │ ┌───────────────────┐ │ │
│ │ │ Entra External ID│ │ │ │ │ │ Entra External ID │ │ │
│ │ │ (認証・MFA)       │ │ │ │ │ │ (認証・MFA)        │ │ │
│ │ └──────────────────┘ │ │ │ │ └───────────────────┘ │ │
│ └──────────┬───────────┘ │ │ └──────────┬────────────┘ │
│            │              │ │            │               │
│ ┌──────────▼───────────┐ │ │ ┌──────────▼────────────┐ │
│ │ Azure SQL DB         │ │ │ │ Azure SQL DB           │ │
│ │ Business Critical    │ │ │ │ (Active Geo-Rep)       │ │
│ │ (可用性ゾーン内同期)   │ │ │ │                        │ │
│ └──────────────────────┘ │ │ └────────────────────────┘ │
│                          │ │                            │
│ ┌──────────────────────┐ │ │ ┌────────────────────────┐ │
│ │ Redis Enterprise     │ │ │ │ Redis Enterprise       │ │
│ │ (セッション/OTP)      │ │ │ │ (Active Geo-Rep)       │ │
│ └──────────────────────┘ │ │ └────────────────────────┘ │
│                          │ │                            │
│ ┌──────────────────────┐ │ │ ┌────────────────────────┐ │
│ │ Cosmos DB            │ │ │ │ Cosmos DB              │ │
│ │ (ユーザー設定/        │ │ │ │ (グローバルテーブル)      │ │
│ │  通知管理)            │ │ │ │                        │ │
│ └──────────────────────┘ │ │ └────────────────────────┘ │
│                          │ │                            │
│ ┌──────────────────────┐ │ │                            │
│ │ Private Link         │ │ │                            │
│ │ → 勘定系 APIM        │ │ │                            │
│ └──────────────────────┘ │ │                            │
│                          │ │                            │
│ ┌──────────────────────┐ │ │ ┌────────────────────────┐ │
│ │ Key Vault            │ │ │ │ Key Vault              │ │
│ │ (暗号鍵・証明書)      │ │ │ │                        │ │
│ └──────────────────────┘ │ │ └────────────────────────┘ │
└──────────────────────────┘ └────────────────────────────┘
                                                          
┌──────────────────────────────────────────────────────────┐
│ 共通サービス                                               │
│ ┌──────────────┐ ┌──────────────┐ ┌───────────────────┐ │
│ │ Log Analytics │ │ Sentinel     │ │ Defender for Cloud│ │
│ │ Workspace    │ │ (不正検知)    │ │                   │ │
│ └──────────────┘ └──────────────┘ └───────────────────┘ │
└──────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| Web アプリ | App Service (Premium v3) / AKS | 可用性ゾーン x3 + Autoscale | 24/365 運用・負荷変動対応 |
| エッジ配信 | Azure Front Door Premium | グローバル POP、Private Link Origin | 静的配信・セキュリティ統合 |
| WAF | Azure Front Door WAF | OWASP Core Rule Set 3.2 + Bot Protection | Web 攻撃防御 |
| 認証基盤 | Microsoft Entra External ID | 外部テナント、MFA、リスクベース認証 | 顧客 CIAM |

### データベース

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| 取引履歴・設定DB | Azure SQL Database Business Critical | Active Geo-Replication (東西)、可用性ゾーン | ACID 保証 |
| ユーザー設定・通知 | Cosmos DB (Session Consistency) | グローバルテーブル (東西) | 低レイテンシ参照 |

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| セッション / OTP | Azure Cache for Redis Enterprise | 可用性ゾーン、Active Geo-Replication | 高速セッション管理 |
| 通知配信 | Azure Communication Services / Event Grid | SMS・メール送信 | 取引通知・OTP 送信 |
| 静的コンテンツ | Blob Storage (ZRS) + Front Door CDN | エッジキャッシュ | SPA アセット配信 |
| 監査ログ | Blob Storage (RA-GRS) + WORM ポリシー | 不変ストレージ | 長期保存（10年） |

### セキュリティ

| コンポーネント | Azureサービス | 構成 | 選定理由 |
|-------------|-------------|------|---------|
| DDoS 防御 | Azure DDoS Protection + Front Door 組み込み | L3/L4/L7 | 大規模 DDoS 攻撃防御 |
| 暗号鍵管理 | Key Vault (Premium) | CMK 管理、証明書管理 | TDE CMK・アプリ暗号鍵 |
| 不正検知 | Microsoft Sentinel | カスタム分析ルール | 不正ログイン・異常取引検知 |
| CSPM | Defender for Cloud | セキュリティスコア監視 | 継続的セキュリティ評価 |
| 特権アクセス管理 | Entra PIM | JIT アクセス | FISC 実25 準拠 |

## FISC実務基準対応（インターネット・モバイルサービス）

| FISC基準 | 要件 | Azure実装 |
|---------|------|----------|
| 実112 | 不正使用の防止 | Entra External ID MFA + Conditional Access + Bot Protection + Rate Limiting |
| 実113 | 利用状況の確認手段 | ログイン履歴・取引履歴の表示機能（直近ログイン日時の画面表示） |
| 実115 | 顧客対応方法の明確化 | Azure Bot Service (FAQ) + Azure Communication Services (通知) |
| 実117 | オンライン口座開設の本人確認 | Entra External ID + eKYC API コネクタ連携 |
| 実1 | パスワード等の保護 | パスワードレス認証（FIDO2 / パスキー）推奨、パスワードポリシー強制 |
| 実8 | 本人確認 | リスクベース認証（Entra ID Protection — 位置情報・デバイス・行動パターン） |
| 実9 | ID不正使用防止 | スマートロックアウト + 異常検知 (Sentinel) + 同時ログイン制御 |
| 実14 | 不正侵入防止 | Front Door WAF + DDoS Protection + Azure Firewall |

## 可用性・DR設計

### 目標値

| 指標 | 目標 |
|------|------|
| **可用性** | 99.95%（年間ダウンタイム4.38時間以内） |
| **RTO** | < 15分 |
| **RPO** | < 5分 |

### 障害レベル別対応

| 障害レベル | 事象 | 対応 | RTO |
|-----------|------|------|-----|
| Level 1 | 単一コンポーネント障害 | App Service インスタンス自動再起動、SQL DB AZ 内 FO | < 30秒 |
| Level 2 | 可用性ゾーン障害 | Front Door が正常 AZ へトラフィック移行、SQL DB 同期レプリカ FO | < 2分 |
| Level 3 | リージョン障害 | Front Door が西日本へルーティング切替（下記フロー参照） | < 15分 |

### リージョン切替自動化フロー

```
┌──────────────────────────────────────────┐
│  Step 1: 障害検知                         │
│    Front Door ヘルスプローブが東日本の       │
│    オリジン異常を検知                       │
│    + 外形監視 (3拠点) のアラート            │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 2: Front Door 自動ルーティング       │
│    Front Door が西日本オリジンへ             │
│    トラフィックを自動切替                    │
│    ※Front Door の組み込みフェイルオーバー    │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 3: データ層フェイルオーバー            │
│    Azure Automation Runbook (西日本で実行)  │
│    SQL DB Active Geo-Replication → 西日本昇格│
│    Redis → Active Geo-Replication 切替      │
│    Cosmos DB → 書込リージョン切替             │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 4: 勘定系接続切替                    │
│    西日本 IB → 西日本勘定系 APIM へ          │
│    Private Link 接続を有効化                 │
│    ※勘定系側のフェイルオーバーと連動           │
└────────────────────┬─────────────────────┘
                     ▼
┌──────────────────────────────────────────┐
│  Step 5: ヘルスチェック・通知               │
│    西日本環境の外形監視・ヘルスチェック        │
│    → 切替完了通知 (社内・顧客告知)           │
└──────────────────────────────────────────┘
```

> **設計ポイント**: IB系は Front Door の組み込みフェイルオーバー機能により、ヘルスプローブ失敗時に自動的に西日本オリジンへルーティングが切り替わります。勘定系等のバックエンドシステムが Tier 1 のため、IB 単独でのフェイルオーバーだけでなく、勘定系側のフェイルオーバーとの連動が必要です。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL DB PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 監査ログ保存 | Blob Storage (RA-GRS) + 不変 (WORM) ポリシー（10年保存） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ランサムウェアによりデータを暗号化・使用不能とされた場合の復旧手段として、不変バックアップからの復元を行います。コンプライアンスモードでボールトロックを作成することで、イミュータブルとなり、データ保持期間が終了するまでデータを削除または変更できなくなります。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | SQL DB Active Geo-Replication の計画的フェイルオーバーを四半期毎に実施 |
| Front Door 切替訓練 | オリジンの計画的ダウンによるルーティング切替検証 |
| 負荷テスト | ピーク時（給料日・賞与日相当）のトラフィックでのスケーリング検証 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Azure Front Door Premium (グローバル)
│
│ Private Link Origin
│
├──▶ Spoke VNet: IB系 東日本 (10.14.0.0/16)
│    ├── snet-app        (10.14.0.0/24)  — App Service VNet 統合 / AKS ノード
│    ├── snet-db         (10.14.1.0/24)  — SQL Database Private Endpoint
│    ├── snet-redis      (10.14.2.0/24)  — Redis Enterprise Private Endpoint
│    ├── snet-cosmos     (10.14.3.0/24)  — Cosmos DB Private Endpoint
│    ├── snet-pe         (10.14.4.0/24)  — その他 Private Endpoint (Key Vault 等)
│    ├── snet-core-pe    (10.14.5.0/24)  — 勘定系 APIM Private Endpoint
│    └── snet-logic      (10.14.6.0/24)  — 通知サービス (Communication Services 等)
│
└──▶ Spoke VNet: IB系 西日本 (10.15.0.0/16)
     ├── (同一サブネット構成)
     └── ...

NSG ルール:
- インバウンド: Front Door サービスタグからのみ許可（直接アクセス不可）
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- snet-core-pe: 勘定系 APIM への通信のみ許可（最小権限）
- SQL DB / Redis: Private Endpoint 経由のアクセスのみ許可
```

> **設計ポイント**: IB 系 VNet からインターネットへの直接アウトバウンド通信は禁止し、Hub VNet の Azure Firewall 経由でのみ外部通信を許可します。Front Door からのインバウンドは Front Door サービスタグで制限し、Front Door を経由しない直接アクセスを排除します。

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | IB のログインページ表示・残高照会 API の疑似リクエスト |
| テスト頻度 | 1〜5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | IB → 勘定系 API の E2E トレース・レイテンシ分析 |
| RUM (Real User Monitoring) | Application Insights JavaScript SDK | エンドユーザーの実体験パフォーマンス計測 |
| サービスマップ | Application Insights Application Map | IB 各コンポーネント間の依存関係・ボトルネック可視化 |
| メトリクス収集 | Azure Monitor | CPU、メモリ、リクエスト数、エラー率のリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 不正ログイン検知・異常取引検知・セキュリティイベント相関分析 |

> IB 系ではエンドユーザーの体験品質が直接顧客満足度に影響するため、**Real User Monitoring (RUM)** による実際のブラウザパフォーマンス計測を重視します。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| ページ応答時間 | Application Insights | P95 > 3秒 |
| API 応答時間 | Application Insights | P99 > 1秒 |
| エラー率 | Application Insights | > 1% |
| ログイン失敗率 | Entra External ID + Sentinel | 短時間の大量失敗（ブルートフォース検知） |
| 不正取引パターン | Microsoft Sentinel | 異常な振込パターン・高額取引の検知 |
| DDoS 検知 | Azure DDoS Protection | 攻撃検知時即時通知 |
| WAF ブロック急増 | Front Door WAF ログ | ブロック数の急増 |
| DB CPU使用率 | Azure Monitor | > 80% |
| Redis メモリ使用率 | Azure Monitor | > 80% |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| Front Door オリジン健全性 | Front Door 診断ログ | オリジン健全性 < 80% |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| デプロイ戦略 | **ブルーグリーンデプロイ**（App Service スロット / AKS Canary） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| フロントエンド | SPA ビルド → Blob Storage + Front Door CDN で配信 |

## 関連リソース

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Microsoft Entra External ID overview](https://learn.microsoft.com/entra/external-id/customers/overview-customers-ciam)
- [Azure Front Door DDoS protection](https://learn.microsoft.com/azure/frontdoor/front-door-ddos)
- [Azure Web Application Firewall on Azure Front Door](https://learn.microsoft.com/azure/web-application-firewall/afds/afds-overview)
- [App Service Environment v3 overview](https://learn.microsoft.com/azure/app-service/environment/overview)
- [Enterprise deployment using App Service Environment](https://learn.microsoft.com/azure/architecture/reference-architectures/enterprise-integration/ase-standard-deployment)
- [Azure SQL Database Business Critical tier](https://learn.microsoft.com/azure/azure-sql/database/service-tier-business-critical)
- [Azure Cache for Redis Enterprise](https://learn.microsoft.com/azure/azure-cache-for-redis/cache-overview#service-tiers)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
- [FISC compliance on Microsoft Cloud](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
