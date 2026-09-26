import { Controller } from "@hotwired/stimulus"

// 日付の欄。ボタンで埋めるのと、読み取った結果の表示。
// 読み取りの規則はサーバ (FuzzyDate.parse) にだけ置き、ここでは問い合わせて表示するだけ。
export default class extends Controller {
  static targets = ["input", "preview"]
  static values = { url: String }

  connect() { this.preview() }

  fill({ params: { text } }) {
    this.inputTarget.value = text
    this.preview()
  }

  preview() {
    clearTimeout(this.timer)
    this.timer = setTimeout(async () => {
      const url = `${this.urlValue}?text=${encodeURIComponent(this.inputTarget.value)}`
      const response = await fetch(url, { headers: { Accept: "text/plain" } })
      if (response.ok) this.previewTarget.textContent = `→ ${await response.text()}`
    }, 150)
  }
}
