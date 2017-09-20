Rails.application.config.generators do |g|
  # MiniTest
  g.test_framework :minitest

  # Mute Rails
  ## stop Rails from generating empty asset files for every controller
  ## stop Rails from creating empty helper files
  g.helper false
  g.assets false
  g.view_specs false
end
