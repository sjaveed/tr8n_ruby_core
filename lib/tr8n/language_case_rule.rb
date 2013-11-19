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

class Tr8n::LanguageCaseRule < Tr8n::Base
  belongs_to  :language_case
  attributes  :id, :description, :examples, :conditions, :conditions_expression, :operations, :operations_expression

  def conditions_expression
    self.attributes[:conditions_expression] ||= Tr8n::RulesEngine::Parser.new(conditions).parse
  end

  def operations_expression
    self.attributes[:operations_expression] ||= Tr8n::RulesEngine::Parser.new(operations).parse
  end

  def gender_variables(object)
    return {} unless conditions.index('@gender')
    return {"@gender" => "unknown"} unless object
    context = language_case.language.context_by_keyword(:gender)
    return {"@gender" => "unknown"} unless context
    context.vars(object)
  end

  #######################################################################################################
  ##  Evaluation Methods
  #######################################################################################################

  def evaluate(value, object = nil)
    return false if conditions.nil?

    re = Tr8n::RulesEngine::Evaluator.new
    re.evaluate(["let", "@value", value])

    gender_variables(object).each do |key, value|
      re.evaluate(["let", key, value])
    end

    re.evaluate(conditions_expression)
  rescue Exception => ex
    Tr8n.logger.error("Failed to evaluate language case #{conditions}: #{ex.message}")
    value
  end

  def apply(value)
    value = value.to_s
    return value if operations.nil?

    re = Tr8n::RulesEngine::Evaluator.new
    re.evaluate(["let", "@value", value])

    re.evaluate(operations_expression)
  #rescue Exception => ex
  #  Tr8n.logger.error("Failed to apply language case rule [case: #{language_case.id}] [rule: #{id}] [conds: #{conditions_expression}] [opers: #{operations_expression}]: #{ex.message}")
  #  value
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def to_cache_hash(*attrs)
    return super(attrs) if attrs.any?
    super(:id, :description, :examples, :conditions, :conditions_expression, :operations, :operations_expression)
  end

end