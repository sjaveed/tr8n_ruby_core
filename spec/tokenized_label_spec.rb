# encoding: UTF-8

require 'helper'

describe Tr8n::TokenizedLabel do
  before do
    @app = Tr8n::Application.new(load_json('application.json'))
    @russian = @app.language('ru')
  end

  describe "#initialize" do
    it "should be empty for labels without any tokens" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello World",
        :application => @app,
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label

      expect(tlabel.label).to eq(tkey.label)
      expect(tlabel.data_tokens).to eq([])
      expect(tlabel.decoration_tokens).to eq([])
      expect(tlabel.tokens?).to be_false
      expect(tlabel.tokens).to eq([])
    end
  end

  describe "parse" do
    it "should parse simple data tokens" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello {user}",
        :application => @app,
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label

      expect(tlabel.label).to eq(tkey.label)
      expect(tlabel.data_tokens?).to be_true
      expect(tlabel.data_tokens.size).to eq(1)
      expect(tlabel.decoration_tokens?).to be_false
      expect(tlabel.decoration_tokens.size).to eq(0)
      expect(tlabel.tokens?).to be_true
      expect(tlabel.tokens.size).to eq(1)
      expect(tlabel.translation_tokens.size).to eq(1)
    end    
  end
end
