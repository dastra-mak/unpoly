# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
Rails.application.config.assets.paths += Dir["#{Rails.root}/vendor/asset-libs/*"].sort_by { |dir| -dir.size }

# Precompile additional assets.
Rails.application.config.assets.precompile += %w( application.js application.css )
Rails.application.config.assets.precompile += %w( jasmine_specs.js jasmine_specs.css )
Rails.application.config.assets.precompile += %w( integration_test.js integration_test.css )
Rails.application.config.assets.precompile += %w( bootstrap_manifest.js bootstrap_manifest.css )

# Precompile jQuery versions from jquery-rails individually, so we can include them as individual <script> tags
Rails.application.config.assets.precompile += %w( jquery.js jquery2.js jquery3.js )

# Precompile Bootstrap bindings individually, so we can include them as individual <script> tags
Rails.application.config.assets.precompile += %w( unpoly-bootstrap3.js unpoly-bootstrap3.css )
