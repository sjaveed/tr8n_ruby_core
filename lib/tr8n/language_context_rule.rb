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

class Tr8n::LanguageContextRule < Tr8n::Base
  belongs_to  :language_context
  attributes  :keyword, :description, :examples, :conditions, :conditions_expression

  def fallback?
    keyword.to_s.to_sym == :other
  end

  def conditions_expression
    self.attributes[:conditions_expression] ||= Tr8n::RulesEngine::Parser.new(conditions).parse
  end

  #######################################################################################################
  ##  Evaluation Methods
  #######################################################################################################

  def evaluate(vars = {})
    return true if fallback?

    re = Tr8n::RulesEngine::Evaluator.new
    vars.each do |key, value|
      re.evaluate(["let", key, value])
    end

    re.evaluate(conditions_expression)
  #rescue Exception => ex
  #  Tr8n.logger.error("Failed to evaluate settings context rule #{conditions_expression}: #{ex.message}")
  #  false
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def to_cache_hash(*attrs)
    return super(attrs) if attrs.any?
    super(:keyword, :description, :examples, :conditions, :conditions_expression)
  end

end
