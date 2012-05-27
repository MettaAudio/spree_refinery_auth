module SpreeRefineryAuth
  class Engine < Rails::Engine
    engine_name 'spree_refinery_auth'

    config.autoload_paths += %W(#{config.root}/lib)
    config.before_initialize do
      Dir.glob("#{config.root}/lib/refinery/*.rb").each do |f|
        require f
      end
    end

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc

    config.to_prepare do
      ::Refinery::AdminController.send :include, ::RestrictRefineryToRefineryUsers
      ::Refinery::AdminController.send :before_filter, :restrict_refinery_to_refinery_users
      [::Refinery::ApplicationController, ::Refinery::AdminController, ::ApplicationController, ::Spree::BaseController].each do |c|
        c.send :include, ::Refinery::AuthenticatedSystem
      end

      Devise.setup do |devise_config|
        devise_config.warden do |manager|
          manager.failure_app = SpreeRefineryAuth::AuthenticationFailureRedirection
        end
      end

    end

    # config.after_initialize do
    #   [::Refinery::ApplicationController, ::ApplicationController].each do |c|
    #     c.send :include, ::Refinery::AuthenticatedSystem
    #   end
    # end
  end
end
