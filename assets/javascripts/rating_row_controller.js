import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['field']

  submitIfReady() {
    if (this.fieldTargets.every((field) => field.value !== '')) {
      this.element.requestSubmit()
    }
  }
}
