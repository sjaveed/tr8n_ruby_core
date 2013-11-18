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

module Tr8n
  module RulesEngine

    class Parser
      attr_reader :tokens, :expression

      def initialize(expression)
        @expression = expression
        if expression =~ /^\(/
          @tokens = expression.scan(/[()]|\w+|@\w+|[\+\-\!\|\=>&<\*\/%]+|".*?"|'.*?'/)
        end
      end

      def parse
        return @expression unless tokens
        token = tokens.shift
        return nil if token.nil?
        return parse_list if (token) == '('
        return token[1..-2].to_s if token =~ /^['"].*/
        return token.to_i if token =~ /\d+/
        token.to_s
      end

      def parse_list
        list = []
        list << parse until tokens.empty? or tokens.first == ')'
        tokens.shift
        list
      end

      def class_for(token)
        {
          /^[\(]$/    => 'open_paren',
          /^[\)]$/    => 'close_paren',
          /^['|"]/    => 'string',
          /^@/        => 'variable',
          /^[\d|.]+$/ => 'number',
        }.each do |regexp, cls|
          return cls if regexp.match(token)
        end
        'symbol'
      end

      def decorate
        html = ["<span class='tr8n_sexp'>"]
        if tokens
          html << tokens.collect do |token|
            "<span class='#{class_for(token)}'>#{token}</span>"
          end.join('')
        else
          html << "<span class='#{class_for(expression)}'>#{expression}</span>"
        end
        html << '</span>'
        html.join('').html_safe
      end

    end

  end
end
