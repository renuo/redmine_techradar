import { Controller } from '@hotwired/stimulus'

// Saves a row of the overview in the background as soon as both levels are
// chosen, so the page neither reloads nor scrolls back to the top.
export default class extends Controller {
  static targets = ['field']

  async submitIfReady() {
    const complete = this.fieldTargets.every((field) => field.value !== '')
    this.setState(complete ? 'saving' : 'incomplete')
    if (!complete) return

    try {
      const response = await fetch(this.element.action, {
        method: 'POST',
        body: new FormData(this.element),
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        credentials: 'same-origin'
      })
      if (!response.ok) throw new Error(`HTTP ${response.status}`)

      this.removeBlankOptions()
      this.setState('saved')
    } catch (error) {
      console.error('Saving rating failed', error)
      this.setState('error')
    }
  }

  // Once saved, a rating can be changed but not cleared again
  removeBlankOptions() {
    this.fieldTargets.forEach((field) => {
      field.querySelectorAll('option[value=""]').forEach((option) => option.remove())
    })
  }

  setState(state) {
    this.element.dataset.state = state
  }
}
