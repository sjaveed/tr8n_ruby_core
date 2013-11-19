#--
# Copyright (c) 2013 Michael Berkovich, tr8nhub.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++

require 'yaml'
require 'base64'
require 'openssl'
require 'json'

module Tr8n
  class Utils
    def self.normalize_tr_params(label, description, tokens, options)
      return label if label.is_a?(Hash)

      if description.is_a?(Hash)
        return {
          :label        => label,
          :description  => nil,
          :tokens       => description,
          :options      => tokens
        }
      end

      {
        :label        => label,
        :description  => description,
        :tokens       => tokens,
        :options      => options
      }
    end

    def self.guid
      (0..16).to_a.map{|a| rand(16).to_s(16)}.join
    end

    def self.split_by_sentence(text)
      sentence_regex = /[^.!?\s][^.!?]*(?:[.!?](?![\'"]?\s|$)[^.!?]*)*[.!?]?[\'"]?(?=\s|$)/

      sentences = []
      text.scan(sentence_regex).each do |s|
        sentences << s
      end

      sentences
    end

    def self.load_json(file_path, env = nil)
      json = JSON.parse(File.read(file_path))
      return json if env.nil?
      return yml['defaults'] if env == 'defaults'
      yml['defaults'].rmerge(yml[env] || {})
    end

    def self.load_yaml(file_path, env = nil)
      yaml = YAML.load_file(file_path)
      return yaml if env.nil?
      return yaml['defaults'] if env == 'defaults'
      yaml['defaults'].rmerge(yaml[env] || {})
    end

    def self.sign_and_encode_params(params, secret)
      payload = params.merge(:algorithm => 'HMAC-SHA256', :ts => Time.now.to_i).to_json
      payload = Base64.encode64(payload)

      sig = OpenSSL::HMAC.digest('sha256', secret, payload)
      encoded_sig = Base64.encode64(sig)

      URI::encode(Base64.encode64("#{encoded_sig}.#{payload}"))
    end

    def self.decode_and_verify_params(signed_request, secret)
      signed_request = URI::decode(signed_request)
      signed_request = Base64.decode64(signed_request)

      encoded_sig, payload = signed_request.split('.', 2)
      expected_sig = OpenSSL::HMAC.digest('sha256', secret, payload)
      expected_sig = Base64.encode64(expected_sig)
      if expected_sig != encoded_sig
        raise Tr8n::Exception.new("Bad signature")
      end

      JSON.parse(Base64.decode64(payload))
    end

    ######################################################################
    # Author: Iain Hecker
    # reference: http://github.com/iain/http_accept_language
    ######################################################################
    def self.browser_accepted_locales(request)
      request.env['HTTP_ACCEPT_LANGUAGE'].split(/\s*,\s*/).collect do |l|
        l += ';q=1.0' unless l =~ /;q=\d+\.\d+$/
        l.split(';q=')
      end.sort do |x,y|
        raise Tr8n::Exception.new("Not correctly formatted") unless x.first =~ /^[a-z\-]+$/i
        y.last.to_f <=> x.last.to_f
      end.collect do |l|
        l.first.downcase.gsub(/-[a-z]+$/i) { |x| x.upcase }
      end
    rescue
      []
    end

  end
end
