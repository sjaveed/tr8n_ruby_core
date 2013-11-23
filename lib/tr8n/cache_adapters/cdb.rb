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

require 'libcdb' if defined?(LibCDB)

class Tr8n::CacheAdapters::Cdb < Tr8n::Cache

  def initialize
    @cache = LibCDB::CDB.open(cache_path)
  end

  def self.cache_path
    "#{Tr8n.config.cache_path}/cdb/current.cdb"
  end

  def cached_by_source?
    false
  end

  def fetch(key, opts = {})
    data = @cache[key]
    if data
      info("Cache hit: #{key}")
      return deserialize_object(key, data)
    end

    info("Cache miss: #{key}")

    return nil unless block_given?

    yield
  rescue Exception => ex
    warn("Failed to retrieve data: #{ex.message}")
    return nil unless block_given?
    yield
  end

  def store(key, data, opts = {})
    warn("This is a readonly cache")
  end

  def delete(key, opts = {})
    warn("This is a readonly cache")
  end

  def exist?(key, opts = {})
    @cache[key]
  end

  def clear(opts = {})
    warn("This is a readonly cache")
  end

end
