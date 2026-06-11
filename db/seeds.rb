# frozen_string_literal: true

ROLE_PERMISSIONS = {
  'Tech Radar Entwickler' => [:view_tech_radar, :rate_technologies],
  'Tech Radar Sales' => [:view_tech_radar]
}.freeze

ROLE_PERMISSIONS.each do |name, permissions|
  Role.find_or_initialize_by(name: name)
    .update!(permissions: permissions, assignable: true)
end

[
  'Ruby', 'Ruby on Rails', 'PostgreSQL', 'Redis', 'Stimulus',
  'Hotwire Turbo', 'TypeScript', 'React', 'Tailwind CSS',
  'Docker', 'Kubernetes', 'Terraform', 'GraphQL', 'gRPC'
].each do |name|
  TechRadar::Technology.find_or_create_by!(name: name)
end
