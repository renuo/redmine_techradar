import { Controller } from '@hotwired/stimulus'

// Rating happens in two steps: pick "can", then "want". The rating is saved
// once both are chosen in this visit. On an already rated card both fields
// start out with the saved levels, so fixing only "want" is a single click,
// while changing "can" still waits for a "want" choice before saving.
export default class extends Controller {
  static targets = ['form', 'canField', 'wantField', 'canButton', 'wantButton', 'canStep', 'wantStep', 'back', 'next']
  static values = {
    canLevel: String,
    wantLevel: String
  }

  connect() {
    this.wantChosen = false
    this.submitting = false
    this.setStage('can')
    this.boundKeydown = this.handleKeydown.bind(this)
    this.boundPageshow = this.handlePageshow.bind(this)
    document.addEventListener('keydown', this.boundKeydown)
    window.addEventListener('pageshow', this.boundPageshow)
    this.refreshHighlights()
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeydown)
    window.removeEventListener('pageshow', this.boundPageshow)
  }

  selectCan(event) {
    this.chooseCan(event.currentTarget.dataset.level)
  }

  selectWant(event) {
    this.chooseWant(event.currentTarget.dataset.level)
  }

  chooseCan(level) {
    this.canFieldTarget.value = level
    this.canLevelValue = level
    this.setStage('want')
    this.refreshHighlights()
    if (this.wantChosen) this.submitIfReady()
  }

  chooseWant(level) {
    this.wantFieldTarget.value = level
    this.wantLevelValue = level
    this.wantChosen = true
    this.refreshHighlights()
    this.submitIfReady()
  }

  setStage(stage) {
    this.stage = stage
    this.canStepTarget.classList.toggle('active', stage === 'can')
    this.wantStepTarget.classList.toggle('active', stage === 'want')
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
    if (this.submitting) return
    if (this.canFieldTarget.value && this.wantFieldTarget.value) {
      this.submitting = true
      this.formTarget.requestSubmit()
    }
  }

  // Going back in browser history may restore this page from the back/forward
  // cache, with the half-finished state of the last visit and a stale saved
  // rating. Reload it so the card always reflects what is stored.
  handlePageshow(event) {
    if (event.persisted) window.location.reload()
  }

  handleKeydown(event) {
    if (this.shouldIgnoreKey(event)) return

    if (event.key === 'ArrowRight') {
      event.preventDefault()
      if (this.hasNextTarget) this.nextTarget.click()
      return
    }
    if (event.key === 'ArrowLeft') {
      event.preventDefault()
      if (this.hasBackTarget) this.backTarget.click()
      return
    }

    const digit = Number.parseInt(event.key, 10)
    if (Number.isNaN(digit)) return

    if (this.stage === 'can' && digit >= 1 && digit <= this.canButtonTargets.length) {
      event.preventDefault()
      this.chooseCan(this.canButtonTargets[digit - 1].dataset.level)
    } else if (this.stage === 'want' && digit >= 1 && digit <= this.wantButtonTargets.length) {
      event.preventDefault()
      this.chooseWant(this.wantButtonTargets[digit - 1].dataset.level)
    }
  }

  shouldIgnoreKey(event) {
    if (event.metaKey || event.ctrlKey || event.altKey) return true
    const tag = event.target.tagName
    return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT'
  }
}
