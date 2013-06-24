# encoding: UTF-8

require 'helper'

describe Tr8n::Language do
  describe "#initialize" do
    it "sets language attributes" do
      russian = Tr8n::Language.new(load_json('languages/russian.json'))
      expect(russian.locale).to eq('ru')
      expect(russian.full_name).to eq("Russian - Русский")

      expect(russian.context_rules.keys).to eq(["date", "gender_list", "gender", "number"])
      expect(russian.context_rules['date'].keys).to eq(["past", "present", "future"])
      expect(russian.context_rules['date']['past'].class.name).to eq("Tr8n::Rules::Date")

      expect(russian.context_rules['number'].keys).to eq(["one", "few", "many"])
      expect(russian.context_rules['number']['one'].class.name).to eq("Tr8n::Rules::Number")
      expect(russian.context_rules['number']['many'].language).to eq(russian)

      expect(russian.context_rules['gender'].keys).to eq(["male", "female", "unknown"])
      expect(russian.context_rules['gender']['male'].class.name).to eq("Tr8n::Rules::Gender")
      expect(russian.context_rules['gender']['male'].language).to eq(russian)

      expect(russian.context_rules['gender']['male'].language).to eq(russian)

      expect(russian.context_rules_by_type('gender')).to be(russian.context_rules['gender'])
      expect(russian.context_rule_by_type_and_key('gender', 'male')).to be(russian.context_rules['gender']['male'])

      expect(russian.application).to be_nil
      expect(russian.dir).to eq('ltr')
    end
  end   
end