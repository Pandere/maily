require 'maily/engine'
require 'maily/version'
require 'maily/mailer'
require 'maily/email'

module Maily
  class << self
    attr_accessor :enabled, :allow_edition, :allow_delivery, :available_locales,
                  :base_controller, :http_authorization

    def init!
      self.enabled            = Rails.env.production? ? false : true
      self.allow_edition      = Rails.env.production? ? false : true
      self.allow_delivery     = Rails.env.production? ? false : true
      self.available_locales  = I18n.available_locales
      self.base_controller    = 'ActionController::Base'
      self.http_authorization = nil
    end

    def load_emails_and_hooks
      # Load emails from file system
      Dir[Rails.root.join('**/*_mailer.rb').to_s].each do |mailer|
        next if mailer[/application/]
        klass = path_to_klass(mailer)
        methods = klass.send(:instance_methods, false)
        Maily::Mailer.new(klass, methods)
      end

      # Load hooks
      hooks_file_path = "#{Rails.root}/lib/maily_hooks.rb"
      require hooks_file_path if File.exist?(hooks_file_path)
    end
    
    def path_to_klass(str)
      parts = str.split('/')
      range = ((parts.index('mailers') + 1)..-1)
      
      name = parts[range].join('/').camelize
      klass_name = File.basename(name, '.rb')
      klass_name.camelize.constantize
    end

    def hooks_for(mailer_name)
      mailer = Maily::Mailer.find(mailer_name.underscore)
      yield(mailer) if block_given?
    end

    def setup
      init!
      yield(self) if block_given?
    end

    def allowed_action?(action)
      case action.to_sym
      when :edit
        allow_edition
      when :update
        allow_edition && !Rails.env.production?
      when :deliver
        allow_delivery
      end
    end
  end
end
