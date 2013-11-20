#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

module Tr8n

  def self.config
    @config ||= Tr8n::Config.new
  end

  # config class can be set
  def self.config=(config)
    @config = config
  end

  # Acts as a global singleton that holds all Tr8n configuration
  # The class can be extended with a different implementation, as long as the interface is supported
  class Config < Tr8n::Base
    thread_safe_attributes :application, :current_user, :current_language, :current_translator, :current_source, :current_component
    thread_safe_attributes :block_options

    def root
      @root ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end

    def env
      'defaults'
    end

    def defaults
      @defaults ||= Tr8n::Utils.load_yaml("#{root}/config/config.yml", env)
    end

    def enabled?
      hash_value(defaults, "enabled")
    end

    def disabled?
      not enabled?
    end

    #########################################################
    ## Application
    #########################################################

    def host
      hash_value(defaults, "application.host")
    end

    def app_key
      hash_value(defaults, "application.key")
    end

    def app_secret
      hash_value(defaults, "application.secret")
    end

    def init_application
      Tr8n::Application.init(host, app_key, app_secret)
      self.current_source = "/tr8n/core"
    end

    def default_locale
      return application.default_locale if application
      hash_value(defaults, "default_locale")
    end

    def default_language
      return Tr8n::Language.new(:locale => default_locale, :default => true) if disabled?
      application.language(default_locale)
    end

    def default_level
      return application.default_level if application
      hash_value(defaults, "default_level")
    end

    def reset
      self.application = nil
      self.current_user = nil
      self.current_language = nil
      self.current_translator = nil
      self.current_source = nil
      self.current_component = nil
      self.block_options = nil
    end

    #########################################################
    ## Logger
    #########################################################

    def logger_enabled?
      hash_value(defaults, "logger.enabled")
    end

    def log_path
      ".#{hash_value(defaults, "logger.path")}"
    end

    #########################################################
    ## Cache
    #########################################################

    def cache_enabled?
      hash_value(defaults, "cache.enabled")
    end

    def cache_path
      "#{root}#{hash_value(defaults, "cache.path")}"
    end

    def cache_adapter
      hash_value(defaults, "cache.adapter")
    end

    def cache_version
      hash_value(defaults, "cache.version")
    end

    def cache_host
      hash_value(defaults, "cache.host")
    end

    #########################################################
    ## Rules Engine
    #########################################################

    def context_rules
      @context_rules ||= {
          "number" => {
              "variables" => {
              }
          },
          "gender" => {
              "variables" => {
                  "@gender" => "gender",
              }
          },
          "genders" => {
              "variables" => {
                  "@genders" => lambda{|list| list.collect do |u|
                      u.is_a?(Hash) ? (u["gender"] || u[:gender]) : u.gender
                    end
                  },
                  "@size" => lambda{|list| list.size}
              }
          },
          "date" => {
              "variables" => {
              }
          },
          "time" => {
              "variables" => {
              }
          },
          "list" => {
              "variables" => {
                  "@count" => lambda{|list| list.size}
              }
          },
      }
    end

    def decorator_class
      Tr8n::Decorators::Default
    end

    def default_data_tokens
      @default_data_tokens ||= Tr8n::Utils.load_yaml("#{@root}/config/tokens/data.yml")
    end

    def default_decoration_tokens
      @default_decoration_tokens ||= Tr8n::Utils.load_yaml("#{@root}/config/tokens/decorations.yml")
    end

    def default_token_value(token_name, type = :data, format = :html)
      return default_data_tokens[format.to_s][token_name.to_s] if type.to_sym == :data
      return default_decoration_tokens[format.to_s][token_name.to_s] if type.to_sym == :decoration
    end

    #########################################################
    ## Block Options
    #########################################################

    def block_options
      (Thread.current[:block_options] ||= []).last || {}
    end

    def with_block_options(opts)
      Thread.current[:block_options] ||= []
      Thread.current[:block_options].push(opts)
      if block_given?
        ret = yield
      end
      Thread.current[:block_options].pop
      ret
    end

    def current_source_from_block_options
      arr = Thread.current[:block_options] || []
      arr.reverse.each do |opts|
        return application.source_by_key(opts[:source]) unless opts[:source].blank?
      end
      nil
    end

    def current_component_from_block_options
      arr = Thread.current[:block_options] || []
      arr.reverse.each do |opts|
        return application.component_by_key(opts[:component]) unless opts[:component].blank?
      end
      Tr8n.config.current_component
    end

    #########################################################
    ## Localization
    #########################################################

    def localization
      hash_value(defaults, "localization")
    end

    def strftime_symbol_to_token(symbol)
      {
          "%a" => "{short_week_day_name}",
          "%A" => "{week_day_name}",
          "%b" => "{short_month_name}",
          "%B" => "{month_name}",
          "%p" => "{am_pm}",
          "%d" => "{days}",
          "%e" => "{day_of_month}",
          "%j" => "{year_days}",
          "%m" => "{months}",
          "%W" => "{week_num}",
          "%w" => "{week_days}",
          "%y" => "{short_years}",
          "%Y" => "{years}",
          "%l" => "{trimed_hour}",
          "%H" => "{full_hours}",
          "%I" => "{short_hours}",
          "%M" => "{minutes}",
          "%S" => "{seconds}",
          "%s" => "{since_epoch}"
      }[symbol]
    end

    def default_day_names
      hash_value(defaults, "localization.default_day_names")
    end

    def default_abbr_day_names
      hash_value(defaults, "localization.default_abbr_day_names")
    end

    def default_month_names
      hash_value(defaults, "localization.default_month_names")
    end

    def default_abbr_month_names
      hash_value(defaults, "localization.default_abbr_month_names")
    end

    def default_date_formats
      hash_value(defaults, "localization.custom_date_formats")
    end

  end
end
