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
        data: spreadOverlapping(this.pointsValue.map((p) => ({ x: p.want, y: p.can, label: p.name }))),
        backgroundColor: '#000000',
        // White outlines keep points and labels readable on top of the background drawing
        borderColor: '#ffffff',
        borderWidth: 1.5,
        pointRadius: 4.5,
        pointHoverRadius: 6,
        clip: false
      }]
    }

    // The four can levels sit one step apart, centred on 0; 0 itself carries no label.
    const canTickValues = [-1.5, -0.5, 0.5, 1.5]
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
        // The container sets the size (a square, see tech_radar.css). Letting the
        // chart keep its own aspect ratio ties the container's height to the canvas,
        // and Chart.js then never grows the chart back after the window shrank.
        maintainAspectRatio: false,
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
          // Labels of densely spread points can still collide; hovering tells them apart
          tooltip: {
            displayColors: false,
            callbacks: {
              title: () => '',
              label: (ctx) => ctx.raw.label
            }
          },
          datalabels: {
            align: 'top',
            offset: 2,
            clip: false,
            color: '#000000',
            font: { size: 10, weight: 'bold' },
            textStrokeColor: '#ffffff',
            textStrokeWidth: 2.5,
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

// Ratings snap to whole grid steps, so equal ratings would sit on top of each
// other. Points sharing a position are fanned out on a sunflower spiral around
// it, ordered by label so the layout is stable across reloads. Neighbours keep
// a fixed spacing, so small groups stay close to their rating and only large
// ones grow, up to just inside the half step around it. On the outer edge the
// spiral only opens towards the plot area.
const SPREAD_SPACING = 0.08
const MAX_SPREAD_RADIUS = 0.4
const AXIS_LIMIT = 2
const GOLDEN_RATIO = (1 + Math.sqrt(5)) / 2

function spreadOverlapping(points) {
  const groups = new Map()
  for (const point of points) {
    const key = `${point.x},${point.y}`
    groups.set(key, [...(groups.get(key) ?? []), point])
  }

  return [...groups.values()].flatMap((group) => {
    if (group.length === 1) return group

    const { x, y } = group[0]
    const { centre, span } = openSector(x, y)

    return group
      .sort((a, b) => a.label.localeCompare(b.label))
      .map((point, i) => {
        const angle = centre + (((i * GOLDEN_RATIO + 0.5) % 1) - 0.5) * span
        // A narrower sector needs a wider radius to fit the same number of points
        const radius = Math.min(MAX_SPREAD_RADIUS, SPREAD_SPACING * Math.sqrt(((i + 0.5) * 2 * Math.PI) / span))
        return { ...point, x: x + radius * Math.cos(angle), y: y + radius * Math.sin(angle) }
      })
  })
}

// The directions a group can spread into without leaving the plot area: a full
// circle inside, a half circle on an edge and a quarter circle in a corner.
function openSector(x, y) {
  const inwardX = Math.abs(x) >= AXIS_LIMIT ? -Math.sign(x) : 0
  const inwardY = Math.abs(y) >= AXIS_LIMIT ? -Math.sign(y) : 0
  const edges = Math.abs(inwardX) + Math.abs(inwardY)
  const span = [2, 1, 0.5][edges] * Math.PI

  return { centre: Math.atan2(inwardY, inwardX), span }
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
