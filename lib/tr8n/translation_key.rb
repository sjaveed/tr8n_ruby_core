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

require 'digest/md5'
# require 'tr8n_client_sdk/api'

class Tr8n::TranslationKey < Tr8n::Base  
  belongs_to :application  
  attributes :id, :key, :label, :description, :locale, :level, :locked
  has_many :translations # hashed by language

  def initialize(attrs = {})
    super
    self.attributes[:key] = self.class.generate_key(label, description).to_s
    self.attributes[:locale] ||= Tr8n.config.default_locale 
    self.attributes[:translations] = {}
    if attrs['translations']
      attrs['translations'].each do |locale, translations|
        language = application.language_by_locale(locale)
        self.attributes[:translations][locale] ||= []
        translations.each do |trn|
          trn = Tr8n::Translation.new(trn.merge(:translation_key => self, :locale => language.locale, :language => language))
          self.attributes[:translations][locale] << trn
        end
      end
    end
  end

  def self.cache_key(key)
    "translation_key_[#{key}]"
  end

  def cache_key
    self.class.cache_key(key)
  end

  def self.generate_key(label, desc = "")
    "#{Digest::MD5.hexdigest("#{label};;;#{desc}")}~"[0..-2]
  end
  
  def language
    @language ||= (locale ? application.language_by_locale(locale) : application.default_language)
  end

  def fetch_translations_for_language(language, options = {})
    return self if self.id and has_translations_for_language?(language)
    return application.cache_translation_key(self) if options[:dry] or Tr8n.config.block_options[:dry]

    tkey = application.post("translation_key/translations", self.to_api_hash.merge(:locale => language.locale), {:class => Tr8n::TranslationKey, :attributes => {:application => application, :language => language}})
    ckey = application.traslation_key_by_key(self.key)
    if ckey 
      ckey.set_language_translations(language, ckey.translations_for_language(language))
    else
      application.cache_translation_key(tkey)
    end

    application.traslation_key_by_key(self.key)
  end

  # switches to a new application
  def set_application(app)
    self.application = app
    translations.each do |locale, locale_translations|
      locale_translations.each do |t|
        t.set_translation_key(self)
      end
    end
    self
  end

  # adds new language translations for a specific locale
  def set_language_translations(language, translations)
    translations = translations.dup
    translations.each do |t|
      t.set_translation_key(self)
    end
    self.translations[t.locale] = translations
  end

  def has_translations_for_language?(language)
    translations and translations[language.locale] and translations[language.locale].any?
  end

  def translations_for_language(language)
    self.translations[language.locale] || []
  end

  def find_first_valid_translation(language, token_values)
    translations_for_language(language).each do |translation|
      return translation if translation.matches_rules?(token_values)
    end
    
    nil
  end

  def translate(language, token_values = {}, options = {})
    if Tr8n.config.disabled? or language.default?
      return substitute_tokens(language, label, token_values, options.merge(:fallback => false))
    end

    translation = find_first_valid_translation(language, token_values)

    if translation
      translated_label = substitute_tokens(language, translation.label, token_values, options)
      return Tr8n::Decorators::Base.decorator(self, language, translated_label, options.merge(:translated => true)).decorate
    end

    # no translation found  
    translated_label = substitute_tokens(application.default_language, label, token_values, options)
    Tr8n::Decorators::Base.decorator(self, language, translated_label, options.merge(:translated => false)).decorate
  end

  ###############################################################
  ## Token Substitution
  ###############################################################

  def tokenized_label
    @tokenized_label ||= Tr8n::TokenizedLabel.new(label)
  end

  def allowed_token?(token)
    return true if tokenized_label.allowed_token?(token)
    # TODO: add support for default data and decoration tokens
    false
  end

  # this is done when the translations engine is disabled
  def self.substitute_tokens(language, label, token_values, options)
    return label.to_s if options[:skip_substitution] 
    Tr8n::TranslationKey.new(:label => label.to_s).substitute_tokens(language, label.to_s, token_values, options)
  end

  def substitute_tokens(language, translated_label, token_values, options)
    processed_label = translated_label.to_s.dup

    # substitute data tokens
    Tr8n::TokenizedLabel.new(processed_label).data_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(self, language, processed_label, token_values, options) 
    end

    # substitute decoration tokens
    Tr8n::TokenizedLabel.new(processed_label).decoration_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(self, language, processed_label, token_values, options) 
    end
    
    processed_label
  end

end
