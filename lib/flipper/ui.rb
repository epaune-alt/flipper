require 'pathname'
require 'rack'
begin
  # Rack 2
  require 'rack/method_override'
rescue LoadError
  require 'rack/methodoverride'
end
require 'rack/protection'

require 'flipper'
require 'flipper/ui/middleware'
require 'flipper/ui/configuration'

module Flipper
  module UI
    class << self
      # These three configuration options have been moved to Flipper::UI::Configuration
      deprecated_configuration_options = %w(application_breadcrumb_href
                                            feature_creation_enabled
                                            feature_removal_enabled)
      deprecated_configuration_options.each do |attribute_name|
        send(:define_method, "#{attribute_name}=".to_sym) do
          raise ConfigurationDeprecated, "The UI configuration for #{attribute_name} has " \
            "deprecated. This configuration option has moved to Flipper::UI::Configuration"
        end

        send(:define_method, attribute_name.to_sym) do
          raise ConfigurationDeprecated, "The UI configuration for #{attribute_name} has " \
            "deprecated. This configuration option has moved to Flipper::UI::Configuration"
        end
      end

      # Public: Set attributes on this instance to customize UI text
      attr_reader :configuration
    end

    def self.root
      @root ||= Pathname(__FILE__).dirname.expand_path.join('ui')
    end

    def self.app(flipper = nil, options = {})
      env_key = options.fetch(:env_key, 'flipper')
      app = ->() { [200, { 'Content-Type' => 'text/html' }, ['']] }
      builder = Rack::Builder.new
      yield builder if block_given?
      #builder.use Rack::Protection
      builder.use ::Rack::Protection::FrameOptions
      builder.use ::Rack::Protection::IPSpoofing
      #builder.use ::Rack::Protection::JsonCsrf
      #builder.use ::Rack::Protection::HttpOrigin
      #builder.use ::Rack::Protection::PathTraversal
      #builder.use ::Rack::Protection::RemoteToken
      #builder.use ::Rack::Protection::SessionHijacking
      #builder.use ::Rack::Protection::XSSHeader
      #builder.use Rack::Protection::AuthenticityToken
      builder.use Rack::MethodOverride
      builder.use Flipper::Middleware::SetupEnv, flipper, env_key: env_key
      builder.use Flipper::Middleware::Memoizer, env_key: env_key
      builder.use Middleware, env_key: env_key
      builder.run app
      klass = self
      builder.define_singleton_method(:inspect) { klass.inspect } # pretty rake routes output
      builder
    end

    # Public: yields configuration instance for customizing UI text
    def self.configure
      yield(configuration)
    end

    def self.configuration
      @configuration ||= ::Flipper::UI::Configuration.new
    end
  end
end
