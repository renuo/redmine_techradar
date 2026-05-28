import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'canField', 'wantField', 'canButton', 'wantButton', 'skip', 'back']
  static values = {
    canLevel: String,
    wantLevel: String,
    previousCanLevel: String,
    previousWantLevel: String
  }

  connect() {
    this.stage = 'can'
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
    this.refreshHighlights()
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown)
  }

  selectCan(event) {
    const level = event.currentTarget.dataset.level
    this.setCan(level)
    this.stage = 'want'
    this.submitIfReady()
  }

  selectWant(event) {
    const level = event.currentTarget.dataset.level
    this.setWant(level)
    this.submitIfReady()
  }

  setCan(level) {
    this.canFieldTarget.value = level
    this.canLevelValue = level
    this.refreshHighlights()
  }

  setWant(level) {
    this.wantFieldTarget.value = level
    this.wantLevelValue = level
    this.refreshHighlights()
  }

  refreshHighlights() {
    this.canButtonTargets.forEach((btn) => {
      btn.classList.toggle('previous', btn.dataset.level === this.previousCanLevelValue)
      btn.classList.toggle('selected', btn.dataset.level === this.canLevelValue)
    })
    this.wantButtonTargets.forEach((btn) => {
      btn.classList.toggle('previous', btn.dataset.level === this.previousWantLevelValue)
      btn.classList.toggle('selected', btn.dataset.level === this.wantLevelValue)
    })
  }

  submitIfReady() {
    if (this.canFieldTarget.value && this.wantFieldTarget.value) {
      this.formTarget.requestSubmit()
    }
  }

  handleKeydown(event) {
    if (this.shouldIgnoreKey(event)) return

    if (event.key === 'ArrowRight') {
      if (!this.hasSkipTarget) return
      event.preventDefault()
      this.skipTarget.click()
      return
    }
    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      this.backTarget.click()
      return
    }

    const digit = Number.parseInt(event.key, 10)
    if (Number.isNaN(digit)) return

    if (this.stage === 'can' && digit >= 1 && digit <= this.canButtonTargets.length) {
      event.preventDefault()
      const level = this.canButtonTargets[digit - 1].dataset.level
      this.setCan(level)
      this.stage = 'want'
      this.submitIfReady()
    } else if (this.stage === 'want' && digit >= 1 && digit <= this.wantButtonTargets.length) {
      event.preventDefault()
      const level = this.wantButtonTargets[digit - 1].dataset.level
      this.setWant(level)
      this.submitIfReady()
    }
  }

  shouldIgnoreKey(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return true
    const tag = event.target.tagName
    return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
  }
}
