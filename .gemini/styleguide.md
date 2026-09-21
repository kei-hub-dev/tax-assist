# コードレビュー ガイド

青色申告向けの帳簿作成 Web アプリです。個人事業主・フリーランスが、仕訳帳と総勘定元帳、
損益計算書と貸借対照表を作成するために使います。

## レビューの言語

**レビューコメントは日本語で書いてください。** コード識別子・ライブラリ名・エラーメッセージは
原文のままで構いません。

## 技術スタック

- Ruby 3.4.10 / Rails 8.1（`config.load_defaults` は 7.2 のまま）
- PostgreSQL 16、開発は Docker Compose（devcontainer）
- 認証は devise 4.9 系 + omniauth-google-oauth2
- PDF 出力は grover（puppeteer → Chromium）、CSV 出力は標準ライブラリの csv
- アセットは sprockets-rails。**importmap / Turbo / Stimulus は未初期化**で、
  JavaScript はビューに直接書かれたインライン `<script>` のみ

## 最優先で指摘してほしいこと

### 1. ユーザースコープの絞り込み漏れ（最重要）

データの所有関係が 2 種類あり、取り違えると**他ユーザーの帳簿が見えてしまいます**。

- `Account` は `user` に直接ぶら下がる → `current_user.accounts`
- `JournalEntry` は **`user_id` を持ちません**。`accounting_period` 経由で user に紐づきます

そのため仕訳を横断的に引くクエリでは、必ず accounting_period を経由してください。

```ruby
# 正しい
JournalEntry.joins(:accounting_period)
            .where(accounting_periods: { user_id: current_user.id })

JournalEntryLine.joins(journal_entry: :accounting_period)
                .where(accounting_periods: { user_id: current_user.id })
```

`JournalEntry.where(...)` を user の条件なしで書いている箇所は指摘してください。
コントローラでは `current_period`（`session[:accounting_period_id]` 由来）でスコープするか、
`before_action :require_accounting_period!` を通しているかを確認してください。

### 2. 複式簿記としての整合性

- `JournalEntryLine#dc` は `"debit"`（借方）か `"credit"`（貸方）のみです
- **貸借一致のバリデーションはモデルに存在しません。** 仕訳を作成・更新するコードでは、
  借方合計と貸方合計が一致するかを呼び出し側で担保する必要があります。
  担保されていなければ指摘してください
- `amount` は **integer（円単位）** です。小数や浮動小数点数を持ち込まないでください。
  金額の計算で `Float` や `to_f` を使っている箇所は必ず指摘してください
- 会計年度（`accounting_period`）を跨いだ集計になっていないか確認してください。
  帳簿は年度単位で閉じている必要があります

### 3. 帳票の正確性

決算書は税務申告に使われます。集計ロジックの誤りは実害につながるため、
損益計算書・貸借対照表・総勘定元帳の計算式は特に注意深く確認してください。

- 損益計算書の段階利益（売上総利益 → 営業利益 → 経常利益 → 税引前当期純利益 → 当期純利益）の
  積み上げ順序
- 勘定科目の `category`（asset / liability / equity / revenue / expense）と
  `sub_category` の対応
- 期首残高（`opening_balance`）の借方・貸方の扱い

### 4. セキュリティ

- strong parameters で許可するカラムが過剰になっていないか
- `send_data` のファイル名にユーザー入力をそのまま使っていないか
- 認証は `ApplicationController` の `before_action :authenticate_user!` が既定です。
  `skip_before_action` で外している箇所があれば、その妥当性を確認してください

### 5. パフォーマンス

帳票コントローラは集計ループが多く、N+1 クエリが発生しやすい構造です。
ループ内でのクエリ発行や、`includes` / `preload` の不足を指摘してください。

## コーディング規約

- **rubocop-rails-omakase** に従います。CI で `bin/rubocop` が実行されるため、
  rubocop が自動検出できるスタイル上の指摘（インデント、クォート、空白など）は
  **レビューコメントにしないでください。** 重複するだけです
- コメントと UI 文言は日本語です
- ロケールは `config/locales/ja.yml`。ビューに日本語文字列を直書きせず、
  既存の i18n キーを使っているか確認してください

## テスト

- RSpec を使います（`spec/`）。Rails 生成時の Minitest（`test/`）が残っていますが、
  新規テストは RSpec で書きます
- `spec/rails_helper.rb` で `infer_spec_type_from_file_location!` が**無効**なため、
  各 spec で `type: :request` などを明示する必要があります
- テストが手薄なリポジトリです。ロジックを追加・変更する PR にテストが無い場合は
  指摘してください。ただし設定ファイルやドキュメントのみの変更では不要です

## 指摘しなくてよいこと

- `Gemfile.lock` / `package-lock.json` / `db/schema.rb` などの自動生成ファイルの中身
- rubocop が検出するスタイル上の問題（上記のとおり）
- 「テストを追加しましょう」だけの、具体性のない一般論
