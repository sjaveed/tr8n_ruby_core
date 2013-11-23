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

require 'faraday'

API_PATH = '/tr8n/api/'

class Tr8n::Application < Tr8n::Base
  attributes :host, :key, :secret, :name, :description, :threshold, :version, :updated_at, :default_locale, :default_level
  has_many :features, :languages, :sources, :components, :tokens

  def self.init(host, key, secret, options = {})
    options[:definition] = true if options[:definition].nil?

    Tr8n.cache.reset_version

    Tr8n.logger.info("Initializing application...")

    Tr8n.config.application = Tr8n.cache.fetch(cache_key(key)) do
      api("application", {:client_id => key, :definition => options[:definition]}, {:host => host, :client_secret => secret, :class => Tr8n::Application, :attributes => {
          :host => host,
          :key => key,
          :secret => secret
      }})
    end

    #if Tr8n.config.cache_enabled?
    #  Tr8n.config.application = Tr8n.cache.fetch(cache_key(key))
    #  return Tr8n.config.application if Tr8n.config.application
    #end
    #
    #Tr8n.config.application = api("application", {:client_id => key, :definition => options[:definition]}, {:host => host, :client_secret => secret, :class => Tr8n::Application, :attributes => {
    #  :host => host,
    #  :key => key,
    #  :secret => secret
    #}})
    #
    #if Tr8n.config.cache_enabled?
    #  Tr8n.cache.store(cache_key(key), Tr8n.config.application)
    #end
    #
    #Tr8n.config.application
  end

  def initialize(attrs = {})
    super

    self.attributes[:languages] = []
    if hash_value(attrs, :languages)
      self.attributes[:languages] = hash_value(attrs, :languages).collect{ |l| Tr8n::Language.new(l.merge(:application => self)) }
    end

    self.attributes[:sources] = []
    if hash_value(attrs, :sources)
      self.attributes[:sources] = hash_value(attrs, :sources).collect{ |l| Tr8n::Source.new(l.merge(:application => self)) }
    end

    self.attributes[:components] = []
    if hash_value(attrs, :components)
      self.attributes[:components] = hash_value(attrs, :components).collect{ |l| Tr8n::Component.new(l.merge(:application => self)) }
    end

    @translation_keys         = {}

    @languages_by_locale      = nil
    @sources_by_key           = nil
    @components_by_key        = nil
    @missing_keys_by_sources  = nil
  end

  def language(locale = nil, fetch = true)
    locale ||= default_locale || Tr8n.config.default_locale

    @languages_by_locale ||= {}
    return @languages_by_locale[locale] if @languages_by_locale[locale]

    if Tr8n.config.cache_enabled?
      language = Tr8n.cache.fetch(Tr8n::Language.cache_key(locale))
      if language
        language.application = self
        @languages_by_locale[locale] = language
        return language
      end
    end

    return nil unless fetch

    # for translator languages will continue to build application cache
    @languages_by_locale[locale] = get("language", {:locale => locale}, {:class => Tr8n::Language, :attributes => {:application => self}})

    if Tr8n.config.cache_enabled? and not Tr8n.cache.read_only?
      Tr8n.cache.store(Tr8n::Language.cache_key(locale), @languages_by_locale[locale])
    end

    @languages_by_locale[locale]
  end

  def locales
    @locales ||= languages.collect{|lang| lang.locale}
  end

  # Mostly used for testing
  def add_language(new_language)
    lang = language(new_language.locale, false)
    return lang if lang

    new_language.application = self
    self.languages << new_language
    @languages_by_locale[new_language.locale] = new_language
    new_language
  end

  def source(key, register = true)
    key = key.source if key.is_a?(Tr8n::Source)

    @sources_by_key ||= begin
      srcs = {}
      (sources || []).each do |src|
        srcs[src.source] = src
      end
      srcs
    end

    return @sources_by_key[key] if @sources_by_key[key]
    return nil unless register

    @sources_by_key[key] ||= post("source/register", {:source => key}, {:class => Tr8n::Source, :attributes => {:application => self}})
  end

  def component(key, register = true)
    key = key.key if key.is_a?(Tr8n::Component)

    @components_by_key ||= begin
      cmps = {}
      (components || []).each do |cmp|
        cmps[cmp.key] = cmp
      end
      cmps
    end

    return @components_by_key[key] if @components_by_key[key]
    return nil unless register

    @components_by_key[key] ||= post("component/register", {:component => key}, {:class => Tr8n::Component, :attributes => {:application => self}})
  end

  def translation_keys
    @translation_keys ||= {}
  end

  def translation_key(key)
    translation_keys[key]
  end

  def cache_translation_key(tkey)
    cached_key = translation_key(tkey.key)

    if cached_key
      # move translations from tkey to the cached key
      tkey.translations.each do |locale, translations|
        cached_key.set_language_translations(language(locale), translations)
      end
      return cached_key
    end

    tkey.set_application(self)
    @translation_keys[tkey.key] = tkey
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
      next unless keys.values.any?
      params << {:source => source, :keys => keys.values.collect{|tkey| tkey.to_hash(:label, :description, :locale, :level)}}
    end
    post('source/register_keys', {:source_keys => params.to_json}, :method => :post)
    @missing_keys_by_sources = nil
  end

  def featured_languages
    @featured_languages ||= begin
      locales = Tr8n.cache.fetch("featured_locales") do
        get("application/featured_locales")
      end
      # use app languages, there is no need for rules for this call
      (locales.nil? or locales.empty?) ? [] : languages.select{|l| locales.include?(l.locale)}
    end
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

  def js_boot_url
    "#{host}/tr8n/api/proxy/boot.js?client_id=#{key}"
  end

  def feature_enabled?(key)
    hash_value(features, key.to_s)
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def self.cache_prefix
    'a@'
  end

  def self.cache_key(key)
    "#{cache_prefix}_[#{key}]"
  end

  def to_cache_hash
    hash = to_hash(:host, :key, :secret, :name, :description, :threshold, :default_locale, :default_level)
    hash["languages"] = []
    languages.each do |lang|
      hash["languages"] << lang.to_hash(:locale, :name, :english_name, :native_name, :right_to_left, :flag_url)
    end
    hash
  end

  #######################################################################################################
  ##  API Methods
  #######################################################################################################
  ## TODO: maybe caching can be done generically on the API level during gets?
  ## TODO: think about it...

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
