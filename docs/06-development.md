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

## 2. ソフトウェア品質管理（実77〜実88）

### 実77: テスト計画の策定
**FISC要件**: テスト計画を策定すること。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| テスト計画管理 | Azure DevOps Test Plans | テストケース・テストスイートの管理 |
| 自動テスト | GitHub Actions | CI パイプラインでの自動テスト実行 |
| テストカバレッジ | SonarQube / Codecov | コードカバレッジの計測・可視化 |

### 実78: 単体テスト・結合テストの実施
**FISC要件**: 単体テスト及び結合テストを適切に実施すること。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| 単体テスト | GitHub Actions（CI） | プルリクエスト時の自動単体テスト実行 |
| 結合テスト | Azure Dev/Test 環境 | 統合テスト環境での結合テスト |
| テスト結果管理 | Azure DevOps Test Plans | テスト結果の記録・追跡・レポート |

### 実79: システムテストの実施
**FISC要件**: システムテストを適切に実施すること。
| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| E2E テスト | Azure Dev/Test 環境 | 本番相当のシステムテスト環境 |
| 性能テスト | Azure Load Testing | JMeter ベースの性能・負荷テスト |
| セキュリティテスト | Microsoft Defender for Cloud | 脆弱性スキャン・セキュリティ評価 |

### 実80: 受入テストの実施
**FISC要件**: 受入テストを適切に実施すること。
**Azure対応**:
- **Azure App Service スロット** — ステージング環境でのユーザー受入テスト
- **Azure DevOps Test Plans** — 受入テストケースの管理・実行・結果記録
- **Azure Monitor / Application Insights** — テスト中のパフォーマンス・エラー監視

### 実81: 回帰テストの実施
**FISC要件**: 変更時に回帰テストを実施すること。
**Azure対応**:
- **GitHub Actions** — 変更時の自動回帰テスト実行（CI/CD パイプライン）
- **Azure DevOps Test Plans** — 回帰テストスイートの管理
- **Azure Load Testing** — 性能回帰テストの自動実行

### 実82〜実88: テスト結果の検証・本番移行管理
| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 実82 | テスト結果の検証 | Azure DevOps Test Plans（テスト結果のレビュー・承認ワークフロー） |
| 実83 | テスト環境と本番環境の分離 | Azure サブスクリプション分離 + Azure Policy による環境ガードレール |
| 実84 | テストデータの管理 | Azure SQL Dynamic Data Masking（本番データのマスキング） |
| 実85 | 本番移行手順の策定 | GitHub Actions / Azure Pipelines（Blue-Green / Canary デプロイ） |
| 実86 | 本番移行後の確認 | Azure Monitor / Application Insights（移行後のヘルスチェック） |
| 実87 | ロールバック手順の策定 | Azure App Service スロットスワップ / AKS ロールバック |
| 実88 | 緊急変更の管理 | Microsoft Entra PIM（緊急時の特権アクセス） + Azure DevOps 緊急変更ワークフロー |

## 3. セキュリティ機能の実装（実89〜実90）

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

### 実91〜実93: 設計・開発ドキュメントの管理
| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 実91 | 設計書の管理 | Azure DevOps Wiki / SharePoint（設計書のバージョン管理・アクセス制御） |
| 実92 | 開発標準の策定 | GitHub リポジトリテンプレート + CODEOWNERS（開発標準の強制） |
| 実93 | ソースコードの管理 | GitHub（署名付きコミット + ブランチ保護 + CODEOWNERS） |

## 4. パッケージ・OSS管理（実94）

### 実94: パッケージ導入時の品質確保

**FISC要件**: パッケージ導入に当たり、ソフトウェアの品質を確保すること。

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| OSS脆弱性管理 | Dependabot / GitHub Advisory | OSS依存関係の脆弱性自動検出・PR作成 |
| ライセンス管理 | GitHub Advanced Security | OSSライセンスの自動検出 |
| パッケージ管理 | Azure Artifacts / GitHub Packages | プライベートパッケージレジストリ |
| SBOM | GitHub SBOM生成 | ソフトウェア部品表の自動生成 |

## 5. 運用テスト・品質保証（実95〜実100）

### 実95〜実100: 運用テスト・品質保証
| FISC基準 | 要件 | Azure対応 |
|---------|------|----------|
| 実95 | 運用テストの実施 | Azure Chaos Studio（本番環境での障害注入テスト） |
| 実96 | 性能基準の設定 | Azure Monitor（SLI/SLO の定義・監視）、Application Insights |
| 実97 | 品質メトリクスの管理 | SonarQube / Azure DevOps（品質ゲート + コードカバレッジ） |
| 実98 | 不具合管理 | GitHub Issues / Azure DevOps Boards（バグトラッキング・優先度管理） |
| 実99 | リリース管理 | GitHub Releases / Azure Pipelines（リリースノート自動生成） |
| 実100 | 変更影響分析 | Azure Monitor Change Analysis（構成変更の影響分析） |

## 6. パフォーマンス管理（実101）

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


---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [07. クラウドガバナンス](07-cloud-governance.md) | クラウド固有リスク・責任分界・外部委託管理 |
| → | [開発基盤 ランディングゾーン](../landing-zone/engineering-platform.md) | GitHub / GitHub Copilot / AVD を活用した開発基盤の詳細設計 |
| → | [ワークロード別 FISC実務基準マッピング](../mapping/fisc-workload-mapping.md) | 各ランディングゾーンへの FISC 基準適用要件 |