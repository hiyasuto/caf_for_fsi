# 開発基盤（Engineering Platform）ランディングゾーン

> ソフトウェア開発ライフサイクル全体を支える開発基盤のAzure + GitHub 設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、金融機関のアプリケーション開発に必要なソースコード管理、CI/CD、開発者ワークステーション、コンテナレジストリ、セキュリティスキャン等の開発基盤を対象としています。
- 各業務システム（勘定系・チャネル系等）のアプリケーションアーキテクチャは各システム別ランディングゾーンを参照してください。本ドキュメントはそれらのシステムを開発・デプロイするための **共通基盤** を定義します。
- 開発基盤は [GitHub Enterprise Cloud](https://docs.github.com/enterprise-cloud@latest/admin/overview/about-github-enterprise-cloud) を中心に構成し、Azure サービスと連携させる設計としています。
- 開発者の作業環境は [Azure Virtual Desktop](https://learn.microsoft.com/azure/virtual-desktop/overview) / [Windows 365](https://learn.microsoft.com/windows-365/overview) / [GitHub Codespaces](https://docs.github.com/codespaces) のいずれかまたは組み合わせで提供し、ソースコードの端末残留を防止します。
- 本アーキテクチャは [セキュア ソフトウェア開発ライフサイクル（SSDLC）](https://learn.microsoft.com/security/zero-trust/develop/embed-zero-trust-dev-workflow) のベストプラクティスに準拠した設計としています。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | 開発基盤（Engineering Platform） |
| 主な機能 | ソースコード管理、CI/CD、コードレビュー、セキュリティスキャン、開発者ワークステーション、コンテナレジストリ、AI支援開発 |
| FISC外部性 | なし（間接的に全システムに影響） |
| 重要度 | **Tier 3〜4**（ただしCI/CDパイプラインの停止は全システムのデプロイに影響） |
| 処理特性 | バッチ処理（ビルド・テスト）、インタラクティブ（開発作業） |
| 可用性要件 | 99.9%以上（GitHub Enterprise Cloud SLA準拠） |

## ユースケース

- **ソースコード管理・InnerSource**: GitHub Enterprise Cloud 上でのリポジトリ管理。組織横断的な InnerSource により、共通ライブラリやフレームワークの再利用を促進する。FISC準拠のブランチ保護ルール（レビュー必須・署名付きコミット等）を全リポジトリに適用する。
- **AI支援開発（GitHub Copilot）**: GitHub Copilot Enterprise によるコード生成・コードレビュー・ドキュメント生成の効率化。金融機関固有のコーディング規約やセキュリティポリシーをカスタムインストラクション（Organization Rulesets）として適用する。
- **セキュアCI/CD**: GitHub Actions による自動ビルド・テスト・デプロイ。Self-hosted Runner を Azure VNet 内に配置し、閉域網内でビルド・デプロイを実行する。各環境（開発→ステージング→本番）へのプロモーションは承認ワークフローで制御する。
- **セキュリティスキャン（Shift Left）**: GitHub Advanced Security（GHAS）による Code Scanning（CodeQL）、Secret Scanning（Push Protection）、Dependabot（依存関係脆弱性管理）をCI/CDパイプラインに統合し、脆弱性の早期検出・修正を実現する。
- **開発者ワークステーション**: AVD / Windows 365 / GitHub Codespaces による仮想化された開発環境。ソースコードが開発者のローカル端末に残留せず、退職・異動時のデータ漏洩リスクを排除する。
- **コンテナイメージ管理**: Azure Container Registry（ACR）による社内コンテナイメージの一元管理。イメージ署名（Notation）、SBOM 添付、脆弱性スキャン（Defender for Containers）によりソフトウェアサプライチェーンセキュリティを確保する。
- **Infrastructure as Code**: Bicep / Terraform によるインフラ定義。コードレビュー → 自動テスト → プランレビュー → 自動適用のワークフローにより、インフラ変更の品質と監査証跡を確保する。

## FISC基準上の位置づけ

開発基盤は直接的に顧客取引を処理するシステムではありませんが、全ての本番システムのソースコード・ビルド・デプロイを管理するため、間接的に極めて高い重要性を持ちます。ソースコードの漏洩やCI/CDパイプラインの改ざんは、全本番システムのセキュリティに直結します。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準適用）
- 実1〜実19: 技術的安全対策（認証・暗号化・アクセス制御）
- 実25〜実28: アクセス権限管理（ソースコードアクセスの最小権限）
- 実39〜実45: バックアップ（ソースコード・構成情報の保護）
- 実150〜実153: 開発・テスト環境の管理（本番環境との分離）
- 実154〜実155: 外部委託先の管理（開発委託先のアクセス制御）

**開発基盤固有のFISC基準対応**:

| FISC基準 | 要件 | 実装 |
|---------|------|------|
| 実25 | アクセス権限管理 | GitHub EMU + Entra ID SAML SSO + SCIM プロビジョニング |
| 実26 | 特権ID管理 | Organization Owner / Repository Admin を Entra PIM で管理 |
| 実39 | バックアップ | GitHub Enterprise バックアップ + ACR Geo-Replication |
| 実150 | 開発環境の管理 | 本番環境と完全分離（別サブスクリプション・別VNet） |
| 実151 | テストデータの管理 | 本番データのマスキング必須・テスト専用データ生成 |
| 実152 | 開発・テスト結果の管理 | GitHub Actions ログ保持 + Log Analytics 長期保存 |
| 実153 | ソースコードの管理 | GitHub リポジトリ（署名付きコミット・ブランチ保護・CODEOWNERS） |
| 実154 | 外部委託先の管理 | EMU ゲストアカウント + 条件付きアクセス + リポジトリ単位の権限 |

## アーキテクチャの特徴

### GitHub Enterprise Cloud（ソースコード管理基盤）

金融機関の開発組織を **GitHub Enterprise Cloud** で統合管理します。**Enterprise Managed Users (EMU)** により、全ユーザーアカウントを Entra ID で一元管理し、退職・異動時の即座のアクセス無効化を実現します。

| 機能 | 設計 |
|------|------|
| 認証 | Entra ID SAML SSO（EMU） — 全ユーザーを IdP 管理下に |
| プロビジョニング | SCIM 自動プロビジョニング — Entra ID のグループに基づく自動追加・削除 |
| Organization 構成 | システム単位（勘定系・チャネル系等）で Organization を分離 |
| リポジトリ可視性 | Internal（Enterprise 内公開）を基本とし InnerSource を促進 |
| ブランチ保護 | main ブランチ: PR必須・レビュー2名以上・署名付きコミット・ステータスチェック必須 |
| CODEOWNERS | 重要ファイル（Dockerfile、IaC、セキュリティ設定等）に対する必須レビュアー指定 |
| Audit Log | Enterprise Audit Log を Log Analytics に転送（90日以上保持） |
| IP制限 | Enterprise レベルの IP Allow List で接続元を制限 |

> **参考**: [GitHub Enterprise Managed Users](https://docs.github.com/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/about-enterprise-managed-users)

### GitHub Copilot Enterprise（AI支援開発）

**GitHub Copilot Enterprise** により、開発者の生産性を向上させつつ、金融機関固有のガバナンスを適用します。

| 機能 | 設計 |
|------|------|
| コード補完 | IDE（VS Code / Visual Studio）でのリアルタイムコード提案 |
| Copilot Chat | コードの説明・リファクタリング・テスト生成・ドキュメント生成 |
| PR レビュー | Copilot による自動 PR サマリー・レビューコメント生成 |
| Knowledge Base | Organization のリポジトリをインデックス化し、社内コードベースに基づく提案 |
| ポリシー制御 | Organization 単位での Copilot 有効/無効設定 |
| コンテンツ除外 | 機密ファイル（鍵・設定・本番データ）を Copilot の学習・提案対象から除外 |
| Suggestions Matching | パブリックコードとの一致検出を有効化（ライセンスリスク回避） |
| 監査ログ | Copilot の利用状況（採用率・言語別利用率）を Enterprise Audit Log で追跡 |

**Copilot ガバナンスポリシー**:
- パブリックコードに一致する提案をブロック（Suggestions Matching Filter: Block）
- 機密リポジトリ（本番設定・暗号鍵管理等）では Copilot を無効化
- Organization Rulesets でカスタムコーディング規約・FISC準拠パターンを指示

### 開発者ワークステーション（AVD / Windows 365 / Codespaces）

金融機関の開発者には、ソースコードの端末残留を防止するため **仮想化された開発環境** を提供します。ユースケースに応じて3つの選択肢を使い分けます。

| 環境 | ユースケース | 特徴 |
|------|------------|------|
| **Azure Virtual Desktop** | 重量級開発（IDE + ビルド + テスト） | GPU対応、カスタムイメージ、VNet統合、マルチセッション |
| **Windows 365** | 標準開発・日常業務 | 常時起動のCloud PC、固定リソース、Intune管理 |
| **GitHub Codespaces** | 軽量開発・コードレビュー・ペアプロ | ブラウザベース、devcontainer定義、プリビルド、秒単位起動 |

**AVD 構成の詳細**:

| 項目 | 設計 |
|------|------|
| ホストプール | 開発用（Standard_D8s_v5）+ AI/ML開発用（Standard_NC24ads_A100_v4） |
| OS イメージ | カスタム Golden Image（VS Code、SDK、開発ツールプリインストール） |
| プロファイル | FSLogix プロファイルコンテナ（Azure Files Premium） |
| ネットワーク | 開発用 VNet に統合（Hub-Spoke、Firewall 経由のインターネットアクセス） |
| セキュリティ | 条件付きアクセス（MFA + 準拠デバイス必須）+ Screen Capture Protection |
| クリップボード | 双方向クリップボードリダイレクトの制限（コピーペースト制御） |
| USB | USB リダイレクト無効化（データ持ち出し防止） |
| Watermark | 画面透かし表示（スクリーンショット抑止） |

> **参考**: [Azure Virtual Desktop](https://learn.microsoft.com/azure/virtual-desktop/overview) — エンタープライズ VDI ソリューション

### GitHub Advanced Security（セキュリティスキャン）

**GitHub Advanced Security (GHAS)** により、開発ライフサイクル全体にわたるセキュリティスキャンを実装します（Shift Left Security）。

| 機能 | 説明 | 適用タイミング |
|------|------|-------------|
| **Code Scanning (CodeQL)** | セマンティック解析による脆弱性検出（SQL Injection、XSS、認証バイパス等） | PR作成時 + mainマージ時 + 週次スケジュール |
| **Secret Scanning** | ソースコード内のシークレット（API鍵、パスワード、証明書等）検出 | Push 時（リアルタイム） |
| **Push Protection** | シークレットを含むコミットの Push を事前ブロック | Push 時（事前防止） |
| **Dependabot** | 依存ライブラリの既知脆弱性検出 + 自動 PR 生成 | 毎日 + Advisory 公開時 |
| **Dependency Review** | PR 内の依存関係変更のセキュリティ影響評価 | PR作成時 |
| **Security Overview** | Enterprise / Organization 全体のセキュリティ状況ダッシュボード | 常時 |

**GHAS ガバナンスポリシー**:
- Code Scanning: Critical / High の検出時、PR マージをブロック
- Secret Scanning: Push Protection を全リポジトリで強制有効化
- Dependabot: Critical 脆弱性の自動 PR を即日レビュー必須
- Security Overview: 週次で CISO / セキュリティチームにレポート提出

> **参考**: [Embed Zero Trust security into your developer workflow](https://learn.microsoft.com/security/zero-trust/develop/embed-zero-trust-dev-workflow)

### GitHub Actions（CI/CD パイプライン）

GitHub Actions による CI/CD パイプラインを構築し、**Self-hosted Runner** を Azure VNet 内に配置することで閉域網内でのビルド・デプロイを実現します。

| コンポーネント | 設計 |
|-------------|------|
| Runner 基盤 | Azure Container Apps Jobs（イベント駆動型 Self-hosted Runner） |
| Runner ネットワーク | 開発用 VNet 内のサブネットに配置（Private Endpoint 経由で Azure サービスにアクセス） |
| Runner スケーリング | ワークフローキューに基づく自動スケーリング（0→N、アイドル時はゼロコスト） |
| シークレット管理 | GitHub Actions Secrets + Azure Key Vault（OIDC Federated Credential） |
| 環境管理 | GitHub Environments（dev / staging / production）+ 承認ワークフロー |
| 保護ルール | production 環境: 手動承認（2名以上）+ IP制限 + 待機タイマー |
| アーティファクト管理 | Azure Container Registry（ビルド済みイメージ）+ GitHub Packages（ライブラリ） |
| OIDC認証 | Azure AD Workload Identity Federation（PAT / Service Principal パスワード不要） |

**CI/CD パイプライン設計（標準テンプレート）**:

```
┌──────────────────────────────────────────────────────┐
│  Developer → PR 作成                                  │
│    ↓                                                  │
│  CI Pipeline (自動実行)                                │
│  ├── 1. Code Scanning (CodeQL)                        │
│  ├── 2. Secret Scanning                               │
│  ├── 3. Dependency Review                             │
│  ├── 4. Unit Test + Integration Test                  │
│  ├── 5. Container Image Build                         │
│  ├── 6. Image Vulnerability Scan (Defender)           │
│  ├── 7. SBOM Generation (sbom-tool)                   │
│  ├── 8. Image Signing (Notation)                      │
│  └── 9. Push to ACR (dev tag)                         │
│    ↓                                                  │
│  Code Review (CODEOWNERS + Copilot PR Review)         │
│    ↓                                                  │
│  Merge to main                                        │
│    ↓                                                  │
│  CD Pipeline                                          │
│  ├── 10. Deploy to Staging (自動)                     │
│  ├── 11. E2E Test + Load Test                         │
│  ├── 12. Staging 承認 (1名)                           │
│  ├── 13. Deploy to Production (承認後)                 │
│  │   └── Production 承認 (2名 + 待機タイマー)          │
│  └── 14. Post-deploy Health Check                     │
└──────────────────────────────────────────────────────┘
```

> **参考**: [Self-hosted CI/CD runners with Azure Container Apps jobs](https://learn.microsoft.com/azure/container-apps/tutorial-ci-cd-runners-jobs)

### Azure Container Registry（コンテナイメージ管理）

**Azure Container Registry (ACR) Premium** により、全システムのコンテナイメージを一元管理します。ソフトウェアサプライチェーンセキュリティを確保するため、イメージの署名・検証・SBOM管理を組み込みます。

| 機能 | 設計 |
|------|------|
| SKU | Premium（Geo-Replication + Private Link + ゾーン冗長） |
| Geo-Replication | 東日本（プライマリ）+ 西日本（DR） |
| Private Endpoint | 各システムのSpoke VNetからPrivate Endpoint経由でアクセス |
| イメージ署名 | Notation（Notary Project）によるイメージ署名・検証 |
| SBOM | sbom-tool によるSBOM生成 + ORAS による ACR への添付 |
| 脆弱性スキャン | Defender for Containers による継続的イメージスキャン |
| アドミッション制御 | AKS + Ratify + Gatekeeper による署名検証（未署名イメージのデプロイ拒否） |
| イメージ保持ポリシー | タグ付きイメージ: 90日保持、untagged: 7日で自動削除 |
| Quarantine | 外部イメージのインポート時は隔離レジストリで検証後に内部レジストリへ昇格 |

**サプライチェーンセキュリティフロー**:

```
外部イメージ取得:
  外部レジストリ → ACR Quarantine → 脆弱性スキャン → SBOM生成
    → 署名検証 → 内部ACRへ昇格 → 各システムで利用可能

社内イメージビルド:
  ソースコード → CI Build → 脆弱性スキャン → SBOM生成
    → Notation署名 → ACR Push → AKS Ratify検証 → デプロイ
```

> **参考**: [Container Secure Supply Chain (CSSC)](https://learn.microsoft.com/azure/security/container-secure-supply-chain/articles/container-secure-supply-chain-implementation/acquire-overview) — Microsoft のコンテナサプライチェーンセキュリティフレームワーク

### ネットワーク分離と環境分離

開発基盤はFISC実150（開発・テスト環境の管理）に基づき、本番環境と **完全分離** します。

| 分離レイヤー | 設計 |
|------------|------|
| サブスクリプション | 開発基盤用の専用サブスクリプション（本番サブスクリプションとは別） |
| VNet | 開発用 Spoke VNet（Hub VNet 経由で接続、ただし本番 Spoke VNet への直接通信は不可） |
| Entra ID | 同一テナント内だが、条件付きアクセスポリシーで本番リソースへのアクセスを制限 |
| データ | 本番データの開発環境への持ち込み禁止（マスキング済みテストデータのみ使用） |
| デプロイ権限 | 本番環境へのデプロイは GitHub Environments の承認ワークフロー必須 |
| クレデンシャル | OIDC Federated Credential（環境別に異なる Azure サービスプリンシパル） |

## アーキテクチャ図

### 全体アーキテクチャ

```
┌──────────────────────────────────────────────────────────────────┐
│  開発者                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │ 社内端末      │  │ リモート端末  │  │ BYOD (ブラウザのみ)   │  │
│  │ (Intune管理)  │  │ (Intune管理)  │  │                      │  │
│  └──────┬───────┘  └──────┬───────┘  └──────────┬────────────┘  │
│         │                 │                      │               │
│         │ RDP/RDWeb       │ RDP/RDWeb            │ HTTPS          │
│         │ (条件付きAccess) │ (MFA+準拠デバイス)    │ (Codespaces)  │
└─────────┼─────────────────┼──────────────────────┼───────────────┘
          │                 │                      │
┌─────────▼─────────────────▼──────────────────────▼───────────────┐
│  GitHub Cloud                                                     │
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │ GitHub Enterprise Cloud (EMU)                                │ │
│  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────────────┐  │ │
│  │ │ Repos    │ │ Actions  │ │ Copilot  │ │ Advanced       │  │ │
│  │ │ (Git)    │ │ (CI/CD)  │ │ Enterprise│ │ Security(GHAS)│  │ │
│  │ └──────────┘ └──────────┘ └──────────┘ └────────────────┘  │ │
│  │ ┌──────────┐ ┌──────────┐ ┌──────────────────────────────┐ │ │
│  │ │ Packages │ │ Codespaces│ │ Security Overview            │ │ │
│  │ └──────────┘ └──────────┘ └──────────────────────────────┘ │ │
│  └──────────────────────────────────────────────────────────────┘ │
│         │ OIDC Federation                                         │
│         │ (Workload Identity)                                     │
└─────────┼────────────────────────────────────────────────────────┘
          │
┌─────────▼────────────────────────────────────────────────────────┐
│ Azure                                                             │
│  ┌───────────────────────────────────────────────────────────┐   │
│  │  Hub VNet (10.0.0.0/16)                                   │   │
│  │  Azure Firewall / ExpressRoute GW                         │   │
│  └──────┬────────────────────────────────────────────────────┘   │
│         │ Peering                                                 │
│         ▼                                                         │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 開発基盤 Spoke VNet (10.28.0.0/16) — 東日本                  │ │
│  │                                                             │ │
│  │ ┌─────────────────────┐  ┌────────────────────────────────┐│ │
│  │ │ AVD ホストプール      │  │ GitHub Actions Self-hosted     ││ │
│  │ │ ┌──────┐ ┌──────┐   │  │ Runner (Container Apps Jobs)   ││ │
│  │ │ │開発用 │ │AI/ML │   │  │ ┌──────┐ ┌──────┐ ┌──────┐  ││ │
│  │ │ │D8s_v5│ │NC24  │   │  │ │Build │ │Test  │ │Deploy│  ││ │
│  │ │ └──────┘ └──────┘   │  │ │Runner│ │Runner│ │Runner│  ││ │
│  │ └─────────────────────┘  │ └──────┘ └──────┘ └──────┘  ││ │
│  │                           └────────────────────────────────┘│ │
│  │ ┌─────────────────────┐  ┌────────────────────────────────┐│ │
│  │ │ Azure Container     │  │ Azure Key Vault (Premium)      ││ │
│  │ │ Registry (Premium)  │  │ ビルド用シークレット・証明書     ││ │
│  │ │ Geo-Rep: 東+西日本  │  │                                ││ │
│  │ │ Notation署名対応     │  │                                ││ │
│  │ └─────────────────────┘  └────────────────────────────────┘│ │
│  │                                                             │ │
│  │ ┌─────────────────────┐  ┌────────────────────────────────┐│ │
│  │ │ Azure Files Premium │  │ Log Analytics Workspace        ││ │
│  │ │ (FSLogix Profile)   │  │ + Microsoft Sentinel           ││ │
│  │ └─────────────────────┘  └────────────────────────────────┘│ │
│  │                                                             │ │
│  │ ┌─────────────────────────────────────────────────────────┐│ │
│  │ │ Defender for Cloud / Defender for Containers             ││ │
│  │ │ → ACRイメージスキャン + AKSランタイム保護                   ││ │
│  │ └─────────────────────────────────────────────────────────┘│ │
│  └─────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │ 本番系 Spoke VNet (10.x.0.0/16)                              │ │
│  │ ※ Runner から ACR Pull + AKS Deploy のみ許可                  │ │
│  │ ※ 開発者の直接アクセスは不可（踏み台なし）                       │ │
│  └─────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### 開発者ワークステーション

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| 仮想デスクトップ | Azure Virtual Desktop | Standard_D8s_v5（Pooled） | 標準開発環境（VS Code + SDK） |
| AI/ML開発用 | Azure Virtual Desktop | Standard_NC24ads_A100_v4 | GPU を必要とする AI/ML モデル開発 |
| Cloud PC | Windows 365 Enterprise | 8 vCPU / 32GB RAM | 常時起動の個人専用開発環境 |
| クラウドIDE | GitHub Codespaces | 8-core / 16GB | 軽量開発・コードレビュー・ペアプログラミング |
| プロファイル | Azure Files Premium | FSLogix プロファイルコンテナ | ユーザープロファイルのローミング |

### CI/CD・ビルド

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| Self-hosted Runner | Azure Container Apps Jobs | イベント駆動型（0→N スケール） | GitHub Actions ワークフロー実行 |
| コンテナレジストリ | Azure Container Registry | Premium（Geo-Rep + Zone冗長） | イメージ管理・署名・SBOM |
| パッケージ管理 | GitHub Packages | — | npm / NuGet / Maven ライブラリ管理 |
| テスト基盤 | Azure Load Testing | — | 負荷テスト・パフォーマンスゲート |

### セキュリティ・ガバナンス

| コンポーネント | サービス | 用途 |
|-------------|---------|------|
| コードスキャン | GitHub Code Scanning (CodeQL) | 静的解析による脆弱性検出 |
| シークレットスキャン | GitHub Secret Scanning + Push Protection | シークレット漏洩防止 |
| 依存関係管理 | GitHub Dependabot | 脆弱な依存ライブラリの検出・自動更新 |
| イメージスキャン | Defender for Containers | ACR 内イメージの脆弱性スキャン |
| CSPM | Defender for Cloud | セキュリティポスチャ管理 |
| シークレット管理 | Azure Key Vault Premium | ビルド用証明書・API鍵・署名鍵 |
| アドミッション制御 | Ratify + Gatekeeper (AKS) | 未署名イメージのデプロイ拒否 |
| SIEM | Microsoft Sentinel | GitHub Audit Log の相関分析・異常検知 |

### ID・アクセス管理

| コンポーネント | サービス | 用途 |
|-------------|---------|------|
| 開発者認証 | Entra ID + GitHub EMU (SAML SSO) | シングルサインオン・自動プロビジョニング |
| 特権管理 | Entra PIM | Organization Owner / Admin の Just-in-Time 昇格 |
| 条件付きアクセス | Entra Conditional Access | MFA + 準拠デバイス + 位置情報制限 |
| Workload Identity | Entra Workload Identity Federation | GitHub Actions → Azure 間の OIDC 認証 |
| デバイス管理 | Microsoft Intune | 開発端末のコンプライアンス強制 |

## 可用性・DR設計

### 目標値

| 項目 | 目標値 | 根拠 |
|------|-------|------|
| **RTO** | < 4時間（GitHub Cloud）、< 1時間（ACR / AVD） | 開発業務の継続性 |
| **RPO** | ≈ 0（Git 分散特性）、< 1時間（AVD プロファイル） | Git は分散型のため各開発者がフルコピーを保持 |
| **可用性** | 99.9%（GitHub SLA）、99.95%（AVD / ACR） | 業務時間帯の可用性を保証 |

### 障害レベル別対応

| 障害レベル | 影響 | 対応 |
|-----------|------|------|
| GitHub 一時障害 | CI/CD の一時停止 | GitHub Status 監視 + 開発者はローカル Git で作業継続 |
| AVD ホスト障害 | 一部開発者のセッション断 | ホストプール自動スケーリング + FSLogix プロファイル再接続 |
| ACR リージョン障害 | イメージ Pull/Push 不可 | Geo-Replication により西日本レプリカへ自動ルーティング |
| Self-hosted Runner 障害 | ビルド・デプロイの一時停止 | Container Apps Jobs の自動再起動 + GitHub-hosted Runner へのフォールバック |
| AZ 障害 | AVD / ACR の一部リソース喪失 | ゾーン冗長構成により他ゾーンで継続 |
| リージョン障害 | 東日本の開発基盤全面停止 | AVD: 西日本ホストプール（Warm Standby）+ ACR: 西日本レプリカ |

### バックアップ

| 対象 | 設計 |
|------|------|
| ソースコード | Git 分散特性（各開発者 + Runner にフルコピー）+ GitHub Enterprise バックアップ API |
| CI/CD 設定 | GitHub Actions ワークフロー YAML はリポジトリ内で Git 管理 |
| IaC テンプレート | リポジトリ内で Git 管理（コードとしてのバックアップ） |
| AVD プロファイル | Azure Files Premium (ZRS) + Azure Backup |
| ACR イメージ | Geo-Replication（東日本 + 西日本） |
| Key Vault | Soft Delete + Purge Protection（90日保持） |
| Audit Log | Log Analytics Workspace（180日オンライン + Blob Archive 7年保持） |

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: 開発基盤 東日本 (10.28.0.0/16)
│               ├── snet-avd       (10.28.0.0/23)  — AVD ホストプール（/23 で最大512台）
│               ├── snet-runner    (10.28.2.0/24)  — GitHub Actions Self-hosted Runner
│               ├── snet-acr       (10.28.3.0/24)  — ACR Private Endpoint
│               ├── snet-kv        (10.28.4.0/24)  — Key Vault Private Endpoint
│               ├── snet-files     (10.28.5.0/24)  — Azure Files Private Endpoint (FSLogix)
│               ├── snet-monitor   (10.28.6.0/24)  — Log Analytics / Sentinel PE
│               └── snet-pe        (10.28.7.0/24)  — その他 Private Endpoint
│
└── Peering ──▶ Spoke VNet: 開発基盤 西日本 (10.29.0.0/16)
                ├── snet-avd       (10.29.0.0/23)  — AVD ホストプール (DR)
                ├── snet-acr       (10.29.3.0/24)  — ACR Private Endpoint (Geo-Rep)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可
- アウトバウンド: Hub Firewall 経由（GitHub.com / Copilot API へのアクセスを明示許可）
- AVD サブネット: RDP (3389) は Azure Virtual Desktop サービスタグからのみ許可
- Runner サブネット: ACR / Key Vault / 本番系 AKS API への Private Endpoint 通信のみ許可
- 本番系 Spoke VNet への通信: Runner → ACR Pull + AKS Deploy のみ（Firewall ルール）
- 開発者 AVD → 本番系 Spoke VNet: 直接通信不可（踏み台アクセスは別途 Bastion 経由）
```

## 監視・オブザーバビリティ

### 開発基盤の監視

| 監視項目 | ツール | 用途 |
|---------|-------|------|
| GitHub 稼働状態 | GitHub Status API + Logic Apps | GitHub 障害時のアラート・Slack/Teams 通知 |
| CI/CD メトリクス | GitHub Actions API + Power BI | ビルド成功率・所要時間・キュー待ち時間の可視化 |
| AVD セッション | Azure Monitor + AVD Insights | アクティブセッション数・レイテンシ・ログオン時間 |
| ACR 使用状況 | Azure Monitor | ストレージ使用量・Pull/Push 回数・Geo-Replication ラグ |
| Runner 状態 | Container Apps Metrics | Runner 起動数・実行時間・エラー率 |

### セキュリティ監視

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| シークレット漏洩 | GitHub Secret Scanning | Push Protection バイパス発生時即時通知 |
| 脆弱性検出 | Code Scanning + Dependabot | Critical / High 検出時即時通知 |
| ACR イメージ脆弱性 | Defender for Containers | Critical 脆弱性イメージの検出時 |
| 不審なリポジトリアクセス | GitHub Audit Log + Sentinel | 通常時間外・通常外IPからのアクセス |
| Organization 設定変更 | GitHub Audit Log + Sentinel | Admin権限操作・ブランチ保護変更時 |
| 大量コードダウンロード | GitHub Audit Log + Sentinel | 短時間での大量 git clone / download |
| AVD 不審ログオン | Entra ID Sign-in Logs + Sentinel | 不可能な旅行（Impossible Travel）検知 |

### 開発者体験（DevEx）メトリクス

| メトリクス | 測定方法 | 目標値 |
|-----------|---------|-------|
| PR リードタイム | GitHub API（PR作成→マージ） | < 24時間 |
| CI ビルド時間 | GitHub Actions（ワークフロー実行時間） | < 10分 |
| デプロイ頻度 | GitHub Actions（本番デプロイ回数/週） | 週1回以上 |
| 変更失敗率 | GitHub Actions（本番デプロイ失敗率） | < 5% |
| MTTR | GitHub Issues（障害検知→修正マージ） | < 4時間 |
| Copilot 採用率 | GitHub Copilot Metrics API | > 80% |

> **設計ポイント**: DORA メトリクス（デプロイ頻度・リードタイム・変更失敗率・MTTR）を継続的に測定し、開発組織のパフォーマンスを定量評価します。

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep（Azure リソース）+ Terraform（マルチクラウド対応が必要な場合） |
| CI/CD | GitHub Actions（Self-hosted Runner on Azure Container Apps） |
| 環境戦略 | 開発 → ステージング → 本番（GitHub Environments + 承認ワークフロー） |
| Golden Image | Azure Image Builder + Packer によるAVD用カスタムイメージの自動ビルド |
| devcontainer | GitHub Codespaces / VS Code Dev Containers 用の標準化された開発環境定義 |
| GitOps | AKS + Flux v2 による宣言的デプロイ（本番系システム向け） |
| ポリシー | Azure Policy（FISC準拠）+ GitHub Organization Rulesets（リポジトリルール） |

## 関連リソース

- [GitHub Enterprise Cloud: Enterprise Managed Users](https://docs.github.com/enterprise-cloud@latest/admin/identity-and-access-management/using-enterprise-managed-users-for-iam/about-enterprise-managed-users)
- [GitHub Advanced Security Overview](https://docs.github.com/code-security/getting-started/github-security-features)
- [GitHub Copilot for Business](https://docs.github.com/copilot/overview-of-github-copilot/about-github-copilot-business)
- [Embed Zero Trust security into your developer workflow](https://learn.microsoft.com/security/zero-trust/develop/embed-zero-trust-dev-workflow)
- [Azure Virtual Desktop Overview](https://learn.microsoft.com/azure/virtual-desktop/overview)
- [Windows 365 Overview](https://learn.microsoft.com/windows-365/overview)
- [GitHub Codespaces Overview](https://docs.github.com/codespaces)
- [Self-hosted CI/CD runners with Azure Container Apps jobs](https://learn.microsoft.com/azure/container-apps/tutorial-ci-cd-runners-jobs)
- [Azure Container Registry: Best practices](https://learn.microsoft.com/azure/container-registry/container-registry-best-practices)
- [Azure Container Registry: Geo-replication](https://learn.microsoft.com/azure/container-registry/container-registry-geo-replication)
- [Azure Container Registry: Private Link](https://learn.microsoft.com/azure/container-registry/container-registry-private-link)
- [Container Secure Supply Chain (CSSC)](https://learn.microsoft.com/azure/security/container-secure-supply-chain/articles/container-secure-supply-chain-implementation/acquire-overview)
- [Notary Project: Container image signing](https://notaryproject.dev/)
- [SBOM tool](https://github.com/microsoft/sbom-tool)
- [Ratify: Artifact verification for Kubernetes](https://ratify.dev/)
- [GitHub Actions: OIDC with Azure](https://docs.github.com/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-azure)
- [Entra Workload Identity Federation](https://learn.microsoft.com/entra/workload-id/workload-identity-federation)
