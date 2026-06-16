import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['form', 'canField', 'wantField', 'canButton', 'wantButton', 'forward', 'back']
  static values = {
    basePath: String,
    skipUrl: String,
    canLevel: String,
    wantLevel: String
  }

  connect() {
    this.stage = 'can'
    this.boundKeydown = this.handleKeydown.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
    this.refreshHighlights()
    if (this.hasBackTarget) this.backTarget.hidden = !this.canGoBack()
    if (this.hasForwardTarget) this.forwardTarget.hidden = !(this.canGoForward() || this.skipUrlValue)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown)
  }

  canGoBack() {
    if (!document.referrer) return false
    try {
      const url = new URL(document.referrer)
      return url.origin === window.location.origin &&
             url.pathname.startsWith(this.basePathValue)
    } catch {
      return false
    }
  }

  back() {
    window.history.back()
  }

  // "Forward" returns through the cards we backed away from, toward where we started.
  // Only when there is nothing ahead in history do we skip to the next unrated card.
  forward() {
    if (this.canGoForward()) {
      window.history.forward()
    } else if (this.skipUrlValue) {
      window.location.assign(this.skipUrlValue)
    }
  }

  canGoForward() {
    return Boolean(window.navigation && window.navigation.canGoForward)
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
      btn.classList.toggle('selected', btn.dataset.level === this.canLevelValue)
    })
    this.wantButtonTargets.forEach((btn) => {
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
      event.preventDefault()
      if (this.hasForwardTarget && !this.forwardTarget.hidden) this.forward()
      return
    }
    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      if (this.hasBackTarget && !this.backTarget.hidden) this.back()
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
