source 'https://rubygems.org'

ruby "2.2.3"

gem 'rails', '4.2.4'
gem 'pg'
gem 'aws-sdk'
gem 'puma'
gem 'active_model_serializers', "0.10.0.rc3"
gem 'gibberish'
gem 'octokit'
gem 'delayed_job_active_record'
gem 'rails_12factor', group: :production
gem 'slack-notifier'
gem 'pundit'

group :development, :test do
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'dotenv-rails'
  gem 'sqlite3'
end

group :development do
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'guard-rspec'
end

group :test do
  gem 'rspec-rails'
  gem 'rspec-its'
  gem 'factory_girl_rails'
  gem 'vcr'
  gem 'webmock', require: false
end
