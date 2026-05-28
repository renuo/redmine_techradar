# frozen_string_literal: true

module RedmineTechradar
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_layouts_base_html_head,
              partial: 'hooks/redmine_techradar/head'
  end
end
