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

class Tr8n::Rules::List < Tr8n::Rules::Base
  belongs_to :language
  attributes :type, :keyword, :value

  def self.key
    :list
  end

  # FORM: [one, many]
  # {actors|| likes, like} this story
  def self.transform_params_to_options(params)
    options = {}
    if params[0].index(':')
      params.each do |arg|
        parts = arg.split(':')
        options[parts.first.strip.to_sym] = parts.last.strip
      end
    else # default falback to {|| male, female} or {|| male, female, unknown} 
      if params.size == 2 # doesn't matter
        options[:one] = params[0]
        options[:other] = params[1]
      else
        raise Tr8n::Exception.new("Invalid number of parameters in the transform token #{token}")
      end  
    end
    options    
  end
  
  def evaluate(token)
    return false unless token.kind_of?(Enumerable)
    
    list_size = token_value(token)
    return false if list_size == nil
    list_size = list_size.to_i

    case value
      when "one_element" then
        return true if list_size == 1
      when "at_least_two_elements" then
        return true if list_size >= 2
    end
    
    false
  end
  
end