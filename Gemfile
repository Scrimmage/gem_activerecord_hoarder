source "https://rubygems.org"

repo_name = "gem_batch_archiving"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem 'paranoia'
gem 'aws-sdk', '~> 3'

group :test do
  gem 'factory_girl_rails'
  gem 'pg'
  gem 'timecop'
end

group :development do
  gem 'pg'
end

gemspec
