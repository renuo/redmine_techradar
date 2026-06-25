import { Controller } from '@hotwired/stimulus'
import Chart from 'chart.js/auto'
import ChartDataLabels from 'chartjs-plugin-datalabels'

export default class extends Controller {
  static values = {
    points: Array,
    canLabel: String,
    wantLabel: String,
    canTicks: Array,
    wantTicks: Array
  }

  connect() {
    const data = {
      datasets: [{
        data: this.pointsValue.map((p) => ({ x: p.want, y: p.can, label: p.name })),
        backgroundColor: '#2a8a4a',
        clip: false
      }]
    }

    // The four can levels; 0 carries no label — it only draws the centre line between them.
    const canTickValues = [-1.5, -0.5, 0.5, 1.5]
    const gridColor = (ctx) => (ctx.tick?.value === 0 ? '#999999' : 'rgba(0, 0, 0, 0.1)')

    this.chart = new Chart(this.element, {
      type: 'scatter',
      data,
      plugins: [ChartDataLabels],
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
