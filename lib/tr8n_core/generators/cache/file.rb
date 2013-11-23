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

class Tr8nCore::Generators::Cache::File < Tr8nCore::Generators::Cache::Base

  def cache_path
    @cache_path ||= begin
      path = "#{Tr8n.config.cache_path}/files/tr8n_#{Tr8n.config.application.key}_#{@started_at.strftime('%Y_%m_%d_%H_%M_%S')}"
      FileUtils.mkdir_p(path)
      FileUtils.chmod(0777, path)
      path
    end
  end

  def cache(key, data)
    file_path = "#{cache_path}/#{Tr8n::CacheAdapters::File.file_name(key)}"
    File.open(file_path, 'w') { |file| file.write(JSON.pretty_generate(data)) }
  end

  def symlink_path
    Tr8n::CacheAdapters::File.cache_path
  end

  def execute
    cache_application
    @languages = cache_languages
    cache_translations
    generate_symlink
  end

  def cache_translations
    log("Downloading translations...")
    sources = Tr8n.config.application.get("application/sources")
    @languages.each do |language|
      log("--------------------------------------------------------------")
      log("Downloading #{language["locale"]} language...")
      log("--------------------------------------------------------------")

      sources.each do |source|
        log("Downloading #{source["source"]} in #{language["locale"]}...")
        translation_keys = Tr8n.config.application.get("source/translations", {:source => source["source"], :locale => language["locale"]})
        data = {:source => source["source"], :translation_keys => translation_keys}
        cache(Tr8n::Source.cache_key(source["source"], language["locale"]), data)
      end
    end
  end

end
