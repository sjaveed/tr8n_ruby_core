# encoding: UTF-8

require 'helper'

describe Tr8n::Tokens::Hidden do
  before do
    @app = Tr8n::Application.new(load_json('application.json'))
    @english = @app.language_by_locale('ru')
    @tkey = Tr8n::TranslationKey.new({
      :label => "{_others}",
      :application => @app,
      :locale => 'en-US'
    })
    @tlabel = @tkey.tokenized_label
  end

  describe "initialize" do
    it "should parse token info" do
      token = @tlabel.tokens.first
      expect(token.class.name).to eq("Tr8n::Tokens::Hidden")
      expect(token.original_label).to eq(@tlabel.label)
      expect(token.full_name).to eq("{_others}")
      expect(token.declared_name).to eq("_others")
      expect(token.name).to eq("_others")
      expect(token.sanitized_name).to eq("{_others}")
      expect(token.name_key).to eq(:"_others")
      expect(token.pipeless_name).to eq("_others")
      expect(token.case_key).to be_nil
      expect(token.supports_cases?).to be_false
      expect(token.has_case_key?).to be_false
      expect(token.caseless_name).to eq("_others")
      expect(token.name_with_case).to eq("_others")

      expect(token.types).to be_nil
      expect(token.has_types?).to be_false
      expect(token.associated_rule_types).to eq([:value])
      expect(token.language_rule_classes).to eq([Tr8n::Rules::Value])
      expect(token.transformable_language_rule_classes).to eq([])
      expect(token.decoration?).to be_false
    end
  end

end
