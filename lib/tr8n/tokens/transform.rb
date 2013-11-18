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
# Transform Token Form
#
# {count:number || one: message, many: messages} 
# {count:number || one: сообщение, few: сообщения, many: сообщений, other: много сообщений}   in other case the number is not displayed#
#
# {count | message}   - will not include {count}, resulting in "messages" with implied {count}
# {count | message, messages} 
#
# {count:number | message, messages} 
#
# {user:gender | he, she, he/she}
#
# {user:gender | male: he, female: she, other: he/she}
#
# {now:date | did, does, will do}
# {users:list | all male, all female, mixed genders}
#
# {count || message, messages}  - will include count:  "5 messages" 
# 
####################################################################### 

class Tr8n::Tokens::Transform < Tr8n::Tokens::Data
  attr_reader :pipe_separator, :piped_params

  def self.expression
    /(\{[^_:|][\w]*(:[\w]+)*(::[\w]+)*\s*\|\|?[^{^}]+\})/
  end

  def parse_elements
    name_without_parens = @full_name[1..-2]
    name_without_pipes = name_without_parens.split('|').first.strip
    name_without_case_keys = name_without_pipes.split('::').first.strip

    @short_name = name_without_pipes.split(':').first.strip
    @case_keys = name_without_pipes.scan(/(::\w+)/).flatten.uniq.collect{|c| c.gsub('::', '')}
    @context_keys = name_without_case_keys.scan(/(:\w+)/).flatten.uniq.collect{|c| c.gsub(':', '')}

    @pipe_separator = (full_name.index("||") ? "||" : "|")
    @piped_params = name_without_parens.split(pipe_separator).last.split(",").collect{|param| param.strip}
  end

  def displayed_in_translation?
    pipe_separator == "||"
  end

  def implied?
    not displayed_in_translation?
  end

  # return with the default transform substitution
  def prepare_label_for_translator(label, language)
    substitution_value = ""
    substitution_value << sanitized_name if displayed_in_translation?
    substitution_value << " " unless substitution_value.blank?

    context = context_for_language(language)

    values = generate_value_map(piped_params, context)

    substitution_value << (values[context.default_rule] || values.values.first)

    label.gsub(full_name, substitution_value)
  end

  # return only the internal part
  def prepare_label_for_suggestion(label, index, language)
    context = context_for_language(language)
    values = generate_value_map(piped_params, context)

    label.gsub(full_name, values[context.default_rule] || values.values.first)
  end

  # token:      {count|| one: message, many: messages}
  # results in: {"one": "message", "many": "messages"}
  #
  # token:      {count|| message}
  # transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "message", "other": "messages"}
  #
  # token:      {count|| message, messages}
  # transform:  [{"one": "{$0}", "other": "{$0::plural}"}, {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "message", "other": "messages"}
  #
  # token:      {user| Dorogoi, Dorogaya}
  # transform:  ["unsupported", {"male": "{$0}", "female": "{$1}", "other": "{$0}/{$1}"}]
  # results in: {"male": "Dorogoi", "female": "Dorogaya", "other": "Dorogoi/Dorogaya"}
  #
  # token:      {actors:|| likes, like}
  # transform:  ["unsupported", {"one": "{$0}", "other": "{$1}"}]
  # results in: {"one": "likes", "other": "like"}
  def generate_value_map(params, context)
    values = {}

    if params.first.index(':')
      params.each do |p|
        nv = p.split(':')
        values[nv.first.strip] = nv.last.strip
      end
      return values
    end

    unless context.token_mapping
      raise Tr8n::Exception.new("The token context #{context.keyword} does not support transformation for unnamed params: #{full_name}")
    end

    token_mapping = context.token_mapping

    # "unsupported"
    if token_mapping.is_a?(String)
      raise Tr8n::Exception.new("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
    end

    # ["unsupported", "unsupported", {}]
    if token_mapping.is_a?(Array)
      if params.size > token_mapping.size
        raise Tr8n::Exception.new("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
      end
      token_mapping = token_mapping[params.size-1]
      if token_mapping.is_a?(String)
        raise Tr8n::Exception.new("The token mapping #{token_mapping} does not support #{params.size} params: #{full_name}")
      end
    end

    # {}
    token_mapping.each do |key, value|
      values[key] = value
      value.scan(/({\$\d(::\w+)*})/).each do |matches|
        token = matches.first
        parts = token[1..-2].split('::')
        index = parts.first.gsub('$', '').to_i

        if params.size < index
          raise Tr8n::Exception.new("The index inside #{context.token_mapping} is out of bound: #{full_name}")
        end

        # apply settings cases
        value = params[index]
        if Tr8n::RequestContext.container_application.feature_enabled?(:language_cases)
          parts[1..-1].each do |case_key|
            lcase = Tr8n::LanguageCase.by_keyword_and_language(case_key, context.language)
            unless lcase
              raise Tr8n::Exception.new("Language case #{case_key} for context #{context.keyword} is not defined: #{full_name}")
            end
            value = lcase.apply(value)
          end
        end
        values[key] = values[key].gsub(token, value)
      end
    end

    values
  end

  def substitute(label, context, language, options = {})
    object = self.class.token_object(context, key)

    unless object
      raise Tr8n::Exception.new("Missing value for a token: #{full_name}")
    end

    if piped_params.empty?
      raise Tr8n::Exception.new("Piped params may not be empty: #{full_name}")
    end

    language_context = context_for_language(language)

    piped_values = generate_value_map(piped_params, language_context)

    rule = language_context.find_matching_rule(object)
    return label unless rule

    value = piped_values[rule.keyword]
    if value.nil? and language_context.fallback_rule
      value = piped_values[language_context.fallback_rule.keyword]
    end

    return label unless value

    substitution_value = []
    if displayed_in_translation?
      substitution_value << token_value(context, options, language)
      substitution_value << " "
    end
    substitution_value << value

    label.gsub(full_name, substitution_value.join(""))
  end
  
end
