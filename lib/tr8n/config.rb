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
  attributes :application, :default_locale
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

  def rules_engine
    {
      :number => {
        :class            => Tr8n::Rules::Number,
        :tokens           => ["count", "num", "age", "hours", "minutes", "years", "seconds"],
        :object_method    => "to_i"
      },
      :gender => {
        :class            => Tr8n::Rules::Gender,
        :tokens           => ["user", "profile", "actor", "target"],
        :object_method    => "gender",
        :method_values    =>  {
          :female         => "female",
          :male           => "male",
          :neutral        => "neutral",
          :unknown        => "unknown"
        }
      },
      :gender_list => {   # requires gender rule to be present
        :class            => Tr8n::Rules::GenderList,
        :tokens           => ["users", "profiles", "actors", "targets"],
        :object_method    => "size"
      },
      :list => {
        :class            => Tr8n::Rules::List,
        :tokens           => ["list", "items", "objects", "elements"],
        :object_method    => "size"
      }, 
      :date => {                
        :class            => Tr8n::Rules::Date,
        :tokens           => ["date"],
        :object_method    => "to_date"
      },
      :value => {             
        :class            => Tr8n::Rules::Value,
        :tokens           => "*",
        :object_method    => "to_s"
      }
    }
  end

  def rule_class_by_type(type)
    return nil unless rules_engine[type.to_sym]
    rules_engine[type.to_sym][:class]
  end

  def rule_types_by_token_name(token_name)
    types = []
    sanitized_token_name = token_name.split('_').last.tr('^A-Za-z', '')
    rules_engine.each do |type, config|
      if config[:tokens] == '*' or config[:tokens].include?(sanitized_token_name)
        types << type 
      end
    end
    types
  end

  def token_classes
    {
      'data'        => [Tr8n::Tokens::Data, Tr8n::Tokens::Hidden, Tr8n::Tokens::Method, Tr8n::Tokens::Transform],
      'decoration'  => [Tr8n::Tokens::Decoration] 
    }
  end

  def data_token_classes
    token_classes['data']
  end

  def decoration_token_classes
    token_classes['decoration']
  end
end
