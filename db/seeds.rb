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

# A role only grants its permissions through a project membership, even when the permission is global.
# Create a project and one test user per role.
project = Project.find_or_create_by!(identifier: 'tech-radar') do |p|
  p.name = 'Tech Radar'
end

TEST_USERS = {
  'techradar_dev' => { lastname: 'Entwickler', role: 'Tech Radar Entwickler' },
  'techradar_sales' => { lastname: 'Sales', role: 'Tech Radar Sales' }
}.freeze

TEST_USERS.each do |login, attrs|
  user = User.find_or_create_by!(login: login) do |u|
    u.firstname = 'Tech Radar'
    u.lastname = attrs[:lastname]
    u.mail = "#{login}@example.com"
    u.password = 'techradar123'
    u.status = User::STATUS_ACTIVE
    puts "Created User #{u.mail} with password #{u.password}"
  end

  unless Member.exists?(user: user, project: project)
    Member.create!(user: user, project: project,
                   roles: [Role.find_by(name: attrs[:role])])
  end
end
