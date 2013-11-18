# encoding: UTF-8

require 'helper'

describe Tr8n::Base do
  describe "hash value method" do
    it "must return correct values" do
      expect(Tr8n::Base.hash_value({"a" => "b"}, "a")).to eq("b")
      expect(Tr8n::Base.hash_value({:a => "b"}, "a")).to eq("b")
      expect(Tr8n::Base.hash_value({:a => "b"}, :a)).to eq("b")
      expect(Tr8n::Base.hash_value({"a" => "b"}, :a)).to eq("b")

      expect(Tr8n::Base.hash_value({"a" => {:b => "c"}}, "a.b")).to eq("c")
      expect(Tr8n::Base.hash_value({:a => {:b => "c"}}, "a.b")).to eq("c")
      expect(Tr8n::Base.hash_value({:a => {:b => "c"}}, "a.d")).to be_nil
      expect(Tr8n::Base.hash_value({:a => {:b => {:c => :d}}}, "a.b.c")).to eq(:d)
    end
  end
end
