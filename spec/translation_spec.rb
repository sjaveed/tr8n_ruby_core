# encoding: UTF-8

require 'helper'

describe Tr8n::Translation do
  describe "initialize" do
    before do
      @app = init_application
      @english = @app.language('en-US')
      @russian = @app.language('ru')
    end

    it "sets attributes" do
      expect(Tr8n::Translation.attributes).to eq([:translation_key, :language, :locale, :label, :context, :precedence])

      t = Tr8n::Translation.new(:label => "You have {count||message}", :context => {"count" => {"number" => "one"}}, :language => @russian)

      [1, 101, 1001].each do |count|
        expect(t.matches_rules?(:count => count)).to be_true
      end

    end
  end
end
