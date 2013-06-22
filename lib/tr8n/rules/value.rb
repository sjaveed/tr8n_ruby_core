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

class Tr8n::Rules::Value < Tr8n::Rules::Base
  belongs_to :language
  attributes :type, :keyword
  attributes :operator, :value

  def self.key
    :value
  end

  def self.transformable?
    false
  end

  def evaluate(token)
    token_value = token_value(token)
    return false unless token_value

    token_value = token_value.gsub(/<\/?[^>]*>/, "")
    values = sanitize_values(value)
    
    case operator
      when "starts_with" 
        values.each do |value|
          return true if token_value.to_s =~ /^#{value.to_s}/  
        end
        return false
      when "does_not_start_with"         
        values.each do |value|
          return false if token_value.to_s =~ /^#{value.to_s}/  
        end
        return true
      when "ends_in"
        values.each do |value|
          return true if token_value.to_s =~ /#{value.to_s}$/  
        end
        return false
      when "does_not_end_in"         
        values.each do |value|
          return false if token_value.to_s =~ /#{value.to_s}$/  
        end
        return true
      when "is"         
        return values.include?(token_value)
      when "is_not"        
        return !values.include?(token_value)
    end
    
    false
  end

end
