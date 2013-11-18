#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
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
  attributes :locale, :label, :context, :precedence

  def initialize(attrs = {})
    super

    if locale
      self.language = self.translation_key.application.language[locale]
    end

    calculate_precedence
  end

  # switches to a new translation key
  def set_translation_key(tkey)
    self.translation_key = tkey
    self.language = tkey.application.language(locale)
  end

  def has_context_rules?
    context and context.any?
  end

  #
  # the precedence is based on the number of fallback rules in the context.
  # a fallback rule is indicated by the keyword "other"
  # the more "others" are used the lower the precedence will be
  #
  # 0 indicates the highest precedence
  #

  def calculate_precedence
    self.precedence = 0
    return unless has_context_rules?

    context.values.each do |rules|
      rules.values.each do |rule_key|
        self.precedence += 1 if rule_key == "other"
      end
    end
  end

  #{
  #    "count" => [{"type" => "number", "key" => "one"}],
  #    "user" => ["type" => "gender", "key" => "male"]
  #}
  #{
  #    "count" => [{"number":"one"}],
  #    "user" => [{"gender":"male"}]
  #}
  # checks if the translation is valid for the given tokens
  def matches_rules?(token_values)
    return true unless has_context_rules?

    context.each do |token_name, rules|
      token_object = Tr8n::Tokens::Data.token_object(token_values, token_name)
      return false unless token_object

      rules.each do |context_key, rule_key|
        next if rule_key == "other"

        context = language.context_by_keyword(context_key)
        return false unless context

        rule = context.find_matching_rule(token_object)
        return false if rule.nil? or rule.keyword != rule_key
      end
    end
    
    true
  end

end
