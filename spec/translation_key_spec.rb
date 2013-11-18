# encoding: UTF-8

require 'helper'

describe Tr8n::TranslationKey do
  describe "#initialize" do
    before do
      @app = init_application
      @english = @app.language('en-US')
      @russian = @app.language('ru')
    end

    it "sets attributes" do
      expect(Tr8n::TranslationKey.attributes).to eq([:application, :language, :id, :key, :label, :description, :locale, :level, :locked, :translations])

      tkey = Tr8n::TranslationKey.new({
          :label => "Hello World",
          :application => @app
      })
      expect(tkey.locale).to eq("en-US")
      expect(tkey.language.locale).to eq("en-US")

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

    it "translates labels correctly into default language" do
      tkey = Tr8n::TranslationKey.new(:label => "Hello World", :application => @app)
      expect(tkey.substitute_tokens("Hello World", {}, @english)).to eq("Hello World")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1}", {:user => "Michael"}, @english)).to eq("Hello {user1}")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => "Michael"}, @english)).to eq("Hello Michael")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user1} and {user2}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1} and {user2}", {:user1 => "Michael" , :user2 => "Tom"}, @english)).to eq("Hello Michael and Tom")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => {:name => "Michael"}, :value => "Michael"}}, @english)).to eq("Hello Michael")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => {:name => "Michael"}, :attribute => "name"}}, @english)).to eq("Hello Michael")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user}", {:user => {:object => double(:name => "Michael"), :attribute => "name"}}, @english)).to eq("Hello Michael")

      tkey = Tr8n::TranslationKey.new(:label => "Hello {user1} [bold: and] {user2}", :application => @app)
      expect(tkey.substitute_tokens("Hello {user1} [bold: and] {user2}", {:user1 => "Michael" , :user2 => "Tom"}, @english)).to eq("Hello Michael <strong>and</strong> Tom")

      tkey = Tr8n::TranslationKey.new(:label => "You have [link: [bold: {count}] messages]", :application => @app)
      expect(tkey.substitute_tokens("You have [link: [bold: {count}] messages]", {:count => 5, :link => {:href => "www.google.com"}}, @english)).to eq("You have <a href='www.google.com'><strong>5</strong> messages</a>")

      tkey = Tr8n::TranslationKey.new(:label => "You have [link][bold: {count}] messages[/link]", :application => @app)
      expect(tkey.substitute_tokens("You have [link][bold: {count}] messages[/link]", {:count => 5, :link => {:href => "www.google.com"}}, @english)).to eq("You have <a href='www.google.com'><strong>5</strong> messages</a>")
    end

    context "labels with numeric rules" do
      it "should return correct translations" do
        key = Tr8n::TranslationKey.new(:label => "You have {count||message}.", :application => @app)
        key.set_language_translations(@russian, [
            Tr8n::Translation.new(:label => "U vas est {count} soobshenie.", :context => {"count" => {"number" => "one"}}),
            Tr8n::Translation.new(:label => "U vas est {count} soobsheniya.", :context => {"count" => {"number" => "few"}}),
            Tr8n::Translation.new(:label => "U vas est {count} soobshenii.", :context => {"count" => {"number" => "many"}}),
        ])

        expect(key.translate(@russian, {:count => 1})).to eq("U vas est 1 soobshenie.")
        expect(key.translate(@russian, {:count => 101})).to eq("U vas est 101 soobshenie.")
        expect(key.translate(@russian, {:count => 11})).to eq("U vas est 11 soobshenii.")
        expect(key.translate(@russian, {:count => 111})).to eq("U vas est 111 soobshenii.")

        expect(key.translate(@russian, {:count => 5})).to eq("U vas est 5 soobshenii.")
        expect(key.translate(@russian, {:count => 26})).to eq("U vas est 26 soobshenii.")
        expect(key.translate(@russian, {:count => 106})).to eq("U vas est 106 soobshenii.")

        expect(key.translate(@russian, {:count => 3})).to eq("U vas est 3 soobsheniya.")
        expect(key.translate(@russian, {:count => 13})).to eq("U vas est 13 soobshenii.")
        expect(key.translate(@russian, {:count => 23})).to eq("U vas est 23 soobsheniya.")
        expect(key.translate(@russian, {:count => 103})).to eq("U vas est 103 soobsheniya.")
      end
    end
  end
end
