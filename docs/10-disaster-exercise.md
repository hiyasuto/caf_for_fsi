# 10 — 障害シナリオと演習

> FISC実務基準（実72）＋ 統制基準（統5-4）→ Azure WAF Reliability Testing (RE:08)

## 概要

本ドキュメントは、パブリッククラウドサービスに起因する障害シナリオの策定および演習の実施に関するガイダンスです。FISC安全対策基準（第13版）の要件を、Azure WAF の **Reliability Testing Strategy（RE:08）** に基づいて実現します。本ドキュメントは「**どうテストするか**」に焦点を当てています。

> **関連ドキュメント**
> - バックアップ・DR アーキテクチャの設計 → [04. 信頼性・事業継続](04-reliability.md)
> - インシデント発生時の対応手順 → [11. インシデント対応計画](11-incident-response.md)
> - コンティンジェンシープランの策定・更新 → [12. コンティンジェンシープラン](12-contingency-plan.md)

### 対応 FISC 基準

| 基準番号 | 基準名 | 本ドキュメントの対応箇所 |
|---------|--------|----------------------|
| 統5-4 | サイバーセキュリティに関する演習・訓練 | セクション 2, 3 |
| 実72 | 障害時の復旧テスト | セクション 2, 3 |

---

## 1. 障害シナリオの策定

FISC基準では、想定以上に深刻で起こり得るシナリオを具体的に設定することが求められています。以下に、パブリッククラウドサービスに起因する障害シナリオを、Azure の障害モデルに基づいて体系化します。

### 1.1 クラウドインフラストラクチャ障害シナリオ

| # | シナリオ | 影響範囲 | 深刻度 | Azure 障害モデル |
|---|---------|---------|--------|-----------------|
| S-01 | 単一可用性ゾーン障害 | 1ゾーン内の全リソース | 高 | データセンター電源/冷却/ネットワーク障害 |
| S-02 | リージョン全体障害 | 東日本リージョン全体 | 最高 | 広域自然災害・大規模インフラ障害 |
| S-03 | リージョンペア同時障害 | 東日本＋西日本 | 壊滅的 | 国家規模の災害・同時多発障害 |
| S-04 | Azure AD（Entra ID）障害 | 全認証・認可機能 | 最高 | IDプラットフォーム全体停止 |
| S-05 | Azure DNS 障害 | 名前解決依存の全サービス | 最高 | グローバル DNS インフラ障害 |
| S-06 | ExpressRoute 障害 | オンプレミス ⇔ Azure 間通信 | 高 | 専用回線の物理障害・ルーティング障害 |

### 1.2 プラットフォームサービス障害シナリオ

| # | シナリオ | 影響範囲 | 深刻度 | 想定される業務影響 |
|---|---------|---------|--------|------------------|
| S-07 | Azure SQL Database サービス停止 | トランザクション処理全般 | 最高 | 勘定系・決済系の処理停止 |
| S-08 | Azure Key Vault 障害 | 暗号鍵・シークレット取得不能 | 最高 | 暗号化データへのアクセス不能 |
| S-09 | Azure Storage 障害 | Blob/Queue/Table/File | 高 | データ参照不能・非同期処理停止 |
| S-10 | Azure Kubernetes Service 障害 | コンテナワークロード | 高 | マイクロサービス群の停止 |
| S-11 | Azure Monitor / Log Analytics 障害 | 監視・ログ収集 | 中 | 障害検知遅延・監査ログ欠損 |
| S-12 | Microsoft Defender for Cloud 障害 | セキュリティ監視 | 中 | 脅威検知の一時停止 |

### 1.3 サイバー攻撃起因の障害シナリオ

| # | シナリオ | 攻撃手法 | 深刻度 | 想定される業務影響 |
|---|---------|---------|--------|------------------|
| S-13 | ランサムウェアによるデータ暗号化 | マルウェア感染 | 最高 | 業務データ・バックアップの利用不能 |
| S-14 | DDoS 攻撃による大規模サービス停止 | 大量トラフィック攻撃 | 高 | インターネットバンキング停止 |
| S-15 | サプライチェーン攻撃 | 依存ライブラリ・サービスの侵害 | 最高 | 広範なシステム侵害 |
| S-16 | 特権アカウントの侵害 | 認証情報の窃取 | 最高 | テナント全体の制御奪取 |
| S-17 | データ漏えい（内部犯行含む） | 内部者による不正アクセス | 最高 | 顧客情報の流出・規制対応 |

### 1.4 複合障害シナリオ

金融庁ガイドラインでは「想定以上に深刻なもので、起こり得るシナリオ」の設定が求められています。以下は複数の障害が連鎖する複合シナリオです。

| # | シナリオ | 構成要素 | 深刻度 |
|---|---------|---------|--------|
| S-18 | 自然災害 ＋ リージョン障害 ＋ 通信途絶 | 南海トラフ地震 → 東日本リージョン停止 → ExpressRoute 断 | 壊滅的 |
| S-19 | サイバー攻撃 ＋ バックアップ破壊 | ランサムウェア → 不変バックアップ以外のデータ暗号化 → DR サイト汚染 | 壊滅的 |
| S-20 | CSP 障害 ＋ 代替手段不能 | Azure AD 全体停止 → Break Glass アカウントでの緊急対応 → 復旧長期化 | 壊滅的 |
| S-21 | 複数金融機関同時被災 | 共通基盤（Azure リージョン）障害 → 同一リージョン利用の複数行が同時に影響 | 壊滅的 |

### 1.5 シナリオ策定の方法論

```
┌─────────────────────────────────────────────────────────┐
│              障害シナリオ策定プロセス                       │
│                                                         │
│  ① 重要業務の特定                                        │
│  │  └─ オペレーショナル・レジリエンスにおける              │
│  │     「重要な業務」の洗い出しと許容停止時間の設定         │
│  ▼                                                      │
│  ② Azure 依存関係の分析                                  │
│  │  └─ Azure Resource Graph / Service Map による          │
│  │     リソース依存関係の可視化                            │
│  ▼                                                      │
│  ③ 障害モードの特定                                      │
│  │  └─ FMEA（Failure Mode and Effects Analysis）         │
│  │     各コンポーネントの障害モードと影響を分析             │
│  ▼                                                      │
│  ④ シナリオの具体化                                      │
│  │  └─ 発生確率 × 影響度でリスク評価                      │
│  │     深刻度に応じて演習対象シナリオを選定                │
│  ▼                                                      │
│  ⑤ 定期的な見直し                                       │
│     └─ Azure の新サービス・アーキテクチャ変更、            │
│        脅威情報の変化に応じてシナリオを更新                │
└─────────────────────────────────────────────────────────┘
```

#### Azure による依存関係分析

| 対策 | Azureサービス | 説明 |
|------|-------------|------|
| リソース依存関係 | Azure Resource Graph | KQL によるリソース横断クエリ・依存関係分析 |
| アプリ依存関係 | Application Insights（アプリケーションマップ） | マイクロサービス間の依存関係可視化 |
| ネットワーク依存 | Azure Network Watcher（トポロジ） | ネットワーク構成の可視化・接続検証 |
| サービス正常性 | Azure Service Health | Azure サービスの稼働状況・計画メンテナンス |
| リスク評価 | Microsoft Defender for Cloud（セキュアスコア） | セキュリティリスクの定量評価 |

---

## 2. 演習の体系

Azure WAF Reliability Maturity Model に基づく3段階の演習体系を、FISC基準の要件に対応付けます。

### 演習レベルの定義

| レベル | 演習種別 | 内容 | リスク | 対応 FISC 基準 | 実施頻度（推奨） |
|-------|---------|------|-------|---------------|----------------|
| **L1** | 机上演習（Tabletop Exercise） | ホワイトボード/会議室での手順ウォークスルー | なし | 統5-4, 実72 | 四半期ごと |
| **L2** | 非本番実機演習（Non-Prod Drill） | ステージング環境でのフェイルオーバー・復旧テスト | 低 | 実72, 実73 | 半期ごと |
| **L3** | 本番カオスエンジニアリング（Production Chaos） | 本番環境への制御された障害注入 | 中〜高 | 実72, 実73-1 | 年次 |

```
                        信頼度
                          ▲
     L3: 本番カオス       │  ████████████████
         エンジニアリング  │
                          │
     L2: 非本番           │  ██████████
         実機演習          │
                          │
     L1: 机上演習         │  █████
                          │
                          └──────────────────► リスク
```

---

## 3. 演習の実施

### 3.1 L1: 机上演習（Tabletop Exercise）

金融機関とクラウドサービス事業者（Microsoft）がともに実施する机上演習の設計・実施ガイダンスです。

#### 演習設計

| 要素 | 内容 |
|------|------|
| **目的** | 障害シナリオに対する対応手順・意思決定フローの確認 |
| **参加者** | IT運用チーム、リスク管理部門、経営層、Microsoft TAM/CSA（必要に応じて） |
| **時間** | 2〜4時間 |
| **シナリオ** | セクション1のシナリオから選定（深刻度「高」以上を推奨） |
| **成果物** | 演習記録、課題一覧、改善アクション、プラン更新箇所の特定 |

#### 演習シナリオ例: リージョン障害（S-02）

```
時刻        イベント                            参加者アクション
──────────────────────────────────────────────────────────────
T+0:00     Azure Service Health にて            監視チーム:
           東日本リージョン障害検知              アラート受領・初動確認

T+0:15     影響範囲の確認                       運用チーム:
           ・勘定系: 影響あり                   BCP 発動判断
           ・決済系: 影響あり                   ・重要度判定
           ・IB:    影響あり                    ・エスカレーション

T+0:30     DR サイト（西日本）への               DR チーム:
           フェイルオーバー判断                  ・ASR フェイルオーバー起動
                                                ・DNS 切替
                                                ・DB フェイルオーバー

T+1:00     部分復旧・縮退運転開始               経営層:
                                                ・対外公表判断
                                                ・顧客影響の評価
                                                ・規制当局への報告判断

T+2:00     全面復旧                             運用チーム:
                                                ・データ整合性確認
                                                ・残存リスクの評価

T+4:00     演習振り返り                         全参加者:
                                                ・課題の洗い出し
                                                ・改善アクションの策定
```

#### 複数金融機関による共同演習

FISC基準では、同一のパブリッククラウドサービスを利用する複数の金融機関が共同で演習を実施することの有効性が示されています。

| 要素 | 内容 |
|------|------|
| **目的** | クラウド集中リスクの実態把握、共通課題の特定 |
| **参加者** | 同一リージョン利用の複数金融機関、Microsoft |
| **シナリオ** | S-21（複数金融機関同時被災）等の共通影響シナリオ |
| **情報共有** | 機密情報を除く障害対応体制・切替手順の相互確認 |
| **成果物** | 業界共通のベストプラクティス、共通課題の改善提言 |

> **参考**: Microsoft は [Service Trust Portal](https://servicetrust.microsoft.com/viewpage/BCPDR) にて四半期ごとの **BCDR Plan Validation Report** を公開しています。共同演習の前提情報として活用できます。

### 3.2 L2: 非本番実機演習（Non-Production Drill）

ステージング環境で実際のフェイルオーバー・復旧手順を実行する演習です。

#### Azure を活用した非本番演習

| 演習項目 | Azureサービス | 内容 |
|---------|-------------|------|
| DR フェイルオーバー | Azure Site Recovery テストフェイルオーバー | 本番影響なしの隔離ネットワークでの DR 切替検証 |
| DB フェイルオーバー | SQL MI Failover Group 強制フェイルオーバー | データベースのリージョン間切替検証 |
| バックアップリストア | Azure Backup 復元テスト | バックアップデータの復元検証・整合性確認 |
| ネットワーク切替 | Azure Front Door / Traffic Manager | トラフィックルーティングの切替検証 |
| 障害注入 | Azure Chaos Studio（非本番） | CPU/メモリ/ネットワーク障害の注入テスト |
| 認証障害 | Entra ID Conditional Access テスト | Break Glass アカウントによる緊急アクセスの検証 |

#### 演習手順テンプレート

```
事前準備
├── ① 演習環境の構築（本番同等のステージング環境）
│   └── IaC（Bicep/Terraform）による自動構築
├── ② 演習シナリオの確定・周知
├── ③ 成功基準の定義（RTO/RPO 目標達成等）
└── ④ ロールバック手順の確認

演習実施
├── ⑤ 障害注入 / フェイルオーバー実行
├── ⑥ 復旧手順の実行・時間計測
├── ⑦ データ整合性の検証
└── ⑧ 縮退運転の確認

事後対応
├── ⑨ 演習結果の記録（RTO/RPO 実績値）
├── ⑩ 課題の洗い出しと改善アクション策定
└── ⑪ コンティンジェンシープランの更新
```

### 3.3 L3: 本番カオスエンジニアリング（Production Chaos）

Azure Chaos Studio を活用した本番環境での制御された障害注入テストです。

#### Azure Chaos Studio による障害注入実験

| 障害タイプ | Chaos Studio フォールト | 対象リソース | 検証内容 |
|-----------|----------------------|-------------|---------|
| コンピュート障害 | VM シャットダウン | Azure VM | 自動フェイルオーバーの動作確認 |
| CPU 負荷 | CPU Pressure | VM / VMSS | オートスケールの動作確認 |
| メモリ負荷 | Physical Memory Pressure | VM / VMSS | メモリ逼迫時の挙動確認 |
| ネットワーク遅延 | Network Latency | AKS Pod | レイテンシー増加時のタイムアウト処理 |
| ネットワーク切断 | Network Disconnect | NSG | ネットワーク分断時のフェイルオーバー |
| DNS 障害 | DNS Failure | DNS Zone | DNS 障害時の代替名前解決 |
| Key Vault 障害 | Disable/Increment Certificate | Key Vault | 証明書障害時のアプリ挙動 |
| Entra ID 障害 | Entra ID Outage（NSG ルール） | NSG | 認証サービス停止時の緊急対応 |

#### 実験設計の原則（Azure WAF RE:08 準拠）

1. **仮説の設定** — 各実験に明確なゴールを定義（例：「AZ1 停止時に AZ2 へ 5 分以内に自動フェイルオーバーすること」）
2. **ベースライン測定** — 正常時のメトリクスを記録し、障害時との比較基準とする
3. **ブラストラディウスの制限** — SLA バッファ内で実験を実施し、エラーバジェットを超えない
4. **安全装置** — 実験の緊急停止条件を事前定義（Azure Chaos Studio のキャンセル機能）
5. **結果の文書化** — 発見事項・改善アクションをバックログに記録

#### カオスエンジニアリング成熟度モデル

```
成熟度    実施内容                                     前提条件
─────────────────────────────────────────────────────────────
Level 1   非本番環境での単一障害注入                   基本的な監視・アラート設定済み
Level 2   非本番環境での複合障害注入                   DR 計画策定済み
Level 3   本番環境での単一障害注入（営業時間外）        Level 2 で問題なし確認済み
Level 4   本番環境での単一障害注入（営業時間中）        Level 3 で問題なし確認済み
Level 5   本番環境での複合障害注入・Game Day           Level 4 で問題なし確認済み
```

### 3.4 CSP との共同演習

Microsoft との共同演習を実施する際の枠組みです。

| 演習タイプ | Microsoft 側参加者 | 内容 |
|-----------|-------------------|------|
| インシデント対応訓練 | TAM / CSA / CSAM | Azure サービス障害時の連携フロー確認 |
| セキュリティインシデント訓練 | Microsoft DART | サイバー攻撃時の初動対応・フォレンジック連携 |
| DR 訓練 | FastTrack Engineer | ASR / DB フェイルオーバーの技術的検証 |
| Azure Incident Readiness | Microsoft Support | [Azure Incident Readiness プログラム](https://learn.microsoft.com/training/technical-support/intro-to-azure-incident-readiness/) の活用 |

> **参考**: Microsoft は [Azure Incident Readiness Training](https://learn.microsoft.com/services-hub/unified/health/incident-readiness) を提供しています。

---

## 4. 年間演習計画（推奨）

| 四半期 | 演習種別 | 対象シナリオ | 参加者 |
|-------|---------|------------|--------|
| Q1 | L1: 机上演習 | S-02 リージョン障害 | IT運用 + リスク管理 + 経営層 |
| Q2 | L2: 非本番実機演習 | S-07 DB 障害 + S-06 ExpressRoute 障害 | IT運用 + DR チーム |
| Q3 | L1: 机上演習（サイバー） | S-13 ランサムウェア + S-16 特権侵害 | IT運用 + CSIRT + 経営層 |
| Q4 | L3: 本番カオスエンジニアリング | S-01 可用性ゾーン障害 | IT運用 + SRE チーム |
| 年次 | CSP 共同演習 | S-21 複数金融機関同時被災 | 複数金融機関 + Microsoft |

---

## 5. 障害時の情報の取扱い

FISC基準では、演習を通じて「障害時の情報の取扱いに関する実態を把握する」ことが求められています。

### 5.1 情報取扱いの確認ポイント

| 確認項目 | 内容 | Azure 機能 |
|---------|------|-----------|
| 障害情報の通知 | Azure → 金融機関への障害通知経路・タイムライン | Azure Service Health / Resource Health |
| 影響範囲の情報 | 障害の影響を受けるリソース・サービスの特定 | Azure Resource Health / Service Map |
| 根本原因分析（RCA） | 障害後の RCA レポートの提供タイムライン | Azure Service Health（PIR: Post-Incident Review） |
| 顧客データの保護 | 障害時のデータ整合性・機密性の確保 | Azure Backup 整合性検証 / 暗号化 |
| 規制当局への報告 | 障害情報を規制当局へ報告する際の情報整理 | Azure Monitor Workbooks（レポート生成） |
| CSP のインシデント対応 | Microsoft 側のインシデント対応体制・SLA | [Microsoft Incident Response](https://learn.microsoft.com/security/operations/incident-response-overview) |

### 5.2 情報共有の枠組み

```
                    ┌─────────────┐
                    │  金融庁等    │
                    │  規制当局    │
                    └──────┬──────┘
                           │ 報告
                    ┌──────▼──────┐
                    │  金融機関    │
                    │  (CSIRT等)  │
                    └──┬───┬───┬──┘
           ┌───────────┘   │   └───────────┐
    ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
    │  Microsoft  │ │ 他の金融機関 │ │ 金融ISAC等  │
    │  (TAM/DART) │ │ (共同演習)   │ │ (情報共有)  │
    └─────────────┘ └─────────────┘ └─────────────┘
```

---

## 参考リンク

### Azure ドキュメント

- [Azure Well-Architected Framework — Reliability Testing Strategy (RE:08)](https://learn.microsoft.com/azure/well-architected/reliability/testing-strategy)
- [Azure Well-Architected Framework — Reliability Maturity Model](https://learn.microsoft.com/azure/well-architected/reliability/maturity-model)
- [Azure Chaos Studio](https://learn.microsoft.com/azure/chaos-studio/chaos-studio-overview)
- [Azure Site Recovery — テストフェイルオーバー](https://learn.microsoft.com/azure/site-recovery/site-recovery-test-failover-to-azure)
- [Azure Incident Readiness Training](https://learn.microsoft.com/training/technical-support/intro-to-azure-incident-readiness/)
- [Microsoft Service Trust Portal — BCDR](https://servicetrust.microsoft.com/viewpage/BCPDR)

### Microsoft 金融サービス向けガイダンス

- [Strengthening Operational Resilience in Financial Services](https://learn.microsoft.com/compliance/assurance/assurance-fsi-resilience)
- [Microsoft Cloud for Financial Services](https://learn.microsoft.com/industry/financial-services/)

### 規制・業界標準

- [FISC安全対策基準・解説書（第13版）](https://www.fisc.or.jp/)
- [FISCコンティンジェンシープラン策定手引書（第5版）](https://www.fisc.or.jp/)
- [金融庁「オペレーショナル・レジリエンス確保に向けた基本的な考え方」](https://www.fsa.go.jp/)

---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [04. 信頼性・事業継続](04-reliability.md) | バックアップ・DR アーキテクチャ設計 |
| → | [11. インシデント対応計画](11-incident-response.md) | インシデント発生時の対応手順 |
| → | [12. コンティンジェンシープラン](12-contingency-plan.md) | コンティンジェンシープランの策定・更新 |
| → | [サイバーレジリエンス ランディングゾーン](../landing-zone/cyber-resilience.md) | サイバー攻撃からの防御・検知・復旧の詳細設計 |

---

*本ドキュメントは FISC安全対策基準・解説書 第13版（2025年3月）および Azure Well-Architected Framework Reliability Testing Strategy (RE:08) に基づいています。*
