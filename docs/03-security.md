# 03 — セキュリティ

> FISC実務基準（実1〜実19, 実25〜実30）→ Azure Security Services

## 概要

FISC実務基準のうち、技術的安全対策に関する基準をAzureセキュリティサービスにマッピングします。認証・アクセス制御、データ保護、暗号化、ネットワークセキュリティ、サイバー攻撃対策を包括的にカバーします。

Azure WAFの**セキュリティの柱**（Security Pillar）の設計原則に沿って構成しています。

## 1. データ保護（実1〜実4）

### 実1: 暗証番号・パスワード等の保護

**FISC要件**: 他人に暗証番号・パスワード等を知られないための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| パスワードレス認証 | Microsoft Entra ID | FIDO2、Windows Hello、Microsoft Authenticator |
| パスワードポリシー | Microsoft Entra ID | 複雑性要件、禁止パスワードリスト |
| 多要素認証（MFA） | Microsoft Entra MFA | SMS、認証アプリ、ハードウェアキー |
| 条件付きアクセス | Microsoft Entra Conditional Access | リスクベースの認証制御 |
| 秘密情報管理 | Azure Key Vault | パスワード・接続文字列・証明書の安全な格納 |

### 実3: 蓄積データの漏えい防止

**FISC要件**: 蓄積データの漏えい防止策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 保存時暗号化 | Azure Storage / SQL Database | TDE（透過的データ暗号化）、Azure Disk Encryption |
| 顧客管理キー（CMK） | Azure Key Vault | 自組織管理の暗号鍵によるデータ暗号化 |
| 機密コンピューティング | Azure Confidential Computing | 処理中データの保護（TEE: Trusted Execution Environment） |
| データ分類・ラベリング | Microsoft Purview Information Protection | 機密度ラベルによるデータ分類と保護 |
| DLP（データ漏えい防止） | Microsoft Purview DLP | 機密データの外部送信を検知・ブロック |

### 実4: 伝送データの漏えい防止

**FISC要件**: 伝送データの漏えい防止策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| TLS 1.2/1.3 | Azure全サービス | 転送中暗号化の強制 |
| VPN接続 | Azure VPN Gateway | IPsec/IKE VPN による暗号化通信 |
| 専用線接続 | Azure ExpressRoute | 専用回線によるプライベート接続（暗号化オプション付き） |
| プライベートエンドポイント | Azure Private Link | インターネットを経由しないプライベート接続 |

## 2. 認証・アクセス制御（実8〜実10）

### 実8: 本人確認機能

**FISC要件**: 本人確認機能を設けること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 統合ID管理 | Microsoft Entra ID | SSO、SAML、OAuth 2.0 / OIDC |
| MFA | Microsoft Entra MFA | 多要素認証による本人確認強化 |
| リスクベース認証 | Microsoft Entra ID Protection | サインインリスクに基づく動的認証要求 |
| 外部ID | Microsoft Entra External ID | B2C向け本人確認（eKYC連携可能） |
| 生体認証 | Windows Hello for Business | 指紋・顔認証による本人確認 |

### 実9: IDの不正使用防止

**FISC要件**: IDの不正使用防止機能を設けること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 不正検知 | Microsoft Entra ID Protection | 異常なサインインパターンの検知 |
| アカウントロックアウト | Microsoft Entra ID | ブルートフォース攻撃対策 |
| セッション管理 | Microsoft Entra Conditional Access | セッション有効期間・再認証ポリシー |
| 特権ID管理 | Microsoft Entra PIM | JIT（Just-In-Time）特権アクセス |

### 実10: アクセス履歴の管理

**FISC要件**: アクセス履歴を管理すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 認証ログ | Microsoft Entra Sign-in Logs | すべてのサインインイベントの記録 |
| 監査ログ | Microsoft Entra Audit Logs | ID関連の変更操作の記録 |
| アクティビティログ | Azure Activity Log | Azureリソース操作の記録 |
| ログ統合・分析 | Microsoft Sentinel / Azure Monitor Logs | SIEM/SOARによるログ統合分析 |
| 長期保存 | Azure Storage（不変ストレージ） | WORM（Write Once Read Many）による改ざん防止保存 |

## 3. 暗号化（実13）

### 実13: 暗号鍵の保護

**FISC要件**: 電子化された暗号鍵を蓄積する機器、媒体、又はそこに含まれるソフトウェアには、暗号鍵の保護機能を設けること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 鍵管理 | Azure Key Vault | FIPS 140-2 Level 2認定のHSMバックエンド |
| マネージドHSM | Azure Key Vault Managed HSM | FIPS 140-2 Level 3認定、専用HSM |
| 決済用HSM | Azure Payment HSM | PCI PTS HSM v3認定、決済トランザクション用 |
| 機密コンピューティング | Azure Confidential Computing | TEEによる処理中の鍵保護 |

## 4. ネットワークセキュリティ（実14〜実16）

### 実14: 不正侵入防止

**FISC要件**: 外部ネットワークからの不正侵入防止策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| ファイアウォール | Azure Firewall (Premium) | L3-L7のネットワークフィルタリング、IDS/IPS |
| WAF | Azure Web Application Firewall | OWASP Top 10対策、カスタムルール |
| DDoS防御 | Azure DDoS Protection | L3/L4 DDoS攻撃の自動緩和 |
| ネットワーク分離 | Azure Virtual Network (VNet) | マイクロセグメンテーション |
| NSG | Network Security Group | サブネット・NIC レベルのアクセス制御 |

### 実14-1: サイバー攻撃端緒の検知・監視（第13版新設）

**FISC要件**: サイバー攻撃の端緒を検知するための監視・分析などの対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| SIEM | Microsoft Sentinel | AIを活用した脅威検知・調査・対応 |
| XDR | Microsoft Defender XDR | エンドポイント・メール・ID・クラウドの統合脅威検知 |
| NDR | Azure Network Watcher + NSG Flow Logs | ネットワークトラフィックの異常検知 |
| 脅威インテリジェンス | Microsoft Defender Threat Intelligence | 最新の脅威情報によるプロアクティブ防御 |

### 実14-2: 脆弱性診断・ペネトレーションテスト（第13版新設）

**FISC要件**: 脆弱性診断及びペネトレーションテストを行うこと。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 脆弱性スキャン | Microsoft Defender 脆弱性管理 | OS・アプリケーションの脆弱性スキャン |
| コンテナスキャン | Microsoft Defender for Containers | コンテナイメージの脆弱性スキャン |
| Webアプリスキャン | Microsoft Defender for App Service | Webアプリケーションの脆弱性検出 |
| ペネトレーションテスト | Azure ペネトレーションテストルール | Azureはペネトレーションテストの実施を許可（事前通知不要） |

### 実15: 接続機器の最小化

**FISC要件**: 外部ネットワークからアクセス可能な接続機器は必要最小限にすること。

**Azure対応**:
- **Azure Private Link / Private Endpoint** — PaaSサービスへのプライベートアクセス（パブリックIP不要）
- **Azure Bastion** — VM への安全なRDP/SSHアクセス（パブリックIP不要）
- **Azure API Management** — APIゲートウェイによるアクセスポイントの一元化

### 実16: 不正アクセス監視

**FISC要件**: 不正アクセスの監視機能を設けること。

**Azure対応**:
- **Microsoft Sentinel** — 相関分析・異常検知・インシデント管理
- **Microsoft Defender for Cloud** — セキュリティアラート・推奨事項
- **Azure Monitor（アラート）** — カスタムアラートルール

## 5. アクセス権限管理（実25〜実27）

### 実25: アクセス権限の明確化

**FISC要件**: 各種資源、システムへのアクセス権限を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| RBAC | Azure RBAC | 役割ベースアクセス制御（最小権限の原則） |
| カスタムロール | Azure Custom Roles | 業務要件に応じたカスタムロール定義 |
| PIM | Microsoft Entra PIM | 特権アクセスのJust-In-Time付与 |
| アクセスレビュー | Microsoft Entra Access Reviews | 定期的なアクセス権限の棚卸し |

### 実26: パスワード保護

**FISC要件**: パスワードが他人に知られないための措置を講じておくこと。

**Azure対応**:
- **Microsoft Entra ID** — パスワード保護ポリシー（禁止パスワードリスト、複雑性要件）
- **Azure Key Vault** — サービスアカウント・接続文字列の安全な格納
- **Managed Identity** — パスワードレスのサービス間認証

### 実27: アクセス権限の付与・見直し

**FISC要件**: 各種資源、システムへのアクセス権限の付与、見直し手続きを明確にすること。

**Azure対応**:
- **Microsoft Entra Access Reviews** — 定期的なアクセス権限レビュー
- **Microsoft Entra Entitlement Management** — アクセスパッケージによる権限の申請・承認ワークフロー
- **Microsoft Entra ID Governance** — ID ライフサイクル管理（入社・異動・退社）

## 6. 暗号鍵運用管理（実30）

### 実30: 暗号鍵の運用管理

**FISC要件**: 暗号鍵の運用管理方法を明確にすること。

**Azure対応**:
- **Azure Key Vault** — 鍵のローテーション・バージョン管理・アクセスポリシー
- **Azure Key Vault Managed HSM** — FIPS 140-2 Level 3準拠の専用HSM
- **Azure Payment HSM** — 決済トランザクション用HSM（Thales payShield 10K）
- **監査ログ** — Azure Key Vault の診断ログで全アクセスを記録

## 参考リンク

- [Azure Well-Architected Framework — Security](https://learn.microsoft.com/azure/well-architected/security/)
- [Azure セキュリティの基礎](https://learn.microsoft.com/azure/security/fundamentals/)
- [Microsoft Entra ID ドキュメント](https://learn.microsoft.com/entra/identity/)
- [Azure Key Vault](https://learn.microsoft.com/azure/key-vault/)
- [Azure Payment HSM](https://learn.microsoft.com/azure/payment-hsm/)
- [Azure Confidential Computing](https://learn.microsoft.com/azure/confidential-computing/)
- [Microsoft Sentinel](https://learn.microsoft.com/azure/sentinel/)


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [04. 信頼性・事業継続](04-reliability.md) | DR・バックアップ・コンティンジェンシープランの設計 |
| → | [08. AI安全対策](08-ai-safety.md) | AI/生成AIの利用方針・リスク管理（第13版新設基準） |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |