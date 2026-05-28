import { Controller } from '@hotwired/stimulus'
import Chart from 'chart.js/auto'
import ChartDataLabels from 'chartjs-plugin-datalabels'

export default class extends Controller {
  static values = {
    points: Array,
    canLabel: String,
    wantLabel: String
  }

  connect() {
    const data = {
      datasets: [{
        data: this.pointsValue.map((p) => ({ x: p.want, y: p.can, label: p.name })),
        backgroundColor: '#2a8a4a',
        clip: false
      }]
    }

    this.chart = new Chart(this.element, {
      type: 'scatter',
      data,
      plugins: [ChartDataLabels],
      options: {
        layout: { padding: { top: 24, right: 48 } },
        interaction: { mode: 'point', intersect: true },
        scales: {
          x: { title: { display: true, text: this.wantLabelValue }, min: 1, max: 5, ticks: { stepSize: 1 } },
          y: { title: { display: true, text: this.canLabelValue }, min: 1, max: 4, ticks: { stepSize: 1 } }
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
