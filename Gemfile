source "https://rubygems.org"

repo_name = "gem_batch_archiving"
git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

group :test do
  gem 'pg'
  gem 'factory_girl_rails'
end

group :development do
  gem 'pg'
end

# Specify your gem's dependencies in batch_archiving.gemspec
gemspec
