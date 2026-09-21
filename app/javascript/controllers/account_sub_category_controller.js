import { Controller } from "@hotwired/stimulus"

// 勘定科目の区分(category)に応じてサブ区分(sub_category)の選択肢を組み替える。
// Account モデルのバリデーションと同じく、収益と費用のときだけサブ区分を
// 必須とし、それ以外の区分では選択欄自体を隠して値を空にする。
export default class extends Controller {
  static targets = ["category", "subCategory", "subCategoryField"]
  static values = {
    options: Object,
    selected: String
  }

  connect() {
    this.#rebuild(this.selectedValue)
  }

  categoryChanged() {
    this.#rebuild("")
  }

  #rebuild(selected) {
    const category = this.categoryTarget.value
    const options = this.optionsValue[category] || {}

    this.subCategoryTarget.replaceChildren(this.#blankOption())

    for (const [value, label] of Object.entries(options)) {
      const option = document.createElement("option")
      option.value = value
      option.textContent = label
      this.subCategoryTarget.appendChild(option)
    }

    const required = this.#requiresSubCategory(category)

    if (this.hasSubCategoryFieldTarget) {
      this.subCategoryFieldTarget.hidden = !required
    }

    this.subCategoryTarget.value = required ? selected : ""
  }

  #requiresSubCategory(category) {
    return category === "revenue" || category === "expense"
  }

  #blankOption() {
    const option = document.createElement("option")
    option.value = ""
    option.textContent = "指定なし"
    return option
  }
}
