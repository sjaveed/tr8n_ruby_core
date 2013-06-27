# encoding: UTF-8

require 'helper'

describe Tr8n::Tokens::Method do
  before do
    @app = init_application
    @english = @app.language('en-US')
    @tkey = Tr8n::TranslationKey.new({
      :label => "Hello {user.first_name}",
      :application => @app,
      :locale => 'en-US'
    })
    @tlabel = @tkey.tokenized_label
  end

  describe "initialize" do
    it "should parse token info" do
      token = @tlabel.tokens.first
      expect(token.class.name).to eq("Tr8n::Tokens::Method")
      expect(token.original_label).to eq(@tlabel.label)
      expect(token.full_name).to eq("{user.first_name}")
      expect(token.declared_name).to eq("user.first_name")
      expect(token.name).to eq("user.first_name")
      expect(token.sanitized_name).to eq("{user.first_name}")
      expect(token.name_key).to eq(:"user.first_name")
      expect(token.pipeless_name).to eq("user.first_name")
      expect(token.case_key).to be_nil
      expect(token.supports_cases?).to be_true
      expect(token.has_case_key?).to be_false
      expect(token.caseless_name).to eq("user.first_name")
      expect(token.name_with_case).to eq("user.first_name")
      expect(token.name_for_case(:nom)).to eq("user.first_name::nom")
      expect(token.sanitized_name_for_case(:nom)).to eq("{user.first_name::nom}")

      expect(token.types).to be_nil
      expect(token.has_types?).to be_false
      expect(token.associated_rule_types).to eq([:value])
      expect(token.language_rule_classes).to eq([Tr8n::Rules::Value])
      expect(token.transformable_language_rule_classes).to eq([])
      expect(token.decoration?).to be_false
    end
  end

  describe "substitute" do
    it "should substitute values" do
      token = @tlabel.tokens.first

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


end
