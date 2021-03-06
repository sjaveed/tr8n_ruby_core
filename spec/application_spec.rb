# encoding: UTF-8

require 'helper'

describe Tr8n::Application do
  describe "#configuration" do
    it "sets class attributes" do
      expect(Tr8n::Application.attributes).to eq([:host, :key, :secret, :name, :description, :threshold, :translator_level, :version, :updated_at, :default_locale, :features, :languages, :sources, :components, :tokens])
    end
  end

  describe "#initialize" do
    before do
      @app = init_application
    end

    it "loads application attributes" do
      expect(@app.key).to eq("default")
      expect(@app.name).to eq("Tr8n Translation Service")

      expect(@app.default_data_token('nbsp')).to eq("&nbsp;")
      expect(@app.default_decoration_token('strong')).to eq("<strong>{$0}</strong>")

      expect(@app.feature_enabled?(:language_cases)).to be_true
      expect(@app.feature_enabled?(:language_flags)).to be_true
    end

    it "loads application language" do
      expect(@app.languages.size).to eq(11)

      russian = @app.language('ru')
      expect(russian.locale).to eq('ru')
      expect(russian.contexts.keys.size).to eq(6)
      expect(russian.contexts.keys).to eq(["date", "gender", "genders", "list", "number", "value"])
    end
  end

  describe "#translation" do
    before do
      @app = init_application
      @english = @app.language('en-US')
      @russian = @app.language('ru')
    end

    it "translates with fallback to English" do
      Tr8n.config.with_block_options(:dry => true) do
        #expect(@russian.translate("{count||message}", {:count => 1})).to eq("1 message")
        #expect(@russian.translate("{count||message}", {:count => 5})).to eq("5 messages")
        #expect(@russian.translate("{count||message}", {:count => 0})).to eq("0 messages")
      end
    end

  #  it "translates basic phrases to Russian" do
  #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@russian.translate("Hello World")).to eq("Привет Мир")
  #      expect(@russian.translate("Hello World", "Wrong context")).to eq("Hello World")
  #      expect(@russian.translate("Hello World", "Greeting context")).to eq("Привет Мир")
  #      expect(@russian.translate("Hello world")).to eq("Hello world")
  #      expect(@russian.translate("Hello {user}", nil, :user => "Михаил")).to eq("Привет Михаил")
  #    end
  #  end
  #
  #  it "translates basic phrases with data tokens to Russian" do
  #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@russian.translate("Hello {user}", nil, :user => "Михаил")).to eq("Привет Михаил")
  #    end
  #  end
  #
  #  it "uses default data tokens" do
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@english.translate("He said: {quot}Hello{quot}", nil)).to eq("He said: &quot;Hello&quot;")
  #      expect(@english.translate("Code sample: {lbrace}a:'b'{rbrace}", nil)).to eq("Code sample: {a:'b'}")
  #    end
  #  end
  #
  #  it "uses basic decoration tokens" do
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@english.translate("Hello [decor: World]", nil, :decor => lambda{|text| "''#{text}''"})).to eq("Hello ''World''")
  #    end
  #  end
  #
  #  it "uses default decoration tokens" do
  #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@english.translate("Hello [i: World]")).to eq("Hello <i>World</i>")
  #      expect(@russian.translate("Hello [i: World]")).to eq("Привет <i>Мир</i>")
  #    end
  #  end
  #
  #  it "uses mixed tokens" do
  #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@english.translate("Hello [i: {user}]", nil, :user => "Michael")).to eq("Hello <i>Michael</i>")
  #      expect(@russian.translate("Hello [i: {user}]", nil, :user => "Michael")).to eq("Привет <i>Michael</i>")
  #    end
  #  end
  #
  #  it "uses method tokens" do
  #    load_translation_keys_from_file(@app, 'translations/ru/basic.json')
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@russian.translate("Hello {user.first_name} [i: {user.last_name}]", nil,
  #        :user => stub_object({:first_name => "Tom", :last_name => "Anderson"}))).to eq("Привет Tom <i>Anderson</i>")
  #    end
  #  end
  #
  #  it "translates phrases with numeric rules to Russian" do
  #    load_translation_keys_from_file(@app, 'translations/ru/counters.json')
  #    trn = @russian.translate("{count||message}", nil, {:count => 1})
  #    expect(trn).to eq("1 сообщение")
  #    trn = @russian.translate("{count||message}", nil, {:count => 2})
  #    expect(trn).to eq("2 сообщения")
  #    trn = @russian.translate("{count||message}", nil, {:count => 5})
  #    expect(trn).to eq("5 сообщений")
  #    trn = @russian.translate("{count||message}", nil, {:count => 15})
  #    expect(trn).to eq("15 сообщений")
  #  end
  #
  #  it "translates phrases with gender rules to Russian" do
  #    #load_translation_key_from_hash(@app, {
  #    #    "label" => "{actor} sent {target} a gift.",
  #    #    "translations" => {
  #    #    "ru" => [
  #    #        {
  #    #          "label"=> "{actor} послал подарок {target::dat}.",
  #    #          "locale"=> "ru",
  #    #          "context"=> {
  #    #            "actor"=> [{ "type"=> "gender", "key"=> "male"}]
  #    #          }
  #    #        },
  #    #        {
  #    #          "label"=> "{actor} послала подарок {target::dat}.",
  #    #          "locale"=> "ru",
  #    #          "context"=> {
  #    #            "actor"=> [{ "type"=> "gender", "key"=> "female"}]
  #    #          },
  #    #        },
  #    #        {
  #    #          "label"=> "{actor} послал/а подарок {target::dat}.",
  #    #          "locale"=> "ru",
  #    #          "context"=> {
  #    #            "actor"=> [{ "type"=> "gender", "key"=> "unknown"}]
  #    #           },
  #    #        }
  #    #      ]
  #    #    }
  #    #});
  #
  #    load_translation_keys_from_file(@app, "translations/ru/genders.json")
  #
  #    actor = {'gender' => 'female', 'name' => 'Таня'}
  #    target = {'gender' => 'male', 'name' => 'Михаил'}
  #
  #    Tr8n.config.with_block_options(:dry => true) do
  #      expect(@russian.translate(
  #                      '{actor} sent {target} a gift.', nil,
  #                      :actor => {:object => actor, :attribute => 'name'},
  #                      :target => {:object => target, :attribute => 'name'})
  #      ).to eq("Таня послала подарок Михаилу.")
  #
  #      expect(@russian.translate(
  #                      '{actor} sent {target} a gift.', nil,
  #                      :actor => {:object => target, :attribute => 'name'},
  #                      :target => {:object => actor, :attribute => 'name'})
  #      ).to eq("Михаил послал подарок Тане.")
  #
  #      expect(@russian.translate(
  #                      '{actor} loves {target}.', nil,
  #                      :actor => {:object => actor, :attribute => 'name'},
  #                      :target => {:object => target, :attribute => 'name'})
  #      ).to eq("Таня любит Михаила.")
  #
  #      expect(@russian.translate(
  #                      '{actor} saw {target} {count||day} ago.', nil,
  #                      :actor => {:object => actor, :attribute => 'name'},
  #                      :target => {:object => target, :attribute => 'name'},
  #                      :count => 2)
  #      ).to eq("Таня видела Михаила 2 дня назад.")
  #
  #      expect(@russian.translate(
  #                      '{actor} saw {target} {count||day} ago.', nil,
  #                      :actor => {:object => target, :attribute => 'name'},
  #                      :target => {:object => actor, :attribute => 'name'},
  #                      :count => 2)
  #      ).to eq("Михаил видел Таню 2 дня назад.")
  #
  #    end
  #
  #    # trn = @russian.translate("{count||message}", nil, {:count => 1})
  #    # expect(trn).to eq("1 сообщение")
  #  end
  #
  end

  #describe "#integration" do
  #  # before do
  #  #   # @app = Tr8n::Application.init("http://geni.berkovich.net", "29adc3257b6960703", "abcdefg")
  #  # end
  #
  #  # it "returns cached language by locale" do
  #  #   # russian = @app.language("ru")
  #  #   # pp russian.translate("{count||message,messages}", nil, :count => 3)
  #  # end
  #
  #  # it "returns new language by locale" do
  #  #   # french = @app.language("fr")
  #  #   # pp french
  #  # end
  #
  #  # it "returns translators" do
  #  #   # translators = @app.translators
  #  #   # pp french
  #  # end
  #
  #  # it "returns featured languages" do
  #  #   # featured_languages = @app.featured_languages
  #  #   # pp french
  #  # end
  #
  #  # it "returns source by key" do
  #  #   # source = @app.source_by_key("/")
  #  #   # pp source.to_api_hash
  #  # end
  #
  #end

end