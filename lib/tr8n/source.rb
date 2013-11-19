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

  def initialize(attrs = {})
    super

    self.translation_keys = nil
    if hash_value(attrs, :translation_keys)
      self.translation_keys = {}
      hash_value(attrs, :translation_keys).each do |tk|
        tkey = Tr8n::TranslationKey.new(tk.merge(:application => application))
        self.translation_keys[tkey.key] = application.cache_translation_key(tkey)
      end
    end
  end

  def fetch_translations_for_language(language, options = {})
    return translation_keys if translation_keys

    keys_with_translations = application.get("source/translations",
                                             {:source => source, :locale => language.locale},
                                             {:class => Tr8n::TranslationKey, :attributes => {:application => application}})

    self.translation_keys = {}

    keys_with_translations.each do |tkey|
      self.translation_keys[tkey.key] = application.cache_translation_key(tkey)
    end

    translation_keys
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def self.cache_prefix
    's@'
  end

  def self.cache_key(source_key, locale)
    "#{cache_prefix}_[#{locale}]_[#{source_key}]"
  end

  def to_cache_hash(*attrs)
    return super(attrs) if attrs.any?

    hash = super(:source, :url, :name, :description)
    if translation_keys and translation_keys.any?
      hash[:translation_keys] = {}
      translation_keys.values.each do |tkey|
        hash[:translation_keys] = tkey.to_cache_hash
      end
    end
    hash
  end

end