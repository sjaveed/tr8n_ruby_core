# encoding: UTF-8

require 'helper'

describe Tr8n::Tokens::Base do
  before do
    @app = Tr8n::Application.new(load_json('application.json'))
    @english = @app.language_by_locale('ru')
  end

  describe "initialize" do
    it "should parse data token" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello {user}",
        :application => @app,
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label

      token = tlabel.tokens.first
      expect(token.class.name).to eq("Tr8n::Tokens::Data")
      expect(token.original_label).to eq(tlabel.label)
      expect(token.full_name).to eq("{user}")
      expect(token.declared_name).to eq("user")
      expect(token.name).to eq("user")
      expect(token.sanitized_name).to eq("{user}")
      expect(token.name_key).to eq(:user)
      expect(token.pipeless_name).to eq("user")
      expect(token.case_key).to be_nil
      expect(token.supports_cases?).to be_true
      expect(token.has_case_key?).to be_false
      expect(token.caseless_name).to eq("user")
      expect(token.name_with_case).to eq("user")
      expect(token.name_for_case(:nom)).to eq("user::nom")
      expect(token.sanitized_name_for_case(:nom)).to eq("{user::nom}")

      expect(token.types).to be_nil
      expect(token.has_types?).to be_false
      expect(token.associated_rule_types).to eq([:gender, :value])
      expect(token.language_rule_classes).to eq([Tr8n::Rules::Gender, Tr8n::Rules::Value])
      expect(token.transformable_language_rule_classes).to eq([Tr8n::Rules::Gender])
      expect(token.decoration?).to be_false
    end
  end

  describe "substitute" do
    it "should substitute values" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello {user}",
        :application => @app,
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label
      token = tlabel.tokens.first

      user = stub_object({:first_name => "Tom", :last_name => "Anderson", :gender => "Male", :to_s => "Tom Anderson"})
    
      # tr("Hello {user}", "", {:user => current_user}}
      expect(token.token_value(user, {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user]}}
      expect(token.token_value([user], {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
      expect(token.token_value([user, user.first_name], {}, @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => [current_user, "{$0} {$1}", "param1"]}}
      expect(token.token_value([user, "{$0} {$1}", "param1"], {}, @english)).to eq(user.to_s + " param1")
      expect(token.token_value([user, "{$0} {$1} {$2}", "param1", "param2"], {}, @english)).to eq(user.to_s + " param1 param2")

      # tr("Hello {user}", "", {:user => [current_user, :name]}}
      expect(token.token_value([user, :first_name], {}, @english)).to eq(user.first_name)

      # tr("Hello {user}", "", {:user => [current_user, :method_name, "param1"]}}
      user.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{user.last_name}"}
      expect(token.token_value([user, :last_name_with_prefix, 'Mr.'], {}, @english)).to eq("Mr. Anderson")

      # tr("Hello {user}", "", {:user => [current_user, lambda{|user| user.name}]}}
      expect(token.token_value([user, lambda{|user| user.to_s}], {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => [current_user, lambda{|user, param1| user.name}, "param1"]}}
      expect(token.token_value([user, lambda{|user, param1| user.to_s + " " + param1}, "extra_param1"], {}, @english)).to eq(user.to_s + " extra_param1")

      # tr("Hello {user}", "", {:user => {:object => current_user, :value => current_user.name}]}}
      expect(token.token_value({:object => user, :value => user.to_s}, {}, @english)).to eq(user.to_s)

      # tr("Hello {user}", "", {:user => {:object => current_user, :attribute => :first_name}]}}
      expect(token.token_value({:object => user, :attribute => :first_name}, {}, @english)).to eq(user.first_name)
      expect(token.token_value({:object => {:first_name => "Michael"}, :attribute => :first_name}, {}, @english)).to eq("Michael")
    end    
  end

  describe "substitute value array" do
    it "should substitute token with array values" do
      tkey = Tr8n::TranslationKey.new({
        :label => "Hello {users}",
        :application => @app,
        :locale => 'en-US'
      })
      tlabel = tkey.tokenized_label
      token = tlabel.tokens.first

      users = []
      1.upto(10) do |i|
        users << stub_object({:first_name => "First name #{i}", :last_name => "Last name #{i}", :gender => "Male"})
      end
    
      # tr("Hello {user}", "", {:user => current_user}}
      expect(token.token_value([users], {}, @english)).to eq("")


      # # tr("Hello {user}", "", {:user => [current_user]}}
      # expect(token.token_value([object], {}, @english)).to eq(object.to_s)

      # # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
      # expect(token.token_value([object, object.first_name], {}, @english)).to eq(object.first_name)

      # # tr("Hello {user}", "", {:user => [current_user, "{$0} {$1}", "param1"]}}
      # expect(token.token_value([object, "{$0} {$1}", "param1"], {}, @english)).to eq(object.to_s + " param1")
      # expect(token.token_value([object, "{$0} {$1} {$2}", "param1", "param2"], {}, @english)).to eq(object.to_s + " param1 param2")

      # # tr("Hello {user}", "", {:user => [current_user, :name]}}
      # expect(token.token_value([object, :first_name], {}, @english)).to eq(object.first_name)

      # # tr("Hello {user}", "", {:user => [current_user, :method_name, "param1"]}}
      # object.stub(:last_name_with_prefix) {|prefix| "#{prefix} #{object.last_name}"}
      # expect(token.token_value([object, :last_name_with_prefix, 'Mr.'], {}, @english)).to eq("Mr. Anderson")

      # # tr("Hello {user}", "", {:user => [current_user, lambda{|user| user.name}]}}
      # expect(token.token_value([object, lambda{|user| user.to_s}], {}, @english)).to eq(object.to_s)

      # # tr("Hello {user}", "", {:user => [current_user, lambda{|user, param1| user.name}, "param1"]}}
      # expect(token.token_value([object, lambda{|user, param1| user.to_s + " " + param1}, "extra_param1"], {}, @english)).to eq(object.to_s + " extra_param1")

      # # tr("Hello {user}", "", {:user => {:object => current_user, :value => current_user.name}]}}
      # expect(token.token_value({:object => object, :value => object.to_s}, {}, @english)).to eq(object.to_s)

      # # tr("Hello {user}", "", {:user => {:object => current_user, :attribute => :first_name}]}}
      # expect(token.token_value({:object => object, :attribute => :first_name}, {}, @english)).to eq(object.first_name)
      # expect(token.token_value({:object => {:first_name => "Michael"}, :attribute => :first_name}, {}, @english)).to eq("Michael")
    end    
  end

end
