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

class Tr8nCore::Generators::Cache::Base

  def log(msg)
   puts("#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}: #{msg}\n")
  end

  def cache_path
    raise Tr8n::Exception.new("Must be implemented by the subclass")
  end

  def cache(key, data)
    raise Tr8n::Exception.new("Must be implemented by the subclass")
  end

  def execute
    raise Tr8n::Exception.new("Must be implemented by the subclass")
  end

  def run
    prepare
    execute
    finalize
  end

  def prepare
    @started_at = Time.now
  end

  def finalize
    @finished_at = Time.now
    log("Cache has been stored in #{cache_path}")
    log("Cache generation took #{@finished_at - @started_at} mls.")
    log("Done.")
  end

  def cache_application
    log("Downloading application...")
    app = Tr8n.config.application.get("application", :definition => true)
    cache(Tr8n::Application.cache_key(app["key"]), app)
    log("Application has been cached.")
    app
  end

  def cache_languages
    log("Downloading languages...")
    languages = Tr8n.config.application.get("application/languages", :definition => true)
    languages.each do |lang|
      cache(Tr8n::Language.cache_key(lang["locale"]), lang)
    end
    log("#{languages.count} languages have been cached.")
    languages
  end

  def symlink_path
    raise Tr8n::Exception.new("Must be implemented by the subclass")
  end

  def generate_symlink
    FileUtils.rm(symlink_path) if File.exist?(symlink_path)
    FileUtils.ln_s(cache_path, symlink_path)
  end
end
