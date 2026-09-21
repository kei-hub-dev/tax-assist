import { Controller } from "@hotwired/stimulus"

// 期首残高の入力に応じて借方・貸方の合計を再計算し、貸借が一致しているかを
// 表示する。複式簿記では期首残高も貸借一致している必要があるため、入力中に
// 気づけるようにしている。
export default class extends Controller {
  static targets = ["debit", "credit", "totalDebit", "totalCredit", "sumRow", "note"]

  connect() {
    this.recalculate()
  }

  recalculate() {
    const debit = this.#sum(this.debitTargets)
    const credit = this.#sum(this.creditTargets)

    if (this.hasTotalDebitTarget) {
      this.totalDebitTarget.textContent = debit.toLocaleString()
    }
    if (this.hasTotalCreditTarget) {
      this.totalCreditTarget.textContent = credit.toLocaleString()
    }

    const balanced = debit === credit

    if (this.hasSumRowTarget) {
      this.sumRowTarget.classList.toggle("sum-ok", balanced)
      this.sumRowTarget.classList.toggle("sum-ng", !balanced)
    }
    if (this.hasNoteTarget) {
      this.noteTarget.classList.toggle("hidden", balanced)
    }
  }

  #sum(targets) {
    return targets.reduce((total, input) => {
      const value = parseInt(input.value, 10)
      return total + (Number.isNaN(value) ? 0 : value)
    }, 0)
  }
}
