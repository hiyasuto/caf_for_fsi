# 11 — インシデント対応計画

> FISC実務基準（実73-1, 実59）＋ 統制基準（統5-4）→ Azure WAF Incident Management (OE:08)

## 概要

本ドキュメントは、パブリッククラウドサービス上で発生する障害・サイバーインシデントに対する対応計画を定義します。FISC安全対策基準（第13版）の実73-1（サイバー攻撃想定のインシデント対応計画）および実59（障害の記録・報告）の要件を、Azure WAF の **Incident Management Plan（OE:08）** に基づいて実現します。

> **関連ドキュメント**: 障害シナリオの策定と演習の実施方法は [10. 障害シナリオと演習](10-disaster-exercise.md) を、コンティンジェンシープランの全体設計は [12. コンティンジェンシープラン](12-contingency-plan.md) を参照してください。

### 対応 FISC 基準

| 基準番号 | 基準名 | 本ドキュメントの対応箇所 |
|---------|--------|----------------------|
| 実73-1 | サイバー攻撃想定のインシデント対応計画 | セクション 1〜6 |
| 実59 | 障害の記録及び報告 | セクション 5 |
| 統5-4 | サイバーセキュリティに関する演習・訓練 | セクション 6 |
| 実14-1 | サイバー攻撃の端緒検知のための監視・分析 | セクション 2 |

---

## 1. インシデント対応体制

### 1.1 対応組織の定義

| 役割 | 責務 | 平常時の所属 |
|------|------|-------------|
| **インシデントコマンダー** | 全体指揮・意思決定・経営層への報告 | IT統括部門長 / CISO |
| **インシデントマネージャー** | 技術対応の指揮・タスク割当・進捗管理 | 運用管理部門 |
| **オンコールエンジニア** | 初動対応・障害切り分け・緩和策の実行 | SRE / インフラチーム |
| **CSIRT メンバー** | サイバーインシデントの調査・封じ込め | セキュリティ部門 |
| **コミュニケーションリード** | 対外通知・顧客対応・規制当局報告 | 広報 / コンプライアンス |
| **フォレンジック担当** | デジタル証拠の保全・分析 | セキュリティ部門 |

### 1.2 エスカレーションフロー

```
                    ┌──────────────┐
                    │  Azure 障害   │
                    │ Service Health│
                    └──────┬───────┘
                           │ 検知
                    ┌──────▼───────┐
                    │  監視チーム    │ ← Azure Monitor / Sentinel アラート
                    │ (24/365)     │
                    └──┬───────────┘
                       │ 重大度判定
              ┌────────┼────────┐
              ▼        ▼        ▼
         ┌────────┐┌────────┐┌────────┐
         │ Low    ││ Medium ││ High/  │
         │ 記録のみ││ 運用チーム││ Critical│
         └────────┘└────────┘└───┬────┘
                                 │ エスカレーション
                          ┌──────▼───────┐
                          │ インシデント    │
                          │ コマンダー     │
                          └──┬────┬───┬──┘
                 ┌───────────┘    │   └──────────┐
                 ▼                ▼               ▼
          ┌────────────┐  ┌────────────┐  ┌────────────┐
          │ 技術対応チーム│  │ CSIRT      │  │ 経営層/     │
          │ (復旧)      │  │ (封じ込め)  │  │ 規制当局報告│
          └────────────┘  └────────────┘  └────────────┘
```

### 1.3 Azure によるエスカレーション自動化

| 機能 | Azureサービス | 説明 |
|------|-------------|------|
| アラートルーティング | Azure Monitor アクショングループ | 重大度に応じた通知先の自動振り分け |
| 段階的エスカレーション | Azure Monitor アラート処理ルール | 未応答時の自動エスカレーション |
| オンコール管理 | Azure Monitor + PagerDuty/ServiceNow 連携 | オンコールスケジュールに基づく自動通知 |
| インシデント作成 | Microsoft Sentinel 自動化ルール | セキュリティアラートからのインシデント自動生成 |

---

## 2. インシデント分類

### 2.1 重大度レベルの定義

| 重大度 | 分類 | 影響基準 | 対応体制 | 初動目標 | 通知先 |
|-------|------|---------|---------|---------|--------|
| **Critical (Sev1)** | 重要業務の全面停止 | 複数の重要業務停止、顧客影響甚大 | 全チーム緊急招集 | 15分以内 | 経営層、金融庁、顧客 |
| **High (Sev2)** | 重要業務の一部停止 | 特定業務の停止、縮退運転可能 | インシデントマネージャー＋関連チーム | 30分以内 | 経営層、顧客 |
| **Medium (Sev3)** | 業務影響軽微 | パフォーマンス低下、代替手段あり | 運用チーム | 2時間以内 | IT管理者 |
| **Low (Sev4)** | 業務影響なし | 一時的エラー、自動回復 | 監視チーム | 翌営業日 | 記録のみ |

### 2.2 インシデントタイプの分類

| タイプ | 説明 | 対応フロー | Azure 検知ツール |
|-------|------|-----------|-----------------|
| **運用障害** | インフラ障害、アプリケーション障害、パフォーマンス劣化 | 標準対応フロー | Azure Monitor / Resource Health |
| **セキュリティインシデント** | 不正アクセス、マルウェア、データ漏えい | CSIRT 対応フロー | Microsoft Sentinel / Defender XDR |
| **データインシデント** | データ破損、誤削除、整合性不整合 | データ復旧フロー | Azure Backup / PITR アラート |
| **サードパーティ障害** | Azure サービス障害、外部接続障害 | CSP 連携フロー | Azure Service Health |
| **デプロイメント障害** | デプロイ失敗、構成変更起因の障害 | ロールバックフロー | Azure DevOps / Monitor（変更分析） |

---

## 3. インシデント対応プロセス

### 3.1 対応フェーズ概要

```
┌──────────────────────────────────────────────────────────────────┐
│                  インシデント対応プロセス                           │
│                                                                  │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌──────────┐  │
│  │  検知   │→│ トリ   │→│  封じ  │→│  復旧  │→│   事後   │  │
│  │ Detect │  │ アージ  │  │  込め  │  │Recover│  │  レビュー │  │
│  │        │  │ Triage │  │Contain│  │       │  │Retrospect│  │
│  └────────┘  └────────┘  └────────┘  └────────┘  └──────────┘  │
│                                                                  │
│  ◄──── 証拠保全（全フェーズを通じて実施）────────────────────►    │
│  ◄──── コミュニケーション（全フェーズを通じて実施）────────────►   │
│  ◄──── 自動化（Sentinel Playbook / Logic Apps）────────────►    │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 フェーズ別 詳細手順

#### Phase 1: 検知（Detect）

| 手順 | 内容 | Azure 実装 | FISC 対応 |
|------|------|-----------|----------|
| 1-1 | アラート受領・確認 | Azure Monitor アラート / Sentinel インシデント | 実14-1 |
| 1-2 | 影響範囲の初期確認 | Azure Resource Health / Service Health | 実59 |
| 1-3 | 重大度の初期判定 | Sentinel インシデント重大度 / カスタムルール | 実73-1 |
| 1-4 | インシデントチケット起票 | Sentinel インシデント / ServiceNow 連携 | 実59 |

**Azure Monitor アラート設計**:

| アラート種別 | 条件例 | アクション |
|------------|-------|-----------|
| メトリクスアラート | CPU > 95% 持続5分 | オンコール通知 |
| ログアラート | エラーログ > 100件/分 | 運用チーム通知 |
| Service Health アラート | Azure サービス障害 | 全チーム通知 |
| Sentinel アラート | 疑わしいサインイン検出 | CSIRT 通知 + 自動調査起動 |
| Smart Detection | 異常なレスポンスタイム | アプリチーム通知 |

#### Phase 2: トリアージ（Triage）

| 手順 | 内容 | Azure 実装 |
|------|------|-----------|
| 2-1 | 影響を受けるシステム・業務の特定 | Application Insights（アプリケーションマップ） |
| 2-2 | 顧客影響の範囲・規模の確認 | Azure Monitor Workbooks（影響分析ダッシュボード） |
| 2-3 | 重大度の確定・エスカレーション判断 | Sentinel インシデント（重大度更新） |
| 2-4 | 対応チームの招集・Bridge 構成 | Microsoft Teams（インシデントチャネル自動作成） |
| 2-5 | 初期仮説の設定と調査方針の決定 | Log Analytics（KQL クエリ）/ 変更分析 |

#### Phase 3: 封じ込め（Contain）

| 手順 | 内容 | Azure 実装 |
|------|------|-----------|
| 3-1 | 影響範囲の隔離 | NSG / Azure Firewall ルール変更 |
| 3-2 | 不正アクセスの遮断 | Entra ID Conditional Access / ユーザー無効化 |
| 3-3 | 感染拡大の防止 | Microsoft Defender for Endpoint（デバイス隔離） |
| 3-4 | 証拠保全の開始 | Azure Disk Snapshot / Immutable Storage |
| 3-5 | 縮退運転への切替判断 | Azure Front Door / Traffic Manager（ルーティング変更） |

**Sentinel Playbook による自動封じ込め例**:

```
トリガー: Sentinel アラート「ランサムウェア検出」
    │
    ├─→ ① 感染VMのネットワーク隔離（NSG Deny All）
    ├─→ ② 感染アカウントの無効化（Entra ID）
    ├─→ ③ ディスクスナップショット取得（証拠保全）
    ├─→ ④ インシデントチケット起票（ServiceNow）
    ├─→ ⑤ Teams チャネルに通知
    └─→ ⑥ 関連バックアップの整合性確認開始
```

#### Phase 4: 復旧（Recover）

| 手順 | 内容 | Azure 実装 |
|------|------|-----------|
| 4-1 | 復旧戦略の選択 | ロールバック / フェイルオーバー / リストア / 再構築 |
| 4-2 | DR サイトへのフェイルオーバー | Azure Site Recovery |
| 4-3 | データの復元 | Azure Backup（PITR） |
| 4-4 | アプリケーションのロールバック | Azure Pipelines（前バージョンデプロイ） |
| 4-5 | データ整合性の検証 | Azure Automation Runbook（自動検証） |
| 4-6 | サービス正常性の確認 | Azure Monitor / Application Insights |
| 4-7 | 縮退運転からの全面復旧 | Traffic Manager / Front Door（ルーティング復元） |

**復旧戦略の選択基準**:

| 障害タイプ | 第一選択 | 第二選択 | Azure ツール |
|-----------|---------|---------|-------------|
| デプロイ起因 | ロールバック | Blue-Green 切替 | Azure Pipelines |
| データ破損 | PITR（ポイントインタイムリストア） | バックアップリストア | Azure SQL / Backup |
| リージョン障害 | フェイルオーバー | マニュアル再構築 | ASR / Failover Group |
| ランサムウェア | 不変バックアップからリストア | クリーン環境に再構築 | Immutable Vault |
| 構成変更起因 | 構成ロールバック（IaC） | 前バージョンデプロイ | Bicep / Terraform |

#### Phase 5: 事後レビュー（Retrospective）

| 手順 | 内容 | Azure 実装 |
|------|------|-----------|
| 5-1 | ブレームレス振り返りの実施 | Microsoft Teams（会議録画・文字起こし） |
| 5-2 | 根本原因分析（RCA） | Azure Monitor（変更分析）/ Log Analytics |
| 5-3 | タイムラインの作成 | Sentinel インシデント（タイムライン表示） |
| 5-4 | 改善アクションの策定 | Azure DevOps Work Items |
| 5-5 | インシデント報告書の作成 | SharePoint / Azure DevOps Wiki |
| 5-6 | プラン・手順書の更新 | → [12. コンティンジェンシープラン](12-contingency-plan.md) |

---

## 4. サイバーインシデント対応（実73-1）

FISC第13版で新設された実73-1に対応する、サイバー攻撃特有のインシデント対応手順です。

### 4.1 サイバーインシデント対応の Azure ツールチェーン

```
┌─────────────────────────────────────────────────────────────┐
│            サイバーインシデント対応 ツールチェーン              │
│                                                             │
│  検知・分析                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │ Defender XDR   │  │ Sentinel       │  │ Defender for │  │
│  │ 統合脅威検知    │  │ SIEM/SOAR      │  │ Cloud        │  │
│  │ ・Endpoint     │  │ ・KQL分析       │  │ ・CSPM       │  │
│  │ ・Identity     │  │ ・自動調査      │  │ ・CWPP       │  │
│  │ ・Cloud Apps   │  │ ・Playbook     │  │ ・脆弱性管理  │  │
│  │ ・Office 365   │  │ ・Workbook     │  │              │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│                                                             │
│  封じ込め・復旧                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │ Entra ID       │  │ NSG / Firewall │  │ Azure Backup │  │
│  │ ・CA ポリシー   │  │ ・ネットワーク  │  │ ・不変ボールト│  │
│  │ ・ユーザー無効化│  │   隔離         │  │ ・PITR       │  │
│  │ ・PIM 緊急昇格  │  │ ・トラフィック  │  │ ・クロスリー  │  │
│  │                │  │   遮断         │  │   ジョン復元  │  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
│                                                             │
│  証拠保全・フォレンジック                                     │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────┐  │
│  │ Disk Snapshot  │  │ Immutable      │  │ Log Analytics│  │
│  │ ・VM ディスク   │  │ Storage        │  │ ・730日保持  │  │
│  │   スナップショット│  │ ・WORM ポリシー │  │ ・KQL 分析   │  │
│  │ ・メモリダンプ   │  │ ・改ざん防止    │  │ ・エクスポート│  │
│  └────────────────┘  └────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### 4.2 攻撃タイプ別 対応プレイブック

#### ランサムウェア対応

| フェーズ | 対応内容 | Azure ツール |
|---------|---------|-------------|
| 検知 | 暗号化挙動の検知、ファイル変更の異常検知 | Defender for Endpoint / Sentinel |
| 封じ込め | 感染端末のネットワーク隔離、横展開の防止 | NSG Deny All / Defender デバイス隔離 |
| 調査 | 感染経路・影響範囲の特定 | Sentinel（エンティティ調査）/ Defender XDR |
| 復旧 | 不変バックアップからのリストア、クリーン環境の構築 | Immutable Vault / IaC による再構築 |
| 事後 | 脆弱性の修正、防御策の強化 | Defender for Cloud 推奨事項 |

#### 不正アクセス・アカウント侵害対応

| フェーズ | 対応内容 | Azure ツール |
|---------|---------|-------------|
| 検知 | 異常なサインイン、不可能な移動の検出 | Entra ID Protection / Defender for Identity |
| 封じ込め | アカウント無効化、セッション失効、MFA リセット | Entra ID / Conditional Access |
| 調査 | アクセスログ分析、操作履歴の確認 | Entra ID サインインログ / Activity Log |
| 復旧 | アカウント復旧、アクセス権限のレビュー | Entra ID / PIM |
| 事後 | パスワードポリシー強化、MFA 強制拡大 | Entra ID セキュリティ設定 |

#### DDoS 攻撃対応

| フェーズ | 対応内容 | Azure ツール |
|---------|---------|-------------|
| 検知 | 異常トラフィックの検出、帯域使用率の急増 | Azure DDoS Protection / Network Watcher |
| 封じ込め | DDoS 緩和策の自動適用、WAF ルール強化 | DDoS Protection Standard / Front Door WAF |
| 調査 | 攻撃元・攻撃パターンの分析 | DDoS 攻撃分析レポート / Flow Logs |
| 復旧 | サービス正常化の確認、縮退解除 | Azure Monitor / Application Insights |
| 事後 | 防御閾値の調整、CDN キャパシティの見直し | DDoS Protection 設定 / Front Door |

### 4.3 Microsoft DART との連携

Microsoft Detection and Response Team（DART）との連携体制を事前に確立します。

| 項目 | 内容 |
|------|------|
| **契約** | Microsoft Unified Support で DART サービスを契約 |
| **連絡窓口** | TAM / CSAM を通じた DART へのエスカレーションパス |
| **事前準備** | DART が調査に必要な権限・アクセスの事前定義 |
| **情報共有** | NDA に基づく脅威情報・IoC（Indicators of Compromise）の共有 |
| **共同調査** | DART と CSIRT の共同フォレンジック調査の枠組み |

---

## 5. 障害の記録・報告（実59）

### 5.1 インシデント記録の要件

| 記録項目 | 内容 | Azure データソース |
|---------|------|-------------------|
| インシデント ID | 一意の識別子 | Sentinel インシデント ID |
| 発生日時 | 検知日時・実際の発生日時 | Azure Monitor アラートタイムスタンプ |
| 重大度 | Sev1〜Sev4 | Sentinel インシデント重大度 |
| 影響範囲 | 影響を受けたシステム・業務・顧客数 | Resource Health / Application Insights |
| 根本原因 | 障害の原因分析結果 | RCA レポート / 変更分析 |
| 対応履歴 | 各フェーズのタイムラインと実施内容 | Sentinel インシデントタイムライン |
| 復旧時間 | 実績 RTO・RPO | Azure Monitor メトリクス |
| 改善アクション | 再発防止策 | Azure DevOps Work Items |

### 5.2 報告フロー

| 報告先 | 報告基準 | 報告タイミング | 報告内容 |
|-------|---------|--------------|---------|
| **社内（経営層）** | Sev1/Sev2 | 発生後1時間以内（第一報） | 概要・影響・対応状況 |
| **金融庁** | 重大な障害 | 所定の期限内 | 所定様式による報告 |
| **顧客** | サービス影響あり | 影響確認後速やかに | 影響範囲・復旧見込み |
| **社内（IT部門）** | Sev1〜Sev3 | 復旧後5営業日以内 | 詳細 RCA レポート |

### 5.3 Azure によるレポート自動生成

| レポート | Azure ツール | 内容 |
|---------|-------------|------|
| インシデントダッシュボード | Azure Monitor Workbooks | リアルタイムのインシデント状況 |
| 月次障害レポート | Log Analytics + Workbooks | 月間のインシデント統計・傾向分析 |
| SLA 達成状況 | Azure Monitor SLI/SLO | 可用性 SLA の達成率 |
| RCA レポート | Azure Service Health PIR | Azure 起因障害の根本原因分析 |

---

## 6. Break Glass 手順

Azure AD（Entra ID）障害時や特権アカウント侵害時の緊急アクセス手順です。

### 6.1 Break Glass アカウントの設計

| 設計要素 | 推奨構成 |
|---------|---------|
| **アカウント数** | 最低2つ（異なる認証方法） |
| **認証方式** | FIDO2 セキュリティキー（クラウド MFA に依存しない） |
| **ロール** | グローバル管理者（Entra ID）+ サブスクリプション所有者 |
| **PIM 対象** | 対象外（常時有効） |
| **条件付きアクセス** | 除外（ただし使用時のアラート設定） |
| **パスワード** | 長い複雑なパスフレーズ、分割保管（金庫等） |

### 6.2 Break Glass 手順の管理

| 管理項目 | 内容 | 頻度 |
|---------|------|------|
| 動作確認テスト | サインイン・管理操作の検証 | 四半期ごと |
| パスワード変更 | 定期的なローテーション | 半期ごと |
| 使用ログ監視 | Sentinel アラートによる即時検知 | 常時（自動） |
| 手順書更新 | オフライン手順書の最新化 | 変更時 |
| 保管場所の確認 | 物理的な保管場所の定期点検 | 四半期ごと |

### 6.3 Break Glass 使用条件

```
Break Glass アカウントの使用条件:

① Entra ID の大規模障害により通常の管理者認証が不能
② 全ての特権アカウントが侵害され、通常のアクセス経路が使用不能
③ Conditional Access ポリシーの設定誤りにより全管理者がロックアウト
④ MFA プロバイダーの障害により多要素認証が不能

使用時の必須手順:
  1. インシデントコマンダーの承認を取得
  2. 使用開始をインシデントログに記録
  3. 必要な操作のみを実施（最小権限原則）
  4. 使用終了後、パスワードを即時変更
  5. 使用中の全操作をレビュー・記録
```

---

## 7. フォレンジック・証拠保全

### 7.1 証拠保全の原則

| 原則 | 内容 | Azure 実装 |
|------|------|-----------|
| **完全性** | 証拠の改ざん・消失を防止 | Immutable Storage（WORM ポリシー） |
| **証拠の連鎖** | 証拠の取得・保管・移転の記録 | Activity Log + Storage アクセスログ |
| **最小侵襲** | 調査が証拠を変更しないこと | Read-Only スナップショット + 隔離環境での分析 |
| **適時性** | 証拠の揮発性を考慮した迅速な保全 | 自動スナップショット（Sentinel Playbook） |

### 7.2 証拠保全の手順

| 手順 | 内容 | Azure ツール |
|------|------|-------------|
| ディスク保全 | 対象 VM のディスクスナップショット取得 | Azure Managed Disk Snapshot |
| メモリ保全 | メモリダンプの取得（可能な場合） | Azure VM Run Command |
| ログ保全 | 関連ログのエクスポート・長期保存 | Log Analytics エクスポート → Immutable Storage |
| ネットワーク保全 | パケットキャプチャの取得 | Network Watcher パケットキャプチャ |
| 隔離環境構築 | フォレンジック分析用の隔離サブスクリプション | 専用サブスクリプション + NSG 隔離 |
| 分析実施 | ディスクイメージのマウント・分析 | 隔離環境の VM にディスクをアタッチ |

> **詳細**: フォレンジック基盤の詳細設計は [サイバーレジリエンス ランディングゾーン](../landing-zone/cyber-resilience.md) を参照してください。

---

## 8. CSP（Microsoft）との連携

### 8.1 障害時の情報取得

| 情報 | 取得元 | タイミング |
|------|-------|-----------|
| Azure サービス障害通知 | Azure Service Health | リアルタイム（アラート） |
| 障害影響範囲 | Azure Resource Health | リアルタイム |
| 根本原因分析（PIR） | Azure Service Health — PIR レポート | 障害復旧後72時間以内 |
| BCDR レポート | [Service Trust Portal](https://servicetrust.microsoft.com/viewpage/BCPDR) | 四半期ごと |
| セキュリティインシデント通知 | Microsoft Defender for Cloud | リアルタイム |

### 8.2 Microsoft との連携体制

| 連携チャネル | 対象 | 用途 |
|------------|------|------|
| TAM / CSAM | 通常のサポート | 障害時のエスカレーション、情報収集 |
| Premier / Unified Support | 重大障害 | Sev A ケースの起票・対応 |
| Microsoft DART | サイバーインシデント | フォレンジック・インシデント対応支援 |
| Azure Engineering | プラットフォーム障害 | CSP 側の根本原因調査への参画 |

---

## 参考リンク

### Azure ドキュメント

- [Azure Well-Architected Framework — Incident Management Plan](https://learn.microsoft.com/azure/well-architected/design-guides/incident-management)
- [Azure Well-Architected Framework — Incident Response Strategy (OE:08)](https://learn.microsoft.com/azure/well-architected/operational-excellence/incident-response)
- [Microsoft Sentinel — インシデント管理](https://learn.microsoft.com/azure/sentinel/incident-investigation)
- [Microsoft Defender XDR — 自動調査と対応](https://learn.microsoft.com/defender-xdr/m365d-autoir)
- [Azure Monitor — アラートの概要](https://learn.microsoft.com/azure/azure-monitor/alerts/alerts-overview)
- [Entra ID — 緊急アクセスアカウント](https://learn.microsoft.com/entra/identity/role-based-access-control/security-emergency-access)
- [Azure Incident Readiness Training](https://learn.microsoft.com/training/technical-support/intro-to-azure-incident-readiness/)
- [Microsoft Incident Response](https://learn.microsoft.com/security/operations/incident-response-overview)

### Microsoft 金融サービス向けガイダンス

- [Strengthening Operational Resilience in Financial Services](https://learn.microsoft.com/compliance/assurance/assurance-fsi-resilience)
- [Microsoft Cloud Security Benchmark — Incident Response](https://learn.microsoft.com/security/benchmark/azure/mcsb-incident-response)

### 規制・業界標準

- [FISC安全対策基準・解説書（第13版）](https://www.fisc.or.jp/)
- [金融庁「金融分野におけるサイバーセキュリティに関するガイドライン」](https://www.fsa.go.jp/)
- [NIST SP 800-61 Rev.2 — Computer Security Incident Handling Guide](https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf)

---

## 次のステップ

| # | 次のドキュメント | 概要 |
|---|----------------|------|
| → | [10. 障害シナリオと演習](10-disaster-exercise.md) | 障害シナリオの策定と演習の実施 |
| → | [12. コンティンジェンシープラン](12-contingency-plan.md) | コンティンジェンシープランの策定・更新 |
| → | [サイバーレジリエンス ランディングゾーン](../landing-zone/cyber-resilience.md) | 自動隔離・フォレンジック基盤の詳細設計 |
| → | [05. 運用管理](05-operations.md) | 障害記録・報告の運用プロセス |

---

*本ドキュメントは FISC安全対策基準・解説書 第13版（2025年3月）および Azure Well-Architected Framework Incident Management (OE:08) に基づいています。*
