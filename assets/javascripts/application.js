import RatingCardController from 'redmine_techradar/rating_card_controller'
import RatingRowController from 'redmine_techradar/rating_row_controller'
import ScatterChartController from 'redmine_techradar/scatter_chart_controller'

if (window.Stimulus) {
  window.Stimulus.register('rating-card', RatingCardController)
  window.Stimulus.register('rating-row', RatingRowController)
  window.Stimulus.register('scatter-chart', ScatterChartController)
}
