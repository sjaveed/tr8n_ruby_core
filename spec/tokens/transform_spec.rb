# encoding: UTF-8

require 'helper'

describe Tr8n::Tokens::Transform do
  before do
    @app = Tr8n::Application.new(load_json('application.json'))
    @english = @app.language_by_locale('ru')
    @tkey = Tr8n::TranslationKey.new({
      :label => "You have {count||message}",
      :application => @app,
      :locale => 'en-US'
    })
    @tlabel = @tkey.tokenized_label
  end

  describe "initialize" do
    it "should parse token info" do
      token = @tlabel.tokens.first
      expect(token.class.name).to eq("Tr8n::Tokens::Transform")
      expect(token.original_label).to eq(@tlabel.label)
      expect(token.full_name).to eq("{count||message}")
      expect(token.declared_name).to eq("count||message")
      expect(token.name).to eq("count")
      expect(token.sanitized_name).to eq("{count}")
      expect(token.name_key).to eq(:count)
      expect(token.pipeless_name).to eq("count")
      expect(token.case_key).to be_nil
      expect(token.supports_cases?).to be_true
      expect(token.has_case_key?).to be_false
      expect(token.caseless_name).to eq("count")
      expect(token.name_with_case).to eq("count")
      expect(token.name_for_case(:ord)).to eq("count::ord")
      expect(token.sanitized_name_for_case(:ord)).to eq("{count::ord}")

      expect(token.types).to be_nil
      expect(token.has_types?).to be_false
      expect(token.associated_rule_types).to eq([:number, :value])
      expect(token.language_rule_classes).to eq([Tr8n::Rules::Number, Tr8n::Rules::Value])
      expect(token.transformable_language_rule_classes).to eq([Tr8n::Rules::Number])
      expect(token.decoration?).to be_false
    end
  end

  describe "substitute" do
    it "should substitute values" do
      token = @tlabel.tokens.first

    end    
  end


end
