# encoding: UTF-8

require 'helper'

describe Tr8n::TranslationKey do
  describe "#initialize" do
    before do
      @app = Tr8n::Application.new(load_json('application.json'))
      @russian = @app.language('ru')
    end

    it "sets attributes" do
      expect(Tr8n::TranslationKey.attributes).to eq([:application, :id, :key, :label, :description, :locale, :level, :locked, :translations])
      
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello World",
        :application => @app,
        :locale => 'en-US'
      })

      expect(tkey.id).to be_nil
      expect(tkey.label).to eq("Hello World")
      expect(tkey.description).to be_nil
      expect(tkey.key).to eq("d541c79af1be6a05b1f16fca8b5730de")
      expect(tkey.locale).to eq("en-US")
      expect(tkey.language.locale).to eq("en-US")
      expect(tkey.has_translations_for_language?(@russian)).to be_false
      expect(tkey.translations_for_language(@russian)).to eq([])

    end
  end
end
