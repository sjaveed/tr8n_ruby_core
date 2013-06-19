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

class Tr8n::Language < Tr8n::Base
  attributes  :application, :locale, :name, :english_name, :native_name, :right_to_left, :enabled
  attributes  :google_key, :facebook_key, :myheritage_key
  attributes  :context_rules, :language_cases

  def initialize(attrs = {})
    super

    if attrs['context_rules']
      self.attributes[:context_rules] = {}

      attrs['context_rules'].each do |rule_class, hash|
        self.attributes[:context_rules][rule_class] ||= {}
        hash.each do |keyword, rule|
          self.attributes[:context_rules][rule_class][keyword] = Tr8n::Rules::Base.rule_class(rule_class).new(rule)
        end
      end
    end

    if attrs['language_cases']
      self.attributes[:language_cases] = attrs['language_cases'].collect{ |lcase| Tr8n::LanguageCase.new(lcase) }
    end
  end

  def context_rules_by_type_and_keyword(type, keyword)
    return nil unless self.context_rules
    return nil unless self.context_rules[type.to_s]
    self.context_rules[type.to_s][keyword.to_s]
  end

  def case_keyword_maps
    @case_keyword_maps ||= begin
      hash = {} 
      language_cases.each do |lcase| 
        hash[lcase.keyword] = lcase
      end
      hash
    end
  end
  
  def case_for(case_keyword)
    case_keyword_maps[case_keyword]
  end
  
  def valid_case?(case_keyword)
    case_for(case_keyword) != nil
  end
  
  def full_name
    return english_name if english_name == native_name
    "#{english_name} - #{native_name}"
  end

  def dir
    right_to_left? ? "rtl" : "ltr"
  end
  
  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end
  
  def translate(label, desc = "", tokens = {}, options = {})
    raise Tr8n::Exception.new("The label #{label} is being translated twice") if label.tr8n_translated?

    unless Tr8n::Config.enabled?
      return Tr8n::TranslationKey.substitute_tokens(label, tokens, options, self).tr8n_translated.html_safe
    end

    translation_key = Tr8n::TranslationKey.fetch_or_register(label, desc, options.merge(:application => application))
    translation_key.translate(self, tokens.merge(:viewing_user => Tr8n::Config.current_user), options).tr8n_translated.html_safe
  end
  alias :tr :translate

  def trl(label, desc = "", tokens = {}, options = {})
    tr(label, desc, tokens, options.merge(:skip_decorations => true))
  end

end
