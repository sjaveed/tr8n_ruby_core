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

class Tr8n::LanguageCaseRule < Tr8n::Base
  attributes :gender, :operator, :multipart, :part1, :value1, :part2, :value2, :operation, :operation_value

  def evaluate(object, value)
    value = value.to_s

    if ["male", "female", "unknown", "neutral"].include?(self.gender)
      object_gender = Tr8n::GenderRule.gender_token_value(object)
      return false if self.gender == "male"    and object_gender != Tr8n::Rules::Gender.gender_object_value_for("male")
      return false if self.gender == "female"  and object_gender != Tr8n::Rules::Gender.gender_object_value_for("female")
      return false if self.gender == "unknown" and object_gender != Tr8n::Rules::Gender.gender_object_value_for("unknown")
    end    
  
    result1 = evaluate_part(value, 1)
    if self.multipart?
      result2 = evaluate_part(value, 2)
      return false if self.operator == "and" and !(result1 and result2)
      return false if self.operator == "or"  and !(result1 or result2)
    end  
    
    result1
  end
  
  def evaluate_part(token_value, index)
    values = sanitize_values(self.attributes["value#{index}"])

    case self.attributes["part#{index}"]
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
  
  def apply(value)
    value = value.to_s
    values = sanitize_values(self.value1)
    regex = values.join('|')
    case self.operation
      when "replace" 
        if self.part1 == "starts_with"
          return value.gsub(/\b(#{regex})/, self.operation_value)
        elsif self.part1 == "is"
          return definition["operation_value"]
        elsif self.part1 == "ends_in"
          return value.gsub(/(#{regex})\b/, self.operation_value)
        end
      when "prepand" 
        return "#{self.operation_value}#{value}"
      when "append"        
        return "#{value}#{self.operation_value}"
    end
    
    value
  end
  
  def sanitize_values(values)
    return [] unless values
    values.split(",").collect{|val| val.strip} 
  end
  
end