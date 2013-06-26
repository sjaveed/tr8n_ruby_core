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

class Tr8n::Source < Tr8n::Base
  belongs_to  :application
  attributes  :source, :url, :name, :description
  has_many    :translation_keys

  def self.normalize(url)
    return nil if url.blank?
    uri = URI.parse(url)
    path = uri.path
    return "/" if uri.path.blank?
    return path if path == "/"

    # always must start with /
    path = "/#{path}" if path[0] != "/"
    # should not end with /
    path = path[0..-2] if path[-1] == "/"
    path
  end

  def language_updated_at(language)
    @language_updated_at ||= {}
    @language_updated_at[language.locale]
  end

  def set_language_updated_at(language, time = Time.now)
    @language_updated_at ||= {}
    @language_updated_at[language.locale] = time
  end

  def language_needs_refetch?(language)
    # by default languages will be refetched for each source every hour
    language_updated_at(language).nil? or language_updated_at(language) < Time.now - 1.hour
  end

  def fetch_translations_for_language(language, options = {})
    Tr8n.logger.debug("calling fetch_translations_for_language: #{language.locale}")

    # for current translators who use inline mode - always fetch translations
    if Tr8n.config.current_translator and Tr8n.config.current_translator.inline?
      return Tr8n.config.current_translation_keys if Tr8n.config.current_translation_keys

      Tr8n.logger.debug("fetching translations for current translator in inline mode")
      keys_with_translations = application.get("source/translations", {:source => source, :locale => language.locale}, {:class => Tr8n::TranslationKey, :attributes => {:application => application, :language => language}})
      fetched_keys = {}
      keys_with_translations.each do |tkey|
        fetched_keys[tkey.key] = tkey
      end
      Tr8n.config.current_translation_keys = fetched_keys
      return fetched_keys
    end

    # return keys if they have already been fetched recently
    if translation_keys and not language_needs_refetch?(language)
      Tr8n.logger.debug("cache hit: using translations for [#{source}] in [#{language.locale}]")
      return translation_keys 
    end

    set_language_updated_at(language)
    keys_with_translations = application.get("source/translations", {:source => source, :locale => language.locale}, {:class => Tr8n::TranslationKey, :attributes => {:application => application, :language => language}})

    Tr8n.logger.trace("caching keys") do 
      self.attributes[:translation_keys] = {}
      keys_with_translations.each do |tkey|
        Tr8n.logger.debug(tkey.label)
        self.attributes[:translation_keys][tkey.key] = application.cache_translation_key(tkey)
      end
    end

    self.attributes[:translation_keys]
  end

  def translation_keys
    self.attributes[:translation_keys] ||= {}
  end

  def reset
    self.attributes[:translation_keys] = {}
  end

end