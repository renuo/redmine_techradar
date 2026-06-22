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
  'JavaScript', 'SQL', 'HTML/CSS', 'Python', 'TypeScript', 'Bash/Shell',
  'Java', 'C#', 'C++', 'PHP', 'C', 'Go', 'PowerShell', 'Rust', 'Kotlin',
  'Dart', 'Ruby', 'Lua', 'Swift', 'Visual Basic', 'Assembly', 'Groovy',
  'VBA', 'R', 'MATLAB', 'Scala', 'Objective-C', 'Perl', 'Elixir', 'Delphi',
  'GDScript', 'Haskell', 'Clojure', 'Lisp', 'MicroPython', 'Solidity',
  'Erlang', 'Zig', 'F#', 'Fortran', 'Apex', 'Julia', 'Ada', 'Prolog',
  'Cobol', 'OCaml', 'Crystal', 'Zephyr', 'Nim',
  'PostgreSQL', 'MySQL', 'SQLite', 'Microsoft SQL Server', 'MongoDB',
  'Redis', 'MariaDB', 'Elasticsearch', 'Oracle', 'Dynamodb',
  'Firebase Realtime Database', 'Cloud Firestore', 'BigQuery', 'H2',
  'Supabase', 'Cosmos DB', 'Microsoft Access', 'Snowflake', 'InfluxDB',
  'Cassandra', 'Databricks SQL', 'Neo4J', 'Clickhouse', 'IBM DB2', 'Solr',
  'DuckDB', 'Firebird', 'Couch DB', 'Cockroachdb', 'Couchbase', 'Presto',
  'Datomic', 'EventStoreDB', 'RavenDB', 'TiDB',
  'React', 'Node.js', 'jQuery', 'Angular', 'ASP.NET CORE', 'Next.js',
  'Express', 'Vue.js', 'ASP.NET', 'Spring Boot', 'Flask', 'Django',
  'WordPress', 'FastAPI', 'Laravel', 'AngularJS', 'NestJS', 'Svelte',
  'Blazor', 'Ruby on Rails', 'Nuxt.js', 'Symfony', 'Htmx', 'Astro',
  'Fastify', 'Phoenix', 'Drupal', 'Strapi', 'Deno', 'CodeIgniter',
  'Gatsby', 'Remix', 'Solid.js', 'Yii 2', 'Play Framework', 'Elm', '.NET',
  'Pandas', 'NumPy', '.NET Framework', 'RabbitMQ', 'Spring Framework',
  'Apache Kafka', 'Flutter', 'Torch/PyTorch', 'React Native',
  'Scikit-Learn', 'TensorFlow', 'OpenCV', 'Qt', 'Electron', 'OpenGL',
  'CUDA', 'Apache Spark', 'SwiftUI', 'Hugging Face Transformers', 'Keras',
  '.NET MAUI', 'Xamarin', 'Ruff', 'Ionic', 'Cordova', 'Hadoop', 'Tauri',
  'GTK', 'Capacitor', 'Roslyn', 'DirectX', 'Quarkus', 'OpenCL', 'Ktor',
  'mlflow', 'MFC', 'Tidyverse', 'JAX',
  'Docker', 'npm', 'Pip', 'Homebrew', 'Kubernetes', 'Yarn', 'Webpack',
  'Vite', 'Make', 'NuGet', 'Maven', 'Gradle', 'Visual Studio Solution',
  'MSBuild', 'Terraform', 'Composer', 'APT', 'pnpm', 'Chocolatey',
  'Ansible', 'Pacman', 'Podman', 'Unity 3D', 'Ninja', 'Bun', 'Godot',
  'Google Test', 'Ant', 'Nix', 'Unreal Engine', 'Dagger', 'Puppet',
  'Pulumi', 'Chef', 'Solidus / Spree', 'THREE.js', 'Fauna', 'Stimulus',
  'Github Actions', 'Turbo', 'GitLab CI', 'nostr'
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
    Rails.logger.info "Created User #{u.mail} with password #{u.password}"
  end

  unless Member.exists?(user: user, project: project)
    Member.create!(user: user, project: project,
                   roles: [Role.find_by(name: attrs[:role])])
  end
end
