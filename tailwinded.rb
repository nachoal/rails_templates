# Kill spring if its running
run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

#################################### GEMFILE ###################################
gsub_file './Gemfile', /(^  $|# .+$)/, ''
gsub_file './Gemfile', /^\n/, ''
gsub_file './Gemfile', /^  $/, ''
gsub_file './Gemfile', /^\n/, ''
gsub_file './Gemfile', /^ruby.+$/, "\nruby '#{RUBY_VERSION}'"
gsub_file './Gemfile', /^gem 'rails'.+$/, "\n# Base\ngem 'rails', '~> #{Rails.version}'"
gsub_file './Gemfile', /^gem 'pg'.+$/, "gem 'pg'"
gsub_file './Gemfile', /^gem 'puma'.+$/, "gem 'puma'"
gsub_file './Gemfile', /^gem 'webpacker'.+$/, "gem 'webpacker'"
gsub_file './Gemfile', /^gem 'turbolinks'.+$/, "gem 'turbolinks'"
gsub_file './Gemfile', /^gem 'sass-rails'.+$/, "gem 'sass-rails'"
gsub_file './Gemfile', /^gem 'jbuilder'.+$/, "gem 'jbuilder'"
gsub_file './Gemfile', /^gem 'bootsnap'.+$/, "gem 'bootsnap', require: false\n"
gsub_file './Gemfile', /gem 'web-console'.+$/, "gem 'web-console'"
gsub_file './Gemfile', /gem 'rack-mini-profiler'.+$/, "gem 'rack-mini-profiler'"
gsub_file './Gemfile', /gem 'listen'.+$/, "gem 'listen'"
gsub_file './Gemfile', /gem 'capybara'.+$/, "gem 'capybara'"
gsub_file './Gemfile', /^end/, "end\n"
gsub_file './Gemfile', /^gem 'tzinfo-data', platforms: \[:mingw, :mswin, :x64_mingw, :jruby\]$/, ""
gsub_file './Gemfile', /gem 'byebug', platforms: \[:mri, :mingw, :x64_mingw\]$/, ""

inject_into_file 'Gemfile', after: "gem 'bootsnap', require: false\n" do
  <<-RUBY
  
# Form helper
gem 'simple_form'

# CSS
gem "tailwindcss-rails"
gem 'autoprefixer-rails'
gem 'font-awesome-sass'

RUBY
end

inject_into_file 'Gemfile', after: 'group :development, :test do' do
  <<-RUBY
  
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'dotenv-rails'
  gem 'rspec-rails'
  gem 'shoulda-matchers'
  gem 'parallel_tests'
  gem 'fuubar'
  gem 'awesome_print'
  gem 'database_cleaner'
  gem 'factory_bot_rails'
  RUBY
end

##################################### Layouts ##################################
gsub_file('app/views/layouts/application.html.erb', '<meta name="viewport" content="width=device-width,initial-scale=1">', '')
gsub_file('app/views/layouts/application.html.erb', "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>", "<%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload', defer: true %>")
style = <<~HTML
  <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
      <meta http-equiv="X-UA-Compatible" content="IE=edge">
      <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
HTML
gsub_file('app/views/layouts/application.html.erb', "<%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>", style)

##################################### README ##################################
markdown_file_content = <<~MARKDOWN
  This project was generated with my custom template
MARKDOWN
file 'README.md', markdown_file_content, force: true

############################# After bundle install #############################
after_bundle do
  rails_command 'db:drop db:create db:migrate'
  generate('tailwindcss:install')
  generate('simple_form:install')
  generate('rspec:install')

  # Git ignore
  ########################################
  append_file '.gitignore', <<~TXT
    # Ignore .env file containing credentials.
    .env*

    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Webpacker / Yarn
  ########################################
  append_file 'app/javascript/packs/application.js', <<~JS

    document.addEventListener('turbolinks:load', () => {
      // Call your functions here
    });
  JS

  # Dotenv
  ########################################
  run 'touch .env'

  inject_into_file 'spec/rails_helper.rb', after: "require 'rspec/rails'\n" do
    <<-RUBY
require 'factory_bot'
require 'database_cleaner'
    RUBY
  end

  inject_into_file 'spec/rails_helper.rb', after: "RSpec.configure do |config|\n" do
    <<-RUBY
  # Avoid having to write FactoryBot.create
  config.include FactoryBot::Syntax::Methods

    RUBY
  end

  gsub_file(
    'spec/rails_helper.rb',
    /config.use_transactional_fixtures = true/,
    'config.use_transactional_fixtures = false'
  )

  gsub_file(
    'spec/rails_helper.rb',
    /^# Dir.+$/,
    "Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }"
  )

  gsub_file(
    '.rspec',
    /--require spec_helper/,
    "--require spec_helper\n--format Fuubar\n--color\n--profile"
  )

  run "mkdir -p spec/support/matchers"
  file "spec/support/matchers/shoulda_matchers.rb", <<~RUBY
require 'shoulda/matchers'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec

    # Or, choose the following (which implies all of the above):
    with.library :rails
  end
end
RUBY

#################################### Procfile ##################################
file 'Procfile', <<~YAML
  release: bundle exec rake db:migrate
  web: bundle exec puma -C config/puma.rb
  worker: bundle exec sidekiq -C config/sidekiq.yml
YAML

###################################### Git #####################################
git add: '.'
git commit: "-m 'Start rails project with tailwinded template'"
end
