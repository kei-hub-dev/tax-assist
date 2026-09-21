# サービス概要
## 青色申告向け帳簿作成用のWebアプリ
 - 本アプリは、青色申告で必要となる以下の書類を作成します。
    - 帳簿 (仕訳帳と総勘定元帳)
    - 決算書 (損益計算書・貸借対照表)
 - 入出金を元に複式簿記(借方/貸方)で記録をします。  
 ※当方は税理士ではありません。  
 本アプリを利用して作成された書類については、必ずご自身の責任で確認を行ってください。  
 また必要に応じて専門家へご相談ください。

## ユーザー層について
会社員や法人以外の小規模向けの個人事業主・フリーランス向け。

## サービスの利用イメージ
リポジトリをクローンし、コンテナを立ち上げてWebアプリケーションを起動し利用する。

## セットアップ
Docker が動作する環境（macOS / Linux いずれも可）で以下を実行します。

```sh
cp .env.example .env     # 中身は空のままでも起動します
docker compose up
```

起動後 http://localhost:3000 にアクセスしてください。
`.env` に値を入れるのは Google 認証やメール送信を試す場合のみです。

## 機能候補
 - MVPリリース
   - 認証機能(devise)
   - ファイルのエクスポート
 - 本リリース対応予定
   - Google認証
   - AI実装(LLM構築後に実装予定)
   - オートコンプリート

## コードレビュー
PR を作成すると GitHub Actions 上で Gemini がコードレビューを行い、指摘を PR に投稿します。
[google-github-actions/run-gemini-cli](https://github.com/google-github-actions/run-gemini-cli) と
[code-review 拡張](https://github.com/gemini-cli-extensions/code-review) を使用しています。

### 必要な設定
リポジトリのシークレットに `GEMINI_API_KEY` を登録してください。
キーは [Google AI Studio](https://aistudio.google.com/apikey) で発行できます。

### 構成
| ファイル | 役割 |
| --- | --- |
| `.github/workflows/gemini-review.yml` | ワークフロー本体 |
| `.gemini/styleguide.md` | このリポジトリ固有のレビュー観点。ワークフローが読み込み `ADDITIONAL_CONTEXT` として渡す |

### 実行される契機
- PR を作成したとき（`opened`）
- PR を再オープンしたとき（`reopened`）
- Actions タブから手動実行したとき（`workflow_dispatch`。PR 番号を指定）

push のたびには実行されません。
途中でもう一度レビューさせたい場合は、PR を Close → Reopen するか手動実行してください。

### モデル
既定は `gemini-3.8-flash` です（Flash 系は無料枠の対象）。
リポジトリ変数 `GEMINI_MODEL` を設定すると上書きできます。

## Google認証設定
- 環境変数 `GOOGLE_CLIENT_ID` と `GOOGLE_CLIENT_SECRET` を設定

### ER図
[画面例](images/ER.png)
