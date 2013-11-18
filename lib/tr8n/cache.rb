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
      klass = Object.const_get("Tr8n::CacheAdapters::#{Tr8n.config.cache_adapter.camelcase}")
      klass.new
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
      raise Tr8n::Exception.new("Must be implemented by the subclass")
    end

    def store(key, data, opts = {})
      raise Tr8n::Exception.new("Must be implemented by the subclass")
    end

    def delete(key, opts = {})
      raise Tr8n::Exception.new("Must be implemented by the subclass")
    end

    def exist?(key, opts = {})
      raise Tr8n::Exception.new("Must be implemented by the subclass")
    end

    def clear(opts = {})
      raise Tr8n::Exception.new("Must be implemented by the subclass")
    end

    def serialize_object(key, data)
      unless ['a@', 'l@', 's@', 'c@'].include?(key[0..1])
        return data
      end

      data.to_json
    end

    def deserialize_object(key, data)
      case key[0..1]
        when 'a@'
          return Tr8n::Application(JSON.parse(data))
        when 'l@'
          return Tr8n::Language(JSON.parse(data).merge(:application => Tr8n.config.application))
        when 's@'
          return Tr8n::Source(JSON.parse(data).merge(:application => Tr8n.config.application))
        when 'c@'
          return Tr8n::Component(JSON.parse(data).merge(:application => Tr8n.config.application))
      end

      data
    end


  end
end