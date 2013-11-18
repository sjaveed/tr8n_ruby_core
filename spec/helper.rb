require 'rspec'
require 'json'
require 'tr8n_core'

def fixtures_root
  File.join(File.dirname(__FILE__), 'fixtures')
end

def load_json(file_path)
  JSON.parse(File.read("#{fixtures_root}/#{file_path}"))
end

def load_translation_keys_from_file(app, path)
  load_json(path).each do |jkey|
    load_translation_key_from_hash(app, jkey)
  end
end

def load_translation_key_from_hash(app, hash)
  app.cache_translation_key(Tr8n::TranslationKey.new(hash.merge(:application => app)))
end

def stub_object(attrs)
  user = double()
  attrs.each do |key, value|
    user.stub(key) { value }
  end
  user
end

def init_application(locales = [], path = 'application.json')
  locales = ['en-US', 'ru'] if locales.size == 0 
  app = Tr8n::Application.new(load_json(path))
  locales.each do |locale|
    app.add_language(Tr8n::Language.new(load_json("languages/#{locale}.json")))
  end
  Tr8n.config.application = app
  Tr8n.config.current_language = app.language('en-US')
  app
end

RSpec.configure do |config|
  config.before do
    ARGV.replace []
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def capture(stream)
    begin
      stream = stream.to_s
      eval "$#{stream} = StringIO.new"
      yield
      result = eval("$#{stream}").string
    ensure
      eval("$#{stream} = #{stream.upcase}")
    end

    result
  end

  def source_root
    fixtures_root
  end
  
  def destination_root
    File.join(File.dirname(__FILE__), 'sandbox')
  end

  alias :silence :capture
end

