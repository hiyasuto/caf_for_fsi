# APIバンキング（オープンAPI）ランディングゾーン

> 銀行法改正に基づく電子決済等代行業者向けオープンAPIプラットフォームのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行法に基づく電子決済等代行業者（PISP/AISP）向けオープンAPIの公開基盤を対象としています。勘定系への接続は [勘定系ランディングゾーン](core-banking.md) を、対外接続系は [対外接続系ランディングゾーン](external-connectivity.md) を参照してください。
- 全国銀行協会（全銀協）の [オープンAPIに係る電文仕様標準（第2版）](https://www.zenginkyo.or.jp/fileadmin/res/news/news301227_3.pdf) に準拠した参照系・更新系APIの設計を前提としています。
- セキュリティプロファイルは [Financial-grade API（FAPI）2.0 Security Profile](https://openid.net/wg/fapi/) に準拠し、OAuth 2.0 / OpenID Connect による認可基盤を構築します。
- 本アーキテクチャは [Azure API Management ランディングゾーンアクセラレータ](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/api-management/landing-zone-accelerator) のガイダンスを基礎としています。
- オンプレミス環境との接続は ExpressRoute による閉域網接続を前提としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | APIバンキングプラットフォーム（オープンAPI） |
| 主な機能 | 参照系API（残高照会・入出金明細）、更新系API（振込指示）、同意管理、TPP管理 |
| FISC外部性 | **機微性** — 外部事業者への口座情報・取引指示の提供。更新系は重大な外部性 |
| 重要度 | **Tier 2（更新系はTier 1相当）** |
| 処理特性 | REST API（JSON/HTTPS）、低レイテンシ応答、バースト対応 |
| 可用性要件 | 99.95%以上（参照系）、99.99%以上（更新系） |

## ユースケース

- 電子決済等代行業者（FinTech事業者）が銀行口座情報を参照し、家計簿アプリ・会計ソフト等で利用する（参照系API / AISP）
- 電子決済等代行業者が利用者の同意に基づき振込指示を銀行に送信する（更新系API / PISP）
- 株式・投信の売買指図、資金移動（振込・振替）など金融取引の外部連携
- 銀行グループ内の他社アプリ（証券・保険等）がAPIを通じて口座連携を行う（グループ内API）
- 株価・為替相場などのマーケット情報照会、ポイント残高照会（公開/軽量API）
- 法人顧客向けにERP/会計システムとの自動連携APIを提供する（法人API）
- APIプラットフォームを通じたBaaS（Banking as a Service）モデルの展開

## FISC基準上の位置づけ

APIバンキングは、外部事業者に銀行機能を提供するシステムとして、FISC基準上「機微性を有するシステム」に分類されます。特に更新系API（振込指示等）は、不正利用時に直接的な金銭被害が発生し得るため、勘定系に準じた安全対策が求められます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（外部接続に関する付加基準を含む）
- 実1〜実9: 認証・認可（FAPI準拠の強認証が必須）
- 実3: **蓄積データの保護** — 取引データ・顧客情報の暗号化
- 実14〜実16: 不正侵入防止・監視（API特有の脅威対策）
- 実25〜実28: アクセス権限管理（TPP別の権限制御）
- 実34: **外部接続管理** — TPP との接続経路の保護・監視
- 実39〜実45: バックアップ（更新系はTier 1レベル）
- 実150: 外部委託・外部接続管理（TPPとの接続契約管理）
- 実151: クラウド利用管理

## アーキテクチャの特徴

### FAPI 2.0 準拠の認可基盤

金融グレードのAPIセキュリティを実現するため、FAPI 2.0 Security Profile に準拠した認可基盤を構築します。

| FAPI要件 | 実装方式 | Azureサービス |
|----------|---------|--------------|
| クライアント認証 | mTLS / private_key_jwt | API Management クライアント証明書検証ポリシー |
| PKCE（Proof Key for Code Exchange） | S256 必須 | Microsoft Entra ID / Entra External ID |
| PAR（Pushed Authorization Request） | 認可リクエストの事前登録 | カスタム認可サーバー（AKS上） |
| 送信者制約トークン | mTLS Certificate-Bound Token | API Management validate-jwt + 証明書バインディング |
| 同意管理（Consent） | 明示的同意取得・管理 | Cosmos DB（同意レコード） + カスタムUI |
| ID Token暗号化 | JWE（A256GCM） | Key Vault（暗号鍵管理） |

### API製品別セキュリティポリシー

単一の API Management ゲートウェイ上で、API Management Products の機能を活用し、APIの性質に応じた段階的なセキュリティポリシーを適用します。2層のゲートウェイに分離するのではなく、**統一ゲートウェイ × 製品別ポリシー**の構成とすることで、運用の一元化とセキュリティの一貫性を両立します。

| API製品 | 対象API | 認証方式 | セキュリティレベル |
|---------|--------|---------|-----------------|
| `public-data` | マーケット情報・為替レート | APIキー（Subscription Key） | 低（公開情報） |
| `user-readonly` | 自口座残高照会・明細照会 | OAuth 2.0 + PKCE（Entra External ID） | 中（個人情報） |
| `aisp-fapi` | TPP向け参照系API | FAPI 2.0（mTLS + Certificate-Bound Token） | 高（TPP連携） |
| `pisp-fapi` | TPP向け更新系API（振込等） | FAPI 2.0（mTLS + PAR + 送信者制約） | 最高（金融取引） |

> **設計判断**: AWSリファレンスアーキテクチャでは、Amazon Cognito（FAPI非対応）とFAPI対応外部認可サーバーを物理的に分離した2層構成を採用しています。Azureでは Microsoft Entra ID / External ID がOAuth 2.0 / OIDC をネイティブに提供し、API Management のポリシーエンジンでmTLS・Certificate-Bound Token検証をゲートウェイレベルで実施できるため、**単一ゲートウェイ上で製品別にセキュリティレベルを適用する統一アーキテクチャ**が最適です。

### 認可サーバーの選択肢

FAPI 2.0 準拠の認可サーバーは、以下の3パターンから組織の要件に応じて選択します。

| 選択肢 | 製品例 | 特徴 | 推奨ケース |
|--------|-------|------|-----------|
| **Entra ID + APIM ポリシー** | Microsoft Entra ID / External ID | Azure ネイティブ。PKCE・OAuth 2.0 は標準対応。mTLS・Certificate-Bound Token は APIM ポリシーで補完 | Azure統合を最大化したい場合（推奨） |
| **3rdパーティ認可サーバー** | Authlete | FAPI 1.0/2.0 の認定取得済み。PAR・RAR・CIBA等の先進機能を標準搭載 | FAPI認定取得が必須要件の場合 |
| **OSSベース** | Keycloak（AKS上） | FAPI 1.0 対応。カスタマイズ自由度が高い。運用負荷は最大 | 既存Keycloak資産がある場合 |

> **推奨構成**: Entra ID をベースの認証基盤とし、FAPI 2.0 固有要件（mTLS Certificate Binding、PAR等）は API Management のカスタムポリシーおよびAKS上の軽量な認可拡張サービスで補完する構成を推奨します。Authlete等の専用認可サーバーを採用する場合も、API Management の背後に配置し、ゲートウェイ層でのトラフィック制御・監視は統一します。

### カスタムドメインとTLS証明書管理

オープンAPIプラットフォームは外部公開サービスのため、カスタムドメインとTLS証明書の適切な管理が必要です。

| コンポーネント | ドメイン例 | TLS証明書 | 管理方式 |
|-------------|-----------|----------|---------|
| Azure Front Door | `api.bank.co.jp` | Front Door マネージド証明書（自動更新） | Front Door 標準機能 |
| API Management Gateway | `gateway.api.bank.co.jp` | Key Vault 連携（自動ローテーション） | Key Vault + APIM 統合 |
| 開発者ポータル | `developer.api.bank.co.jp` | Key Vault 連携 | App Service カスタムドメイン |
| 認可エンドポイント | `auth.api.bank.co.jp` | Key Vault 連携 | AKS Ingress + cert-manager |

**DNS構成**:
- `api.bank.co.jp` → Azure Front Door（CNAME）→ APIM（Private Link Origin）
- Azure Private DNS Zone で内部名前解決（VNet内のみ）
- カスタムドメインのDNSは Azure DNS で一元管理（CAA レコードにより発行元CA制限）

### 全銀協電文仕様標準への対応

全銀協が策定したオープンAPI電文仕様標準（第2版）に基づき、参照系・更新系APIの電文を設計します。

**参照系API（AISP向け）**:

| API | エンドポイント例 | 主な応答項目 |
|-----|----------------|-------------|
| 残高照会 | `GET /accounts/{id}/balances` | 口座識別子、通貨コード（ISO 4217）、現在残高、基準日 |
| 入出金明細照会 | `GET /accounts/{id}/transactions` | 取引日、金額、摘要、取引種別、残高 |
| 口座一覧 | `GET /accounts` | 口座番号、口座種別、口座名義 |

**更新系API（PISP向け）**:

| API | エンドポイント例 | 主な要求項目 |
|-----|----------------|-------------|
| 振込指示 | `POST /payments/domestic-transfers` | 振込先口座情報、金額、処理日、認証情報 |
| 振込状態照会 | `GET /payments/{id}/status` | 処理状態、受付番号、エラーコード |
| 振込取消 | `DELETE /payments/{id}` | 取消理由、認証情報 |

### API Gateway アーキテクチャ

Azure API Management Premium v2 を中核として、多層防御型のAPIゲートウェイを構築します。

```
TPP（FinTech）             銀行利用者
     │                       │
     ▼                       ▼
┌──────────────────────────────────────┐
│ Azure Front Door Premium             │
│ ・DDoS Protection                    │
│ ・WAF（OWASP Top 10 / API脅威）      │
│ ・Geo-フィルタリング（日本のみ）       │
└──────────┬───────────────────────────┘
           ▼
┌──────────────────────────────────────┐
│ Azure API Management Premium v2      │
│ ・VNet Injection（完全閉域）          │
│ ・mTLS クライアント認証               │
│ ・OAuth 2.0 / FAPI ポリシー          │
│ ・レート制限・クォータ管理             │
│ ・API バージョニング                  │
│ ・リクエスト/レスポンス検証            │
│ ・バックエンド回路遮断器              │
└──────────┬───────────────────────────┘
           ▼
┌──────────────────────────────────────┐
│ バックエンドマイクロサービス（AKS）     │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │認可     │ │参照系   │ │更新系   │ │
│ │サービス │ │API      │ │API      │ │
│ └────┬────┘ └────┬────┘ └────┬────┘ │
│      │           │           │       │
│      ▼           ▼           ▼       │
│ ┌─────────┐ ┌─────────┐ ┌─────────┐ │
│ │同意管理 │ │TPP管理  │ │監査     │ │
│ │サービス │ │サービス │ │サービス │ │
│ └─────────┘ └─────────┘ └─────────┘ │
└──────────────────────────────────────┘
```

### TPP（電子決済等代行業者）管理

金融庁に登録された電子決済等代行業者のみがAPIを利用できるよう、厳格なTPP管理を実施します。

| 管理項目 | 実装方式 |
|----------|---------|
| TPP登録審査 | 金融庁登録番号の確認、セキュリティ監査（ISO 27001等） |
| クライアント証明書管理 | Key Vault + mTLS。証明書有効期限監視と自動ローテーション |
| API製品・サブスクリプション管理 | API Management Products（参照系/更新系を分離） |
| レート制限（Rate Limiting） | TPP別・API製品別の呼び出し上限（rate-limit-by-key ポリシー） |
| クォータ管理 | 月間呼び出し回数の上限（quota-by-key ポリシー） |
| TPP監視ダッシュボード | Application Insights + Workbooks による呼び出し統計 |
| 契約管理 | 銀行法に基づくAPI利用契約（全銀協条文例準拠） |

### 同意管理（Consent Management）

利用者がTPPに対してどの口座・どの操作を許可したかを一元管理する同意管理基盤を構築します。

```
利用者 ──▶ 同意画面（銀行ドメイン）──▶ 同意レコード作成
                                        │
                                        ▼
                                   Cosmos DB
                                   ┌───────────────────────┐
                                   │ consent_id: "c-001"   │
                                   │ user_id: "u-123"      │
                                   │ tpp_id: "tpp-456"     │
                                   │ scope: ["balances",   │
                                   │         "transactions"]│
                                   │ accounts: ["acct-789"]│
                                   │ granted_at: "2025-..."│
                                   │ expires_at: "2026-..."│
                                   │ status: "active"      │
                                   │ revoked_at: null      │
                                   └───────────────────────┘
```

**同意のライフサイクル**:
1. **同意取得**: 利用者が銀行の同意画面でTPPへのアクセス許可を明示的に付与
2. **同意検証**: API呼び出し時にAPI Managementポリシーで同意レコードを検証
3. **同意更新**: 有効期限前にTPPが再同意を要求（リフレッシュフロー）
4. **同意撤回**: 利用者がいつでも銀行チャネルから同意を撤回可能
5. **同意監査**: 全同意操作をLedgerテーブルに記録（改ざん防止）

### 更新系APIのトランザクション保証

更新系API（振込指示等）は金銭取引を伴うため、勘定系との間で厳密なトランザクション保証を実現します。

| 要件 | 実装方式 |
|------|---------|
| べき等性（Idempotency） | x-idempotency-key ヘッダー + Redis による重複排除 |
| 非同期処理 | 振込指示 → 受付番号返却 → 状態照会パターン |
| 補償トランザクション | Saga パターン（Orchestration型）による分散トランザクション |
| 二重送信防止 | API Management でx-idempotency-keyの重複チェック |
| タイムアウト制御 | 振込指示: 30秒、残高照会: 5秒 |
| リトライ制御 | Exponential Backoff + Circuit Breaker |

## アーキテクチャ図

```
                    ┌────────────────────────────────────────────────────────────────────────┐
                    │                        Azure（東日本リージョン）                          │
                    │                                                                        │
 TPP（FinTech）     │  ┌──────────────────────────────────────────────────────────────────┐   │
 ┌──────────┐      │  │                    APIバンキング Spoke VNet (10.30.0.0/16)        │   │
 │FinTech   │      │  │                                                                  │   │
 │アプリ    │──┐   │  │  ┌────────────────────────────────────────────────────────────┐  │   │
 └──────────┘  │   │  │  │ Frontend Subnet (10.30.1.0/24)                             │  │   │
 ┌──────────┐  │   │  │  │  ┌──────────────────────────────────────────────────────┐  │  │   │
 │FinTech   │  │   │  │  │  │ Azure API Management Premium v2                      │  │  │   │
 │アプリ    │──┤   │  │  │  │  ・VNet Injection（Public IP なし）                    │  │  │   │
 └──────────┘  │   │  │  │  │  ・mTLS + FAPI ポリシー                               │  │  │   │
               │   │  │  │  │  ・rate-limit-by-key / quota-by-key                   │  │  │   │
               │   │  │  │  │  ・validate-jwt / validate-content                    │  │  │   │
 銀行利用者    │   │  │  │  │  ・Circuit Breaker（バックエンド保護）                  │  │  │   │
 ┌──────────┐  │   │  │  │  └──────────────────────────────────────────────────────┘  │  │   │
 │同意画面  │──┤   │  │  └────────────────────────────────────────────────────────────┘  │   │
 │（銀行）  │  │   │  │                                                                  │   │
 └──────────┘  │   │  │  ┌────────────────────────────────────────────────────────────┐  │   │
               │   │  │  │ App Subnet (10.30.2.0/24)                                  │  │   │
      ─────────┘   │  │  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │   │
          │        │  │  │  │認可サービス │ │参照系API   │ │更新系API   │              │  │   │
  Azure Front Door │  │  │  │(FAPI/OAuth) │ │(AISP)      │ │(PISP)      │              │  │   │
  ＋ WAF Policy    │  │  │  └────────────┘ └────────────┘ └────────────┘              │  │   │
          │        │  │  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │   │
          └────────┤  │  │  │同意管理    │ │TPP管理     │ │監査サービス│              │  │   │
                   │  │  │  │サービス    │ │サービス    │ │            │              │  │   │
                   │  │  │  └────────────┘ └────────────┘ └────────────┘              │  │   │
                   │  │  │  ※ AKS Private Cluster（3 AZ分散）                         │  │   │
                   │  │  └────────────────────────────────────────────────────────────┘  │   │
                   │  │                                                                  │   │
                   │  │  ┌────────────────────────────────────────────────────────────┐  │   │
                   │  │  │ Data Subnet (10.30.3.0/24)                                 │  │   │
                   │  │  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │   │
                   │  │  │  │Cosmos DB   │ │Azure Cache │ │Azure SQL   │              │  │   │
                   │  │  │  │(同意/TPP)  │ │for Redis   │ │Ledger      │              │  │   │
                   │  │  │  │            │ │(べき等性)  │ │(監査ログ)  │              │  │   │
                   │  │  │  └────────────┘ └────────────┘ └────────────┘              │  │   │
                   │  │  └────────────────────────────────────────────────────────────┘  │   │
                   │  │                                                                  │   │
                   │  │  ┌────────────────────────────────────────────────────────────┐  │   │
                   │  │  │ Integration Subnet (10.30.4.0/24)                          │  │   │
                   │  │  │  ┌────────────┐ ┌────────────┐ ┌────────────┐              │  │   │
                   │  │  │  │Service Bus │ │Event Hubs  │ │Event Grid  │              │  │   │
                   │  │  │  │(振込指示Q) │ │(APIログ)   │ │(Webhook)   │              │  │   │
                   │  │  │  └────────────┘ └────────────┘ └────────────┘              │  │   │
                   │  │  └────────────────────────────────────────────────────────────┘  │   │
                   │  │                                                                  │   │
                   │  │  ┌────────────────────────────────────────────────────────────┐  │   │
                   │  │  │ Private Endpoint Subnet (10.30.5.0/24)                     │  │   │
                   │  │  │  Key Vault / Storage / Container Registry PE               │  │   │
                   │  │  └────────────────────────────────────────────────────────────┘  │   │
                   │  │                                                                  │   │
                   │  │         ┌─── VNet Peering ───┐                                   │   │
                   │  └─────────┘                    └───────────────────────────────────┘   │
                   │                                                                        │
                   │        Hub VNet (10.0.0.0/16)                                          │
                   │        ├── ExpressRoute Gateway                                        │
                   │        ├── Azure Firewall Premium                                      │
                   │        └── Private DNS Resolver                                        │
                   │                 │                                                      │
                   └─────────────────┼──────────────────────────────────────────────────────┘
                                     │ ExpressRoute
                                     ▼
                    ┌────────────────────────────────────────────┐
                    │ オンプレミス                                │
                    │  ┌──────────┐  ┌──────────┐               │
                    │  │ 勘定系   │  │ CRM      │               │
                    │  │ ホスト   │  │          │               │
                    │  └──────────┘  └──────────┘               │
                    └────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| サービス | 用途 | SKU/構成 |
|---------|------|---------|
| Azure API Management | APIゲートウェイ | Premium v2（VNet Injection、3 AZ） |
| Azure Kubernetes Service | バックエンドマイクロサービス | Private Cluster、Standard_D4s_v5 × 6+ |
| Azure Front Door | グローバルエントリポイント | Premium（WAF + Private Link Origin） |

### データストア

| サービス | 用途 | SKU/構成 |
|---------|------|---------|
| Azure Cosmos DB | 同意レコード・TPP管理 | Multi-region Write、Session Consistency |
| Azure Cache for Redis | べき等性キー・セッション・レート制限 | Enterprise E10（Active Geo-Rep） |
| Azure SQL Database | API利用統計・分析 | Hyperscale（Ledger テーブル有効） |
| Azure SQL Ledger | 監査ログ（改ざん防止） | 自動ダイジェスト（Azure Confidential Ledger連携） |

### メッセージング・統合

| サービス | 用途 | SKU/構成 |
|---------|------|---------|
| Azure Service Bus | 更新系API非同期処理 | Premium（VNet統合、重複検出有効） |
| Azure Event Hubs | APIアクセスログストリーム | Standard（Kafka互換） |
| Azure Event Grid | Webhook通知（振込完了通知等） | System Topics |

### セキュリティ・認証

| サービス | 用途 | SKU/構成 |
|---------|------|---------|
| Microsoft Entra ID | 内部認証・TPP OIDC認可 | P2（条件付きアクセス + PIM） |
| Microsoft Entra External ID | 利用者同意フロー（CIAM） | External tenant |
| Azure Key Vault | 証明書・暗号鍵・シークレット管理 | Premium HSM（FIPS 140-2 Level 3） |
| Azure Managed HSM | FAPI署名鍵（JWS/JWE） | Standard B1 |

### 監視・ガバナンス

| サービス | 用途 | SKU/構成 |
|---------|------|---------|
| Azure Monitor | メトリクス・ログ統合 | — |
| Application Insights | API応答時間・エラー率 | Workspace-based |
| Microsoft Sentinel | APIセキュリティ監視 | Pay-as-you-go |
| Microsoft Defender for APIs | API脅威検出 | Defender for Cloud P2 |

## 可用性・DR設計

### 可用性目標

| API種別 | 可用性目標 | RTO | RPO |
|---------|----------|-----|-----|
| 参照系API | 99.95% | < 15分 | < 5分 |
| 更新系API | 99.99% | < 5分 | ≈ 0（メッセージロスなし） |
| 同意管理 | 99.95% | < 15分 | < 1分 |
| 開発者ポータル | 99.9% | < 1時間 | < 1時間 |

### 障害レベル別の対応

| 障害レベル | 影響範囲 | 対応方式 | 想定RTO |
|-----------|---------|---------|---------|
| L1: AZ障害 | 単一AZ | AZ間自動フェイルオーバー（API Management + AKS） | 自動（数分） |
| L2: サービス障害 | 特定サービス | Circuit Breaker + Fallback応答 | 自動（秒単位） |
| L3: リージョン障害 | 東日本全域 | 西日本へのDRフェイルオーバー | < 30分 |
| L4: データ破損 | データ層 | Point-in-Time Restore + Ledger検証 | < 2時間 |

### DR構成（西日本リージョン）

> **設計ポイント**: 認証・認可基盤に Microsoft Entra ID（外部IdP）を使用することで、リージョン間での認証情報の同期が不要となります。Entra ID はグローバルサービスとして両リージョンのAPI基盤から参照でき、DRフェイルオーバー時もトークン検証が継続可能です。3rdパーティ認可サーバー（Authlete等）を採用する場合も、マルチリージョン対応のSaaS製品を選定することで同等のメリットが得られます。

```
┌──────────────────────────┐     ┌──────────────────────────┐
│   東日本（プライマリ）      │     │   西日本（DR）            │
│                           │     │                          │
│ API Management Premium v2 │ ──▶ │ API Management Premium v2│
│ (Active)                  │     │ (Standby)                │
│                           │     │                          │
│ AKS Cluster               │ ──▶ │ AKS Cluster              │
│ (Active, 3 AZ)            │     │ (Warm Standby)           │
│                           │     │                          │
│ Cosmos DB                 │ ◀─▶ │ Cosmos DB                │
│ (Multi-region Write)      │     │ (Auto Failover)          │
│                           │     │                          │
│ Redis Enterprise          │ ◀─▶ │ Redis Enterprise         │
│ (Active Geo-Rep)          │     │ (Active Geo-Rep)         │
│                           │     │                          │
│ Service Bus Premium       │ ──▶ │ Service Bus Premium      │
│ (Geo-DR paired)           │     │ (Geo-DR paired)          │
└──────────────────────────┘     └──────────────────────────┘
        ▲                                ▲
        └──── Azure Front Door ──────────┘
              (自動フェイルオーバー)
```

### バックアップ

| データ | バックアップ方式 | 保持期間 | 頻度 |
|-------|----------------|---------|------|
| 同意レコード（Cosmos DB） | 継続的バックアップ（PITR） | 30日 | 継続的 |
| 監査ログ（SQL Ledger） | 自動バックアップ + LTR | 10年 | 日次 |
| API利用統計 | geo冗長バックアップ | 7年 | 日次 |
| API定義・ポリシー | Git リポジトリ（IaC） | 無期限 | コミット毎 |
| Key Vault（証明書・鍵） | 論理削除 + 消去保護 | 90日 | — |

### DR訓練

| 訓練種別 | 頻度 | 内容 |
|---------|------|------|
| Cosmos DB フェイルオーバー | 四半期 | Multi-region Write の手動フェイルオーバー実行 |
| API Management DR切替 | 半期 | Front Door によるリージョン切替とTPPへの通知訓練 |
| 更新系API障害シミュレーション | 四半期 | Service Bus 障害注入と補償トランザクションの検証 |
| 全面DR訓練 | 年次 | 全コンポーネントの西日本切替と復旧 |

## ネットワーク設計

### サブネット構成

```
API Banking Spoke VNet - 東日本 (10.30.0.0/16)
├── APIM Subnet (10.30.1.0/24)
│   └── API Management Premium v2（VNet Injection）
├── App Subnet (10.30.2.0/24)
│   └── AKS Private Cluster（ノードプール）
├── Data Subnet (10.30.3.0/24)
│   └── Cosmos DB / Redis / SQL PE
├── Integration Subnet (10.30.4.0/24)
│   └── Service Bus / Event Hubs / Event Grid PE
├── Private Endpoint Subnet (10.30.5.0/24)
│   └── Key Vault / Storage / ACR PE
└── Developer Portal Subnet (10.30.6.0/24)
    └── App Service（開発者ポータルカスタムUI）

API Banking Spoke VNet - 西日本 (10.31.0.0/16)
├── APIM Subnet (10.31.1.0/24)
├── App Subnet (10.31.2.0/24)
├── Data Subnet (10.31.3.0/24)
├── Integration Subnet (10.31.4.0/24)
├── Private Endpoint Subnet (10.31.5.0/24)
└── Developer Portal Subnet (10.31.6.0/24)
```

### NSGルール（APIM Subnet）

| 方向 | 送信元 | 宛先 | ポート | プロトコル | 用途 |
|------|--------|------|--------|-----------|------|
| Inbound | Azure Front Door | APIM Subnet | 443 | TCP | APIリクエスト |
| Inbound | AzureLoadBalancer | APIM Subnet | 6390 | TCP | APIM管理 |
| Outbound | APIM Subnet | App Subnet | 443 | TCP | バックエンド通信 |
| Outbound | APIM Subnet | AzureKeyVault | 443 | TCP | 証明書・シークレット取得 |
| Outbound | APIM Subnet | AzureMonitor | 443 | TCP | ログ・メトリクス送信 |
| Outbound | APIM Subnet | Storage | 443 | TCP | ログ・構成の保存 |

### APIトラフィックフロー

```
TPP ──▶ Front Door ──▶ APIM (mTLS) ──▶ AKS ──▶ Service Bus ──▶ 勘定系
                        │                │              ↑
                        ├─▶ Key Vault    ├─▶ Cosmos DB  │
                        │   (証明書検証)  │   (同意検証)  │
                        │                │              │
                        └─▶ Redis        └─▶ SQL Ledger │
                            (レート制限)      (監査記録)  │
                                                        │
                     振込結果 ◀── Event Grid ◀──────────┘
                     (Webhook)
```

## 監視・オブザーバビリティ

### API固有の監視メトリクス

| メトリクス | 閾値 | アラート |
|-----------|------|---------|
| API応答時間（P95） | 参照系 < 200ms / 更新系 < 500ms | Warning: 150% / Critical: 200% |
| API可用性 | 参照系 99.95% / 更新系 99.99% | 目標値を下回った場合 |
| 4xx エラー率 | < 5% | Warning: 5% / Critical: 10% |
| 5xx エラー率 | < 0.1% | Warning: 0.1% / Critical: 0.5% |
| レート制限ヒット率 | — | 特定TPPの異常なヒット増加 |
| mTLS認証失敗 | — | 失敗パターンの異常検知 |
| 同意切れAPI呼び出し | 0 | 1件以上で即時アラート |

### セキュリティ監視

| 監視項目 | 検知方式 | 対応 |
|---------|---------|------|
| APIエンドポイントスキャン | Defender for APIs | 自動ブロック + SOCエスカレーション |
| 異常なAPI呼び出しパターン | Sentinel Analytics Rule | TPPへの確認 + 一時停止検討 |
| 証明書の不正利用 | API Management ログ分析 | 即時証明書失効 |
| 同意なしアクセス試行 | カスタム検知ルール | 自動ブロック + 監査記録 |
| DDoS攻撃 | Front Door + DDoS Protection | 自動緩和 + 通知 |
| OWASP API脅威 | WAF + API Management Validation | 自動ブロック |

### APIダッシュボード

| ダッシュボード | 対象者 | 主な表示項目 |
|-------------|--------|-------------|
| API運用ダッシュボード | 運用チーム | 可用性、レイテンシ、エラー率、スループット |
| TPP利用状況 | ビジネス | TPP別呼び出し数、利用API分布、成長トレンド |
| セキュリティ概況 | CISO/SOC | 脅威検知、認証失敗、異常パターン |
| SLA/KPIレポート | 経営層 | SLA達成率、TPP数推移、更新系API利用拡大 |

## デプロイ・IaC

### リポジトリ構成

```
api-banking-platform/
├── infra/
│   ├── modules/
│   │   ├── apim/              # API Management（Bicep）
│   │   ├── aks/               # AKS Private Cluster
│   │   ├── cosmos/            # Cosmos DB（同意/TPP）
│   │   ├── redis/             # Azure Cache for Redis
│   │   ├── servicebus/        # Service Bus Premium
│   │   ├── keyvault/          # Key Vault + 証明書
│   │   ├── frontdoor/         # Front Door + WAF
│   │   └── monitoring/        # 監視・アラート
│   ├── environments/
│   │   ├── dev.bicepparam
│   │   ├── staging.bicepparam
│   │   └── prod.bicepparam
│   └── main.bicep
├── apis/
│   ├── definitions/           # OpenAPI 3.0 仕様書
│   │   ├── accounts-v1.yaml   # 口座API
│   │   ├── balances-v1.yaml   # 残高API
│   │   ├── transactions-v1.yaml # 明細API
│   │   └── payments-v1.yaml   # 振込API
│   ├── policies/              # API Management ポリシー
│   │   ├── global-policy.xml
│   │   ├── fapi-validation.xml
│   │   ├── rate-limiting.xml
│   │   └── consent-check.xml
│   └── products/              # API製品定義
│       ├── aisp-product.json
│       └── pisp-product.json
├── services/
│   ├── auth-service/          # FAPI認可サービス
│   ├── account-api/           # 参照系API
│   ├── payment-api/           # 更新系API
│   ├── consent-service/       # 同意管理
│   ├── tpp-service/           # TPP管理
│   └── audit-service/         # 監査サービス
├── tests/
│   ├── conformance/           # FAPI適合性テスト
│   ├── security/              # セキュリティテスト
│   └── performance/           # 負荷テスト
└── docs/
    ├── developer-guide.md     # TPP向け開発者ガイド
    └── api-changelog.md       # API変更履歴
```

### API Management ポリシー（FAPI検証）

```xml
<!-- FAPI 2.0 準拠 グローバルポリシー -->
<policies>
  <inbound>
    <!-- mTLS クライアント証明書検証 -->
    <choose>
      <when condition="@(context.Request.Certificate == null)">
        <return-response>
          <set-status code="401" reason="Client certificate required" />
        </return-response>
      </when>
    </choose>
    <!-- TPP証明書のサムプリント検証 -->
    <validate-client-certificate
      validate-revocation="true"
      validate-trust="true"
      validate-not-before="true"
      validate-not-after="true" />
    <!-- JWT アクセストークン検証 -->
    <validate-jwt header-name="Authorization"
                  require-scheme="Bearer"
                  output-token-variable-name="jwt">
      <openid-config url="https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration" />
      <required-claims>
        <claim name="cnf" match="all">
          <!-- Certificate-Bound Token: mTLS証明書との紐付け検証 -->
        </claim>
      </required-claims>
    </validate-jwt>
    <!-- レート制限（TPP別） -->
    <rate-limit-by-key
      calls="100" renewal-period="60"
      counter-key="@(context.Request.Certificate.Thumbprint)"
      remaining-calls-header-name="X-RateLimit-Remaining"
      total-calls-header-name="X-RateLimit-Limit" />
    <!-- リクエストボディ検証（OpenAPI準拠） -->
    <validate-content
      unspecified-content-type-action="prevent"
      max-size="102400"
      errors-variable-name="validationErrors">
      <content type="application/json" validate-as="json"
               action="prevent" />
    </validate-content>
  </inbound>
</policies>
```

### FAPI適合性テスト

FAPI準拠を確認するため、OpenID Foundation が提供する [FAPI Conformance Test Suite](https://openid.net/certification/fapi_op_testing/) を活用した適合性テストを実施します。

| テストフェーズ | 内容 | 実施タイミング |
|-------------|------|-------------|
| FAPI 2.0 Security Profile テスト | Authorization Code Flow + PKCE + mTLS の正常系・異常系 | 認可基盤構築完了時 |
| Certificate-Bound Token テスト | トークンと証明書の紐付け検証、異なる証明書での拒否確認 | 認可基盤構築完了時 |
| PAR（Pushed Authorization Request）テスト | 認可リクエスト事前登録の正常系・不正リクエスト拒否 | 認可基盤構築完了時 |
| TPP結合テスト | 実際のTPPアプリとのEnd-to-End通信確認 | ステージング環境 |
| 侵入テスト（Penetration Test） | OWASP API Top 10 に基づくAPIセキュリティ診断 | 本番リリース前（年次） |
| 負荷テスト | TPP数×同時呼び出し数の最大負荷シミュレーション | 本番リリース前 |

### CI/CDパイプライン

```
┌─────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Commit   │───▶│ Build    │───▶│ Test     │───▶│ Stage    │───▶│ Prod     │
│          │    │          │    │          │    │          │    │          │
│・API定義 │    │・Lint    │    │・FAPI    │    │・カナリア │    │・Blue/   │
│・ポリシー│    │・Build   │    │ 適合性   │    │ デプロイ  │    │ Green    │
│・サービス│    │・SAST    │    │・セキュリ│    │・TPP結合 │    │・TPP通知 │
│          │    │・SBOM    │    │ ティ     │    │ テスト   │    │          │
│          │    │          │    │・負荷    │    │          │    │          │
└─────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
```

### APIバージョニング戦略

| 方針 | 詳細 |
|------|------|
| バージョニング方式 | URLパスベース（`/v1/accounts`、`/v2/accounts`） |
| 後方互換性 | 既存フィールドの削除・型変更は禁止。追加のみ許可 |
| 非推奨通知 | `Sunset` HTTPヘッダーによる廃止予告（最低6ヶ月前） |
| 並行運用期間 | 旧バージョンは最低12ヶ月間並行運用 |
| 変更通知 | TPPへのメール通知 + 開発者ポータルでの告知 |

## 関連リソース

### Microsoft Learn

- [Azure API Management ランディングゾーンアクセラレータ](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/api-management/landing-zone-accelerator)
- [API Management のセキュリティ設計](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/api-management/security)
- [API Management のネットワーク設計](https://learn.microsoft.com/azure/cloud-adoption-framework/scenarios/app-platform/api-management/network-topology-and-connectivity)
- [API Management Premium v2 VNet Injection](https://learn.microsoft.com/azure/api-management/inject-vnet-v2)
- [API Management の認証・認可](https://learn.microsoft.com/azure/api-management/authentication-authorization-overview)
- [API Management のレート制限](https://learn.microsoft.com/azure/api-management/api-management-sample-flexible-throttling)
- [API Management のバックエンド回路遮断器](https://learn.microsoft.com/azure/api-management/backends#circuit-breaker)
- [Microsoft Defender for APIs](https://learn.microsoft.com/azure/defender-for-cloud/defender-for-apis-introduction)
- [Azure API Management と GitHub による開発者エクスペリエンス設計](https://learn.microsoft.com/azure/architecture/example-scenario/web/design-api-developer-experiences-management-github)
- [Azure Cosmos DB — 継続的バックアップ](https://learn.microsoft.com/azure/cosmos-db/continuous-backup-restore-introduction)
- [Azure SQL Database Ledger](https://learn.microsoft.com/azure/azure-sql/database/ledger-overview)

### 業界標準・規制

- [Financial-grade API（FAPI）2.0 Security Profile — OpenID Foundation](https://openid.net/wg/fapi/)
- [全銀協 オープンAPIに係る電文仕様標準（第2版）](https://www.zenginkyo.or.jp/fileadmin/res/news/news301227_3.pdf)
- [全銀協 銀行法に基づくAPI利用契約の条文例](https://www.zenginkyo.or.jp/news/2018/n10918/)
- [金融庁 電子決済等代行業者登録一覧](https://www.fsa.go.jp/menkyo/menkyoj/denshikessai.pdf)
- [FISC 安全対策基準（第13版）](https://www.fisc.or.jp/)

### 事例

- [ClearBank — Azure API Management による銀行APIプラットフォーム](https://customers.microsoft.com/story/1790114264617229624-clearbank-azure-api-management-banking-and-capital-markets-en-united-kingdom)
