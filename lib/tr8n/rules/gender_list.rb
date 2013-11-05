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

class Tr8n::Rules::GenderList < Tr8n::Rules::Base
  belongs_to :language
  attributes :type, :keyword, :value1, :multipart, :part2, :value2
    
  def self.key
    :gender_list
  end

  def self.male_female_occupants(arr)
    has_male = false  
    has_female = false
    has_unknown = false
    has_neutral = false

    arr.each do |object|
      object_gender = Tr8n::Rules::Gender.token_value(object)
      return [false, false] unless object_gender
      has_male = true if object_gender == Tr8n::Rules::Gender.gender_object_value_for("male")
      has_female = true if object_gender == Tr8n::Rules::Gender.gender_object_value_for("female")
      has_unknown = true if object_gender == Tr8n::Rules::Gender.gender_object_value_for("unknown")
      has_neutral = true if object_gender == Tr8n::Rules::Gender.gender_object_value_for("neutral")
    end  
    
    [has_male, has_female, has_unknown, has_neutral]
  end
  
  def male_female_occupants(arr)
    self.class.male_female_occupants(arr)
  end
  
  # FORM: [one element male, one element female, at least two elements]
  # or: [one element, at least two elements]
  # {actors:gender_list|| likes, like} this story
  def self.default_transform_options(params, token)
    options = {}
    if params.size == 2 # doesn't matter
      options[:one] = params[0]
      options[:other] = params[1]
    else
      raise Tr8n::Exception.new("Invalid number of parameters in the transform token #{token}")
    end  
    options    
  end

  def multipart?
    self.multipart == 'true'
  end

  def one_element?
    value1 == 'one_element'
  end

  def at_least_two_elements?
    value1 == 'at_least_two_elements'
  end

  def evaluate(token)
    return false unless token.kind_of?(Enumerable)
    
    list_size = token_value(token)
    return false unless list_size
    
    list_size = list_size.to_i
    return false if list_size == 0

    has_male, has_female, has_unknown, has_neutral = male_female_occupants(token)
    
    if one_element?
      return false unless list_size == 1
      return true unless multipart?

      if part2 == "is"
        return true if value2 == "male"    and has_male
        return true if value2 == "female"  and has_female
        return true if value2 == "unknown" and has_unknown
        return true if value2 == "neutral" and has_neutral
        return false
      end

      if part2 == "is_not"
        return true if value2 == "male"    and !has_male
        return true if value2 == "female"  and !has_female
        return true if value2 == "unknown" and !has_unknown
        return true if value2 == "neutral" and !has_neutral
        return false
      end
      
      return false
    end
    
    if at_least_two_elements?
      return false unless list_size >= 2
      return true unless multipart?
    
      if part2 == "are"
        return true if value2 == "all_male" and (has_male and !(has_female or has_unknown or has_neutral))
        return true if value2 == "all_female" and (has_female and !(has_male or has_unknown or has_neutral))
        return true if value2 == "mixed" and ((has_male and (has_female or has_unknown or has_neutral)) or (has_female and (has_male or has_unknown or has_neutral)))
        return false
      end

      if part2 == "are_not"
        return true if value2 == "all_male" and (has_male and (has_female or has_unknown or has_neutral)) 
        return true if value2 == "all_female" and (has_female and (has_male or has_unknown or has_neutral)) 
        return true if value2 == "mixed" and ((has_male and !(has_female or has_unknown or has_neutral)) or (has_female and !(has_male or has_unknown or has_neutral)))
        return false
      end
      
      return false
    end
    
    false
  end
  
end