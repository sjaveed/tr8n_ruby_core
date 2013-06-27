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


class Tr8n::Translation < Tr8n::Base
  belongs_to :translation_key, :language
  attributes :locale, :label, :context

  # switches to a new translation key
  def set_translation_key(tkey)
    self.translation_key = tkey
    self.language = tkey.application.language(locale)
  end

  def token_value_from_hash(token_values, token_name)
    token_value = token_values[token_name.to_sym]
    if token_value.is_a?(Array)
      token_value = token_value.first   
    elsif token_value.is_a?(Hash) 
      token_value = token_value[:object]
    end 
    token_value
  end

  # checks if the translation is valid for the given tokens
  def matches_rules?(token_values)
    return true if context.nil? or context.empty?   # doesn't have any rules

    context.each do |token_name, rules|
      token_value = token_value_from_hash(token_values, token_name)
      rules.each do |rule_def|
        rule = language.context_rule_by_type_and_key(rule_def['type'], rule_def['key'])
        return false unless rule and rule.evaluate(token_value)
      end
    end
    
    true
  end

end
