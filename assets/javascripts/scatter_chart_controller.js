import { Controller } from '@hotwired/stimulus'
import Chart from 'chart.js/auto'
import ChartDataLabels from 'chartjs-plugin-datalabels'

export default class extends Controller {
  static values = {
    points: Array,
    canLabel: String,
    wantLabel: String,
    canTicks: Array,
    wantTicks: Array,
    backgroundImage: String
  }

  connect() {
    const data = {
      datasets: [{
        data: this.pointsValue.map((p) => ({ x: p.want, y: p.can, label: p.name })),
        backgroundColor: '#2a8a4a',
        // White outlines keep points and labels readable on top of the background drawing
        borderColor: '#ffffff',
        borderWidth: 1.5,
        pointRadius: 5,
        clip: false
      }]
    }

    // The four can levels; 0 carries no label — it only reserves the empty slot between them.
    const canTickValues = [-2, -1, 1, 2]
    // The background drawing has its own hand-drawn axes, so the centre grid line stays hidden.
    const gridColor = (ctx) => (ctx.tick?.value === 0 ? 'transparent' : 'rgba(0, 0, 0, 0.1)')

    const background = new Image()
    background.onload = () => this.chart?.draw()
    background.src = this.backgroundImageValue

    this.chart = new Chart(this.element, {
      type: 'scatter',
      data,
      plugins: [ChartDataLabels, quadrantBackground(background)],
      options: {
        aspectRatio: 1,
        layout: { padding: { top: 24, right: 48 } },
        interaction: { mode: 'point', intersect: true },
        scales: {
          x: {
            title: { display: true, text: this.wantLabelValue },
            min: -2,
            max: 2,
            grid: { color: gridColor },
            ticks: {
              stepSize: 1,
              callback: (value) => this.wantTicksValue[value + 2]
            }
          },
          y: {
            title: { display: true, text: this.canLabelValue },
            min: -2,
            max: 2,
            grid: { color: gridColor },
            afterBuildTicks: (axis) => {
              // Add 0 so the centre line is drawn
              axis.ticks = [...canTickValues, 0].sort((a, b) => a - b).map((value) => ({ value }))
            },
            ticks: {
              callback: (value) => (value === 0 ? '' : this.canTicksValue[canTickValues.indexOf(value)])
            }
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              title: () => '',
              label: (ctx) => ctx.raw.label
            }
          },
          datalabels: {
            align: 'top',
            offset: 4,
            clip: false,
            textStrokeColor: '#ffffff',
            textStrokeWidth: 3,
            formatter: (_, ctx) => ctx.dataset.data[ctx.dataIndex].label
          }
        }
      }
    })
  }

  disconnect() {
    this.chart?.destroy()
  }
}

// Stretches the image over the plot area, beneath the grid and the points. The
// image is cropped so that its axis crossing sits exactly at its centre.
function quadrantBackground(image) {
  return {
    id: 'quadrantBackground',
    beforeDraw(chart) {
      if (!image.complete || image.naturalWidth === 0) return

      const { left, top, width, height } = chart.chartArea
      chart.ctx.drawImage(image, left, top, width, height)
    }
  }
}
