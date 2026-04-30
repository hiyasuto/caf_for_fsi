---
title: FISC安全対策基準 第13版 — 設備基準 索引
type: fisc-reference
status: draft
tags: [fisc, facility-standards, infrastructure, datacenter]
updated: 2026-04-30
---

# FISC安全対策基準 第13版 — 設備基準 (設x) 索引

> **出典・著作権**: 「金融機関等コンピュータシステムの安全対策基準・解説書（第13版）」は公益財団法人 FISC が著作権を保有する有償刊行物です。本ページは章番号・基準番号と本リポジトリ内のAzure対応分析を索引化したもので、FISC原文の転載ではありません。正式な基準内容は[FISC原本](https://www.fisc.or.jp/)を参照してください。

## このページの位置づけ

- 設備基準は建物・電源・空調・通信設備・営業店・ATM等のデータセンターおよび物理セキュリティに関する基準（**全134項目**）。
- Azure 利用時、データセンター関連の設備要件の多くは **Microsoft 側責任** としてマネージドデータセンターで充足される（責任共有モデル）。
- 営業店・ATM等の **顧客拠点に関する設備基準** は引き続き顧客責任。
- 関連: [Azure コンプライアンス（FISC Japan）](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)

## 責任共有モデルにおける設備基準

| 領域 | 責任 | 説明 |
|---|---|---|
| データセンター建物（耐震・防火・防水・立地） | Microsoft | 物理層 / SOC 2 Type II・ISO 27001 等の第三者認証で充足 |
| 不法侵入防止（多層物理セキュリティ） | Microsoft | 物理層 |
| 電源・空調・UPS（冗長構成） | Microsoft | 物理層 |
| ネットワーク敷設・通信回線 | Microsoft | 物理回線 |
| 顧客側オンプレ接続機器（ExpressRoute / VPN ルーター等） | 顧客 | エッジ機器の設置・運用 |
| 営業店設備 | 顧客 | 顧客拠点 |
| ATM 関連設備 | 顧客 | 顧客拠点 |

## 基準別 索引（mapping から抽出）

> 本リポジトリでは設備基準を **領域単位** で扱っています。基準番号順の個別解説は対象外（Microsoft 側責任が中心のため）。下記は [`mapping/fisc-to-azure-services.md`](../../mapping/fisc-to-azure-services.md) からの抽出です。

### 設1: データセンター立地
- **概要**: 災害・障害が発生しやすい地域を避けた立地選定。
- **Azure対応**: Microsoft 側責任。Azure 日本リージョン（東日本・西日本）は地理的リスク分散を考慮して設計。
- **関連**: → [docs/04-reliability.md](../../docs/04-reliability.md)（マルチリージョン設計）

### 設2〜設14: 建物構造（耐震・防火・防水等）
- **概要**: データセンター建物の物理的堅牢性に関する要件群。
- **Azure対応**: Microsoft 側責任（マネージド対応）。SOC 2 Type II / ISO 27001 等の第三者認証で充足。
- **関連**: [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)

### 設15〜設16: 不法侵入防止
- **概要**: 物理的な不正侵入対策。
- **Azure対応**: Microsoft 側責任。生体認証・カードキー・常時監視等の多層物理セキュリティ。

### 設20〜設40: 電源・空調・UPS
- **概要**: 電源設備・空調・無停電電源装置等の冗長構成。
- **Azure対応**: Microsoft 側責任。冗長電源・冷却システム・自家発電。

### 設50〜設70: 通信設備
- **概要**: 通信回線・通信機器の要件。
- **Azure対応**: Microsoft 側責任（DC 内ネットワーク）。顧客側は ExpressRoute / VPN Gateway の冗長構成で対応。
- **関連**: → [docs/03-security.md](../../docs/03-security.md)（ネットワーク設計）

### 設80〜設100: 営業店の安全対策
- **概要**: 金融機関営業店舗の物理セキュリティ。
- **Azure対応**: 顧客責任（オンプレミス／拠点設備）。Azure スコープ外。

### 設110〜設138: ATM 関連
- **概要**: ATM の物理・運用セキュリティ。
- **Azure対応**: 顧客責任（オンプレミス設備）。Azure スコープ外。

## 未網羅範囲

- 設備基準は全 **134 項目** ありますが、本リポジトリでは Azure 利用時に Microsoft 側責任で充足される領域が大半のため、**個別基準番号単位の解説は未網羅** です。
- 設17〜設19、設41〜設49、設71〜設79、設101〜設109 など、上記領域区分に明示されない番号帯の個別項目は本リポジトリでは未網羅。詳細は FISC 原本を参照してください。
- 顧客責任領域（営業店・ATM）の個別 Azure 対応分析も本リポジトリ対象外。

## 関連リンク

- [安対基準 README](./README.md)
- [mapping/fisc-to-azure-services.md](../../mapping/fisc-to-azure-services.md)
- [Azure コンプライアンス（FISC Japan）](https://learn.microsoft.com/compliance/regulatory/offering-fisc-japan)
- [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Azure コンプライアンスドキュメント](https://learn.microsoft.com/azure/compliance/)
