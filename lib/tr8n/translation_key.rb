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
  attributes :id, :key, :label, :description, :locale, :level, :locked, :translations

  def initialize(attrs = {})
    super
    self.translations = (attrs["translations"] || []).collect{|t| Tr8n::Translation.new(t)}
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

  def self.fetch_or_register(label, desc = "", options = {})
    hash = generate_key(label, desc).to_s

    source = options[:application].source_by_key(options[:source]) 
    
    tkey = source.translation_key_by_language_and_hash(Tr8n::Config.current_language, hash)
    return tkey if tkey
    tkey = Tr8n::Config.application.traslation_key_by_language_and_hash(Tr8n::Config.current_language, hash)
    if tkey
      Tr8n::Config.application.register_missing_key(tkey, source)
      return tkey
    end

    tkey = Tr8n::TranslationKey.new({
        :key => hash, 
        :label => label, 
        :description => desc,
        :admin => Tr8n::Config.block_options[:admin],
        :locale => options[:locale] || Tr8n::Config.block_options[:default_locale] || Tr8n::Config.default_locale,
        :level => options[:level] || Tr8n::Config.block_options[:level]
    })
    Tr8n::Config.application.register_missing_key(tkey, source)
    tkey
  end
  
  def language
    @language ||= (locale ? Tr8n::Language.by_locale(locale) : Tr8n::Config.default_language)
  end
  
  def tokenized_label
    @tokenized_label ||= Tr8n::TokenizedLabel.new(label)
  end

  def find_first_valid_translation(language, token_values)
    tkey = Tr8n::Config.current_source.translation_key_by_language_and_hash(language, key)
    return nil unless tkey and tkey.translations

    tkey.translations.each do |translation|
      return translation if translation.matches_rules?(token_values)
    end
    
    nil
  end

  def translate(language = Tr8n::Config.current_language, token_values = {}, options = {})
    if Tr8n::Config.disabled? or language.default?
      return substitute_tokens(label, token_values, options.merge(:fallback => false), language).html_safe
    end
    
    translation = find_first_valid_translation(language, token_values)
    
    if translation
      translated_label = substitute_tokens(translation.label, token_values, options, language)
      return decorate_translation(language, translated_label, translation != nil, options).html_safe
    end

    # no translation found  
    translated_label = substitute_tokens(label, token_values, options, Tr8n::Config.default_language)
    decorate_translation(language, translated_label, translation != nil, options).html_safe  
  end

  ###############################################################
  ## Substitution and Decoration Related Stuff
  ###############################################################

  def allowed_token?(token)
    return true if tokenized_label.allowed_token?(token)
    # TODO: add support for default data and decoration tokens
    false
  end

  # this is done when the translations engine is disabled
  def self.substitute_tokens(label, tokens, options = {}, language = Tr8n::Config.default_language)
    return label.to_s if options[:skip_substitution] 
    Tr8n::TranslationKey.new(:label => label.to_s).substitute_tokens(label.to_s, tokens, options, language)
  end

  def substitute_tokens(translated_label, token_values, options = {}, language = Tr8n::Config.current_language)
    processed_label = translated_label.to_s.dup

    # substitute data tokens
    Tr8n::TokenizedLabel.new(processed_label).data_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(self, processed_label, token_values, options, language) 
    end

    # substitute decoration tokens
    Tr8n::TokenizedLabel.new(processed_label).decoration_tokens.each do |token|
      next unless allowed_token?(token)
      processed_label = token.substitute(self, processed_label, token_values, options, language) 
    end
    
    processed_label
  end
  
  def decorate_translation(language, translated_label, translated = true, options = {})
    return translated_label if options[:skip_decorations]
    return translated_label if self.language == language
    return translated_label unless Tr8n::Config.current_translator
    return translated_label unless Tr8n::Config.current_translator.inline?
    return translated_label if locked? and not Tr8n::Config.current_translator.manager?

    if id.nil?
      html = "<tr8n style='border-bottom: 2px dotted #ff0000;'>"
      html << translated_label
      html << "</tr8n>"
      return html
    end      

    classes = ['tr8n_translatable']
    
    if locked?
      classes << 'tr8n_locked'
    elsif language.default?
      classes << 'tr8n_not_translated'
    elsif options[:fallback] 
      classes << 'tr8n_fallback'
    else
      classes << (translated ? 'tr8n_translated' : 'tr8n_not_translated')
    end  

    html = "<tr8n class='#{classes.join(' ')}' translation_key_id='#{id}'>"
    html << translated_label
    html << "</tr8n>"
    html
  end
end
