require 'helper'

describe Tr8n::Application do
  describe "#initialize" do
    it "sets application attributes" do
      app = Tr8n::Application.new(load_json('application.json'))
    end
  end 

  describe "#integration" do
    it "loads application from live service" do
      app = Tr8n::Application.init("http://geni.berkovich.net", "29adc3257b6960703", "abcdefg")
      # pp russian
    end
  end 

end