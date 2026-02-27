# モバイルバンキング ランディングゾーン

> スマートフォンアプリ向けバンキングサービスのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、銀行のスマートフォンアプリ（iOS / Android）向けモバイルバンキングシステムを対象としています。Web ブラウザ経由のインターネットバンキングについては [internet-banking.md](internet-banking.md) を参照してください。
- 本アーキテクチャは [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/) のガイダンスに準拠した設計としています。
- モバイルアプリ特有の脅威（端末改ざん・中間者攻撃・リバースエンジニアリング）に対応するため、**アプリ完全性検証 + 証明書ピニング + デバイスバインディング** を組み合わせた多層防御を採用しています。
- 顧客認証には **Microsoft Entra External ID**（CIAM）を採用し、デバイスのバイオメトリクス（Face ID / Touch ID / 指紋認証）と連携した **パスキー / FIDO2 認証** を推奨しています。
- モバイル専用の BFF（Backend for Frontend）層を設け、デバイス特性に最適化されたAPIを提供しています。
- 勘定系システム（コアバンキング）への接続は Private Link 経由の閉域網接続としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | モバイルバンキング（MB） |
| 主な機能 | 残高照会、振込・送金、QRコード決済、プッシュ通知、生体認証ログイン、口座開設 |
| FISC外部性 | 各金融機関の判断による（主要チャネルの場合は外部性大） |
| 重要度 | **Tier 2〜3** |
| 処理特性 | REST API（モバイル BFF）、プッシュ通知、イベント駆動型非同期処理、24時間365日運用 |
| 可用性要件 | 99.95%以上（年間ダウンタイム4.38時間以内） |

## ユースケース

- 個人顧客向けリテールバンキング（残高照会・振込・振替・定期預金等）をスマートフォンアプリで提供します。
- **QRコード決済**（JPQR対応）による店頭決済・P2P送金をサポートします。
- **口座開設**（eKYC連携）をアプリ内で完結させ、本人確認書類の撮影・アップロード・顔照合をモバイルで実行します。
- **プッシュ通知**による取引通知（入出金通知・振込結果通知）、セキュリティアラート（ログイン通知・不正検知）をリアルタイム配信します。
- 給料日・月末・賞与日等のピーク時には通常の **5〜10倍** のトラフィックが発生するため、自動スケーリングが必須です。
- 振込・口座開設等の更新系処理は**イベントソーシング + トランザクションアウトボックスパターン**により非同期で処理し、アプリ側の体験を損なわずに整合性を担保します。

## FISC基準上の位置づけ

モバイルバンキングは FISC 基準の「ダイレクトチャネル」に分類され、インターネットバンキングと同様に実112〜実117 の固有基準が適用されます。加えて、モバイルデバイス特有のリスク（端末紛失・改ざん・不正アプリ）への対策が求められます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準 + 付加基準適用）
- 実1〜実19: 技術的安全対策（全項目適用）
- 実112: **不正使用の防止** — 生体認証・パスキー・リスクベース認証・不正ログイン検知
- 実113: **利用状況の確認手段** — ログイン履歴・取引履歴のアプリ内表示
- 実115: **顧客対応方法の明確化** — アプリ内FAQ・チャットボット
- 実117: **オンライン口座開設の本人確認** — eKYC連携（Document Intelligence + Face API）
- 実39〜実45: バックアップ
- 実71, 実73: DR・コンティンジェンシープラン

**モバイル固有の追加要件**:
- 実1: **パスワード等の保護** — パスキー / FIDO2 認証推奨、端末内の鍵はSecure Enclave / TEEに保管
- 実4: **通信の安全性** — TLS 1.3 + 証明書ピニング（SPKI方式）による中間者攻撃防止
- 実6: **アプリの完全性** — ルート化/JB検出 + アプリ改ざん検出 + App Attestation
- 実8: **本人確認** — デバイスバイオメトリクス連携（Face ID / Touch ID / 指紋認証）
- 実9: **ID不正使用防止** — デバイスバインディング + 条件付きアクセス + アカウントロックアウト
- 実14: **不正侵入防止** — WAF + DDoS Protection + Bot Protection + レート制限

## アーキテクチャの特徴

### BFF（Backend for Frontend）パターン

モバイルアプリ専用の **BFF（Backend for Frontend）** 層を設け、デバイス特性に最適化されたAPIを提供します。Web向けインターネットバンキングとは異なるデータ形式・レスポンスサイズ・認証フローが求められるため、フロントエンドごとにバックエンドを分離します。

| 要素 | モバイルBFFの最適化 |
|------|------------------|
| レスポンスサイズ | モバイル通信環境を考慮し、最小限のペイロードに最適化 |
| ページネーション | 無限スクロール対応のカーソルベースページネーション |
| オフライン対応 | 差分同期API（最終同期タイムスタンプベース） |
| プッシュ通知連携 | Notification Hubs のデバイストークン管理をBFF内で統合 |
| バイオメトリクス | デバイス認証結果（Attestation Token）の検証をBFF層で実施 |

> **参考**: [Backends for Frontends pattern](https://learn.microsoft.com/azure/architecture/patterns/backends-for-frontends)

### イベントソーシング + トランザクションアウトボックス

振込・口座開設等の更新系処理は**イベントソーシング**パターンを採用し、すべての状態変更をイベントの連続として記録します。**トランザクションアウトボックスパターン**によりDB更新とイベント発行の原子性を保証し、勘定系APIとの連携における整合性を担保します。

```
┌─────────┐    ┌──────────┐    ┌──────────────┐    ┌──────────────┐
│ モバイル  │───▶│ BFF API   │───▶│ Event Store   │───▶│ Outbox Table  │
│ アプリ    │    │ (受付)    │    │ (Cosmos DB)   │    │ (Cosmos DB)   │
└─────────┘    └──────────┘    └──────────────┘    └──────┬───────┘
                                                          │ Change Feed
                                                   ┌──────▼───────┐
                                                   │ Event Hubs    │
                                                   └──────┬───────┘
                                                          │
                                                   ┌──────▼───────┐
                                                   │ Worker        │
                                                   │ (勘定系API    │
                                                   │  呼出し)      │
                                                   └──────────────┘
```

- アプリには即座に「受付完了」を返却し、非同期で勘定系APIを呼び出す
- 冪等キー（Idempotency Key）により再試行時の二重処理を防止
- Cosmos DB Change Feed + Event Hubs によるイベント駆動型の疎結合アーキテクチャ
- 処理結果はプッシュ通知でアプリに通知

### プッシュ通知アーキテクチャ

**Azure Notification Hubs** と **Azure Service Bus** を組み合わせた企業向けプッシュ通知基盤を構築します。

```
┌──────────────────┐    ┌──────────────┐    ┌──────────────────┐
│ バックエンドシステム │───▶│ Service Bus   │───▶│ Notification     │
│ (勘定系/AML等)     │    │ Topic         │    │ Worker           │
└──────────────────┘    └──────────────┘    └────────┬─────────┘
                                                      │
                                              ┌───────▼────────┐
                                              │ Notification    │
                                              │ Hubs            │
                                              │ ├─ APNs (iOS)   │
                                              │ └─ FCM (Android)│
                                              └───────┬────────┘
                                                      │
                                              ┌───────▼────────┐
                                              │ モバイルアプリ    │
                                              └────────────────┘
```

| 通知種別 | トリガー | 優先度 |
|---------|---------|-------|
| 入出金通知 | 勘定系からの取引完了イベント | 高 |
| 振込結果通知 | 非同期処理の完了イベント | 高 |
| セキュリティアラート | 異常ログイン検出・パスワード変更 | 最高（即時） |
| マーケティング | スケジュール配信 | 低 |
| サイレントプッシュ | データ同期トリガー | 中 |

> **参考**: [Enterprise push architectural guidance](https://learn.microsoft.com/azure/notification-hubs/notification-hubs-enterprise-push-notification-architecture)

### モバイルアプリのセキュリティ（OWASP MASVS準拠）

モバイルアプリ特有の脅威に対し、**デバイス層 → 通信層 → サーバー層** の3層で防御します。

#### デバイス層の保護

| 対策 | 実装 | 説明 |
|------|------|------|
| ルート化/JB検出 | アプリ側実装 + Intune MAM連携 | 改ざんされた端末でのアプリ起動をブロック |
| App Attestation | iOS: App Attest / Android: Play Integrity API | アプリの真正性をサーバー側で検証 |
| Secure Enclave / TEE | 認証鍵の端末内ハードウェア保管 | パスキー/FIDO2の秘密鍵をハードウェアレベルで保護 |
| アプリ難読化 | コード難読化 + タンパー検出 | リバースエンジニアリング防止 |
| ローカルデータ保護 | iOS Keychain / Android Keystore + 暗号化DB | 端末内のキャッシュデータ・トークンの暗号化保管 |
| 画面キャプチャ防止 | アプリ側実装（残高表示画面等） | スクリーンショット・画面録画の制限 |

#### 通信層の保護

| 対策 | 実装 | 説明 |
|------|------|------|
| TLS 1.3 強制 | Azure Front Door + アプリ側設定 | 最新のTLSプロトコルのみ許可 |
| 証明書ピニング（SPKI） | アプリ側実装 + バックアップピン | 中間者攻撃防止。公開鍵ハッシュ方式で証明書更新に対応 |
| リクエスト署名 | HMAC-SHA256 によるリクエスト署名 | APIリクエストの改ざん防止 |
| Attestation Token | App Attest / Play Integrity のトークンをAPI呼出しに付加 | 不正クライアントからのAPIアクセス防止 |

> **参考**: [Certificate pinning and Azure services](https://learn.microsoft.com/azure/security/fundamentals/certificate-pinning)

#### サーバー層の保護

| 対策 | 実装 | 説明 |
|------|------|------|
| Front Door WAF | OWASP Core Rule Set + カスタムルール | SQLi/XSS/RCE等の攻撃防止 |
| Bot Protection | Front Door Premium Bot Manager | 自動化攻撃・クレデンシャルスタッフィング防止 |
| DDoS Protection | Azure DDoS Protection Standard | L3/L4/L7 DDoS攻撃の自動緩和 |
| レート制限 | APIM スロットリング（ユーザー/デバイス別） | APIの過剰利用・ブルートフォース防止 |
| Attestation検証 | BFF層でApp Attest / Play Integrityトークンを検証 | 正規アプリからのリクエストのみ受付 |

### 顧客認証（CIAM）

**Microsoft Entra External ID** を CIAM 基盤として採用し、モバイルデバイスのバイオメトリクスと連携したパスワードレス認証を実現します。

| 認証方式 | 説明 | セキュリティレベル |
|---------|------|---------------|
| パスキー / FIDO2 | デバイスの Face ID / Touch ID / 指紋認証と連携 | 最高（フィッシング耐性あり） |
| SMS OTP | ワンタイムパスワード（フォールバック用） | 中（SIMスワップリスク） |
| デバイスバインディング | 条件付きアクセスによるデバイス準拠チェック | 高 |
| リスクベース認証 | Entra ID Protection による異常検知 | 適応的 |
| トランザクション認証 | 高額振込時の追加認証（生体 + PIN） | 最高 |

認証フロー: OAuth 2.0 + PKCE（Authorization Code Flow with PKCE）を採用し、モバイルアプリに適したセキュアなトークン管理を実現します。

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────┐
│  オンプレミス DC        │
│  ┌────────────────┐   │
│  │ 既存系・勘定系   │   │
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
│  │ │ Azure Front Door Premium   │ │  │ │ (Front Door 自動ルーティング│ │ │
│  │ │ ・WAF (OWASP + カスタム)    │ │  │ │  によりDRリージョンへ      │ │ │
│  │ │ ・Bot Protection           │ │  │ │  自動切替)                │ │ │
│  │ │ ・DDoS Protection          │ │  │ └──────────────────────────┘ │ │
│  │ │ ・Geo Filter               │ │  │                              │ │
│  │ │ ・Rate Limiting            │ │  │ ┌──────────────────────────┐ │ │
│  │ └───────────┬───────────────┘ │  │ │ APIM (Premium)           │ │ │
│  │             │ Private Link     │  │ │ (Standby)                │ │ │
│  │ ┌───────────▼───────────────┐ │  │ └──────────┬───────────────┘ │ │
│  │ │ APIM (Premium)            │ │  │            │                │ │
│  │ │ 内部VNet統合               │ │  │ ┌──────────▼───────────────┐ │ │
│  │ │ ・レート制限・認証検証      │ │  │ │ Container Apps / AKS     │ │ │
│  │ │ ・APIバージョン管理         │ │  │ │ (Warm Standby)           │ │ │
│  │ │ ・Attestation Token検証   │ │  │ │ モバイルBFF               │ │ │
│  │ └───────────┬───────────────┘ │  │ └──────────┬───────────────┘ │ │
│  │             │                   │  │            │                │ │
│  │ ┌───────────▼───────────────┐ │  │ ┌──────────▼───────────────┐ │ │
│  │ │ Container Apps / AKS      │ │  │ │ Azure SQL DB             │ │ │
│  │ │ (可用性ゾーン x3)          │ │  │ │ Business Critical        │ │ │
│  │ │ ┌────────┐ ┌────────────┐│ │  │ │ (Failover Group)         │ │ │
│  │ │ │モバイル  │ │口座開設    ││ │  │ └──────────────────────────┘ │ │
│  │ │ │BFF     │ │サービス    ││ │  │                              │ │
│  │ │ ├────────┤ ├────────────┤│ │  │ ┌──────────────────────────┐ │ │
│  │ │ │振込    │ │QR決済     ││ │  │ │ Cosmos DB                │ │ │
│  │ │ │サービス │ │サービス    ││ │  │ │ (グローバルテーブル)       │ │ │
│  │ │ ├────────┤ ├────────────┤│ │  │ └──────────────────────────┘ │ │
│  │ │ │通知    │ │認証       ││ │  │                              │ │
│  │ │ │サービス │ │サービス    ││ │  │ ┌──────────────────────────┐ │ │
│  │ │ └────────┘ └────────────┘│ │  │ │ Redis Enterprise         │ │ │
│  │ └───────────────────────────┘ │  │ │ (Active Geo-Rep)         │ │ │
│  │                               │  │ └──────────────────────────┘ │ │
│  │ ┌───────────────────────────┐ │  └──────────────────────────────┘ │
│  │ │ Azure SQL DB               │ │                                  │
│  │ │ Business Critical          │ │非同期                             │
│  │ │ (可用性ゾーン内同期)         │ │─────▶ Failover Group            │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Cosmos DB                  │ │                                  │
│  │ │ ・イベントストア (Event     │ │グローバル                         │
│  │ │   Sourcing)               │ │テーブル                           │
│  │ │ ・セッション管理            │ │                                  │
│  │ │ ・Outbox Table            │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Redis Enterprise           │ │                                  │
│  │ │ (Active Geo-Replication)   │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Event Hubs / Service Bus  │ │                                  │
│  │ │ (Geo-DR)                  │ │                                  │
│  │ │ ├─ 取引イベントストリーム    │ │                                  │
│  │ │ └─ プッシュ通知トピック      │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Notification Hubs          │ │                                  │
│  │ │ ├─ APNs (iOS)             │ │                                  │
│  │ │ └─ FCM (Android)          │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  │                               │                                  │
│  │ ┌───────────────────────────┐ │                                  │
│  │ │ Entra External ID (CIAM)  │ │                                  │
│  │ │ ・パスキー / FIDO2         │ │                                  │
│  │ │ ・Face ID / Touch ID連携  │ │                                  │
│  │ │ ・SMS OTP (フォールバック)  │ │                                  │
│  │ │ ・リスクベース認証          │ │                                  │
│  │ └───────────────────────────┘ │                                  │
│  └───────────────────────────────┘                                  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                 監視・自動化 (グローバル)                         │  │
│  │  Log Analytics Workspace | Application Insights                 │  │
│  │  Azure Monitor (外形監視) | Microsoft Sentinel                  │  │
│  │  Azure Automation (FO 自動化) | App Center (クラッシュ分析)       │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| モバイルBFF | Azure Container Apps / AKS | 可用性ゾーン3ゾーン、HTTPスケーリング | モバイルに最適化されたAPI提供、トラフィック急増時の自動スケール |
| 非同期ワーカー | Azure Container Apps / AKS Job | 専用ノードプール | イベントソーシングのOutbox処理、勘定系API連携 |
| API Gateway | Azure API Management (Premium) | 内部VNet統合、可用性ゾーン | レート制限・認証・APIバージョン管理・Attestation Token検証 |
| エッジ保護 | Azure Front Door Premium | WAF + Bot Protection + DDoS + CDN | 多層防御・CDN・自動リージョンルーティング |

### データベース

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| メインDB | Azure SQL DB Business Critical | 可用性ゾーン + Failover Group | 取引履歴・ユーザー設定。99.995% SLA |
| イベントストア | Azure Cosmos DB (NoSQL) | グローバルテーブル | イベントソーシングのイベント格納・Outbox Table・セッション管理 |
| キャッシュ | Azure Cache for Redis Enterprise | Active Geo-Replication | トークンキャッシュ・残高キャッシュ・セッション管理 |

> **DB構成の設計意図**: メインDB (SQL DB) はトランザクション処理（ACID特性）に最適化し、イベントストア (Cosmos DB) はイベントソーシングの追記型ストアおよびリージョン切替時の切替作業を不要とするためにグローバルテーブルを活用します。

### ストレージ・メッセージング

| コンポーネント | Azureサービス | 構成 | 理由 |
|-------------|-------------|------|------|
| メッセージング | Azure Event Hubs + Service Bus Premium | 可用性ゾーン + Geo-DR | イベントソーシングのイベント配信 + プッシュ通知トピック |
| プッシュ通知 | Azure Notification Hubs (Standard) | iOS APNs + Android FCM | マルチプラットフォーム通知配信・大量配信対応 |
| ファイルストレージ | Azure Blob Storage (ZRS) | Private Endpoint | eKYC用の本人確認書類アップロード |

### セキュリティ

| コンポーネント | Azureサービス | FISC基準 |
|-------------|-------------|---------|
| 顧客認証（CIAM） | Microsoft Entra External ID | 実1, 実8（パスキー / FIDO2 / SMS OTP） |
| 暗号鍵管理 | Azure Key Vault (Premium) | 実13（FIPS 140-2 Level 2） |
| DB暗号化 | TDE + 顧客管理キー（CMK） | 実3（蓄積データ保護） |
| ネットワーク分離 | Private Endpoint + NSG | 実15（接続機器最小化） |
| WAF | Azure Front Door WAF | 実14（不正侵入防止） |
| DDoS | Azure DDoS Protection Standard | 実14（不正侵入防止） |
| コンテナセキュリティ | Microsoft Defender for Containers | 実14（コンテナイメージ脆弱性スキャン） |
| データガバナンス | Microsoft Purview | 実3（学習データの分類・リネージ） |

## 可用性・DR設計

### 目標値

| 要件 | 設計 |
|------|------|
| **RTO** | < 15分（Front Door 自動ルーティングにより即時切替） |
| **RPO** | < 5分（SQL DB Failover Group 非同期レプリケーション） |

### 障害レベル別の対応

| 障害レベル | 対応方式 | RTO | RPO |
|-----------|---------|-----|-----|
| 単一ノード障害 | Container Apps セルフヒーリング | < 1分 | 0 |
| 可用性ゾーン障害 | SQL DB Business Critical AZ間自動FO | < 5分 | 0 |
| リージョン障害 | 自動切替フロー（後述）による西日本への切替 | < 15分 | < 5分 |
| ランサムウェア・データ破壊 | 不変バックアップからの復元 | 業務判断 | PITR設定に依存 |

### リージョン切替の自動化フロー

```
┌─ 外形監視（東日本 + 西日本 + 東南アジアから実施）─┐
│  Application Insights 可用性テスト                │
│  (モバイルBFF APIの合成トランザクション)             │
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
│    → 処理中のイベント（振込等）完了を待機    │
│                                          │
│  Step 2: データ同期確認                    │
│    → SQL DB replication_lag_sec 確認       │
│    → Cosmos DB グローバルテーブル同期確認   │
│                                          │
│  Step 3: SQL DB Failover Group 切替       │
│    → 計画的フェイルオーバー or 強制FO        │
│                                          │
│  Step 4: アプリケーション切替               │
│    → 西日本 Container Apps の本番昇格       │
│    → APIM の閉塞解除（西日本側）            │
│    → Front Door バックエンドの変更          │
│                                          │
│  Step 5: 正常性確認                        │
│    → モバイルBFF APIのヘルスチェック         │
│    → プッシュ通知配信テスト                  │
│    → 切替完了通知                          │
└──────────────────────────────────────────┘
```

> **モバイル固有の考慮**: モバイルアプリは Front Door の自動ルーティングにより、エンドポイント変更なしにDRリージョンへ切替可能です。アプリ側のリトライロジックと組み合わせることで、ユーザー体験への影響を最小化します。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL DB PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| 長期保存 | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー |
| イベントストア | Cosmos DB 継続的バックアップ（PITR 30日） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| モバイル固有テスト | プッシュ通知配信テスト、Attestation検証テスト、証明書ピニング更新テスト |
| 負荷テスト | ピーク時（給料日）相当の負荷テストを四半期毎に実施 |

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: MB 東日本 (10.22.0.0/16)
│               ├── snet-apim      (10.22.0.0/24)  — API Management
│               ├── snet-app       (10.22.1.0/24)  — Container Apps / AKS（モバイルBFF）
│               ├── snet-db        (10.22.2.0/24)  — SQL DB Private Endpoint
│               ├── snet-cosmos    (10.22.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-cache     (10.22.4.0/24)  — Redis Enterprise
│               ├── snet-msg       (10.22.5.0/24)  — Event Hubs / Service Bus PE
│               ├── snet-notify    (10.22.6.0/24)  — Notification Hubs PE
│               └── snet-pe        (10.22.7.0/24)  — その他 Private Endpoint
│
└── Peering ──▶ Spoke VNet: MB 西日本 (10.23.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Front Door (サービスタグ) → APIM のみ許可
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- サブネット間: 必要最小限のポートのみ許可
- 勘定系連携: Hub VNet 経由で Core Banking Spoke VNet へのみ通信許可
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | モバイルBFF APIへの疑似リクエスト（残高照会API等） |
| テスト頻度 | 1〜5分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | BFF → 各サービス → 勘定系のリクエストトレース |
| サービスマップ | Application Insights Application Map | サービス間依存関係・ボトルネック可視化 |
| メトリクス収集 | Azure Monitor + Container Apps Metrics | CPU・メモリ・リクエスト数・エラー率 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 不正ログイン検出・異常取引パターン |
| クラッシュ分析 | App Center / Application Insights | アプリクラッシュ・ANR分析・デバイス別分布 |

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| API応答時間 | Application Insights | P99 > 2秒 |
| エラー率 | Application Insights | 5xx エラー率 > 1% |
| DB レプリケーションラグ | Azure Monitor | > 3秒 |
| プッシュ通知失敗率 | Notification Hubs Metrics | 配信失敗率 > 5% |
| 認証失敗急増 | Entra External ID + Sentinel | 認証失敗が通常の5倍以上 |
| 外形監視失敗 | Application Insights 可用性テスト | 2拠点以上で失敗 |
| イベント処理遅延 | Azure Monitor カスタムメトリクス | Outbox滞留 > 100件 or 処理遅延 > 5分 |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| バックエンドCI/CD | Azure DevOps Pipelines または GitHub Actions |
| モバイルアプリCI/CD | App Center Build + GitHub Actions（iOS / Android） |
| モバイルアプリ配布 | App Center Distribution（テスター配布）+ App Store / Google Play（本番） |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| 証明書ピン更新 | アプリリリースサイクルに合わせたバックアップピンの事前組込み |
| APIバージョン管理 | APIM によるバージョン管理（v1 / v2 並行運用、段階的移行） |

## 関連リソース

- [Azure Well-Architected Framework](https://learn.microsoft.com/azure/well-architected/)
- [Backends for Frontends pattern](https://learn.microsoft.com/azure/architecture/patterns/backends-for-frontends)
- [Enterprise push architectural guidance — Notification Hubs](https://learn.microsoft.com/azure/notification-hubs/notification-hubs-enterprise-push-notification-architecture)
- [What is Azure Notification Hubs?](https://learn.microsoft.com/azure/notification-hubs/notification-hubs-push-notification-overview)
- [Microsoft Entra External ID overview](https://learn.microsoft.com/entra/external-id/external-identities-overview)
- [Passkeys (FIDO2) in Microsoft Entra ID](https://learn.microsoft.com/entra/identity/authentication/concept-authentication-passkeys-fido2)
- [Certificate pinning and Azure services](https://learn.microsoft.com/azure/security/fundamentals/certificate-pinning)
- [Azure SQL Database: High availability and disaster recovery](https://learn.microsoft.com/azure/azure-sql/database/high-availability-sla-local-zone-redundancy)
- [Azure SQL Database: Failover groups](https://learn.microsoft.com/azure/azure-sql/database/failover-group-sql-db)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
