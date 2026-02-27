# ATM系システム ランディングゾーン

> ATM端末管理・ATM取引処理・提携ネットワーク接続を担うシステムのAzure設計ガイダンス

## 前提条件

- 本リファレンスアーキテクチャは、ATMスイッチ（ISO 8583 トランザクション処理）、ATM端末管理、提携ATMネットワーク接続を対象としています。勘定系との連携は [勘定系システム ランディングゾーン](core-banking.md) を参照してください。
- ATM端末自体のハードウェア設計（現金カセット、カードリーダー等）は本ドキュメントの対象外です。ATMベンダーの仕様に準拠してください。
- 本アーキテクチャは [Azure Well-Architected Framework のミッションクリティカルワークロード](https://learn.microsoft.com/azure/well-architected/mission-critical/) ガイダンスに準拠した設計としています。
- オンプレミスおよびATM端末からの接続は ExpressRoute / 専用線 / VPN による閉域網接続を前提としています。
- ATM取引には現金が伴うため、取引データの損失は許容されません（RPO = 0）。

## システム概要

| 項目 | 内容 |
|------|------|
| システム名 | ATM系システム |
| 主な機能 | 現金入出金、振込・送金、残高照会、通帳記帳、提携ATM連携、キャッシュリサイクル |
| 設置形態 | 銀行店舗内、コンビニ、駅・空港、ショッピングセンター、移動店舗車 |
| FISC外部性 | 各金融機関の判断による（提携ATMネットワーク経由の場合は外部性あり） |
| 重要度 | **Tier 2**（自行ATM）〜 **Tier 1**（提携ネットワーク接続） |
| 処理特性 | リアルタイム取引（OLTP）、24時間365日運用 |
| 可用性要件 | 99.95%以上（24x365 運用） |

## ユースケース

- **現金入出金**: ATM端末からのキャッシュカード/ICカードによる出金・入金処理。ISO 8583メッセージを受信し、PIN検証→口座残高確認→取引実行→現金払出/受入の一連のフローを低レイテンシで処理する。
- **振込・送金**: ATM端末から他行口座への振込。全銀システム（内国為替）との連携により、即時振込（モアタイムシステム対応）および通常振込を処理する。
- **残高照会・通帳記帳**: 口座残高の照会および通帳への取引明細印字。勘定系への読み取り専用アクセスとなるため、キャッシュ層を活用して勘定系への負荷を軽減する。
- **提携ATM連携（CAFIS / 統合ATM / MICS）**: コンビニATM（セブン銀行、ローソン銀行、イーネット等）および他行ATMとの相互利用。CAFIS（Credit And Finance Information Switching）、統合ATM、MICS（Multi Integrated Cash Service）等の提携ネットワークを経由して取引を中継する。
- **EMVチップカード処理**: IC チップカード（EMV規格）の認証・暗号文検証。オンライン認証（ARQC/ARPC）およびオフライン認証（SDA/DDA/CDA）を処理する。
- **キャッシュマネジメント**: ATM端末ごとの現金残高監視、現金需要予測に基づく補充計画の最適化。曜日・時間帯・イベント等のパターンを分析し、現金切れ・過剰在庫を最小化する。
- **不正取引検知**: スキミング、不正出金パターン（短時間・多拠点出金等）、カード偽造の検知。リアルタイムストリーム処理による即時ブロックとSIEMによる事後分析を組み合わせる。

## FISC基準上の位置づけ

ATM関連はFISC安全対策基準で最も多く言及されるシステムの一つです。FISC第13版では設置形態の多様化（コンビニ、駅、移動店舗車等）に対応した基準見直しが行われています。ATM端末の物理セキュリティからネットワーク接続、暗号鍵管理まで広範な基準が適用されます。

**適用される主な基準**:
- 統1〜統3: 安全対策方針・計画（基礎基準適用）
- 実1〜実19: 技術的安全対策（認証・暗号化・アクセス制御）
- 実39〜実45: バックアップ（取引データの完全性保証）
- 実71, 実73: DR・コンティンジェンシープラン
- 実107〜実110: カード管理・取引監視（ATM固有）
- 実119〜実121: ATMコーナー運用管理・防犯体制（ATM固有）
- 設113〜設138: ATM設備基準・物理セキュリティ（ATM固有）

**ATM固有のFISC基準対応**:

| FISC基準 | 要件 | Azure実装 |
|---------|------|----------|
| 実107 | カードの管理方法 | Azure Key Vault（カード暗号鍵管理）+ Payment HSM（マスターキー保管） |
| 実108 | カード取引犯罪の注意喚起 | ATM画面表示（業務運用）+ IoT Hub D2C メッセージによる端末状態監視 |
| 実109 | ICカード利用促進 | EMVカーネル処理 + Payment HSM（ARQC/ARPC検証） |
| 実110 | カード取引監視 | Stream Analytics（リアルタイム検知）+ Sentinel（SIEM相関分析） |
| 実119 | ATMコーナー運用管理 | Payment HSM（PIN検証・PIN翻訳）+ AKS 上の取引認可サービス |
| 実120 | 不正払戻し等の防止 | Stream Analytics MATCH_RECOGNIZE（連続異常パターン検知）+ 自動ブロック |
| 実121 | ATMコーナー防犯体制 | IoT Hub（監視カメラ連携・異常検知イベント転送） |
| 設113-138 | ATM設備基準 | ATMベンダー準拠（Azure側は端末管理・監視を担当） |

## アーキテクチャの特徴

### ATMスイッチ（ISO 8583 トランザクション処理）

ATMスイッチは ISO 8583 メッセージの受信・解析・ルーティング・応答を行う中核コンポーネントです。**AKS Private Cluster** 上にマイクロサービスとして実装し、以下のサービスに分離します。

| サービス | 役割 |
|---------|------|
| Gateway Service | ISO 8583 メッセージの受信・パース・レスポンス生成 |
| Authorization Service | PIN検証・口座残高確認・取引可否判定 |
| Routing Service | 自行/提携ネットワークへのメッセージルーティング |
| Settlement Service | 提携取引の精算データ生成・バッチ集計 |
| Reversal Service | タイムアウト・障害時の取消（リバーサル）処理 |

ISO 8583 メッセージ処理は **低レイテンシ**（P99 < 200ms）が求められるため、AKS ノードには **Proximity Placement Group** を適用し、Payment HSM との物理的近接性を確保します。各取引には **一意のトランザクションID**（STAN: Systems Trace Audit Number + RRN: Retrieval Reference Number）を付与し、**冪等性**を保証します。

### ATM端末管理（IoT Hub Device Twin）

数千〜数万台のATM端末を **Azure IoT Hub** で集中管理します。各ATM端末を IoT デバイスとして登録し、**Device Twin**（デバイスツイン）により端末の状態をクラウド側で一元管理します。

| Device Twin プロパティ | 用途 |
|----------------------|------|
| Reported Properties | 端末稼働状態、現金残高（金種別）、障害コード、ファームウェアバージョン |
| Desired Properties | ファームウェア更新指示、運用パラメータ変更、取引限度額設定 |
| Tags | 設置場所、端末モデル、管理グループ、メンテナンス担当 |

IoT Hub の **Device Provisioning Service (DPS)** により、新規ATM端末の自動プロビジョニング（X.509 証明書認証）を実現します。端末ファームウェアの更新は **IoT Hub Direct Method** + **Automatic Device Management** により、段階的ロールアウト（カナリアデプロイ）で安全に実施します。

> **参考**: [IoT Hub Device Twin](https://learn.microsoft.com/azure/iot-hub/iot-hub-devguide-device-twins) — デバイスのメタデータ・状態・構成の同期

### Payment HSM（PIN検証・暗号鍵管理）

ATM取引の暗号処理は **Azure Payment HSM**（Thales payShield 10K）で実行します。Payment HSM はベアメタルサービスとして顧客の VNet に直接接続され、完全な顧客管理下で運用されます。

| 暗号処理 | 説明 |
|---------|------|
| PIN検証 | ATM端末で暗号化されたPINブロックを検証（IBM 3624 / Visa PVV / ARQC） |
| PIN翻訳 | 提携ネットワーク間でのPINブロック形式変換（Zone PIN Key変換） |
| MAC生成・検証 | ISO 8583メッセージの完全性検証（MAC: Message Authentication Code） |
| EMV暗号文検証 | ICカードのオンライン認証（ARQC→ARPC応答生成） |
| Remote Key Loading | ATM端末への暗号鍵配信（TR-31 / TR-34 鍵ブロック） |
| マスターキー管理 | TMK（Terminal Master Key）、ZPK（Zone PIN Key）等の鍵階層管理 |

Payment HSM は **HA ペア構成**（2台）で配置し、1台の障害時もサービス継続します。PCI PIN / PCI DSS 準拠が必須であり、鍵管理手順は PCI PIN Security Requirements に従います。

> **参考**: [Azure Payment HSM](https://learn.microsoft.com/azure/payment-hsm/overview) — PCI PIN / PCI DSS / FIPS 140-2 Level 3 準拠

### 提携ネットワーク接続（CAFIS / 統合ATM / MICS）

日本の銀行ATMは複数の提携ネットワークを経由して他行ATMやコンビニATMと相互接続します。

| ネットワーク | 役割 | 接続方式 |
|------------|------|---------|
| CAFIS | NTTデータ運営のカード決済中継ネットワーク | ExpressRoute（専用線） |
| 統合ATM | ゆうちょ銀行・全国銀行のATM相互利用 | ExpressRoute（専用線） |
| MICS | 信用金庫・信用組合等のATM相互利用 | ExpressRoute（専用線） |
| BANCS | 都市銀行のATM相互利用ネットワーク | ExpressRoute（専用線） |
| セブン銀行/ローソン銀行 | コンビニATM提携 | ExpressRoute / VPN |

各提携ネットワークとの接続は **Hub VNet 経由の ExpressRoute** で閉域網接続します。提携ネットワークごとに **異なるZone PIN Key (ZPK)** を使用するため、Payment HSM で PIN翻訳（PIN Block 変換）を行います。

### 不正取引検知（リアルタイム + SIEM）

ATM不正取引の検知は **2層構成** で実装します。

**第1層: リアルタイム検知（Stream Analytics）**
- ISO 8583 トランザクションログを Event Hubs 経由で Stream Analytics に投入
- **MATCH_RECOGNIZE** パターンマッチングにより連続異常を即時検知
  - 同一カードの短時間・多拠点出金（Travel Rule 違反）
  - 連続PIN入力エラー後の出金成功
  - 取引限度額近接の分割出金
  - 深夜帯の異常高額出金
- 検知時は **Service Bus キュー** 経由で Authorization Service に即時ブロック指示

**第2層: SIEM相関分析（Microsoft Sentinel）**
- スキミング端末の検知（同一ATMからの連続不正パターン）
- カード偽造の広域分析（地理的に離れた同時利用）
- IoT Hub からの端末異常イベント（カードリーダー異常、筐体開放等）との相関
- ATMコーナーの監視カメラ映像と取引ログの時刻突合

> **参考**: [Stream Analytics MATCH_RECOGNIZE](https://learn.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns#advanced-pattern-matching-with-match_recognize) — ATM連続障害検知パターン

### キャッシュマネジメント（現金需要予測）

ATM端末の現金残高を IoT Hub Device Twin の Reported Properties で収集し、**現金需要予測モデル**により最適な補充計画を策定します。

| コンポーネント | 用途 |
|-------------|------|
| IoT Hub Reported Properties | 金種別現金残高のリアルタイム収集 |
| Azure Machine Learning | 現金需要予測モデル（曜日・時間帯・給与日・イベント等のパターン分析） |
| Azure SQL DB | 補充計画・実績の管理、警備会社への補充指示データ |
| Power BI | 現金残高ダッシュボード、補充効率分析、現金切れリスク可視化 |

現金切れ（Cash Out）は顧客満足度とブランドイメージに直結するため、**閾値アラート**（金種別残高 < 20%）と **予測アラート**（予測枯渇時刻 < 次回補充予定時刻）の2段階で管理します。

### ATMオフラインフォールバック（Store and Forward）

通信断時のATM端末動作として **Store and Forward** パターンを採用します。

| モード | 条件 | 許可取引 | 限度額 |
|-------|------|---------|-------|
| オンラインモード | ATMスイッチとの通信正常 | 全取引 | 通常限度額 |
| スタンドイン処理 | ATMスイッチ障害時 | 出金のみ（制限付き） | 減額限度額（例: 5万円） |
| オフラインモード | 通信完全断 | 取引停止 | — |

スタンドイン処理時は ATM端末内の **SAF（Store and Forward）キュー** に取引データを蓄積し、通信復旧時に一括送信します。復旧時の重複取引防止のため、STAN + RRN による **冪等性チェック** を ATMスイッチ側で実施します。

## アーキテクチャ図

### 全体アーキテクチャ（マルチロケーション × マルチリージョン）

```
┌──────────────────────────────────────────────────────────────┐
│  ATM端末群                                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐     │
│  │ 自行ATM   │  │ コンビニ  │  │ 提携ATM   │  │ 移動店舗  │     │
│  │ (店舗内)  │  │ ATM      │  │ (他行)    │  │ 車ATM    │     │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘     │
│       │ 専用線/VPN   │ VPN        │ 提携NW      │ LTE/VPN   │
└───────┼──────────────┼────────────┼──────────────┼───────────┘
        │              │            │              │
┌───────▼──────────────▼────────────│──────────────▼───────────┐
│  オンプレミス DC                    │                          │
│  ┌────────────────────────┐       │                          │
│  │ ATM端末集約装置          │       │                          │
│  │ (既存フロントエンド)      │       │                          │
│  └───────────┬────────────┘       │                          │
└──────────────┼────────────────────│──────────────────────────┘
               │ ExpressRoute        │
               │ (冗長2回線)          │ ExpressRoute
               │                     │ (提携ネットワーク)
┌──────────────┼─────────────────────┼─────────────────────────┐
│ Azure        │                     │                          │
│  ┌───────────▼─────────────────────▼──────────┐              │
│  │  Hub VNet (10.0.0.0/16)                     │              │
│  │  Azure Firewall Premium                     │              │
│  │  ExpressRoute Gateway (冗長)                 │              │
│  └──────┬──────────────────────┬───────────────┘              │
│         │ Peering              │ Peering                      │
│         ▼                      ▼                              │
│  ┌─────────────────────────┐  ┌──────────────────────────┐   │
│  │ 東日本リージョン (Primary)│  │ 西日本リージョン (DR)      │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ APIM (内部VNet統合)  │ │  │ │ APIM (Standby)       │ │   │
│  │ │ ISO 8583 ← → REST   │ │  │ │                      │ │   │
│  │ └──────────┬──────────┘ │  │ └──────────┬───────────┘ │   │
│  │            │             │  │            │              │   │
│  │ ┌──────────▼──────────┐ │  │ ┌──────────▼───────────┐ │   │
│  │ │ AKS Private Cluster │ │  │ │ AKS Private Cluster  │ │   │
│  │ │ (可用性ゾーン x3)    │ │  │ │ (Warm Standby)       │ │   │
│  │ │ ┌────┐ ┌────┐ ┌───┐│ │  │ │ ┌────┐ ┌────┐ ┌───┐ │ │   │
│  │ │ │GW  │ │Auth│ │Rtg││ │  │ │ │GW  │ │Auth│ │Rtg│ │ │   │
│  │ │ │Svc │ │Svc │ │Svc││ │  │ │ │Svc │ │Svc │ │Svc│ │ │   │
│  │ │ └────┘ └────┘ └───┘│ │  │ │ └────┘ └────┘ └───┘ │ │   │
│  │ │ ┌────┐ ┌────┐      │ │  │ │ ┌────┐ ┌────┐       │ │   │
│  │ │ │Stl │ │Rev │      │ │  │ │ │Stl │ │Rev │       │ │   │
│  │ │ │Svc │ │Svc │      │ │  │ │ │Svc │ │Svc │       │ │   │
│  │ │ └────┘ └────┘      │ │  │ │ └────┘ └────┘       │ │   │
│  │ └──────────┬─────────┘  │  │ └──────────┬──────────┘ │   │
│  │            │             │  │            │              │   │
│  │ ┌──────────▼──────────┐ │  │ ┌──────────▼───────────┐ │   │
│  │ │ SQL MI Bus.Critical │ │非同│ │ SQL MI               │ │   │
│  │ │ (ATM取引DB)          │ │期  │ │ (Failover Group)     │ │   │
│  │ │ (可用性ゾーン内同期)  │ │ ──▶│ │                      │ │   │
│  │ └────────────────────┘  │  │ └──────────────────────┘ │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ Cosmos DB            │ │グロ│ │ Cosmos DB            │ │   │
│  │ │ (セッション管理/      │ │ーバ│ │ (グローバル           │ │   │
│  │ │  端末状態キャッシュ)  │ │ルテ│ │  テーブル)            │ │   │
│  │ └─────────────────────┘ │ーブ│ └──────────────────────┘ │   │
│  │                         │ル  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ Payment HSM (HA)    │ │  │ │ Payment HSM (HA)     │ │   │
│  │ │ PIN検証/翻訳/EMV    │ │  │ │ (DR用ペア)            │ │   │
│  │ └─────────────────────┘ │  │ └──────────────────────┘ │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ IoT Hub (S3)        │ │  │ │ IoT Hub (S3)         │ │   │
│  │ │ ATM端末管理          │ │手動│ │ (Manual FO)          │ │   │
│  │ │ Device Twin          │ │FO │ │                      │ │   │
│  │ └─────────────────────┘ │  │ └──────────────────────┘ │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ Event Hubs Std      │ │  │ │ Event Hubs Std       │ │   │
│  │ │ (Geo-DR)            │ │  │ │ (Geo-DR Pair)        │ │   │
│  │ │ ATM取引ストリーム     │ │  │ │                      │ │   │
│  │ └──────────┬──────────┘ │  │ └──────────────────────┘ │   │
│  │            │             │  │                          │   │
│  │ ┌──────────▼──────────┐ │  │                          │   │
│  │ │ Stream Analytics    │ │  │                          │   │
│  │ │ (不正取引検知)       │ │  │                          │   │
│  │ └─────────────────────┘ │  │                          │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │ ┌──────────────────────┐ │   │
│  │ │ Key Vault (HSM)     │ │  │ │ Key Vault (HSM)      │ │   │
│  │ │ アプリ鍵管理          │ │  │ │                      │ │   │
│  │ └─────────────────────┘ │  │ └──────────────────────┘ │   │
│  │                         │  │                          │   │
│  │ ┌─────────────────────┐ │  │                          │   │
│  │ │ Microsoft Sentinel  │ │  │                          │   │
│  │ │ (不正取引SIEM)       │ │  │                          │   │
│  │ └─────────────────────┘ │  │                          │   │
│  └─────────────────────────┘  └──────────────────────────┘   │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐   │
│  │ 提携ネットワーク接続                                      │   │
│  │ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────────────┐│   │
│  │ │CAFIS │ │統合  │ │MICS  │ │BANCS │ │コンビニATM    ││   │
│  │ │      │ │ATM   │ │      │ │      │ │(セブン等)     ││   │
│  │ └──────┘ └──────┘ └──────┘ └──────┘ └──────────────┘│   │
│  │ ← ExpressRoute (各提携先専用回線) →                     │   │
│  └────────────────────────────────────────────────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

## Azureサービス構成

### コンピューティング

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| ATMスイッチ | AKS Private Cluster | Standard_D8s_v5 x 6ノード以上 | ISO 8583メッセージ処理（可用性ゾーン x3） |
| API Gateway | API Management | Premium（内部VNet統合） | ISO 8583 ↔ REST プロトコル変換・レート制限 |
| ATM端末管理 | Azure IoT Hub | S3（大規模デバイス管理） | Device Twin・DPS・ファームウェア更新 |

### データベース

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| ATM取引DB | Azure SQL MI Business Critical | 8 vCore以上、可用性ゾーン冗長 | 取引ジャーナル（ACID保証・Ledger テーブル） |
| セッション/状態管理 | Azure Cosmos DB | Session Consistency | 端末状態キャッシュ・取引セッション（グローバルテーブル） |
| 精算データ | Azure SQL DB | General Purpose | 提携取引の日次精算・手数料計算 |

### セキュリティ・暗号

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| PIN/EMV暗号処理 | Azure Payment HSM | payShield 10K HA ペア | PIN検証・PIN翻訳・MAC・ARQC/ARPC・RKL |
| アプリ鍵管理 | Azure Key Vault | Premium (HSM-backed) | TLS証明書・API鍵・暗号化鍵 |
| SIEM | Microsoft Sentinel | — | 不正取引相関分析・インシデント管理 |
| CSPM | Defender for Cloud | — | セキュリティポスチャ管理・PCI DSS準拠評価 |

### メッセージング・ストリーム処理

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| 取引ストリーム | Azure Event Hubs | Standard（Geo-DR） | ATM取引ログのリアルタイムストリーミング |
| リアルタイム検知 | Azure Stream Analytics | Standard | MATCH_RECOGNIZE による不正パターン検知 |
| コマンド/イベント | Azure Service Bus | Premium | 取引ブロック指示・端末制御コマンド |

### ネットワーク・接続

| コンポーネント | Azureサービス | SKU/構成 | 用途 |
|-------------|-------------|---------|------|
| 閉域網接続 | Azure ExpressRoute | Standard / Premium | 提携ネットワーク・オンプレDC接続 |
| ネットワーク制御 | Azure Firewall | Premium | L7フィルタリング・IDPS |
| Private DNS | Azure Private DNS Zone | — | 名前解決の閉域化 |

## 可用性・DR設計

### 目標値

| 項目 | 目標値 | 根拠 |
|------|-------|------|
| **RTO** | < 15分（AZ障害）、< 30分（リージョン障害） | ATM端末のスタンドイン処理で取引継続中に切替完了 |
| **RPO** | 0（取引データ損失不可） | 現金取引のため1件たりとも損失不可 |
| **可用性** | 99.95%以上 | 24時間365日運用 |

### 障害レベル別対応

| 障害レベル | 影響 | 対応 |
|-----------|------|------|
| 単一Pod障害 | 特定サービスの一時応答遅延 | AKS ReplicaSet による自動再起動（秒単位） |
| 可用性ゾーン障害 | 1ゾーンのAKSノード/SQL MI レプリカ喪失 | AKS ゾーン分散 + SQL MI ゾーン内自動FO（< 30秒） |
| Payment HSM 単体障害 | PIN検証処理の一時中断 | HA ペアのセカンダリへ自動切替（< 5秒） |
| IoT Hub 障害 | 端末管理一時不可（取引処理には影響なし） | 手動フェイルオーバー + 端末側キャッシュで継続 |
| リージョン障害 | プライマリリージョン全面停止 | SQL MI Failover Group + AKS DR起動 + ATM端末スタンドイン |
| 通信障害 | ATM端末とスイッチ間の通信断 | ATM端末のStore and Forward（制限付き取引継続） |

### リージョン切替自動化フロー

```
┌──────────────────────────────────────────┐
│  障害検知（東日本リージョン）                 │
│    App Insights 可用性テスト: 3拠点監視      │
│    2拠点以上で連続失敗 → アラート発火         │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Step 1: ATM端末スタンドインモード移行       │
│    → ATM端末に制限モード指示               │
│    → スタンドイン処理で出金継続（減額限度）    │
│    → 新規取引の減額限度額適用                │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Step 2: SQL MI Failover Group 切替       │
│    → 西日本がプライマリに昇格               │
│    → 取引データ損失 = 0（同期レプリケーション）│
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Step 3: AKS / APIM / Payment HSM 起動   │
│    → 西日本 AKS の Pod スケールアウト       │
│    → APIM のトラフィック切替                │
│    → Payment HSM DR ペアの有効化           │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Step 4: ATM端末の接続先切替              │
│    → DNS更新 / ルーティング変更             │
│    → ATM端末のオンラインモード復帰          │
│    → スタンドイン中のSAFキューデータ回収      │
└──────────────┬───────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────┐
│  Step 5: 正常性確認                       │
│    → PIN検証テスト取引の実行               │
│    → 提携ネットワーク接続確認               │
│    → SAFデータの重複チェック・精算           │
│    → 切替完了通知                          │
└──────────────────────────────────────────┘
```

> **設計ポイント**: ATM端末のスタンドイン処理により、リージョン切替中もエンドユーザーは（制限付きではあるが）出金を継続できます。SAFキューのデータ回収時は STAN + RRN による冪等性チェックで重複取引を防止します。

### バックアップ・ランサムウェア対策

| 項目 | 設計 |
|------|------|
| バックアップ | Azure Backup (GRS) + SQL MI PITR（最大35日） |
| 不変ボールト | Azure Backup Immutable Vault（コンプライアンスモード） |
| ボールトロック | 一度ロックされると保持期間終了までデータ削除・変更不可 |
| 長期保存 | Azure Blob Storage (RA-GRS) + 不変 (WORM) ポリシー |
| 取引ジャーナル | SQL MI Ledger テーブルによる改ざん検知（ブロックチェーンベース検証） |
| 復元テスト | 月次で別環境へのリストアテストを実施 |

> **注意**: ATM取引ジャーナルは **SQL MI Ledger テーブル** を使用し、取引データの改ざん不可能性を暗号学的に保証します。ランサムウェアによるデータ暗号化に対しては、不変バックアップからの復元に加え、Ledger テーブルのダイジェストにより改ざんの有無を検証できます。

### DR訓練

| 項目 | 内容 |
|------|------|
| 障害注入テスト | Azure Chaos Studio + Azure Load Testing による月次実施 |
| フェイルオーバー訓練 | SQL MI Failover Group の計画的フェイルオーバーを四半期毎に実施 |
| ATMスタンドイン訓練 | ATM端末のStore and Forward動作を四半期毎に訓練 |
| 訓練環境 | 本番相当のE2E検証環境で実施（本番リスク回避） |
| 負荷テスト併用 | 障害注入と負荷テストを同時実行し、障害時のシステム挙動を検証 |
| 訓練内容 | Payment HSM障害、IoT Hub障害、提携NW断、AZ障害、DB FO、通信断 |

> **参考**: [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)

## ネットワーク設計

```
Hub VNet (10.0.0.0/16) ← ExpressRoute Gateway + Azure Firewall
│
├── Peering ──▶ Spoke VNet: ATM系 東日本 (10.26.0.0/16)
│               ├── snet-apim      (10.26.0.0/24)  — API Management
│               ├── snet-app       (10.26.1.0/24)  — AKS ノード（ATMスイッチ）
│               ├── snet-db        (10.26.2.0/24)  — SQL MI サブネット（専用委任）
│               ├── snet-cosmos    (10.26.3.0/24)  — Cosmos DB Private Endpoint
│               ├── snet-phsm      (10.26.4.0/24)  — Payment HSM（専用委任）
│               ├── snet-iot       (10.26.5.0/24)  — IoT Hub Private Endpoint
│               ├── snet-msg       (10.26.6.0/24)  — Event Hubs / Service Bus PE
│               ├── snet-stream    (10.26.7.0/24)  — Stream Analytics
│               └── snet-pe        (10.26.8.0/24)  — その他 Private Endpoint
│
└── Peering ──▶ Spoke VNet: ATM系 西日本 (10.27.0.0/16)
                ├── (同一サブネット構成)
                └── ...

NSG ルール:
- インバウンド: Hub Firewall からのみ許可（ATM端末 → スイッチ）
- アウトバウンド: Hub Firewall 経由のみ（インターネット直接不可）
- Payment HSM サブネット: NSG非対応のため Firewall SNAT で制御
- サブネット間: 必要最小限のポートのみ許可
- SQL MI サブネット: SQL MI 専用の NSG ルール適用
- IoT Hub: Private Endpoint 経由のみ（パブリックエンドポイント無効化）
```

## 監視・オブザーバビリティ

### 外形監視

| 項目 | 内容 |
|------|------|
| 監視方式 | Application Insights 可用性テスト（Standard Test） |
| 監視ロケーション | 東日本、西日本、東南アジア（第三リージョン）の3拠点以上 |
| テスト内容 | ATMスイッチへの疑似 ISO 8583 メッセージ（残高照会） |
| テスト頻度 | 1分間隔 |
| アラート条件 | 2拠点以上で連続失敗時にアラート発火 |

### ATM端末フリート監視

| 監視項目 | ツール | 用途 |
|---------|-------|------|
| 端末稼働状態 | IoT Hub + Device Twin | オンライン/オフライン/障害の一元監視 |
| 現金残高 | IoT Hub Reported Properties | 金種別残高・枯渇予測 |
| ハードウェア状態 | IoT Hub D2C メッセージ | カードリーダー・紙幣搬送・レシートプリンタ・筐体開閉 |
| ファームウェア | IoT Hub Device Twin Tags | バージョン管理・更新状況追跡 |
| 端末接続性 | Event Grid + Monitor | 接続/切断イベントのリアルタイム追跡 |

> IoT Hub の **Event Grid 統合** により、端末の接続/切断イベントをリアルタイムで検知します。Device Twin クエリにより「現金残高20%以下の端末一覧」「ファームウェア未更新端末」等をフリート全体から即座に抽出できます。

### マイクロサービスのオブザーバビリティ

| コンポーネント | ツール | 用途 |
|-------------|-------|------|
| 分散トレーシング | Application Insights + OpenTelemetry | ISO 8583メッセージの処理トレース・レイテンシ分析 |
| サービスマップ | Application Insights Application Map | ATMスイッチ内サービス間依存関係の可視化 |
| メトリクス収集 | Azure Monitor + Prometheus (AKS) | TPS、レイテンシ、エラー率のリアルタイム監視 |
| ログ集約 | Log Analytics Workspace | 全コンポーネントの統合ログ分析 |
| SIEM | Microsoft Sentinel | 不正取引パターン検出・セキュリティイベント相関分析 |

> AKS 上の各 Pod にサイドカーコンテナとして OpenTelemetry Collector を配置し、アプリケーションコードの変更なしに分散トレーシングを実現します。ISO 8583 メッセージの処理フロー（受信→PIN検証→口座照会→応答）を一気通貫で追跡できます。

### アラート

| 監視項目 | ツール | アラート条件 |
|---------|-------|------------|
| ATMスイッチ応答時間 | Application Insights | P99 > 200ms |
| PIN検証応答時間 | Application Insights | P99 > 100ms（Payment HSM レイテンシ） |
| DB CPU使用率 | Azure Monitor | > 80% |
| DB レプリケーションラグ | Azure Monitor | > 1秒 |
| ATM端末オフライン数 | IoT Hub Metrics | オフライン端末 > 閾値（端末数の5%） |
| 現金残高低下 | IoT Hub + Logic Apps | 金種別残高 < 20% |
| 不正取引検知 | Stream Analytics | MATCH_RECOGNIZE パターン一致 |
| フェイルオーバーイベント | Azure SQL MI 診断ログ | FO発生時即時通知 |
| Payment HSM 稼働状態 | Azure Monitor | HA ペアの片系障害検知 |
| 外形監視失敗 | Application Insights | 2拠点以上で連続失敗 |
| 異常取引パターン | Microsoft Sentinel | カスタム検出ルール（スキミング・カード偽造） |

## デプロイ・IaC

| 項目 | 内容 |
|------|------|
| IaC | Bicep / Terraform によるインフラストラクチャ定義 |
| CI/CD | Azure DevOps Pipelines または GitHub Actions |
| 環境戦略 | 開発 → ステージング → 本番（プロモーション方式） |
| テスト統合 | CI/CD パイプラインに Azure Load Testing + Chaos Studio を統合 |
| コンテナイメージ | Azure Container Registry (Premium, Geo-Replication) |
| GitOps | AKS + Flux v2 による宣言的デプロイ |
| Payment HSM | Thales payShield Manager による構成管理（IaC対象外） |
| ATMファームウェア | IoT Hub Automatic Device Management による段階的展開 |

## 関連リソース

- [Azure Well-Architected Framework: Mission-Critical Workloads](https://learn.microsoft.com/azure/well-architected/mission-critical/)
- [Azure Payment HSM Overview](https://learn.microsoft.com/azure/payment-hsm/overview)
- [Azure Payment HSM: Security best practices](https://learn.microsoft.com/azure/payment-hsm/secure-payment-hsm)
- [Azure Payment HSM: Certification and compliance (PCI PIN/DSS/3DS)](https://learn.microsoft.com/azure/payment-hsm/certification-compliance)
- [Azure IoT Hub: Device Twin](https://learn.microsoft.com/azure/iot-hub/iot-hub-devguide-device-twins)
- [Azure IoT Hub: Device Provisioning Service](https://learn.microsoft.com/azure/iot-dps/)
- [Azure IoT Hub: Device management overview](https://learn.microsoft.com/azure/iot-hub/iot-hub-device-management-overview)
- [Stream Analytics: MATCH_RECOGNIZE pattern matching](https://learn.microsoft.com/azure/stream-analytics/stream-analytics-stream-analytics-query-patterns)
- [Stream Analytics: Real-time fraud detection tutorial](https://learn.microsoft.com/azure/stream-analytics/stream-analytics-real-time-fraud-detection)
- [Azure SQL MI: Failover groups](https://learn.microsoft.com/azure/azure-sql/managed-instance/failover-group-sql-mi)
- [Azure SQL MI: Ledger tables](https://learn.microsoft.com/azure/azure-sql/database/ledger-overview)
- [Continuous validation with Azure Load Testing and Azure Chaos Studio](https://learn.microsoft.com/azure/architecture/guide/testing/mission-critical-deployment-testing)
- [Application Insights availability tests](https://learn.microsoft.com/azure/azure-monitor/app/availability)
