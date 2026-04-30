---
title: FISC安全対策基準 第13版 — 統制基準 索引
type: fisc-reference
status: draft
tags: [fisc, control-standards, governance]
updated: 2026-04-30
---

# FISC安全対策基準 第13版 — 統制基準 (統x) 索引

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 金融情報システムセンター (FISC) が著作権を保有する有償刊行物です。本ページは公開されている章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。正式な基準内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## このページの位置づけ

- **入り口**: FISC文書の目次（基準番号順）から該当箇所のAzure対応を引きたいときに使用するインデックス
- **Azure側の詳細解説**: 本リポジトリ `docs/02-governance.md`（統制基準全般）および `docs/07-cloud-governance.md`（クラウド観点）を参照
- **基準→Azureサービス マッピング全表**: [`mapping/fisc-to-azure-services.md`](../../mapping/fisc-to-azure-services.md)
- **凡例**: 🆕 = 第13版新設、 ✏️ = 第13版改定

## 統制基準 全体構造（統1〜統28）

統制基準は、金融機関等の経営層・管理者が果たすべきITガバナンス・ITマネジメントに関する基準群です。第13版ではサイバーセキュリティ・サプライチェーン関連の枝番基準（統1-x、統4-x、統5-x、統28）が新設されました。

### グループ別 索引

| グループ | 基準番号 | 主題 | 主な参照先 |
|---|---|---|---|
| 1. 方針・計画 | 統1〜統3（含 統1-1, 統1-2） | 安全対策規程・サイバーセキュリティ基本方針・中長期システム計画 | [docs/02-governance.md §1](../../docs/02-governance.md#1-方針計画統1統3) |
| 2. 組織体制 | 統4〜統19（含 統4-1/2, 統5-1〜5-5） | セキュリティ管理体制・リスク管理・要員管理 | [docs/02-governance.md §2](../../docs/02-governance.md#2-組織体制統4統19) |
| 3. 外部委託管理 | 統20〜統23 | 委託先選定・契約・再委託・遂行状況確認 | [docs/02-governance.md §3](../../docs/02-governance.md#3-外部委託管理統20統23) / [docs/07-cloud-governance.md §2](../../docs/07-cloud-governance.md#2-外部委託管理統20統23) |
| 4. クラウド固有 | 統24 | クラウドサービス固有のリスク対策・責任共有・データ所在地 | [docs/07-cloud-governance.md §1](../../docs/07-cloud-governance.md#1-統24-クラウドサービス固有の安全対策) |
| 5. FinTech等連携 | 統25〜統27 | FinTech連携の安全対策・サービス安全性確認・利用者保護 | [docs/02-governance.md §4](../../docs/02-governance.md#4-fintech等連携管理統25統27) |
| 6. サプライチェーン | 統28 | サプライチェーンを考慮したサイバーセキュリティリスク管理 | [docs/07-cloud-governance.md §3](../../docs/07-cloud-governance.md#3-サプライチェーンセキュリティ統28) |

## 基準別 索引

### 1. 方針・計画（統1〜統3）

#### 統1 ✏️: 安全対策に係る規程の整備
- **概要**: システムの安全対策に係る重要事項を定めた規程を整備することを求める基準。
- **Azure対応**: Azure Policy / Microsoft Defender for Cloud / Management Groups → [docs/02-governance.md §統1](../../docs/02-governance.md#統1-安全対策に係る規程の整備)
- **関連**: [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)

#### 統1-1 🆕: サイバーセキュリティ基本方針の整備
- **概要**: サイバーセキュリティ対策に関する基本方針の整備を求める第13版新設基準。
- **Azure対応**: Microsoft Defender for Cloud（CSPM）/ Microsoft Sentinel → [docs/02-governance.md §統1-1](../../docs/02-governance.md)

#### 統1-2 🆕: サイバーセキュリティ規程・業務プロセスの整備
- **概要**: サイバーセキュリティ対策に関する規程等および業務プロセスの整備を求める第13版新設基準。
- **Azure対応**: Azure DevOps / GitHub / Microsoft Purview → [docs/02-governance.md §統1-2](../../docs/02-governance.md)

#### 統2 ✏️: 中長期的システム計画の策定
- **概要**: 中長期的視点に立ったシステムの企画・開発・運用に関する計画策定を求める基準。
- **Azure対応**: Azure CAF / Azure Migrate / Azure Advisor → [docs/02-governance.md §統2](../../docs/02-governance.md)

#### 統3 ✏️: システム開発計画の整合性確認・承認
- **概要**: システム開発計画と中長期システム計画との整合性確認および承認取得を求める基準。
- **Azure対応**: Azure DevOps Boards / Azure Policy → [docs/02-governance.md §統3](../../docs/02-governance.md)

### 2. 組織体制（統4〜統19）

#### 統4 ✏️: セキュリティ管理体制の整備
- **概要**: セキュリティを管理するための体制整備を求める基準。
- **Azure対応**: Microsoft Entra ID（RBAC）/ Microsoft Entra PIM / Defender for Cloud → [docs/02-governance.md §統4](../../docs/02-governance.md#統4-セキュリティ管理体制の整備)

#### 統4-1 🆕: サイバーセキュリティ経営資源・人材計画
- **概要**: サイバーセキュリティ管理に必要な経営資源および人材計画の策定を求める第13版新設基準。
- **Azure対応**: Defender for Cloud（セキュアスコア）/ Microsoft Learn / Entra ID Governance → [docs/02-governance.md §統4-1](../../docs/02-governance.md)

#### 統4-2 🆕: サイバーセキュリティ管理態勢の監視・牽制
- **概要**: サイバーセキュリティ管理態勢の継続的な監視・牽制を求める第13版新設基準。
- **Azure対応**: Defender for Cloud / Microsoft Sentinel / Azure Monitor / Activity Log → [docs/02-governance.md §統4-2](../../docs/02-governance.md)

#### 統5: （欠番）
- **概要**: 第13版で枝番（統5-1〜統5-5）に再編されたため本番号は欠番。

#### 統5-1 🆕: 情報資産の適切な管理
- **概要**: サイバーセキュリティリスク特定の前提となる情報資産管理を求める第13版新設基準。
- **Azure対応**: Microsoft Purview（カタログ・分類）/ Defender for Cloud（資産インベントリ） → [docs/02-governance.md §統5-1](../../docs/02-governance.md)

#### 統5-2 🆕: リスクの特定・評価・対応計画
- **概要**: サイバーセキュリティリスクの特定・評価・対応計画策定を求める第13版新設基準。
- **Azure対応**: Defender for Cloud（脆弱性評価）/ Microsoft Defender 脅威インテリジェンス → [docs/02-governance.md §統5-2](../../docs/02-governance.md)

#### 統5-3 🆕: 脆弱性管理手続き
- **概要**: ハードウェア・ソフトウェア等の脆弱性管理手続き整備を求める第13版新設基準。
- **Azure対応**: Microsoft Defender 脆弱性管理 / Azure Update Manager → [docs/02-governance.md §統5-3](../../docs/02-governance.md)

#### 統5-4 🆕: 演習・訓練
- **概要**: サイバーセキュリティに関する演習・訓練の実施を求める第13版新設基準。
- **Azure対応**: Attack Simulation Training / Azure Chaos Studio / Microsoft Sentinel → [docs/02-governance.md §統5-4](../../docs/02-governance.md)

#### 統5-5 🆕: 教育・研修
- **概要**: サイバーセキュリティに係る教育・研修の実施を求める第13版新設基準。
- **Azure対応**: Microsoft Learn Security / Security Awareness Training → [docs/02-governance.md §統5-5](../../docs/02-governance.md)

#### 統6: システム管理体制
- **概要**: システム全般の管理体制整備を求める基準。
- **Azure対応**: Azure Management Groups / Azure RBAC → [docs/02-governance.md §統6統19](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統7 ✏️: データ管理体制
- **概要**: データの取扱い・分類・保護に関する管理体制整備を求める基準。
- **Azure対応**: Microsoft Purview / Azure Data Catalog → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統8: ネットワーク管理体制
- **概要**: ネットワークの管理体制整備を求める基準。
- **Azure対応**: Azure Network Watcher / Azure Firewall Manager → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統9: 業務組織の整備
- **概要**: 業務遂行のための組織整備を求める基準。
- **Azure対応**: Microsoft Entra ID（組織構造のモデリング） → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統10: 安全管理組織の整備
- **概要**: 安全管理を担う組織整備を求める基準。
- **Azure対応**: Microsoft Defender for Cloud（セキュリティチーム向けダッシュボード） → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統11 ✏️: 防犯組織の整備
- **概要**: 物理的な防犯組織整備を求める基準（Azureデータセンター側で対応される領域を含む）。
- **Azure対応**: Azure データセンターの物理セキュリティ → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統12 ✏️: 各種業務規則の整備
- **概要**: 各種業務に関する規則整備を求める基準。
- **Azure対応**: Azure Policy / Microsoft Compliance Manager → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統13 ✏️: セキュリティ遵守状況の確認
- **概要**: セキュリティ規程等の遵守状況の確認を求める基準。
- **Azure対応**: Defender for Cloud（規制コンプライアンス ダッシュボード） → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統14: システム運用計画の策定
- **概要**: システム運用に関する計画策定を求める基準。
- **Azure対応**: Azure Monitor / Azure Automation / Azure Advisor → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統15: セキュリティ要件の明確化
- **概要**: システム導入・変更時のセキュリティ要件明確化を求める基準。
- **Azure対応**: Azure Policy / Microsoft Defender for Cloud → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統16: 情報セキュリティ教育・研修
- **概要**: 情報セキュリティに関する教育・研修の実施を求める基準。
- **Azure対応**: Microsoft Learn / Security Awareness Training → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統17: 要員管理
- **概要**: 要員のアクセス権ライフサイクル等の管理を求める基準。
- **Azure対応**: Microsoft Entra ID Governance（ライフサイクル管理） → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統18: 業務委託時のセキュリティ
- **概要**: 業務委託時にセキュリティに関する事項を明確にすることを求める基準。
- **Azure対応**: Microsoft Service Trust Portal / Azure SLA → [docs/02-governance.md](../../docs/02-governance.md#統6統19-その他の組織体制)

#### 統19 ✏️: 要員の健康管理
- **概要**: 要員の健康管理を求める基準（組織管理事項のためAzureサービス対象外）。
- **Azure対応**: — （組織管理事項）

### 3. 外部委託管理（統20〜統23）

#### 統20 ✏️: 外部委託の目的・範囲・選定手続き
- **概要**: 外部委託の目的・範囲明確化と委託先選定手続きを求める基準。
- **Azure対応**: Azure 第三者認証（SOC, ISO, PCI DSS等）/ Service Trust Portal / Azure SLA → [docs/02-governance.md §統20](../../docs/02-governance.md#統20-外部委託の目的範囲選定手続き) / [docs/07-cloud-governance.md §2](../../docs/07-cloud-governance.md#2-外部委託管理統20統23)

#### 統21 ✏️: 安全対策に関する契約
- **概要**: 委託先と安全対策事項を含む契約を締結することを求める基準。
- **Azure対応**: Microsoft Product Terms / DPA / Azure データ所在地保証 → [docs/02-governance.md §統21](../../docs/02-governance.md#統21-安全対策に関する契約)

#### 統22: 外部委託先の再委託管理
- **概要**: 委託先による再委託の管理を求める基準。
- **Azure対応**: Microsoft サブプロセッサーリスト / DPA / Service Trust Portal → [docs/02-governance.md §統22](../../docs/02-governance.md#統22-外部委託先の再委託管理)

#### 統23 ✏️: 外部委託管理体制と遂行状況確認
- **概要**: 外部委託の管理体制整備と遂行状況の確認を求める基準。
- **Azure対応**: Azure Service Health / Azure Monitor / Defender for Cloud → [docs/02-governance.md §統23](../../docs/02-governance.md#統23-外部委託管理体制と遂行状況確認)

### 4. クラウドサービス固有のリスク対策（統24）

#### 統24 ✏️: クラウドサービス固有の安全対策
- **概要**: クラウドサービス利用時の固有リスク（責任共有、データ所在地、データ分離、可用性、監査権限、ベンダーロックイン等）を考慮した安全対策を求める基準。
- **Azure対応**: 責任共有モデル / 日本リージョン / 顧客管理キー（CMK）/ Confidential Computing / Private Link / Azure Policy → [docs/07-cloud-governance.md §1](../../docs/07-cloud-governance.md#1-統24-クラウドサービス固有の安全対策)
- **関連**: [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)

### 5. FinTech等連携管理（統25〜統27）

#### 統25: FinTech企業等との連携に係る安全対策
- **概要**: FinTech企業等との連携時の安全対策を求める基準。
- **Azure対応**: Azure API Management / Microsoft Entra External ID / Azure Front Door WAF → [docs/02-governance.md §統25](../../docs/02-governance.md#統25-fintech企業等との連携に係る安全対策)

#### 統26: FinTech企業等が提供するサービスの安全性確認
- **概要**: FinTech企業等が提供するサービスの安全性確認を求める基準。
- **Azure対応**: Microsoft Defender for Cloud Apps / Azure Policy → [docs/02-governance.md §統26](../../docs/02-governance.md#統26-fintech企業等が提供するサービスの安全性確認)

#### 統27: FinTech企業等との関係における利用者保護
- **概要**: FinTech連携における利用者保護策を求める基準。
- **Azure対応**: Azure Front Door WAF / API Management（レート制限・認証）/ Microsoft Sentinel → [docs/02-governance.md §統27](../../docs/02-governance.md#統27-fintech企業等との関係における利用者保護)

### 6. サプライチェーンセキュリティ（統28）

#### 統28 🆕: サプライチェーンを考慮したサイバーセキュリティリスク管理
- **概要**: サプライチェーン全体を視野に入れたサイバーセキュリティリスク管理を求める第13版新設基準。
- **Azure対応**: GitHub Advanced Security（SBOM・依存関係スキャン）/ Defender for Cloud CSPM / Microsoft Secure Score / Entra ID + Conditional Access → [docs/07-cloud-governance.md §3](../../docs/07-cloud-governance.md#3-サプライチェーンセキュリティ統28)

## 関連リンク

- [安対基準 README](./README.md)
- [docs/02-governance.md](../../docs/02-governance.md) — 統制基準のAzure対応詳細
- [docs/07-cloud-governance.md](../../docs/07-cloud-governance.md) — クラウド観点（統24, 統28）詳細
- [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md) — 全基準→Azureサービス マッピング表
- [FISC公式サイト](https://www.fisc.or.jp/) — 原本入手先
