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


class Tr8n::CacheAdapters::Cdb < Tr8n::Cache

  #def self.cache_path
  #  "#{Tr8n.config.cache_path}/files/current"
  #end
  #
  #def self.file_name(key)
  #  "#{key.gsub(/[\.\/]/, '-')}.json"
  #end
  #
  #def self.file_path(key)
  #  "#{cache_path}/#{file_name(key)}"
  #end
  #
  #def fetch(key, opts = {})
  #  path = self.class.file_path(key)
  #
  #  if File.exists(path)
  #    info("Cache hit: #{key}")
  #    data = File.read(path)
  #    return deserialize_object(key, data)
  #  end
  #
  #  info("Cache miss: #{key}")
  #
  #  yield
  #end
  #
  #def store(key, data, opts = {})
  #  warn("This is a readonly cache")
  #end
  #
  #def delete(key, opts = {})
  #  warn("This is a readonly cache")
  #end
  #
  #def exist?(key, opts = {})
  #  File.exists(file_path(key))
  #end
  #
  #def clear(opts = {})
  #  warn("This is a readonly cache")
  #end

end
