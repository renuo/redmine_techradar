# frozen_string_literal: true

pin 'redmine_techradar/application',
    to: 'plugin_assets/redmine_techradar/application.js',
    preload: true
pin 'redmine_techradar/rating_card_controller',
    to: 'plugin_assets/redmine_techradar/rating_card_controller.js',
    preload: true
pin 'redmine_techradar/scatter_chart_controller',
    to: 'plugin_assets/redmine_techradar/scatter_chart_controller.js',
    preload: true
pin 'redmine_techradar/radar_filter_controller',
    to: 'plugin_assets/redmine_techradar/radar_filter_controller.js',
    preload: true

pin 'chart.js/auto',
    to: 'https://ga.jspm.io/npm:chart.js@4.5.1/auto/auto.js'
pin 'chart.js',
    to: 'https://ga.jspm.io/npm:chart.js@4.5.1/dist/chart.js'
pin 'chart.js/helpers',
    to: 'https://ga.jspm.io/npm:chart.js@4.5.1/helpers/helpers.js'
pin '@kurkle/color',
    to: 'https://ga.jspm.io/npm:@kurkle/color@0.3.4/dist/color.esm.js'
pin 'chartjs-plugin-datalabels',
    to: 'https://ga.jspm.io/npm:chartjs-plugin-datalabels@2.2.0/dist/chartjs-plugin-datalabels.esm.js'
