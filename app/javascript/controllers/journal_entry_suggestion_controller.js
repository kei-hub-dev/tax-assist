import { Controller } from "@hotwired/stimulus"

// 摘要から勘定科目の提案を取得し、明細行に反映する。
//
// 提案はあくまで下書きで、保存はしない。利用者がフォームを確認して
// 通常どおり送信する。判定基準と食い違う提案には警告を表示する。
export default class extends Controller {
  static targets = ["description", "button", "status", "warning"]
  static values = { url: String }

  async suggest() {
    const description = this.descriptionTarget.value.trim()
    if (!description) {
      this.#status("摘要を入力してください")
      return
    }

    this.#busy(true)
    this.#clearWarning()

    try {
      const response = await fetch(this.urlValue, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.#csrfToken()
        },
        body: JSON.stringify({ description, amount: this.#firstAmount() })
      })

      const data = await response.json().catch(() => ({}))

      if (!response.ok) {
        this.#status(data.error || "提案を取得できませんでした")
        return
      }

      this.#apply(data)
    } catch {
      this.#status("提案を取得できませんでした")
    } finally {
      this.#busy(false)
    }
  }

  #apply(data) {
    const row = this.element.querySelector("#lines tr.line:not([hidden])")
    if (!row) {
      this.#status("明細行がありません")
      return
    }

    const account = row.querySelector("select[name*='[account_id]']")
    const dc = row.querySelector("select[name*='[dc]']")
    if (account) account.value = data.debit_account_id
    if (dc) dc.value = "debit"

    const confidence = Math.round((data.confidence ?? 0) * 100)
    this.#status(
      `借方: ${data.debit_account_name} / 貸方: ${data.credit_account_name} (確信度 ${confidence}%)`
    )

    if (data.differs_from_standard && data.warning) {
      this.#showWarning(data.warning)
    }
  }

  #busy(busy) {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = busy
      this.buttonTarget.textContent = busy ? "提案を取得中..." : "AI提案"
    }
    if (busy) this.#status("")
  }

  #status(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

  #showWarning(message) {
    if (!this.hasWarningTarget) return
    this.warningTarget.textContent = message
    this.warningTarget.hidden = false
  }

  #clearWarning() {
    if (!this.hasWarningTarget) return
    this.warningTarget.textContent = ""
    this.warningTarget.hidden = true
  }

  #firstAmount() {
    const input = this.element.querySelector("#lines input[name*='[amount]']")
    const value = parseInt(input?.value, 10)
    return Number.isNaN(value) || value <= 0 ? null : value
  }

  #csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content ?? ""
  }
}
