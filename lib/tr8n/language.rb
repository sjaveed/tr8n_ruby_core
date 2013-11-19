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

class Tr8n::Language < Tr8n::Base
  belongs_to  :application
  attributes  :locale, :name, :english_name, :native_name, :right_to_left, :flag_url
  has_many    :contexts, :cases

  def initialize(attrs = {})
    super

    self.attributes[:contexts] = {}
    if hash_value(attrs, :contexts)
      hash_value(attrs, :contexts).each do |key, context|
        self.attributes[:contexts][key] = Tr8n::LanguageContext.new(context.merge(:language => self))
      end
    end

    self.attributes[:cases] = {}
    if hash_value(attrs, :cases)
      hash_value(attrs, :cases).each do |key, lcase|
        self.attributes[:cases][key] = Tr8n::LanguageCase.new(lcase.merge(:language => self))
      end
    end
  end

  def context_by_keyword(keyword)
    hash_value(contexts, keyword)
  end

  def context_by_token_name(token_name)
    contexts.values.detect{|ctx| ctx.applies_to_token?(token_name)}
  end

  def language_case_by_keyword(keyword)
    cases[keyword]
  end

  def has_definition?
    contexts.any?
  end

  def default?
    return true unless application
    application.default_locale == locale
  end

  def dir
    right_to_left? ? "rtl" : "ltr"
  end

  def align(dest)
    return dest unless right_to_left?
    dest.to_s == 'left' ? 'right' : 'left'
  end

  def full_name
    return english_name if english_name == native_name
    "#{english_name} - #{native_name}"
  end

  def current_source(options)
    options[:source] || Tr8n.config.block_options[:source] || Tr8n.config.current_source
  end

  #######################################################################################################
  ##  Translation Methods
  ##
  ##  Note - when inline translation mode is enable, cache will not be used and translators will
  ##  always hit the live service to get the most recent translations
  ##
  ##  Some cache adapters cache by source, others by key. Some are read-only, some are built on the fly.
  #######################################################################################################

  def translate(label, description = "", tokens = {}, options = {})
    locale = options[:locale] || Tr8n.config.block_options[:locale] || Tr8n.config.default_locale
    level = options[:level] || Tr8n.config.block_options[:level] || Tr8n.config.default_level

    temp_key = Tr8n::TranslationKey.new({
        :application  => application,
        :label        => label,
        :description  => description,
        :locale       => locale,
        :level        => level,
        :translations => []
    })

    unless Tr8n.config.enabled?
      return temp_key.substitute_tokens(label, tokens, self, options).tr8n_translated
    end

    tokens.merge!(:viewing_user => Tr8n.config.current_user)

    translation_key = application.translation_key(temp_key.key)
    if translation_key
      return translation_key.translate(self, tokens, options)
    end

    if Tr8n.config.cache_enabled? and Tr8n.config.current_translator? and Tr8n.config.current_translator.inline?
      return translate_from_cache(temp_key, tokens, options)
    end

    translate_from_service(temp_key, tokens, options)
  rescue Exception => ex
    Tr8n.logger.error("Failed to translate: #{label} : #{ex.message}")
    Tr8n.logger.error(ex.backtrace)
    label
  end

  def translate_from_cache(translation_key, tokens, options)
    # In most scenarios translations should be cached by source
    if Tr8n.cache.cached_by_source?
      source_key = current_source(options)
      cache_key = Tr8n::Source.cache_key(source_key, locale);
      source = Tr8n.cache.fetch(cache_key)

      if source
        translation_keys = source.translation_keys
      elsif Tr8n.cache.read_only?
        translation_keys = {}
      else
        source = application.source(source_key)
        translation_keys = surce.fetch_translations_for_language(self, options)
        Tr8n.cache.store(cache_key, source)
      end

      if translation_keys[translation_key.key]
        translation_key = translation_keys[translation_key.key]
        return translation_key.translate(self, tokens, options)
      end

      translation_key.translations = {locale => []}
      application.cache_translation_key(translation_key)
      return translation_key.translate(self, tokens, options)
    end

    # CDB allows for caching by key
    cache_key = Tr8n::TranslationKey.cache_key(translation_key.label, translation_key.description, locale)
    translations = Tr8n.cache.fetch(cache_key)

    if translations.nil?
      if Tr8n.cache.read_only?
        translation_key.translations = {locale => []}
        application.cache_translation_key(translation_key)
        return translation_key.translate(self, tokens, options)
      end

      translation_key = translation_key.fetch_translations(self, options)
      Tr8n.cache.store(cache_key, translation_key.translations(self))
      return translation_key.translate(self, tokens, options)
    end

    unless translations.is_a?(Array)
      translations = [translations]
    end

    translation_key.translations = {locale => translations}
    application.cache_translation_key(translation_key)
    translation_key.translate(self, tokens, options)
  end

  def translate_from_service(translation_key, tokens, options)
    source_key = current_source(options)

    if source_key
      source = application.source(source_key)
      source_translation_keys = source.fetch_translations_for_language(self, options)
      if source_translation_keys[translation_key.key]
        translation_key = source_translation_keys[translation_key.key]
      else
        application.register_missing_key(translation_key, source)
      end

      return translation_key.translate(self, tokens, options)
    end

    # all translations are cached in memory as the second level cache
    memory_cached_translation_key = application.translation_key(translation_key.key)
    if memory_cached_translation_key
      translation_key = memory_cached_translation_key
    else
      translation_key = translation_key.fetch_translations(self, options)
    end

    translation_key.translate(self, tokens, options)
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def self.cache_prefix
    'l@'
  end

  def self.cache_key(locale)
    "#{cache_prefix}_[#{locale}]"
  end

  def to_cache_hash(*attrs)
    return super(attrs) if attrs.any?

    hash = super(:locale, :name, :english_name, :native_name, :right_to_left, :flag_url)
    hash[:contexts] = {}
    contexts.each do |name, value|
      hash[:contexts][name] = value.to_cache_hash
    end
    hash[:cases] = {}
    cases.each do |name, value|
      hash[:cases][name] = value.to_cache_hash
    end
    hash
  end

end
