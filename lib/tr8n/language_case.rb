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

class Tr8n::LanguageCase < Tr8n::Base
  belongs_to  :language
  attributes  :keyword, :latin_name, :native_name, :description, :application
  has_many    :rules

  def initialize(attrs = {})
    super
    if attrs['rules']
      self.attributes[:rules] = attrs['rules'].collect{ |rule| Tr8n::LanguageCaseRule.new(rule.merge(:language_case => self)) }
    end
  end

  def apply(object, value, options = {})
    value = value.to_s
    html_tag_expression = /<\/?[^>]*>/
    html_tokens = value.scan(html_tag_expression).uniq
    sanitized_value = value.gsub(html_tag_expression, "")
    
    if application == 'phrase'
      words = [sanitized_value]
    else  
      words = sanitized_value.split(/[\s\/\\]/).uniq
    end
    
    # replace html tokens with temporary placeholders {$h1}
    html_tokens.each_with_index do |html_token, index|
      value = value.gsub(html_token, "{$#{index}}")
    end

    # replace words with temporary placeholders {$w1}
    words.each_with_index do |word, index|
      value = value.gsub(word, "{$w#{index}}")
    end
    
    transformed_words = []
    words.each do |word|
      lcvm = Tr8n::LanguageCaseValueMap.by_language_and_keyword(language, word)
      
      if lcvm
        map_case_value = lcvm.value_for(object, keyword)
        case_value = map_case_value.blank? ? word : map_case_value
      else
        case_rule = evaluate_rules(object, word)
        case_value = case_rule ? case_rule.apply(word) : word 
      end

      transformed_words << decorate_language_case(word, case_value || word, case_rule, options)
    end
    
    # replace back the temporary placeholders with the html tokens  
    transformed_words.each_with_index do |word, index|
      value = value.gsub("{$w#{index}}", word)
    end
    
    # replace back the temporary placeholders with the html tokens  
    html_tokens.each_with_index do |html_token, index|
      value = value.gsub("{$h#{index}}", html_token)
    end
     
    value
  end

  def evaluate_rules(object, value)
    rules.each do |rule|
      return rule if rule.evaluate(object, value)
    end
    nil
  end

  def decorate_language_case(case_map_key, case_value, case_rule, options = {})
    return case_value if options[:skip_decorations]
    return case_value if language.default?
    return case_value if Tr8n.config.current_user
    return case_value unless Tr8n.config.current_translator
    return case_value unless Tr8n.config.current_translator.inline?
    
    "<span class='tr8n_language_case' case_id='#{id}' rule_id='#{case_rule ? case_rule.id : ''}' case_key='#{case_map_key.gsub("'", "\'")}'>#{case_value}</span>"
  end

end
