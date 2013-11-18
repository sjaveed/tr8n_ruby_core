# encoding: UTF-8

require 'helper'

describe Tr8n::Utils do
  describe "helper methods" do
    it "should return correct values" do
      expect(Tr8n::Utils.root).to eq(File.expand_path("#{__dir__}/../"))
      expect(Tr8n::Utils.load_yml("/config/tokens/data.yml").class).to eq(Hash)

      expect(
        Tr8n::Utils.normalize_tr_params("Hello {user}", "Sample label", {:user => "Michael"}, {})
      ).to eq(
        {:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}
      )

      expect(
        Tr8n::Utils.normalize_tr_params("Hello {user}", {:user => "Michael"}, nil, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>nil, :tokens=>{:user=>"Michael"}, :options=>nil}
      )

      expect(
        Tr8n::Utils.normalize_tr_params("Hello {user}", {:user => "Michael"}, {:skip_decoration => true}, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>nil, :tokens=>{:user=>"Michael"}, :options=>{:skip_decoration=>true}}
      )

      expect(
        Tr8n::Utils.normalize_tr_params({:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}, nil, nil, nil)
      ).to eq(
        {:label=>"Hello {user}", :description=>"Sample label", :tokens=>{:user=>"Michael"}, :options=>{}}
      )

      expect(Tr8n::Utils.guid.class).to be(String)
    end

    it "should correctly split by sentence" do

      expect(
          Tr8n::Utils.split_by_sentence("Hello World")
      ).to eq(
          ["Hello World"]
      )

      expect(
          Tr8n::Utils.split_by_sentence("This is the first sentence. Followed by the second one.")
      ).to eq(
           ["This is the first sentence.", "Followed by the second one."]
       )

    end

    it "should correctly sign and verify signature" do
      data = {"name" => "Michael"}
      key = "abc"

      request =  Tr8n::Utils.sign_and_encode_params(data, key)
      result = Tr8n::Utils.decode_and_verify_params(request, key)
      expect(result["name"]).to eq(data["name"])
    end

  end
end
