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

require 'dalli' if defined?(Dalli)

class Tr8n::CacheAdapters::Memcache < Tr8n::Cache

  def initialize
    options = { :namespace => "tr8n", :compress => true }
    @cache = Dalli::Client.new(Tr8n.config.cache_host, options)
  end

  def read_only?
    false
  end

  def fetch(key, opts = {})
    data = @cache.get(versioned_key(key, opts))
    if data
      info("Cache hit: #{key}")
      return deserialize_object(key, data)
    end

    info("Cache miss: #{key}")

    return nil unless block_given?

    data = yield

    store(key, data)

    data
  rescue Exception => ex
    warn("Failed to retrieve data: #{ex.message}")
    return nil unless block_given?
    yield
  end

  def store(key, data, opts = {})
    info("Cache store: #{key}")
    ttl = opts[:ttl] || Tr8n.config.cache_timeout
    @cache.set(versioned_key(key, opts), serialize_object(key, data), ttl)
    data
  rescue Exception => ex
    warn("Failed to store data: #{ex.message}")
    data
  end

  def delete(key, opts = {})
    info("Cache delete: #{key}")
    @cache.delete(versioned_key(key, opts))
    key
  rescue Exception => ex
    warn("Failed to delete data: #{ex.message}")
    key
  end

  def exist?(key, opts = {})
    data = @cache.get(versioned_key(key, opts))
    not data.nil?
  rescue Exception => ex
    warn("Failed to check if key exists: #{ex.message}")
    false
  end

  def clear(opts = {})
    info("Cache clear")
  rescue Exception => ex
    warn("Failed to clear cache: #{ex.message}")
  end
end
