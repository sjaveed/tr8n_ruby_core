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

module Tr8n

  def self.cache
    @cache ||= begin
      if Tr8n.config.cache_enabled?
        klass = Tr8n::CacheAdapters.const_get(Tr8n.config.cache_adapter.camelcase)
        klass.new
      else
        # blank implementation
        Tr8n::Cache.new
      end
    end
  end

  class Cache

    def enabled?
      Tr8n.config.cache_enabled?
    end

    def cached_by_source?
      true
    end

    def read_only?
      true
    end

    def cache_name
      self.class.name.underscore.split('_').last
    end

    def info(msg)
      Tr8n.logger.info("#{cache_name} - #{msg}")
    end

    def warn(msg)
      Tr8n.logger.warn("#{cache_name} - #{msg}")
    end

    def versioned_key(key)
      "tr8n_rc_v#{Tr8n.config.cache_version}_#{key}"
    end

    def fetch(key, opts = {})
      return nil unless block_given?
      yield
    end

    def store(key, data, opts = {})
      # do nothing
    end

    def delete(key, opts = {})
      # do nothing
    end

    def exist?(key, opts = {})
      false
    end

    def clear(opts = {})
      # do nothing
    end

    def serialize_object(key, data)
      if [Tr8n::Application.cache_prefix,
              Tr8n::Language.cache_prefix,
              Tr8n::Source.cache_prefix,
              Tr8n::Component.cache_prefix,
              Tr8n::TranslationKey.cache_prefix].include?(key[0..1])
        json_data = data.to_cache_hash.to_json
      else
        # the data must be in cacheable form - usually API responses
        json_data = data.to_json
      end

      #info(json_data)
      json_data
    end

    def deserialize_object(key, data)
      #info(data.inspect)

      case key[0..1]
        when Tr8n::Application.cache_prefix
          return Tr8n::Application.new(JSON.parse(data))
        when Tr8n::Language.cache_prefix
          return Tr8n::Language.new(JSON.parse(data).merge(:application => Tr8n.config.application))
        when Tr8n::Source.cache_prefix
          return Tr8n::Source.new(JSON.parse(data).merge(:application => Tr8n.config.application))
        when Tr8n::Component.cache_prefix
          return Tr8n::Component.new(JSON.parse(data).merge(:application => Tr8n.config.application))
        when Tr8n::TranslationKey.cache_prefix
          return Tr8n::TranslationKey.new(JSON.parse(data).merge(:application => Tr8n.config.application))
      end

      # API response form will be here
      JSON.parse(data)
    end


  end
end