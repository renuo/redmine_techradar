# frozen_string_literal: true

ROLE_PERMISSIONS = {
  'Tech Radar Entwickler' => [:view_tech_radar, :rate_technologies],
  'Tech Radar Sales' => [:view_tech_radar]
}.freeze

ROLE_PERMISSIONS.each do |name, permissions|
  Role.find_or_create_by!(name: name) do |role|
    role.permissions = permissions
    role.assignable = true
  end
end
