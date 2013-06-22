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

class Tr8n::Rules::Date < Tr8n::Rules::Base
  belongs_to :language
  attributes :type, :keyword, :value

  def self.key
    :date
  end


  # FORM: [past, present, future]
  # This event {date| past: took place, present: is taking place, future: will take place} on {date}.
  def self.transform_params_to_options(params)
    options = {}
    if params[0].index(':')
      params.each do |arg|
        parts = arg.split(':')
        options[parts.first.strip.to_sym] = parts.last.strip
      end
    else # default falback to {|| male, female} or {|| male, female, unknown} 
      if params.size == 3 # doesn't matter
        options[:past] = params[0]
        options[:present] = params[1]
        options[:other] = params[2]
      else
        raise Tr8n::Exception.new("Invalid number of parameters in the transform token #{token}")
      end  
    end
    options    
  end

  def evaluate(token)
    return false unless token.is_a?(Date) or token.is_a?(Time)
    
    token_value = token_value(token)
    return false unless token_value
    
    current_date = Date.today
    
    case value
      when "past" then
          return true if token_value < current_date
      when "present" then
          return true if token_value == current_date
      when "future" then
          return true if token_value > current_date
    end

    false    
  end
  
end