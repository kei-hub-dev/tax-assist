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

## AI による仕訳提案
摘要から借方・貸方の勘定科目を提案します。推論には [Ollama](https://ollama.com/) を使います。
接続先は自由に指定でき、同じマシン・LAN 内の別マシン・リモートのサーバのいずれでも構いません。

### 準備
1. Ollama を用意する（手元で動かす場合は [インストール](https://ollama.com/) して起動）
2. モデルを取得する（既定のモデルは約 17GB）
   ```sh
   ollama pull qwen3.8:27b-q4_K_M
   ```
3. `.env` に接続先を設定する
   ```sh
   # 同じマシンの Ollama に繋ぐ場合 (Docker Desktop for Mac / Windows)
   OLLAMA_URL=http://host.docker.internal:11434

   # LAN 内の別マシンやリモートのサーバに繋ぐ場合
   OLLAMA_URL=https://ollama.example.com
   OLLAMA_API_KEY=...   # 認証が必要なら設定 (Authorization: Bearer で送信)
   ```

### 接続先ごとの注意
| 接続先 | 注意点 |
| --- | --- |
| 同じマシン (macOS / Windows) | Ollama 側の設定変更は不要。`host.docker.internal` からホストのループバックへ転送される |
| 同じマシン (Linux) | `host-gateway` が docker0 ブリッジの IP に解決されるため、`OLLAMA_HOST=0.0.0.0` が必要 |
| LAN 内の別マシン | 上と同じく Ollama を `0.0.0.0` で待ち受ける必要がある |
| リモートのサーバ | HTTPS と認証を用意すること。`OLLAMA_API_KEY` で Bearer トークンを付与できる |

Ollama を `0.0.0.0` で公開すると、同一ネットワーク上の他端末からも到達できるようになります。

⚠️ **帳簿データは `OLLAMA_URL` で指定した宛先に送信されます。** 摘要と勘定科目に加え、
過去の仕訳が最大 40 件プロンプトに含まれます。自分で管理していない Ollama を指定しないでください。

### 動作
- `OLLAMA_URL` を設定したときだけ有効になります。
  未設定ならボタン自体が表示されず、アプリは従来どおり動作します
- 判断の優先順位は **勘定科目の判定基準 → 一般的な会計知識 → 過去の仕訳** です。
  過去の仕訳が判定基準と食い違う場合は、正しい科目を提案したうえで警告を表示します
- 提案はフォームに入力されるだけで、保存はされません。内容を確認してから保存してください
- モデルは `OLLAMA_MODEL`（既定 `qwen3.8:27b-q4_K_M`）、待ち時間の上限は `OLLAMA_TIMEOUT`（既定 60 秒）で変更できます

※提案は参考情報です。最終的な判断はご自身の責任で行ってください。

## コードレビュー
PR の作成時に GitHub Actions 上で Gemini がコードレビューを行います。
([run-gemini-cli](https://github.com/google-github-actions/run-gemini-cli) +
[code-review 拡張](https://github.com/gemini-cli-extensions/code-review))

- 必要な設定はシークレット `GEMINI_API_KEY` のみ（[AI Studio](https://aistudio.google.com/apikey) で発行）
- 実行契機は PR の `opened` / `reopened` / `ready_for_review` と手動実行のみ。push のたびには走りません
- 無料枠は 1 日あたりのリクエスト数が少なく（2026-09 時点で `gemini-3.5-flash` は 20 リクエスト/日）、
  使い切るとレビューはスキップされます。その場合はチェックが成功のまま
  「クォータ超過のためスキップ」と警告とジョブサマリに明示されます。
  クォータ超過**以外**の失敗はチェックを落とすので、両者は区別できます
- レビュー観点は `.gemini/styleguide.md` に記述

## Google認証設定
- 環境変数 `GOOGLE_CLIENT_ID` と `GOOGLE_CLIENT_SECRET` を設定

### ER図
[画面例](images/ER.png)
