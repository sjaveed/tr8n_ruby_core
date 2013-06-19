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
  attributes :application, :source, :url, :name, :description

  def self.normalize_source(url)
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

  def fetch_keys_for_language(language, opts = {})
    keys_with_translations = get("source/translations", {:source => source, :locale => language.locale}, {:class => Tr8n::TranslationKey})
    keys = {}
    keys_with_translations.each do |tkey|
      # building global translation hash along the way, for fallback
      Tr8n::Config.application.register_translation_key(language, tkey) if opts[:global]
      keys[tkey.key] = tkey
    end
    keys
  end

  def translation_key_by_language_and_hash(language, hash)
    if Tr8n::Config.current_translator and Tr8n::Config.current_translator.inline?
      # for inline translator do this always
      @translator_keys ||= fetch_keys_for_language(language)
      return @translator_keys[hash]
    end

    @translation_keys_by_language ||= {}
    @translation_keys_by_language[language.locale] ||= fetch_keys_for_language(language, :global => true)
    @translation_keys_by_language[language.locale][hash]
  end

  def reset_translator_keys
    @translator_keys = nil
  end

  def reset
    @translation_keys_by_language = {}
  end

end