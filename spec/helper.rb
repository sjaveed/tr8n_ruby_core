require 'rspec'
require 'json'
require 'tr8n_core'

def fixtures_root
  File.join(File.dirname(__FILE__), 'fixtures')
end

def load_json(file_path)
  JSON.parse(File.read("#{fixtures_root}/#{file_path}"))
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

