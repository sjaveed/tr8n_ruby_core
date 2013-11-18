# encoding: UTF-8

require 'helper'

describe Tr8n::LanguageCase do
  before do
    @app = init_application
    @english = @app.language('en-US')
    @russian = @app.language('ru')
  end

  describe "initialize" do
    it "sets attributes" do
      expect(Tr8n::LanguageCase.attributes).to eq([:language, :keyword, :latin_name, :native_name, :description, :application, :rules])
    end
  end

  describe "apply case" do
    it "should return correct data" do
      lcase = Tr8n::LanguageCase.new(
          :language     => @english,
          :keyword      => "pos",
          :latin_name   => "Possessive",
          :native_name  => "Possessive",
          :description  => "Used to indicate possession (i.e., ownership). It is usually created by adding 's to the word",
          :application  => "phrase"
      )

      lcase.rules << Tr8n::LanguageCaseRule.new(:conditions => "(match '/s$/' @value)", :operations => "(append \"'\" @value)")
      lcase.rules << Tr8n::LanguageCaseRule.new(:conditions => "(not (match '/s$/' @value))", :operations => "(append \"'s\" @value)")
      expect(lcase.apply("Michael")).to eq("Michael's")
    end

    it "should correctly process default cases" do
      possessive = @english.language_case_by_keyword('pos')
      expect(possessive.apply("Michael")).to eq("Michael's")


      plural = @english.language_case_by_keyword('plural')

      expect(plural.apply("fish")).to eq("fish")
      expect(plural.apply("money")).to eq("money")

      # irregular
      expect(plural.apply("move")).to eq("moves")

      # plurals
      expect(plural.apply("quiz")).to eq("quizzes")
      expect(plural.apply("wife")).to eq("wives")

      singular = @english.language_case_by_keyword('singular')
      expect(singular.apply("quizzes")).to eq("quiz")
      expect(singular.apply("cars")).to eq("car")
      expect(singular.apply("wives")).to eq("wife")
    end
  end

end