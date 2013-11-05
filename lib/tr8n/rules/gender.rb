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

class Tr8n::Rules::Gender < Tr8n::Rules::Base
  belongs_to :language
  attributes :type, :keyword, :operator, :value

  def self.key
    :gender
  end

  def self.gender_object_value_for(type)
    Tr8n.config.rules_engine[:gender][:method_values][type.to_sym]
  end

  def gender_object_value_for(type)
    self.class.gender_object_value_for(type)
  end
  
  # FORM: [male, female(, unknown)]
  # {user | registered on}
  # {user | he, she}
  # {user | he, she, he/she}
  # {user | male: he, female: she, unknown: he/she}
  # {user | female: she, other: he}
  def self.default_transform_options(params, token)
    options = {}
    if params.size == 1 # doesn't matter
      options[:other] = params[0]
    elsif params.size == 2 # {|| singular}
      options[:male] = params[0]
      options[:female] = params[1]
      options[:other] = "#{params[0]}/#{params[1]}"
    elsif params.size == 3
      options[:male] = params[0]
      options[:female] = params[1]
      options[:other] = params[2]
    else
      raise Tr8n::Exception.new("Invalid number of parameters in the transform token #{token}")
    end  
    options    
  end
  
  def evaluate(token)
    token_value = token_value(token)
    return false unless token_value
    
    if operator == "is"
      return true if token_value == gender_object_value_for(value)
    end

    if operator == "is_not"
      return true if token_value != gender_object_value_for(value)
    end
    
    false    
  end
  
end