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
  # Run rails dev:cache to toggle caching.
  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      "Cache-Control" => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  config.action_mailer.perform_caching = false
  config.action_mailer.default_url_options = { host: "localhost:5000", utm_source: "dev", utm_medium: "email", utm_campaign: "default" }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  if ENV["DEVELOPMENT_SMTP_USER_NAME"].present?
    config.action_mailer.smtp_settings = {
      user_name: ENV["DEVELOPMENT_SMTP_USER_NAME"],
      password: ENV["DEVELOPMENT_SMTP_PASWORD"],
      address: ENV["DEVELOPMENT_SMTP_HOST"],
      domain: ENV["DEVELOPMENT_SMTP_DOMAIN"],
      port: ENV["DEVELOPMENT_SMTP_PORT"],
      authentication: :cram_md5
    }
  else
    config.action_mailer.delivery_method = :letter_opener_web
  end
  config.action_mailer.asset_host = "http://localhost:5000"

  config.active_job.queue_adapter = :delayed_job

  config.action_mailer.perform_caching = false

  config.log_level = :info
  # config.log_level = :debug # debug logs all the SQL queries made by ActiveRecord

  # allows to see debug logs when running with foreman / overmind
  # cf https://github.com/rails/sprockets-rails/issues/376#issuecomment-287560399
  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = config.log_formatter
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

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

  # Check N+1 Queries / Eager loading
  config.after_initialize do
    Bullet.enable = true
    # Bullet.alert = true
    Bullet.rails_logger = true
  end

  # https://github.com/JackC/tod/#activemodel-serializable-attribute-support
  config.active_record.time_zone_aware_types = [:datetime]
end
