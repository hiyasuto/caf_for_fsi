---
title: FISC安全対策基準 第13版 — 実務基準 索引（開発・追加信頼性・AI安全対策）
type: fisc-reference
status: draft
tags: [fisc, practice-standards, development, ai-safety]
updated: 2026-04-30
---

# FISC安全対策基準 第13版 — 実務基準 索引（実75〜実153）

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 FISC が著作権を保有する有償刊行物です。本ページは章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。基準の正式な要件本文・解説は [FISC原本](https://www.fisc.or.jp/) を参照してください。

## このページの位置づけ

- 実務基準のうち、**開発（実75〜実101）／障害の早期発見・回復に係る追加信頼性（実102〜実105）／AI 安全対策（実150〜実153、第13版新設）** を扱う索引です。
- 実1〜実74（運用・セキュリティ運用領域）は Part A: [`02-practice-standards-security-ops.md`](./02-practice-standards-security-ops.md) を参照してください。
- 各エントリの「Azure対応」リンクは、本リポジトリ内の `docs/` 配下にある詳細分析を指します。

## グループ別 索引

| グループ | 基準範囲 | 主題 | 主な参照先 |
|---|---|---|---|
| 開発プロセス | 実75〜実76 | 開発・変更手順、テスト環境整備 | [docs/06-development.md](../../docs/06-development.md) |
| ソフトウェア品質管理（テスト） | 実77〜実88 | テスト計画／単体・結合・システム・受入・回帰／本番移行 | [docs/06-development.md](../../docs/06-development.md) |
| セキュア開発・設計 | 実89〜実93 | DevSecOps、設計品質、ドキュメント／ソース管理 | [docs/06-development.md](../../docs/06-development.md) |
| パッケージ・OSS管理 | 実94 | OSS／パッケージ導入時の品質確保 | [docs/06-development.md](../../docs/06-development.md) |
| 運用テスト・品質保証 | 実95〜実100 | 運用テスト、品質メトリクス、不具合・リリース管理 | [docs/06-development.md](../../docs/06-development.md) |
| パフォーマンス管理 | 実101 | 負荷状態の監視制御 | [docs/06-development.md](../../docs/06-development.md) |
| 信頼性（追加：障害の早期発見・回復） | 実102〜実105 | 監視・検出・切分け、縮退、取引制限 | [docs/04-reliability.md](../../docs/04-reliability.md) |
| AI 安全対策（13版新設） | 実150〜実153 | AI/生成AIの方針・運用・安全対策・教育 | [docs/08-ai-safety.md](../../docs/08-ai-safety.md) |

## 基準別 索引

### 開発プロセス（実75〜実76）

#### 実75: システムの開発・変更手順
- **概要**: 開発・変更を統制するための手順整備。ソース管理、CI/CD、変更管理、環境分離、IaC、承認ゲートが論点。
- **Azure対応**: GitHub / Azure Repos、GitHub Actions / Azure Pipelines、Azure DevOps Boards、Azure Subscriptions、Bicep/Terraform → [docs/06-development.md §1](../../docs/06-development.md)

#### 実76: テスト環境の整備
- **概要**: 本番から分離した開発・テスト用環境の整備とテストデータ管理。
- **Azure対応**: Azure Dev/Test サブスクリプション、Azure SQL Data Masking、Azure Load Testing、App Service スロット → [docs/06-development.md §1](../../docs/06-development.md)

### ソフトウェア品質管理（実77〜実88）

#### 実77: テスト計画の策定
- **概要**: テスト計画（範囲・観点・合格基準）の策定。
- **Azure対応**: Azure DevOps Test Plans、GitHub Actions、SonarQube/Codecov（カバレッジ可視化）→ [docs/06-development.md §2](../../docs/06-development.md)

#### 実78: 単体テスト・結合テストの実施
- **概要**: 単体／結合テストの計画的実施と結果記録。
- **Azure対応**: GitHub Actions（PR時 CI 実行）、Azure Dev/Test 環境、Azure DevOps Test Plans → [docs/06-development.md §2](../../docs/06-development.md)

#### 実79: システムテストの実施
- **概要**: 本番相当環境でのシステムテスト（機能・性能・セキュリティ）。
- **Azure対応**: Azure Dev/Test 環境、Azure Load Testing、Microsoft Defender for Cloud → [docs/06-development.md §2](../../docs/06-development.md)

#### 実80: 受入テストの実施
- **概要**: 利用部門による受入テスト（UAT）の実施。
- **Azure対応**: App Service スロット、Azure DevOps Test Plans、Azure Monitor / Application Insights → [docs/06-development.md §2](../../docs/06-development.md)

#### 実81: 回帰テストの実施
- **概要**: 変更時の既存機能影響を確認する回帰テスト。
- **Azure対応**: GitHub Actions（自動回帰）、Azure DevOps Test Plans、Azure Load Testing → [docs/06-development.md §2](../../docs/06-development.md)

#### 実82: テスト結果の検証
- **概要**: テスト結果のレビュー・承認による品質判定。
- **Azure対応**: Azure DevOps Test Plans のレビュー／承認ワークフロー → [docs/06-development.md §2](../../docs/06-development.md)

#### 実83: テスト環境と本番環境の分離
- **概要**: テスト・本番環境の分離と相互影響の防止。
- **Azure対応**: サブスクリプション分離、Azure Policy による環境ガードレール → [docs/06-development.md §2](../../docs/06-development.md)

#### 実84: テストデータの管理
- **概要**: 本番データ流用時のマスキング等、テストデータの統制。
- **Azure対応**: Azure SQL Dynamic Data Masking → [docs/06-development.md §2](../../docs/06-development.md)

#### 実85: 本番移行手順の策定
- **概要**: 本番リリース手順（段階デプロイを含む）の整備。
- **Azure対応**: GitHub Actions / Azure Pipelines（Blue-Green、Canary）→ [docs/06-development.md §2](../../docs/06-development.md)

#### 実86: 本番移行後の確認
- **概要**: 移行直後のヘルスチェック・モニタリング。
- **Azure対応**: Azure Monitor、Application Insights → [docs/06-development.md §2](../../docs/06-development.md)

#### 実87: ロールバック手順の策定
- **概要**: 移行失敗時に確実に元に戻すための手順。
- **Azure対応**: App Service スロットスワップ、AKS ロールバック → [docs/06-development.md §2](../../docs/06-development.md)

#### 実88: 緊急変更の管理
- **概要**: 緊急時の変更承認・特権アクセス・事後検証。
- **Azure対応**: Microsoft Entra PIM、Azure DevOps 緊急変更ワークフロー → [docs/06-development.md §2](../../docs/06-development.md)

### セキュリティ機能の実装・設計品質（実89〜実93）

#### 実89: セキュリティ機能の取込み
- **概要**: 開発工程全体でのセキュリティ機能組込み（DevSecOps）。SAST/DAST/SCA、シークレット・依存関係スキャン、IaC スキャンが論点。
- **Azure対応**: GitHub Advanced Security、CodeQL、Dependabot、Microsoft Defender for DevOps / Containers / App Service → [docs/06-development.md §3](../../docs/06-development.md)

#### 実90: 設計段階のソフトウェア品質確保
- **概要**: 要件・設計レビュー、品質ゲートの整備。
- **Azure対応**: Azure DevOps Boards / Wiki、PR レビュー（ブランチポリシー）、SonarQube 連携 → [docs/06-development.md §3](../../docs/06-development.md)

#### 実91: 設計書の管理
- **概要**: 設計書のバージョン管理・アクセス制御。
- **Azure対応**: Azure DevOps Wiki、SharePoint → [docs/06-development.md §3](../../docs/06-development.md)

#### 実92: 開発標準の策定
- **概要**: コーディング規約等の開発標準化と強制。
- **Azure対応**: GitHub リポジトリテンプレート、CODEOWNERS → [docs/06-development.md §3](../../docs/06-development.md)

#### 実93: ソースコードの管理
- **概要**: ソースコードの保護・改ざん検知・アクセス制御。
- **Azure対応**: GitHub（署名付きコミット、ブランチ保護、CODEOWNERS）→ [docs/06-development.md §3](../../docs/06-development.md)

### パッケージ・OSS管理（実94）

#### 実94: パッケージ導入時の品質確保
- **概要**: OSS／商用パッケージ導入時の脆弱性・ライセンス確認、SBOM管理。
- **Azure対応**: Dependabot、GitHub Advisory、Azure Artifacts / GitHub Packages、SBOM 生成 → [docs/06-development.md §4](../../docs/06-development.md)

### 運用テスト・品質保証（実95〜実100）

#### 実95: 運用テストの実施
- **概要**: 障害注入を含む運用視点でのテスト実施。
- **Azure対応**: Azure Chaos Studio → [docs/06-development.md §5](../../docs/06-development.md)

#### 実96: 性能基準の設定
- **概要**: SLI/SLO 等の性能・可用性基準の定義と監視。
- **Azure対応**: Azure Monitor、Application Insights → [docs/06-development.md §5](../../docs/06-development.md)

#### 実97: 品質メトリクスの管理
- **概要**: コードカバレッジ・品質ゲート等のメトリクス管理。
- **Azure対応**: SonarQube、Azure DevOps 品質ゲート → [docs/06-development.md §5](../../docs/06-development.md)

#### 実98: 不具合管理
- **概要**: バグの記録・優先度付け・追跡。
- **Azure対応**: GitHub Issues、Azure DevOps Boards → [docs/06-development.md §5](../../docs/06-development.md)

#### 実99: リリース管理
- **概要**: リリース計画・成果物・リリースノートの管理。
- **Azure対応**: GitHub Releases、Azure Pipelines → [docs/06-development.md §5](../../docs/06-development.md)

#### 実100: 変更影響分析
- **概要**: 構成変更が業務・性能に与える影響の分析。
- **Azure対応**: Azure Monitor Change Analysis → [docs/06-development.md §5](../../docs/06-development.md)

### パフォーマンス管理（実101）

#### 実101: 負荷状態の監視制御
- **概要**: 高負荷状態の検知と自動制御（スケール、配信最適化、キャッシュ等）。
- **Azure対応**: Azure Monitor、Autoscale / VMSS、Azure Load Testing、Azure Front Door / CDN、Azure Cache for Redis → [docs/06-development.md §6](../../docs/06-development.md)

### 信頼性（追加：障害の早期発見・回復機能、実102〜実105）

#### 実102: システム運用状況の監視機能
- **概要**: 稼働・停止・エラー状態を監視し、障害の早期発見につなげる機能。
- **Azure対応**: Azure Monitor、Application Insights、Network Watcher、Log Analytics、Azure Monitor Workbooks/Grafana、Azure Arc → [docs/04-reliability.md §3](../../docs/04-reliability.md)

#### 実103: 障害の検出及び障害箇所の切分け機能
- **概要**: 障害検出・トレース・切分け・基盤起因／自社起因の判別。
- **Azure対応**: Azure Monitor Alerts（動的閾値）、Application Insights（分散トレース／アプリケーションマップ）、Azure Resource Health、Service Health、Network Watcher → [docs/04-reliability.md §3](../../docs/04-reliability.md)

#### 実103-1: 冗長構成・バックアップ構成の正常機能確認（第13版新設）
- **概要**: 冗長／バックアップ構成が実際に正常動作することを継続的に検証。サイバー攻撃で本番・バックアップが同時不能化するリスクの低減も論点。
- **Azure対応**: Azure Chaos Studio、Azure Site Recovery テストフェールオーバー、Load Balancer ヘルスプローブ、Automation Runbook、イミュータブルストレージ → [docs/04-reliability.md §3](../../docs/04-reliability.md)

#### 実104: 障害時の縮退・再構成機能
- **概要**: 障害発生時に機能を縮小しつつシステム継続運転、自動再構成・復旧後再組込み。
- **Azure対応**: Azure API Management（レート制限／サーキットブレーカー）、Load Balancer / Traffic Manager、VM Scale Sets / AKS（自動修復）、App Configuration Feature Flags → [docs/04-reliability.md §3](../../docs/04-reliability.md)

#### 実105: 障害時の取引制限機能
- **概要**: 障害状況に応じた業務／サービス／リージョン／機能単位での取引制限。
- **Azure対応**: Azure API Management、Azure Front Door、Traffic Manager、Application Gateway、App Configuration Feature Flags → [docs/04-reliability.md §3](../../docs/04-reliability.md)

### AI 安全対策（第13版新設、実150〜実153）

#### 実150: AI利用に係る方針策定・態勢整備
- **概要**: AI／生成AI 利用方針の策定とガバナンス態勢（責任分界・組織体制）の整備。
- **Azure対応**: Azure Policy（AI 利用ガードレール）、Azure AI Content Safety、Microsoft Entra ID + RBAC、Microsoft Responsible AI 6原則 → [docs/08-ai-safety.md §1](../../docs/08-ai-safety.md)

#### 実151: AI適切な運用管理方法
- **概要**: モデル・プロンプトのバージョン／品質／監査ログ管理、データガバナンス。
- **Azure対応**: Azure Machine Learning、Microsoft Foundry（プロンプト管理・評価）、Azure OpenAI 診断ログ、Microsoft Purview → [docs/08-ai-safety.md §2](../../docs/08-ai-safety.md)

#### 実152: AIに係る安全対策
- **概要**: 機密データ漏えい、ハルシネーション、プロンプトインジェクション、悪用、バイアス、知財リスクへの対策。
- **Azure対応**: Azure AI Content Safety（Prompt Shields）、Microsoft Purview DLP、Azure AI Search + Azure OpenAI（RAG）、Azure API Management、Microsoft Foundry 評価、Azure OpenAI 著作権フィルター → [docs/08-ai-safety.md §3](../../docs/08-ai-safety.md)

#### 実153: AI利用に係る教育・注意喚起
- **概要**: 利用者への教育・利用ガイドライン整備・注意喚起（ハルシネーション検証義務等）。
- **Azure対応**: Microsoft Learn Responsible AI モジュール、Azure OpenAI 利用ガイドライン／利用規約の組織内周知 → [docs/08-ai-safety.md §4](../../docs/08-ai-safety.md)

## 関連リンク

- [安対基準 README](./README.md)
- Part A（運用・セキュリティ運用、実1〜実74）: [`02-practice-standards-security-ops.md`](./02-practice-standards-security-ops.md)
- [docs/06-development.md](../../docs/06-development.md) — セキュア開発（実75〜実101）
- [docs/04-reliability.md](../../docs/04-reliability.md) — 信頼性（実102〜実105 ほか）
- [docs/08-ai-safety.md](../../docs/08-ai-safety.md) — AI 安全対策（実150〜実153）
- [docs/10-disaster-exercise.md](../../docs/10-disaster-exercise.md) — 災害訓練（実72 関連）
- [docs/11-incident-response.md](../../docs/11-incident-response.md) — インシデント対応（実59、実73-1 関連）
- [docs/12-contingency-plan.md](../../docs/12-contingency-plan.md) — コンティンジェンシープラン（実73 関連）
- [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md) — FISC基準⇄Azureサービス対応表
- [リポジトリ README](../../README.md)
