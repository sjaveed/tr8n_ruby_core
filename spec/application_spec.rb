require 'helper'

describe Tr8n::Application do
  describe "#initialize" do
    it "sets application attributes" do
      # app = Tr8n::Application.new(load_json('application.json'))
    end
  end 

  describe "#integration" do
    before do
      @app = Tr8n::Application.init("http://geni.berkovich.net", "29adc3257b6960703", "abcdefg")
    end

    it "returns cached language by locale" do
      russian = @app.language_by_locale("ru")
      pp russian.translate("{count||message,messages}", nil, :count => 3)
    end

    # it "returns new language by locale" do
    #   # french = @app.language_by_locale("fr")
    #   # pp french
    # end

    # it "returns translators" do
    #   # translators = @app.translators
    #   # pp french
    # end

    # it "returns featured languages" do
    #   # featured_languages = @app.featured_languages
    #   # pp french
    # end

    # it "returns source by key" do
    #   # source = @app.source_by_key("/")
    #   # pp source.to_api_hash
    # end

  end 

end