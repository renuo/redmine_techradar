import RatingCardController from 'redmine_techradar/rating_card_controller'
import ScatterChartController from 'redmine_techradar/scatter_chart_controller'
import RadarFilterController from 'redmine_techradar/radar_filter_controller'

if (window.Stimulus) {
  window.Stimulus.register('rating-card', RatingCardController)
  window.Stimulus.register('scatter-chart', ScatterChartController)
  window.Stimulus.register('radar-filter', RadarFilterController)
}
