# http://guides.rubyonrails.org/rails_application_templates.html

@master_url = 'https://raw.githubusercontent.com/elfassy/sb_app_generator/master'

whoami = run('whoami', capture: true).strip

def get_from_master_repo(file_path)
    remove_file file_path
    get "#{@master_url}/templates/#{file_path}", file_path
end
def get_from_file(file_path)
    remove_file file_path
    get "#{File.expand_path File.dirname(__FILE__)}/templates/#{file_path}", file_path
end

# Layout
remove_file 'app/views/layouts/application.html.erb'
get_from_master_repo 'app/views/layouts/application.html.slim'

# readme
remove_file "README.rdoc"
get_from_master_repo 'README.md'
gsub_file 'README.md', /\{\{app_name\}\}/, app_name if app_name.present?

# test
empty_directory_with_keep_file 'test/factories'
empty_directory 'test/support'
get_from_master_repo 'test/test_helper.rb'
get_from_master_repo 'Guardfile'
get_from_master_repo 'config/initializers/generators.rb'

# gemfile
get_from_master_repo 'Gemfile'

# Gem initializers
get_from_master_repo 'config/initializers/time_formats.rb'
get_from_master_repo 'config/initializers/rack-attack.rb'

# gitignore
remove_file ".gitignore"
get "#{@master_url}/git/.gitignore", '.gitignore' 

# Spring
get_from_master_repo '.envrc'

#modify application.rb
gsub_file 'config/application.rb', /\#\ config\.time_zone\ \=\ \'Central\ Time\ \(US\ \&\ Canada\)\'/, "config.time_zone = 'Eastern Time (US & Canada)'"
gsub_file 'config/application.rb', /(\n\s*end\nend)/, <<-EOS

    # Rack attack gem
    config.middleware.use Rack::Attack

    # Email default url host
    config.action_mailer.default_url_options = { :host => Rails.configuration.x.host }
\\1

EOS

# modify production.rb
gsub_file 'config/environments/production.rb', /\#\ (config\.action_dispatch\.x_sendfile_header\ \=\ \'X-Accel-Redirect\')/, '\1'
gsub_file 'config/environments/production.rb', /\#\ (config\.cache_store\ \=\ \:mem_cache_store)/, '\1'
gsub_file 'config/environments/production.rb', /\#\ (config\.action_dispatch\.rack_cache\ \=\ true)/, '\1'
gsub_file 'config/environments/production.rb', /(\n\s*end)/, <<-EOS

  #   config.action_mailer.delivery_method = :smtp 
  #   ActionMailer::Base.smtp_settings = {
  #     :user_name => Env.smtp.user_name,
  #     :password => Env.smtp.password,
  #     :domain => Env.host,
  #     :address => Env.smtp.address,
  #     :port => 587,
  #     :authentication => :plain,
  #     :enable_starttls_auto => true
  #   }
  
  #   # Automatic email on exception
  #   config.middleware.use ExceptionNotification::Rack,
  #   :email => {
  #     :email_prefix => "[site_name Error] ",
  #     :sender_address => %{"Error notifier" <noreply@smashingboxes.com>},
  #     :exception_recipients => %w{your_name@smashingboxes.com}
  #   }
\\1
EOS

gsub_file 'config/environments/test.rb', /(\n\s*end)/, <<-EOS
  # Custom app configs
  config.x.host = 'localhost:3000'
EOS

gsub_file 'config/environments/production.rb', /(\n\s*end)/, <<-EOS
  # Custom app configs
  config.x.host = 'yourapp.com'
EOS

gsub_file 'config/environments/development.rb', /(\n\s*end)/, <<-EOS
  # Custom app configs
  config.x.host = 'localhost:3000'

  # Email
  config.action_mailer.delivery_method = :letter_opener

  #Uncomment to use absolute paths for assets, added for using asset pipeline in email templates.
  #Sets config.action_controller.asset_host and config.action_mailer.asset_host
  #config.asset_host = 'http://localhost:3000'

\\1
EOS

run 'cp config/environments/production.rb config/environments/staging.rb'
gsub_file 'config/environments/production.rb', /(config\.log_level\ \=\ \:)info/, '\1error'

# modify assets
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.css.scss"
get_from_master_repo 'app/assets/javascripts/application.js'

# secrets
run 'cp config/secrets.yml config/secrets_example.yml'

# annotation
get_from_master_repo 'lib/tasks/auto_annotate_models.rake'

# Public pages
get_from_master_repo 'public/404.html'
get_from_master_repo 'public/422.html'
get_from_master_repo 'public/500.html'

# Locales
get_from_master_repo 'config/locales/en.yml'

# bundle (before database creation)
bundle_command('update') # also does bundle install

get_from_master_repo 'Procfile'

# Create database
get_from_master_repo 'config/database.yml'
run 'cp config/database.yml config/database_example.yml'
# db_username = ask("Database Username [#{whoami}]: ").underscore
# db_password = ask('Database Password []: ').underscore
# db_username = db_username.empty? ? whoami : db_username
db_username = whoami
db_password = ""
gsub_file 'config/database.yml', /\{\{db_name\}\}/, app_name if app_name.present?
gsub_file 'config/database.yml', /\{\{db_username\}\}/, db_username if db_username.present?
gsub_file 'config/database.yml', /\{\{db_password\}\}/, db_password

rake('db:create:all')

# Robots.txt with sitemap
route "get '/robots', to: 'application\#robots', format: 'txt'"
remove_file 'public/robots.txt'
empty_directory_with_keep_file 'app/views/application'
get_from_master_repo 'app/views/application/robots.text.erb'
get_from_master_repo 'config/sitemap.rb'

if yes? 'Do you want to generate a root controller? [n]'
  name = ask('What should it be called? [main]').underscore
  name = "main" if name.empty?
  generate :controller, "#{name} index"
  route "root to: '#{name}\#index'"
end
remove_file 'public/index.html'

git :init
run "git add . > /dev/null"
run "git rm config/secrets.yml"
run "git commit -m 'initial commit'  > /dev/null"

