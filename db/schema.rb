# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2025_10_05_031501) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "accounting_periods", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "accounting_year"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "accounting_year"], name: "index_accounting_periods_on_user_id_and_accounting_year", unique: true
    t.index ["user_id"], name: "index_accounting_periods_on_user_id"
  end

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "name"], name: "index_accounts_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_accounts_on_user_id"
  end

  create_table "opening_balances", force: :cascade do |t|
    t.bigint "accounting_period_id", null: false
    t.bigint "account_id", null: false
    t.integer "debit_amount", default: 0, null: false
    t.integer "credit_amount", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_opening_balances_on_account_id"
    t.index ["accounting_period_id", "account_id"], name: "index_opening_balances_on_accounting_period_id_and_account_id", unique: true
    t.index ["accounting_period_id"], name: "index_opening_balances_on_accounting_period_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "business_name"
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "accounting_periods", "users"
  add_foreign_key "accounts", "users"
  add_foreign_key "opening_balances", "accounting_periods"
  add_foreign_key "opening_balances", "accounts"
end
