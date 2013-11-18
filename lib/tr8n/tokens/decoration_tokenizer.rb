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
    class DecorationTokenizer

      attr_reader :tokens, :fragments, :context, :text, :opts

      RESERVED_TOKEN       = 'tr8n'

      RE_SHORT_TOKEN_START = '\[[\w]*:'
      RE_SHORT_TOKEN_END   = '\]'
      RE_LONG_TOKEN_START  = '\[[\w]*\]'
      RE_LONG_TOKEN_END    = '\[\/[\w]*\]'
      RE_TEXT              = '[^\[\]]+' #'[\w\s!.:{}\(\)\|,?]*'

      def initialize(text, context = {}, opts = {})
        @text = "[#{RESERVED_TOKEN}]#{text}[/#{RESERVED_TOKEN}]"
        @context = context
        @opts = opts
        tokenize
      end

      def tokenize
        re = [RE_SHORT_TOKEN_START,
              RE_SHORT_TOKEN_END,
              RE_LONG_TOKEN_START,
              RE_LONG_TOKEN_END,
              RE_TEXT].join('|')
        @fragments = text.scan(/#{re}/)
        @tokens = []
      end

      def parse
        return @text unless fragments
        token = fragments.shift

        if token.match(/#{RE_SHORT_TOKEN_START}/)
          return parse_tree(token.gsub(/[\[:]/, ''), :short)
        end

        if token.match(/#{RE_LONG_TOKEN_START}/)
          return parse_tree(token.gsub(/[\[\]]/, ''), :long)
        end

        token.to_s
      end

      def parse_tree(name, type = :short)
        tree = [name]
        @tokens << name unless (@tokens.include?(name) or name == RESERVED_TOKEN)

        if type == :short
          first = true
          until fragments.first.nil? or fragments.first.match(/#{RE_SHORT_TOKEN_END}/)
            value = parse
            if first and value.is_a?(String)
              value = value.lstrip
              first = false
            end
            tree << value
          end
        elsif type == :long
          until fragments.first.nil? or fragments.first.match(/#{RE_LONG_TOKEN_END}/)
            tree << parse
          end
        end

        fragments.shift
        tree
      end

      def default_decoration(token_name, token_value)
        default_decoration = Tr8n.config.default_token_value(token_name, :decoration)
        unless default_decoration
          raise Tr8n::Exception.new("Invalid decoration token value #{token_name}")
        end

        default_decoration = default_decoration.clone
        decoration_token_values = context[token_name.to_sym] || context[token_name.to_s] || []

        if decoration_token_values.is_a?(Array)
          params = [token_value, decoration_token_values].flatten
          params.each_with_index do |param, index|
            default_decoration.gsub!("{$#{index}}", param.to_s)
          end

          # clean all the rest of the {$num} params, if any
          param_index = params.size
          while default_decoration.index("{$#{param_index}}")
            default_decoration.gsub!("{$#{param_index}}", "")
            param_index += 1
          end

          return default_decoration
        end

        if decoration_token_values.is_a?(Hash)
          default_decoration.gsub!("{$0}", token_value.to_s)

          decoration_token_values.keys.each do |key|
            default_decoration.gsub!("{$#{key}}", decoration_token_values[key].to_s)
          end

          return default_decoration
        end

        raise Tr8n::Exception.new("Don't know how to process decoration token value")
      end

      def allowed_token?(token)
        return true if opts[:allowed_tokens].nil?
        opts[:allowed_tokens].include?(token)
      end

      def apply(token, value)
        return value if token == RESERVED_TOKEN
        return value unless allowed_token?(token)

        method = context[token.to_sym] || context[token.to_s]

        if method
          if method.is_a?(Proc)
            return method.call(value)
          end

          if method.is_a?(Array) or method.is_a?(Hash)
            return default_decoration(token, value)
          end

          if method.is_a?(String)
            return method.to_s.gsub("{$0}", value)
          end

          raise Tr8n::Exception.new("Invalid decoration token value")
        end

        if Tr8n.config.default_token_value(token, :decoration)
          return default_decoration(token, value)
        end

        raise Tr8n::Exception.new("Missing decoration token value")
      end

      def evaluate(expr)
        unless expr.is_a?(Array)
          return expr
        end

        token = expr[0]
        args = expr.drop(1)
        value = args.map { |a| self.evaluate(a) }.join('')

        apply(token, value)
      end

      def substitute
        evaluate(parse)
      end

    end
  end
end
