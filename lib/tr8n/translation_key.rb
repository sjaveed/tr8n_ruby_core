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

class Tr8n::TranslationKey < Tr8n::Base  
  belongs_to :application, :language
  attributes :id, :key, :label, :description, :locale, :level, :locked
  has_many :translations # hashed by language

  def initialize(attrs = {})
    super

    self.attributes[:key] ||= self.class.generate_key(label, description)
    self.attributes[:locale] ||= Tr8n.config.block_options[:locale] || application.default_locale
    self.attributes[:language] ||= application.language(locale)
    self.attributes[:translations] = {}

    if hash_value(attrs, :translations)
      hash_value(attrs, :translations).each do |locale, translations|
        language = application.language(locale)

        self.attributes[:translations][locale] ||= []

        translations.each do |translation_hash|
          translation = Tr8n::Translation.new(translation_hash.merge(:translation_key => self, :locale => language.locale))
          self.attributes[:translations][locale] << translation
        end
      end
    end
  end

  def self.cache_key(label, description, locale)
    "t@_[#{locale}]_[#{generate_key(label, description)}]";
  end

  def self.generate_key(label, desc = "")
    "#{Digest::MD5.hexdigest("#{label};;;#{desc}")}~"[0..-2].to_s
  end

  def has_translations_for_language?(language)
    translations and translations[language.locale] and translations[language.locale].any?
  end

  def fetch_translations(language, options = {})
    if self.id and has_translations_for_language?(language)
      return self
    end

    if options[:dry] or Tr8n.config.block_options[:dry]
      return application.cache_translation_key(self)
    end

    tkey = application.post("translation_key/translations",
                            {:key => key, :label => label, :description => description, :locale => language.locale},
                            {:class => Tr8n::TranslationKey, :attributes => {:application => application}})

    application.cache_translation_key(tkey)
  end

  # switches to a new application
  def set_application(app)
    self.application = app
    translations.values.each do |locale_translations|
      locale_translations.each do |t|
        t.set_translation_key(self)
      end
    end
    self
  end

  def set_language_translations(language, translations)
    translations.each do |translation|
      translation.locale = language.locale
      translation.set_translation_key(self)
    end
    self.translations[language.locale] = translations
  end

  # adds new language translations for a specific locale
  def set_translations(language, new_translations)
    new_translations.each do |t|
      t.set_translation_key(self)
    end
    self.translations[language.locale] = new_translations
  end

  def translations_for_language(language)
    return [] unless self.translations
    self.translations[language.locale] || []
  end

  def find_first_valid_translation(language, token_values)
    translations = translations_for_language(language)

    translations.sort! { |x,y| y.precedence <=> x.precedence }

    translations.each do |translation|
      return translation if translation.matches_rules?(token_values)
    end
    
    nil
  end

  def translate(language, token_values = {}, options = {})
    if Tr8n.config.disabled? or language.locale == self.attributes[:language].locale
      return substitute_tokens(label, token_values, language, options.merge(:fallback => false))
    end

    translation = find_first_valid_translation(language, token_values)

    if translation
      translated_label = substitute_tokens(translation.label, token_values, translation.language, options)
      return Tr8n::Decorators::Base.decorator(self, translation.language, translated_label, options.merge(:translated => true)).decorate
    end

    translated_label = substitute_tokens(label, token_values, self.attributes[:language], options)
    Tr8n::Decorators::Base.decorator(self, self.attributes[:language], translated_label, options.merge(:translated => false)).decorate
  end

  ###############################################################
  ## Token Substitution
  ###############################################################

  # Returns an array of decoration tokens from the translation key
  def decoration_tokens
    @decoration_tokens ||= begin
      dt = Tr8n::Tokens::DecorationTokenizer.new(label)
      dt.parse
      dt.tokens
    end
  end

  # Returns an array of data tokens from the translation key
  def data_tokens
    @data_tokens ||= begin
      dt = Tr8n::Tokens::DataTokenizer.new(label)
      dt.tokens
    end
  end

  def data_tokens_names_map
    @data_tokens_names_map ||= begin
      map = {}
      data_tokens.each do |token|
        map[token.name] = token
      end
      map
    end
  end

  # if the translations engine is disabled
  def self.substitute_tokens(label, token_values, language, options = {})
    return label.to_s if options[:skip_substitution] 
    Tr8n::TranslationKey.new(:label => label.to_s).substitute_tokens(label.to_s, token_values, language, options)
  end

  def substitute_tokens(translated_label, token_values, language, options = {})
    if translated_label.index('{')
      dt = Tr8n::Tokens::DataTokenizer.new(translated_label, token_values, :allowed_tokens => data_tokens_names_map)
      translated_label = dt.substitute(language, options)
    end

    return translated_label unless translated_label.index('[')
    dt = Tr8n::Tokens::DecorationTokenizer.new(translated_label, token_values, :allowed_tokens => decoration_tokens)
    dt.substitute
  end

end
