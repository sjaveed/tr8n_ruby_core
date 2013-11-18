#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
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

require 'json'

module Tr8n
  def self.config
    @config ||= Tr8n::Config.new
  end
  # config class can be set
  def self.config=(config)
    @config = config
  end
end

# Acts as a global singleton that holds all Tr8n configuration
# The class can be extended with a different implementation, as long as the interface is supported
class Tr8n::Config < Tr8n::Base
  thread_safe_attributes :application, :default_locale
  thread_safe_attributes :current_user, :current_language, :current_translator, :current_source, :current_component, :current_translation_keys
  thread_safe_attributes :block_options  

  def root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end

  def enabled?
    true
  end

  def disabled?
    not enabled?
  end

  def enable_logger?
    false
  end

  def log_path
    "./log/tr8n.log"
  end

  def enable_caching?
    false
  end

  def cache_store
    nil
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
    {
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

  def default_data_tokens
    @default_data_tokens ||= Tr8n::Utils.load_yml("/config/tokens/data.yml")
  end

  def default_decoration_tokens
    @default_decoration_tokens ||= Tr8n::Utils.load_yml("/config/tokens/decorations.yml")
  end

  def default_token_value(token_name, type = :data, format = 'html')
    return default_data_tokens[format.to_s][token_name.to_s] if type == :data
    return default_decoration_tokens[format.to_s][token_name.to_s] if type == :decoration
  end

end
