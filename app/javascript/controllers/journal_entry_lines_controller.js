import { Controller } from "@hotwired/stimulus"

// 仕訳の明細行を動的に追加・削除する。
//
// 追加はサーバー側で描画したプロトタイプ HTML を複製し、child_index の
// プレースホルダを一意な値に置換することで、fields_for のパラメータ名を
// 衝突させずに増やしている。
// 削除は行を DOM から消さず、_destroy を 1 にして隠す(既存行を確実に削除
// 対象としてサーバーへ送るため)。
export default class extends Controller {
  static targets = ["rows", "template"]
  static values = { placeholder: { type: String, default: "NEW_RECORD" } }

  add() {
    const html = this.templateTarget.innerHTML.replaceAll(
      this.placeholderValue,
      this.#uniqueIndex()
    )

    const holder = document.createElement("tbody")
    holder.innerHTML = html.trim()

    // プロトタイプは明細行とエラー表示行の 2 行構成なので、まとめて移す
    while (holder.firstElementChild) {
      this.rowsTarget.appendChild(holder.firstElementChild)
    }
  }

  remove(event) {
    const row = event.currentTarget.closest("tr")
    if (!row) return

    const destroyField = row.querySelector("input[name*='[_destroy]']")
    if (destroyField) destroyField.value = 1

    row.hidden = true

    // 対になっているエラー表示行も一緒に隠す
    const errorRow = row.nextElementSibling
    if (errorRow && errorRow.classList.contains("line-errors")) {
      errorRow.hidden = true
    }
  }

  // Date.now() だけでは同一ミリ秒内の連続追加で衝突するため連番を足す
  #uniqueIndex() {
    this.constructor.counter = (this.constructor.counter || 0) + 1
    return `${Date.now()}${this.constructor.counter}`
  }
}
