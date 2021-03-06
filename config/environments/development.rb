# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  config.active_job.queue_adapter = :sidekiq
  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = {
    host: '127.0.0.1:3000'
  }

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Custom configuration
  # Those setting isn't on Rails, we store theme here to access them later on
  # Those need to take care when we update Rails
  # TODO: Update
  config.action_mailer.delivery_method = :smtp
  config.local_proxy_public = ENV.fetch('NGROK', nil)
  config.incident_confirm_location = 1 # How many location need to match in order to confirm that an incident has occured
  config.incident_notification_interval = 10.minutes
  config.telegram_bot = {
    name: 'notydevbot'
  }
  config.slack_bot = {
    scope: 'bot',
    client_id: '51439348069.157091434678',
    redirect_uri: 'http://127.0.0.1:3000/bot/slack',
    client_secret: ENV.fetch('SLACK_CLIENT_SECRET', nil)
  }
  # End custom configuration
end
