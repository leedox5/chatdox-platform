import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = window.setTimeout(() => {
      this.element.remove()
    }, 5000)
  }

  disconnect() {
    if (this.timeout) {
      window.clearTimeout(this.timeout)
    }
  }
}