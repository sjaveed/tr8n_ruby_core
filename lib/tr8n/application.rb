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
  attributes :host, :key, :secret, :name, :description, :definition, :languages, :version, :updated_at

  def self.init(host, key, secret)
    app = api("application", {:client_id => key, :definition => true}, {:host => host, :class => Tr8n::Application})    
    app.key = key
    app.secret = secret
    app
  end

  def initialize(attrs = {})
    super
    if attrs['languages']
      self.attributes[:languages] = attrs['languages'].collect{ |l| Tr8n::Language.new(l.merge(:application => self)) }
    end
    unless attrs['definition']
      self.attributes[:definition] = {}
    end
  end

  def update_cache_version
    return unless updated_at.nil? 
    return if updated_at and updated_at > (Time.now - 1.hour)
    
    # version = get("application/version")
    # Tr8n::Cache.set_version(version)
  end

  def reset!
    @language_by_locale = nil
    @featured_languages = nil
    @sources = nil
    @components = nil
    @traslation_keys_by_language = nil
  end

  def language_by_locale(locale)
    @language_by_locale ||= begin
      langs = {}
      languages.each do |lang|      
        langs[lang.locale] = lang
      end
      langs
    end
    return @language_by_locale[locale] if @language_by_locale[locale]

    # for translator languages will continue to build application cache
    @language_by_locale[locale] = get("language", {:locale => locale}, {:class => Tr8n::Language, :attributes => {:application => self}})    
    @language_by_locale[locale]
  end

  def featured_languages
    @featured_languages ||= get("application/featured_locales").collect{ |locale| language_by_locale(locale) }
  end
 
  def translators
    Tr8n::Cache.fetch("application_translators") do 
      get("application/translators")
    end
  end

  def default_decoration_tokens
    definition["default_decoration_tokens"]
  end

  def default_data_tokens
    definition["default_data_tokens"]
  end

  def enable_language_cases?
    self.definition["enable_language_cases"]
  end

  def enable_language_flags?
    self.definition["enable_language_flags"]
  end

  def default_data_tokens
    self.definition["default_data_tokens"]
  end

  def default_data_token(token)
    default_data_tokens[token.to_s]
  end

  def default_decoration_tokens
    self.definition["default_decoration_tokens"]
  end

  def default_decoration_token(token)
    default_decoration_tokens[token.to_s]
  end

  def rules
    self.definition["rules"]
  end

  def sources
    @sources ||= {}
  end

  def source_by_key(key)
    @sources ||= {}
    @sources[key] ||= post("source/register", {:source => key}, {:class => Tr8n::Source, :attributes => {:application => self}})
  end

  def components
    @components ||= {}
  end

  def component_by_key(key)
    @components ||= {}
    @components[key] ||= post("component/register", {:component => key}, {:class => Tr8n::Component, :attributes => {:application => self}})
  end

  def traslation_key_by_language_and_hash(language, hash)
    @traslation_keys_by_language ||= {}
    @traslation_keys_by_language[language.locale] ||= {}
    @traslation_keys_by_language[language.locale][hash]
  end

  def register_translation_key(language, tkey)
    @traslation_keys_by_language ||= {}
    @traslation_keys_by_language[language.locale] ||= {}
    @traslation_keys_by_language[language.locale][tkey.key] = tkey
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

  def translate(label, description = nil, tokens = {}, options = {})

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

    self.class.api(path, params, opts.merge(:host => host))
  end

  def self.api(path, params = {}, opts = {})
    pp [:api, path, params, opts]

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

    pp data

    unless data["error"].nil?
      raise Tr8n::Exception.new("Error: #{data["error"]}")
    end

    process_response(data, opts)
  end

  def self.object_class(opts)
    return unless opts[:class]
    opts[:class].is_a?(String) ? opts[:class].constantize : opts[:class]
  end

  def self.process_response(data, opts)
    if data["results"]
      return data["results"] unless object_class(opts)
      objects = []
      data["results"].each do |data|
        objects << object_class(opts).new(data.merge(opts[:attributes] || {}))
      end
      return objects
    end

    return data unless object_class(opts)
    object_class(opts).new(data.merge(opts[:attributes] || {}))
  end
end
