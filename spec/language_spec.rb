# encoding: UTF-8

require 'helper'

describe Tr8n::Language do
  describe "#initialize" do
    it "sets language attributes" do
      russian = Tr8n::Language.new(load_json('languages/ru.json'))
      expect(russian.locale).to eq('ru')
      expect(russian.full_name).to eq("Russian - Русский")
    end
  end



end