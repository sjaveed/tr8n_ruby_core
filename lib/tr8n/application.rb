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

require 'faraday'

API_PATH = '/tr8n/api/'

class Tr8n::Application < Tr8n::Base
  attributes :host, :key, :secret, :name, :description, :threshold, :translator_level, :version, :updated_at, :default_locale
  has_many :features, :languages, :translation_keys, :sources, :components, :tokens

  def self.init(host, key, secret, options = {})
    options[:definition] = true if options[:definition].nil?
    api("application", {:client_id => key, :definition => options[:definition]}, {:host => host, :client_secret => secret, :class => Tr8n::Application, :attributes => {
      :host => host, 
      :key => key,
      :secret => secret
    }})   
  end

  def initialize(attrs = {})
    super
    if hash_value(attrs, :languages)
      self.attributes[:languages] = hash_value(attrs, :languages).collect{ |l| Tr8n::Language.new(l.merge(:application => self)) }
    end
    if hash_value(attrs, :sources)
      self.attributes[:sources] = hash_value(attrs, :sources).collect{ |l| Tr8n::Source.new(l.merge(:application => self)) }
    end
    if hash_value(attrs, :components)
      self.attributes[:components] = hash_value(attrs, :components).collect{ |l| Tr8n::Component.new(l.merge(:application => self)) }
    end
  end

  def cache_key(key)
    "a@_[#{key}]"
  end

  def language(locale = nil, fetch = true)
    locale ||= Tr8n.config.default_locale

    return @languages_by_locale[locale] if @languages_by_locale[locale]
    #Tr8n::Cache.fetch()
    return nil unless fetch

    # for translator languages will continue to build application cache
    @languages_by_locale[locale] = get("language", {:locale => locale}, {:class => Tr8n::Language, :attributes => {:application => self}})
    @languages_by_locale[locale]
  end

  def update_cache_version
    return unless updated_at.nil? 
    return if updated_at and updated_at > (Time.now - 1.hour)
    
    # version = get("application/version")
    # Tr8n::Cache.set_version(version)
  end

  def reset!
    # @languages_by_locale = nil
    # @sources_by_key = nil
    # @components_by_key = nil
    # @featured_languages = nil
    super
  end

  def add_language(lang)
    @languages_by_locale ||= {}
    return if @languages_by_locale[lang.locale]
    
    lang.application = self
    @languages_by_locale[lang.locale] = lang
  end

  def featured_languages
    @featured_languages ||= get("application/featured_locales").collect{ |locale| language(locale) }
  end
 
  def translators
    get("application/translators", {}, {:class => Tr8n::Translator, :attributes => {:application => self}})
  end

  def default_decoration_token(token)
    hash_value(tokens, "decoration.#{token.to_s}")
  end

  def default_data_token(token)
    hash_value(tokens, "data.#{token.to_s}")
  end

  def source_by_key(key)
    key = key.source if key.is_a?(Tr8n::Source)
    @sources_by_key ||= begin
      srcs = {}
      (sources || []).each do |src|
        srcs[src.source] = src
      end
      srcs
    end
    @sources_by_key[key] ||= post("source/register", {:source => key}, {:class => Tr8n::Source, :attributes => {:application => self}})
  end

  def component_by_key(key)
    key = key.key if key.is_a?(Tr8n::Component)
    @components_by_key ||= begin
      cmps = {}
      components.each do |cmp|      
        cmps[cmp.key] = cmp
      end
      cmps
    end
    @components_by_key[key] ||= post("component/register", {:component => key}, {:class => Tr8n::Component, :attributes => {:application => self}})
  end

  def translation_keys
    self.attributes[:translation_keys] ||= {}
  end

  def traslation_key_by_key(key)
    translation_keys[key]
  end

  def cache_translation_key(tkey)
    cached_key = traslation_key_by_key(tkey.key)

    if cached_key
      # move translations from tkey to the cached key
      tkey.translations.each do |locale, translations|
        cached_key.set_language_translations(language(locale), translations)
      end
      return cached_key
    end

    self.translation_keys[tkey.key] = tkey.set_application(self)
    tkey
  end

  def cache_translation_keys(tkeys)
    tkeys.each do |tkey|
      cache_translation_key(tkey)
    end
  end

  def register_missing_key(tkey, source)    
    @missing_keys_by_sources ||= {}
    @missing_keys_by_sources[source.source] ||= {}
    @missing_keys_by_sources[source.source][tkey.key] ||= tkey
  end

  def submit_missing_keys
    return if @missing_keys_by_sources.nil? or @missing_keys_by_sources.empty?
    params = []
    @missing_keys_by_sources.each do |source, keys|
      params << {:source => source, :keys => keys.values.collect{|tkey| tkey.to_api_hash(:label, :description, :locale, :level)}}
      source_by_key(source).reset
    end 
    post('source/register_keys', {:source_keys => params.to_json}, :method => :post)
    @missing_keys_by_sources = nil
  end

  def feature_enabled?(key)
    hash_value(features, key.to_s)
  end

  #######################################################################################################
  ##  API Methods
  #######################################################################################################

  def get(path, params = {}, opts = {})
    api(path, params, opts)
  end

  def post(path, params = {}, opts = {})
    api(path, params, opts.merge(:method => :post))
  end

  def self.error?(data)
    not data["error"].nil?
  end

  def api(path, params = {}, opts = {})
    params = params.merge(:client_id => key, :t => Time.now.to_i)
    
    # TODO: sign request

    self.class.api(path, params, opts.merge(:host => self.host))
  end

  def self.api(path, params = {}, opts = {})
    Tr8n.logger.trace_api_call(path, params) do
      conn = Faraday.new(:url => opts[:host]) do |faraday|
        faraday.request(:url_encoded)               # form-encode POST params
        # faraday.response :logger                  # log requests to STDOUT
        faraday.adapter(Faraday.default_adapter)    # make requests with Net::HTTP
      end
      
      if opts[:method] == :post
        response = conn.post("#{API_PATH}#{path}", params)
      else
        response = conn.get("#{API_PATH}#{path}", params)
      end

      data = JSON.parse(response.body)

      unless data["error"].nil?
        raise Tr8n::Exception.new("Error: #{data["error"]}")
      end

      process_response(data, opts)
    end
  end

  def self.object_class(opts)
    return unless opts[:class]
    opts[:class].is_a?(String) ? opts[:class].constantize : opts[:class]
  end

  def self.process_response(data, opts)
    if data["results"]
      Tr8n.logger.debug("recieved #{data["results"].size} result(s)")
      return data["results"] unless object_class(opts)
      objects = []
      data["results"].each do |data|
        objects << object_class(opts).new(data.merge(opts[:attributes] || {}))
      end
      return objects
    end

    return data unless object_class(opts)
    Tr8n.logger.debug("constructing #{object_class(opts).name}")
    object_class(opts).new(data.merge(opts[:attributes] || {}))
  end
end
