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

####################################################################### 
# 
# Decoration Token Forms:
#
# [link: click here]
#
# Decoration Tokens Allow Nesting:
# 
# [link: {count} {_messages}] 
# [link: {count||message}] 
# [link: {count||person, people}] 
# [link: {user.name}] 
#
####################################################################### 
class Tr8n::Tokens::Decoration < Tr8n::Tokens::Base
  
  def self.expression
    /(\[\w+:[^\]]+\])/
  end
  
  def decoration?
    true
  end
  
  def language_rule
    nil
  end
  
  def supports_cases?
    false
  end

  def supports_rules?
    false
  end

  def types
    nil
  end

  def value
    @value ||= begin
      parts = full_name.gsub(/[\]]/, '').split(':')
      vl = parts[1..-1].join(':')
      vl.strip
    end
  end
  
  # return as is
  def prepare_label_for_translator(label)
    label
  end

  # return only the internal part
  def prepare_label_for_suggestion(label, index)
    label.gsub(name, "(#{index})")
  end
    
  def handle_default_decorations(translation_key, token_name, token_value, token_values)
    unless translation_key.application.default_decoration_tokens[token_name]
      raise Tr8n::Exception.new("Invalid decoration token value")
    end

    default_decoration = translation_key.application.default_decoration_tokens[token_name].clone
    decoration_token_values = token_values[token_name.to_sym] || []
    
    if decoration_token_values.is_a?(Array)
      params = [token_value, decoration_token_values].flatten
      params.each_with_index do |param, index|
        default_decoration.gsub!("{$#{index}}", param.to_s)
      end

      # clean all the rest of the {$num} params, if any
      param_index = params.size
      while default_decoration.index("{$#{param_index}}")
        default_decoration.gsub!("{$#{param_index}}", "")
        param_index += 1
      end
    elsif decoration_token_values.is_a?(Hash)
      default_decoration.gsub!("{$0}", token_value.to_s)
      
      decoration_token_values.keys.each do |key|
        default_decoration.gsub!("{$#{key}}", decoration_token_values[key].to_s)
      end
    end
    
    default_decoration
  end  
  
  def substitute(translation_key, language, label, values, options)
    method = values[name_key]
    substitution_value = ""
    
    if method
      if method.is_a?(Proc)
        substitution_value = method.call(value)
      elsif method.is_a?(Array) or method.is_a?(Hash)
        substitution_value = handle_default_decorations(translation_key, name, value, values)
      elsif method.is_a?(String)
        substitution_value = method.to_s.gsub("{$0}", value)
      else
        raise Tr8n::Exception.new("Invalid decoration token value")
      end
    elsif translation_key.application.default_decoration_tokens[name]
      substitution_value = handle_default_decorations(translation_key, name, value, values)
    else
      raise Tr8n::Exception.new("Missing decoration token value")
    end
      
    label.gsub(full_name, substitution_value) 
  end
  
  def sanitized_name
    "[#{name}: ]"
  end
  
end
