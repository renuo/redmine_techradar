# frozen_string_literal: true

Redmine::Plugin.register :redmine_techradar do
  name "Techradar"
  author "snitzelbread"
  description "Create custom references to external tickets."
  version "0.1.0"
  url "https://github.com/renuo/redmine_techradar"
  author_url "https://github.com/renuo"

  project_module :redmine_techradar do
    permission :show_techradar, { radar_technologies: %i[index] }, require: :loggedin
  end

  menu :top_menu, :radar_technologies, { controller: "radar_technologies", action: "index" },
       caption: "Tech Radar", if: proc { User.current.allowed_to_globally?(action: :index, controller: "radar_technologies") }
end
