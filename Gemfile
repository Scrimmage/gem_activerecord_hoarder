source "https://rubygems.org"

repo_name = "gem_batch_archiving"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'aws-sdk-s3', '~> 1'
gem 'arel'

group :test do
  gem 'factory_girl_rails'
  gem 'sqlite3'
  gem 'timecop'
end

group :development do
  gem 'sqlite3'
end

gemspec
