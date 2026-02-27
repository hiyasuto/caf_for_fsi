# 06 — セキュア開発

> FISC実務基準（実75〜実101）→ Azure DevOps / GitHub / Security in Development

## 概要

FISC実務基準における開発・テスト・品質管理要件を、Azure DevOps/GitHubのDevSecOpsパイプラインとAzureの開発者向けセキュリティ機能を活用して実現します。

## 1. 開発プロセス（実75〜実76）

### 実75: システムの開発・変更手順

**FISC要件**: システムの開発・変更手順を明確にすること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| ソース管理 | GitHub / Azure Repos | Git ベースのバージョン管理 |
| CI/CD | GitHub Actions / Azure Pipelines | 自動ビルド・テスト・デプロイ |
| 変更管理 | Azure DevOps Boards | 変更要求の管理・追跡・承認 |
| 環境分離 | Azure Subscriptions / Resource Groups | 開発・テスト・ステージング・本番の環境分離 |
| IaC | Bicep / Terraform | インフラの宣言的定義・変更管理 |
| 承認ゲート | Azure Pipelines Approvals | 本番デプロイ前の承認プロセス |

### 実76: テスト環境の整備

**FISC要件**: テスト環境を整備すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| テスト環境 | Azure Dev/Test サブスクリプション | 割引料金でのテスト環境構築 |
| テストデータ | Azure SQL Data Masking | 本番データのマスキングによるテストデータ生成 |
| 負荷テスト | Azure Load Testing | JMeterベースの負荷テスト |
| ステージング | Azure App Service スロット | スロットによるステージング環境 |

## 2. セキュリティ機能の実装（実89〜実90）

### 実89: セキュリティ機能の取込み

**FISC要件**: 必要となるセキュリティ機能を取り込むこと。

**Azure対応（DevSecOps）**:

```
コード作成 → ビルド → テスト → デプロイ → 運用
   │          │        │         │         │
   ▼          ▼        ▼         ▼         ▼
GitHub       SAST     DAST     承認ゲート  Defender
Advanced    (CodeQL)  (OWASP)  (PIM)     for Cloud
Security                                 (継続監視)
```

| フェーズ | ツール | 説明 |
|---------|-------|------|
| コーディング | GitHub Advanced Security | シークレットスキャン・依存関係レビュー |
| 静的解析 | CodeQL / Microsoft Security DevOps | SAST（静的アプリケーションセキュリティテスト） |
| 依存関係 | Dependabot / GitHub Advisory Database | サードパーティライブラリの脆弱性検出 |
| コンテナ | Microsoft Defender for Containers | コンテナイメージの脆弱性スキャン |
| IaC | Checkov / Microsoft Defender for DevOps | IaC テンプレートのセキュリティ検証 |
| 動的解析 | Microsoft Defender for App Service | DAST（動的アプリケーションセキュリティテスト） |

### 実90: 設計段階のソフトウェア品質確保

**FISC要件**: 設計段階におけるソフトウェアの品質を確保すること。

**Azure対応**:
- **Azure DevOps Boards** — 要件定義・設計レビューの管理
- **Azure DevOps Wiki** — 設計ドキュメントの管理
- **Pull Request レビュー** — コードレビューの義務化（ブランチポリシー）
- **品質ゲート** — SonarQube等との連携による品質メトリクス管理

## 3. パッケージ・OSS管理（実94）

### 実94: パッケージ導入時の品質確保

**FISC要件**: パッケージ導入に当たり、ソフトウェアの品質を確保すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| OSS脆弱性管理 | Dependabot / GitHub Advisory | OSS依存関係の脆弱性自動検出・PR作成 |
| ライセンス管理 | GitHub Advanced Security | OSSライセンスの自動検出 |
| パッケージ管理 | Azure Artifacts / GitHub Packages | プライベートパッケージレジストリ |
| SBOM | GitHub SBOM生成 | ソフトウェア部品表の自動生成 |

## 4. パフォーマンス管理（実101）

### 実101: 負荷状態の監視制御

**FISC要件**: 負荷状態の監視制御機能を充実すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| パフォーマンス監視 | Azure Monitor / Application Insights | アプリケーションパフォーマンスの監視 |
| 自動スケーリング | Azure Autoscale / VMSS | 負荷に応じた自動スケールアウト/イン |
| 負荷テスト | Azure Load Testing | 本番相当の負荷テスト |
| CDN | Azure Front Door / Azure CDN | コンテンツ配信の最適化 |
| キャッシュ | Azure Cache for Redis | データベース負荷の軽減 |

## 参考リンク

- [Azure DevOps](https://learn.microsoft.com/azure/devops/)
- [GitHub Advanced Security](https://docs.github.com/code-security)
- [Microsoft Security DevOps](https://learn.microsoft.com/azure/defender-for-cloud/azure-devops-extension)
- [Azure Load Testing](https://learn.microsoft.com/azure/load-testing/)
