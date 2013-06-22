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

class Tr8n::Rules::Base < Tr8n::Base
  belongs_to :language
  attributes :type, :keyword

  def self.key
    raise Tr8n::Exception.new("This method must be implemented in the extending rule") 
  end

  def self.rule_class(type)
    Tr8n.config.rule_class_by_type(type)
  end

  def self.config
    Tr8n.config.rules_engine[key]
  end

  def self.method_name
    config[:object_method]
  end
  
  def self.token_value(token)
    return nil unless token and token.respond_to?(method_name)
    token.send(method_name)
  end

  def token_value(token)
    self.class.token_value(token)
  end

  def self.sanitize_values(values)
    return [] unless values
    values.split(",").collect{|val| val.strip} 
  end
  
  def sanitize_values(values)
    self.class.sanitize_values(values)
  end

  def evaluate(token_value)
    raise Tr8n::Exception.new("This method must be implemented in the extending rule") 
  end
  
  def self.transformable?
    true
  end

  def self.transform_params_to_options(params)
    raise Tr8n::Exception.new("This method must be implemented in the extending rule") 
  end

  def self.transform(token, object, params, language)
    if params.empty?
      raise Tr8n::Exception.new("Invalid form for token #{token}")
    end

    options = transform_params_to_options(params)

    matched_key = nil
    options.keys.each do |keyword|
      next if keyword == :other  # other is a special keyword - don't process it
      rule = language.context_rule_by_type_and_keyword(self.key, keyword)

      unless rule
        raise Tr8n::Exception.new("Invalid rule name #{keyword} for transform token #{token}")
      end

      if rule.evaluate(object)
        matched_key = keyword.to_sym
        break
      end
    end

    unless matched_key
      return options[:other] if options[:other]
      raise Tr8n::Exception.new("No rules matched for transform token #{token} : #{options.inspect} : #{object}")
    end

    options[matched_key]
  end
end
