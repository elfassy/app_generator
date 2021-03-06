# http://guides.rubyonrails.org/rails_application_templates.html
require "open-uri"
require "json"

@master_url = 'https://raw.githubusercontent.com/elfassy/app_generator/master'

whoami = run('whoami', capture: true).strip

run "git add . > /dev/null"
run "git commit -m 'raw rails' > /dev/null"

# Remove files
remove_file 'app/views/layouts/application.html.erb'
remove_file "README.rdoc"
remove_file ".gitignore"
run "mv app/assets/stylesheets/application.css app/assets/stylesheets/application.scss"

# empty_directory_with_keep_file 'test/factories'
empty_directory 'test/support'

# Replace with template files
JSON.parse(open('https://api.github.com/repos/elfassy/app_generator/git/trees/master?recursive=1').read)['tree'].select{|x| x["type"] != 'tree'}.map{|x| x['path']}.each do |path|
  next unless file_path = path.split('templates/')[1]
  remove_file file_path
  get "#{@master_url}/templates/#{file_path}", file_path
end

#modify application.rb
gsub_file 'config/application.rb', /\#\ config\.time_zone\ \=\ \'Central\ Time\ \(US\ \&\ Canada\)\'/, "config.time_zone = 'Eastern Time (US & Canada)'"
gsub_file 'config/application.rb', /(\n\s*end\nend)/, <<-EOS

    # Background Jobs
    config.active_job.queue_adapter = :sidekiq

    # Rack attack gem
    config.middleware.use Rack::Attack

    # Email default url host
    config.action_mailer.default_url_options = { :host => Rails.configuration.x.host }
\\1

EOS

# modify production.rb
gsub_file 'config/environments/production.rb', /\#\ (config\.action_dispatch\.x_sendfile_header\ \=\ \'X-Accel-Redirect\')/, '\1'
gsub_file 'config/environments/production.rb', /\#\ (config\.cache_store\ \=\ \:mem_cache_store)/, '\1'
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

gsub_file 'config/environments/production.rb', /(config\.log_level\ \=\ \:)debug/, '\1error'

# secrets
# run 'cp config/secrets.yml config/secrets_example.yml'

# bundle (before database creation)
bundle_command('update') # also does bundle install

# Create database
run 'cp config/database.yml config/database_example.yml'
db_username = whoami
db_password = ""
gsub_file 'config/database.yml', /\{\{db_name\}\}/, app_name if app_name.present?
gsub_file 'config/database.yml', /\{\{db_username\}\}/, db_username if db_username.present?
gsub_file 'config/database.yml', /\{\{db_password\}\}/, db_password

rake('db:create:all')

route "get '/robots', to: 'application\#robots', format: 'txt'"
remove_file 'public/robots.txt'
empty_directory_with_keep_file 'app/views/application'

generate :controller, "main index"
route "root to: 'main\#index'"

remove_file 'public/index.html'

gsub_file 'README.md', /\{\{app_name\}\}/, app_name if app_name.present?

run "bundle exec rails generate simple_form:install"
gsub_file 'config/initializers/simple_form.rb', /\#\ (config\.default_form_class\ \=\ )nil/, '\1"form"'
gsub_file 'config/initializers/simple_form.rb', /(config\.button_class\ =\ )\'btn\'/, '\1"button"'
gsub_file 'config/initializers/simple_form.rb', /(config\.wrappers\ \:default,\ class\:\ )\:input/, '\1"form-item"'

run "git add . > /dev/null"
run "git commit -m 'app generator'  > /dev/null"

