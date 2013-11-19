# encoding: UTF-8

require 'helper'

describe Tr8n::Config do
  describe "loading defaults" do
    it "should load correct values" do
      expect(Tr8n.config.logger_enabled?).to be_false
      expect(Tr8n.config.enabled?).to be_true
      expect(Tr8n.config.default_locale).to eq("en-US")
      expect(Tr8n.config.cache_enabled?).to be_false
      expect(Tr8n.config.log_path).to eq("./log/tr8n.log")
      expect(Tr8n.config.cache_adapter).to eq("file")
    end
  end
end
