source "https://rubygems.org"

repo_name = "gem_activerecord_hoarder"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'aws-sdk-s3', '~> 1'

group :test do
  gem 'factory_girl_rails'
  gem 'sqlite3'
  gem 'timecop'
end

group :development do
  gem 'sqlite3'
end

gemspec
