# 03 — セキュリティ

> FISC実務基準（実1〜実22, 実25〜実30）→ Azure Security Services

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

### 実2: 暗証番号の盗聴防止

**FISC要件**: 暗証番号の盗聴を防止するための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 通信暗号化 | TLS 1.2/1.3 | 認証情報の転送時暗号化 |
| トークン化 | Microsoft Entra ID | OAuth 2.0 トークンベース認証（パスワード直接送信の回避） |
| HSM保護 | Azure Key Vault Managed HSM | 暗証番号関連鍵のFIPS 140-2 Level 3 HSM内処理 |
| PIN暗号化 | Azure Payment HSM | ATM/POS端末からのPINブロック暗号化・翻訳 |

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

## 2. データ完全性・プログラム保護（実5〜実7）

### 実5: データの破壊・改ざん防止

**FISC要件**: データの破壊、改ざんを防止するための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 改ざん検知 | Azure SQL MI Ledger テーブル | 暗号学的ハッシュチェーンによる改ざん検知 |
| 不変ストレージ | Azure Blob Storage（WORM） | Write Once Read Many による書換え防止 |
| ダイジェスト保管 | Azure Confidential Ledger | Ledger テーブルのダイジェスト外部保管 |
| 整合性チェック | Microsoft Defender for Cloud | ファイル整合性監視（FIM） |

### 実6: プログラムの不正使用防止

**FISC要件**: プログラムの不正使用を防止するための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 実行制御 | Azure RBAC | プログラム実行権限の最小化 |
| アプリケーション制御 | Microsoft Defender for Cloud（適応型アプリケーション制御） | 許可リストベースのアプリケーション実行制御 |
| コンテナセキュリティ | Microsoft Defender for Containers | Pod Security Standards による実行制限 |
| 特権昇格防止 | Microsoft Entra PIM | 管理操作の JIT 承認 |

### 実7: プログラムの改ざん防止

**FISC要件**: プログラムの改ざんを防止するための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| コード署名 | GitHub（署名付きコミット） | GPG/SSH 署名による変更の真正性保証 |
| ブランチ保護 | GitHub ブランチ保護ルール | 強制プッシュ禁止・レビュー必須 |
| コンテナ署名 | Notation（ORAS） | コンテナイメージの署名・検証 |
| 整合性監視 | Microsoft Defender for Cloud FIM | デプロイ済みファイルの改ざん検知 |

## 3. 認証・アクセス制御（実8〜実10）

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

## 4. 帳票・残留データ管理（実11〜実12）

### 実11: 出力帳票のアクセス管理

**FISC要件**: 出力帳票に対するアクセスの管理を行うこと。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 情報保護 | Microsoft Purview Information Protection | 機密度ラベルによる帳票の分類・保護 |
| 権限管理 | Microsoft Purview IRM | 帳票の印刷・転送・コピーの制限 |
| 透かし | Microsoft 365 透かし機能 | 印刷時の追跡用透かし挿入 |

### 実12: 残留データの保護

**FISC要件**: コンピュータ内に残留する秘密データの保護に関する対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| ディスク暗号化 | Azure Disk Encryption | BitLocker/DM-Crypt による保存時暗号化 |
| 安全な消去 | Azure ディスクの安全な廃棄 | NIST 800-88 準拠のデータ消去（Microsoft DC 管理） |
| メモリ保護 | Azure Confidential Computing | TEE による処理中データの保護・メモリ暗号化 |
| 一時データ消去 | Azure VM 一時ディスク | VM 停止時の一時ディスク自動消去 |

## 5. 暗号化（実13）

### 実13: 暗号鍵の保護

**FISC要件**: 電子化された暗号鍵を蓄積する機器、媒体、又はそこに含まれるソフトウェアには、暗号鍵の保護機能を設けること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 鍵管理 | Azure Key Vault | FIPS 140-2 Level 2認定のHSMバックエンド |
| マネージドHSM | Azure Key Vault Managed HSM | FIPS 140-2 Level 3認定、専用HSM |
| 決済用HSM | Azure Payment HSM | PCI PTS HSM v3認定、決済トランザクション用 |
| 機密コンピューティング | Azure Confidential Computing | TEEによる処理中の鍵保護 |

## 6. ネットワークセキュリティ（実14〜実16）

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

## 7. 異常取引検知・不正アクセス対応（実17〜実19）

### 実17: 異常な取引状況の把握

**FISC要件**: 異常な取引状況を把握するための対策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| リアルタイム検知 | Azure Stream Analytics | 取引パターンの異常検知（時系列分析） |
| SIEM相関分析 | Microsoft Sentinel | 複数データソースの相関分析による異常検知 |
| ML検知 | Microsoft Sentinel ML | 機械学習ベースの異常行動検知 |
| ダッシュボード | Azure Monitor Workbooks | 取引状況のリアルタイム可視化 |

### 実18: 異例取引の監視

**FISC要件**: 異例取引の監視を行うこと。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| カスタムルール | Microsoft Sentinel 分析ルール | 閾値ベース・パターンベースの異例取引検知 |
| アラート | Azure Monitor アラート | 異例取引発生時の自動通知（Teams / メール） |
| 調査 | Microsoft Sentinel インシデント | 異例取引の調査・エスカレーションワークフロー |

### 実19: 不正アクセス対応策・復旧策

**FISC要件**: 不正アクセスに対する対応策・復旧策を講ずること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 自動対応 | Microsoft Sentinel SOAR | Logic Apps ベースの自動インシデント対応プレイブック |
| 隔離 | NSG / Azure Firewall | 不正アクセス検知時のネットワーク自動隔離 |
| フォレンジック | Azure Disk Snapshot | 証拠保全のためのディスクスナップショット |
| 復旧 | Azure Backup / Azure Site Recovery | バックアップからの迅速な復旧 |

## 8. 不正プログラム対策（実20〜実22）

FISC第13版「情報セキュリティ (6) 不正プログラム対策」に対応し、コンピュータウイルス等の不正プログラムへの**防御・検知・被害時対策**をAzureサービスで実現します。

### 実20: 不正プログラムへの防御対策

**FISC要件**: コンピュータウイルス等の不正プログラムへの防御対策を講ずること。

防御対策として、ウイルス侵入防止、プログラム改ざん防止、不正プログラム組込み防止の3観点で対策を講じます。

| 対策区分 | Azureサービス | 説明 |
|---------|-------------|------|
| エンドポイント防御 | Microsoft Defender for Endpoint | パターンマッチング・ヒューリスティック・振る舞い検知の多層防御（EDR） |
| サーバー防御 | Microsoft Defender for Servers | サーバーワークロードへのリアルタイム保護・脆弱性評価 |
| コンテナ防御 | Microsoft Defender for Containers | コンテナイメージのスキャン・ランタイム保護 |
| ストレージ防御 | Microsoft Defender for Storage | Blob/Fileへのマルウェアスキャン（アップロード時自動検査） |
| ネットワーク防御 | Azure Firewall Premium / WAF | IDS/IPS機能・TLSインスペクション・悪意あるトラフィックの遮断 |
| アプリケーション制御 | 適応型アプリケーション制御 | ホワイトリスト方式による許可されたプログラムのみ実行 |
| パッチ管理 | Azure Update Manager | OS・ミドルウェアの脆弱性パッチ自動適用 |
| マーケットプレイス検証 | Azure Marketplace 認定 | Microsoft認定済みイメージ・拡張機能の利用による不正プログラム混入防止 |

> **ランサムウェア対策**: FISC第13版（参考3）では、ランサムウェア対策として「社内ネットワークから切り離した環境でのバックアップ保管」を求めています。Azure Backupの**イミュータブルボールト**（変更不可バックアップ）や**論理削除**機能により、ランサムウェアによるバックアップの暗号化・削除を防止できます。

### 実21: 不正プログラムの検知対策

**FISC要件**: コンピュータウイルス等の不正プログラムの検知対策を講ずること。

| 検知方式 | Azureサービス | 説明 |
|---------|-------------|------|
| マルウェア検知 | Microsoft Defender for Cloud | パターンマッチング＋振る舞い検知による不正プログラム検出 |
| 不正侵入検知 | Azure Firewall Premium IDS/IPS | 仮想ネットワーク境界でのホスト型・ネットワーク型侵入検知 |
| アクセス履歴検知 | Microsoft Entra ID Protection | 異常なサインイン・不正アクセスパターンの検知 |
| SIEM統合 | Microsoft Sentinel | 複数サーバーのログ一元管理・AI分析による不正プログラム検知 |
| 資源異常検知 | Azure Monitor | CPU・メモリ・ディスク等リソースの異常使用パターン検知 |
| ファイル整合性 | Defender for Cloud（FIM） | ファイル整合性監視によるプログラム改ざん検知 |
| 脅威インテリジェンス | Microsoft Threat Intelligence | 最新の脅威情報に基づくパターンファイル・検知ロジック自動更新 |

> **クラウド固有の確認事項**: 仮想マシンのスケーリング時にも抗ウイルスソフトが自動導入されるよう、Azure Policyによる拡張機能の強制適用を設定します。また、クラウド固有のパラメーター（API呼び出し頻度、リソースプロビジョニング異常等）も監視対象に含めます。

### 実22: 不正プログラムによる被害時対策

**FISC要件**: コンピュータウイルス等の不正プログラムによる被害時対策を講ずること。

感染発見から復旧までの9段階の対応手順をAzureで自動化・効率化します。

| FISC対応手順 | Azureサービス | 実装方法 |
|-------------|-------------|---------|
| (1) 感染システムの切離し | NSG / Azure Firewall | ファイアウォール設定変更スクリプトによる感染VMのネットワーク自動隔離 |
| (2) 関係先への連絡 | Microsoft Sentinel SOAR | Logic Appsによる自動通知（Teams・メール・チケット起票） |
| (3) 他システムの検査 | Defender for Cloud | ハイパーバイザ攻撃時の影響範囲自動評価・横展開検査 |
| (4) ウイルス駆除 | Defender for Endpoint | 自動修復アクション（ファイル隔離・プロセス停止） |
| (5) プログラム再インストール | Azure VM再デプロイ | IaCテンプレートからのクリーンな環境再構築 |
| (6) バックアップデータ再ロード | Azure Backup | 感染前のリストアポイントからのデータ復旧 |
| (7) ウイルス再検査 | Defender for Cloud | 復旧後の全体スキャン実行・安全性確認 |
| (8) 再発防止策 | Azure Policy / Sentinel | セキュリティポリシー強化・検知ルール追加 |
| (9) システム再接続 | NSG / Azure Firewall | ファイアウォール設定変更による隔離解除・段階的再接続 |

> **トレーサビリティ**: クラウド事業者提供ツールで要件を充足しない場合、Microsoft Defender XDRの**Advanced Hunting**（KQLクエリ）や**Azure Resource Graph**を活用し、情報抽出・証跡確保のためのカスタムツールを構築できます。

## 9. アクセス権限管理（実25〜実27）

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

### 実28: データファイルの授受・管理

**FISC要件**: データファイルの授受及び管理に関する事項を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| ファイル転送 | Azure Storage（SFTP / FTPS） | 暗号化されたファイル転送 |
| 受渡し管理 | Azure Blob Storage + SAS トークン | 有効期限付きの安全なファイル共有 |
| 改ざん検知 | ハッシュ検証 | ファイル受渡し時の SHA-256 ハッシュ検証 |
| 監査ログ | Azure Storage 診断ログ | ファイルアクセスの全操作ログ |

### 実29: 磁気テープ等の外部保管

**FISC要件**: 磁気テープ等の外部保管について安全管理上の措置を講ずること。

**Azure対応**:
- **Azure Blob Storage（GRS / RA-GRS）** — Geo 冗長による遠隔地保管相当の保護
- **Azure Blob Storage（不変ストレージ）** — WORM ポリシーによる改ざん防止
- **Azure Blob Storage アクセス層** — Archive 層による長期保管（コスト最適化）
- **暗号化** — CMK（顧客管理キー）による保管データの暗号化

## 10. 暗号鍵運用管理（実30）

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