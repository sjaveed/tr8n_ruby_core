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
    thread_safe_attributes :application
    thread_safe_attributes :current_user, :current_language, :current_translator, :current_source, :current_component, :current_translation_keys
    thread_safe_attributes :block_options

    def root
      @root ||= File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
    end

    def defaults
      @defaults ||= Tr8n::Utils.load_json("#{@root}/config/config.json")
    end

    def enabled?
      hash_value(defaults, "enabled")
    end

    def disabled?
      not enabled?
    end

    def logger_enabled?
      hash_value(defaults, "logger.enabled")
    end

    def log_path
      "#{root}#{hash_value(defaults, "logger.path")}"
    end

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

    def init_application(host, app_key, app_secret)
      self.application = Tr8n::Application.init(host, app_key, app_secret)
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

    def block_options
      (Thread.current[:block_options] ||= []).last || {}
    end

    def decorator_class
      Tr8n::Decorators::Default
    end

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
                  "@genders" => lambda{|list| list.collect{|u| u.gender}},
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

    def default_locale
      return application.default_locale if application
      hash_value(defaults, "default_locale")
    end

    def default_level
      0
    end

    def default_data_tokens
      @default_data_tokens ||= Tr8n::Utils.load_yml("#{@root}/config/tokens/data.yml")
    end

    def default_decoration_tokens
      @default_decoration_tokens ||= Tr8n::Utils.load_yml("#{@root}/config/tokens/decorations.yml")
    end

    def default_token_value(token_name, type = :data, format = 'html')
      return default_data_tokens[format.to_s][token_name.to_s] if type.to_sym == :data
      return default_decoration_tokens[format.to_s][token_name.to_s] if type.to_sym == :decoration
    end

  end
end
