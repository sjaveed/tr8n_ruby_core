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

#######################################################################
#
# Decoration Token Forms:
#
# [link: click here]
# or
# [link] click here [/link]
#
# Decoration Tokens Allow Nesting:
#
# [link: {count} {_messages}]
# [link: {count||message}]
# [link: {count||person, people}]
# [link: {user.name}]
#
#######################################################################
module Tr8n
  module Tokens
    class DataTokenizer

      attr_accessor :text, :context, :tokens, :opts

      def self.supported_tokens
        [Tr8n::Tokens::Data, Tr8n::Tokens::Hidden, Tr8n::Tokens::Method, Tr8n::Tokens::Transform]
      end

      def initialize(text, context={}, opts={})
        self.text = text
        self.context = context
        self.opts = opts
        self.tokens = []
        tokenize
      end

      def tokenize
        self.tokens = []
        self.class.supported_tokens.each do |klass|
          self.tokens << klass.parse(self.text)
        end
        self.tokens.flatten!.uniq!
      end

      def token_allowed?(token)
        return true unless opts[:allowed_tokens]
        not opts[:allowed_tokens][token.name].nil?
      end

      def substitute(language, options = {})
        label = self.text
        tokens.each do |token|
          next unless token_allowed?(token)
          label = token.substitute(label, context, language, options)
        end
        label
      end

    end
  end
end
