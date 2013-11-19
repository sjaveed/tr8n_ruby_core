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
# Data Token Forms:
#
# {count}
# {count:number}
# {user:gender}
# {today:date}
# {user_list:list}
# {long_token_name}
# {user1}
# {user1:user}
# {user1:user::pos}
#
# Data tokens can be associated with any rules through the :dependency
# notation or using the naming convention of the token suffix, defined
# in the tr8n configuration file
#
#######################################################################

class Tr8n::Tokens::Data < Tr8n::Base
  attr_reader :label, :full_name, :short_name, :case_keys, :context_keys

  def self.expression
    /(\{[^_:][\w]*(:[\w]+)*(::[\w]+)*\})/
  end

  def self.parse(label, opts = {})
    tokens = []
    label.scan(expression).uniq.each do |token_array|
      tokens << self.new(label, token_array.first)
    end
    tokens
  end

  def initialize(label, token)
    @label = label
    @full_name = token
    parse_elements
  end

  def parse_elements
    name_without_parens = self.full_name[1..-2]
    name_without_case_keys = name_without_parens.split('::').first.strip

    @short_name = name_without_parens.split(':').first.strip
    @case_keys = name_without_parens.scan(/(::\w+)/).flatten.uniq.collect{|c| c.gsub('::', '')}
    @context_keys = name_without_case_keys.scan(/(:\w+)/).flatten.uniq.collect{|c| c.gsub(':', '')}
  end

  def name(opts = {})
    val = short_name
    val = "#{val}:#{context_keys.join(':')}" if opts[:context_keys] and context_keys.any?
    val = "#{val}::#{case_keys.join('::')}" if opts[:case_keys] and case_keys.any?
    val = "{#{val}}" if opts[:parens]
    val
  end

  def key
    short_name.to_sym
  end

  # used by the translator submit dialog
  def name_for_case_keys(keys)
    keys = [keys] unless keys.is_a?(Array)
    "#{name}::#{keys.join('::')}"
  end

  def sanitize(object, value, options, language)
    value = "#{value.to_s}" unless value.is_a?(String)

    unless Tr8n.config.block_options[:skip_html_escaping]
      if options[:sanitize_values] and not value.html_safe?
        value = ERB::Util.html_escape(value)
      end
    end

    if Tr8n.config.application and not Tr8n.config.application.feature_enabled?(:language_cases)
      return value
    end

    case_keys.each do |key|
      value = apply_case(key, value, object, options, language)
    end

    value
  end

  def context_for_language(language, opts = {})
    if context_keys.any?
      ctx = language.context_by_keyword(context_keys.first)
    else
      ctx = language.context_by_token_name(short_name)
    end

    unless opts[:silent]
      raise Tr8n::Exception.new("Unknown context for a token: #{full_name} in #{language.locale}") unless ctx
    end

    ctx
  end

  ##############################################################################
  #
  # chooses the appropriate case for the token value. case is identified with ::
  #
  # examples:
  #
  # tr("Hello {user::nom}", "", :user => current_user)
  # tr("{actor} gave {target::dat} a present", "", :actor => user1, :target => user2)
  # tr("This is {user::pos} toy", "", :user => current_user)
  #
  ##############################################################################
  def apply_case(key, value, object, options, language)
    lcase = language.language_case_by_keyword(key)
    return value unless lcase
    lcase.apply(value, object, options)
  end

  def decoration?
    false
  end

  ##############################################################################
  #
  # gets the value based on various evaluation methods
  #
  # examples:
  #
  # tr("Hello {user}", "", {:user => [current_user, current_user.name]}}
  # tr("Hello {user}", "", {:user => [current_user, "{$0} {$1}", "param1"]}}
  # tr("Hello {user}", "", {:user => [current_user, :name]}}
  # tr("Hello {user}", "", {:user => [current_user, :method_name, "param1"]}}
  # tr("Hello {user}", "", {:user => [current_user, lambda{|user| user.name}]}}
  # tr("Hello {user}", "", {:user => [current_user, lambda{|user, param1| user.name}, "param1"]}}
  #
  ##############################################################################
  def evaluate_token_method_array(object, method_array, options, language)
    # if single object in the array return string value of the object
    if method_array.size == 1
      return sanitize(object, object.to_s, options, language)
    end

    # second params identifies the method to be used with the object
    method = method_array[1]
    params = method_array[2..-1]
    params_with_object = [object] + params

    # if the second param is a string, substitute all of the numeric params,
    # with the original object and all the following params
    if method.is_a?(String)
      parametrized_value = method.clone
      if parametrized_value.index("{$")
        params_with_object.each_with_index do |val, i|
          parametrized_value.gsub!("{$#{i}}", sanitize(object, val, options.merge(:skip_decorations => true), language))
        end
      end
      return sanitize(object, parametrized_value, options, language)
    end

    # if second param is symbol, invoke the method on the object with the remaining values
    if method.is_a?(Symbol)
      return sanitize(object, object.send(method, *params), options.merge(:sanitize_values => true), language)
    end

    # if second param is lambda, call lambda with the remaining values
    if method.is_a?(Proc)
      return sanitize(object, method.call(*params_with_object), options, language)
    end

    raise Tr8n::Exception.new("Invalid array second token value: #{full_name} in #{label}")
  end

  def self.token_object(token_values, token_name)
    return nil if token_values.nil?
    token_object = token_values[token_name] || token_values[token_name.to_sym]
    return token_object.first if token_object.is_a?(Array)
    return token_object[:object] || token_object['object'] if token_object.is_a?(Hash)
    token_object
  end

  ##############################################################################
  #
  # tr("Hello {user_list}!", "", {:user_list => [[user1, user2, user3], :name]}}
  #
  # first element is an array, the rest of the elements are similar to the
  # regular tokens lambda, symbol, string, with parameters that follow
  #
  # if you want to pass options, then make the second parameter an array as well
  # tr("{user_list} joined the site", "",
  #       {:user_list => [[user1, user2, user3],
  #                         [:name],      # this can be any of the value methods
  #                         { :expandable => true,
  #                           :to_sentence => true,
  #                           :limit => 4,
  #                           :separator => ',',
  #                           :andor => 'and',
  #                           :translate_items => false,
  #                           :minimizable => true
  #                         }
  #                       ]
  #                      ]})
  #
  # acceptable params:  expandable,
  #                     to_sentence,
  #                     limit,
  #                     andor,
  #                     more_label,
  #                     less_label,
  #                     separator,
  #                     translate_items,
  #                     minimizable
  #
  ##############################################################################
  def token_array_value(token_value, options, language)
    objects = token_value.first

    objects = objects.collect do |obj|
      if token_value[1].is_a?(Array)
        evaluate_token_method_array(obj, [obj] + token_value.second, options, language)
      else
        evaluate_token_method_array(obj, token_value, options, language)
      end
    end

    list_options = {
        :translate_items => false,
        :expandable => true,
        :minimizable => true,
        :to_sentence => true,
        :limit => 4,
        :separator => ", ",
        :andor => 'and'
    }

    if token_value[1].is_a?(Array) and token_value.size == 3
      list_options.merge!(token_value.last)
    end

    objects = objects.collect{|obj| obj.translate("List element", {}, options)} if list_options[:translate_items]

    # if there is only one element in the array, use it and get out
    return objects.first if objects.size == 1

    list_options[:expandable] = false if options[:skip_decorations]

    return objects.join(list_options[:separator]) unless list_options[:to_sentence]

    if objects.size <= list_options[:limit]
      return "#{objects[0..-2].join(list_options[:separator])} #{list_options[:andor].translate("", {}, options)} #{objects.last}"
    end

    display_ary = objects[0..(list_options[:limit]-1)]
    remaining_ary = objects[list_options[:limit]..-1]
    result = "#{display_ary.join(list_options[:separator])}"

    unless list_options[:expandable]
      result << " " << list_options[:andor].translate("", {}, options) << " "
      result << "{num|| other}".translate("List elements joiner",
                                            {:num => remaining_ary.size, :_others => "other".pluralize_for(remaining_ary.size)}, options)
      return result
    end

    uniq_id = Tr8n::TranslationKey.generate_key(label, objects.join(","))
    result << "<span id=\"tr8n_other_link_#{uniq_id}\">" << " " << list_options[:andor].translate("", {}, options) << " "
    result << "<a href='#' onClick=\"Tr8n.Utils.Effects.hide('tr8n_other_link_#{uniq_id}'); Tr8n.Utils.Effects.show('tr8n_other_elements_#{uniq_id}'); return false;\">"
    result << (list_options[:more_label] ? list_options[:more_label] : "{num|| other}".translate("List elements joiner", {:num => remaining_ary.size}, options))
    result << "</a></span>"
    result << "<span id=\"tr8n_other_elements_#{uniq_id}\" style='display:none'>" << list_options[:separator]
    result << "#{remaining_ary[0..-2].join(list_options[:separator])} #{list_options[:andor].translate("", {}, options)} #{remaining_ary.last}"

    if list_options[:minimizable]
      result << "<a href='#' style='font-size:smaller;white-space:nowrap' onClick=\"Tr8n.Utils.Effects.show('tr8n_other_link_#{uniq_id}'); Tr8n.Utils.Effects.hide('tr8n_other_elements_#{uniq_id}'); return false;\"> "
      result << (list_options[:less_label] ? list_options[:less_label] : "{laquo} less".translate("List elements joiner", {}, options))
      result << "</a>"
    end

    result << "</span>"
  end

  # evaluate all possible methods for the token value and return sanitized result
  def token_value(object, options, language)
    # token is an array
    if object.is_a?(Array)
      # if you provided an array, it better have some values
      if object.empty?
        return raise Tr8n::Exception.new("Invalid array value for a token: #{full_name}")
      end

      # if the first value of an array is an array handle it here
      if object.first.kind_of?(Enumerable)
        return token_array_value(object, options, language)
      end

      # if the first item in the array is an object, process it
      return evaluate_token_method_array(object.first, object, options, language)
    elsif object.is_a?(Hash)
      # if object is a hash, it must be of a form: {:object => {}, :value => "", :attribute => ""}
      # either value can be passed, or the attribute. attribute will be used first
      if object[:object].nil?
        return raise Tr8n::Exception.new("Hash token is missing an object key for a token: #{full_name}")
      end

      value = object[:value]      || object["value"]
      obj   = object[:object]     || object["object"]
      attr  = object[:attribute]  || object["attribute"]

      unless attr.nil?
        if obj.is_a?(Hash)
          value = obj[attr.to_s] || obj[attr.to_sym]
        else
          value = obj.send(attr)
        end
      end

      if value.nil?
        return raise Tr8n::Exception.new("Hash object is missing a value or attribute key for a token: #{full_name}")
      end

      object = value
    end

    # simple token
    sanitize(object, object.to_s, options, language)
  end

  def allowed_in_translation?
    true
  end

  def implied?
    false
  end

  def substitute(label, context, language, options = {})
    # get the object from the values
    object = hash_value(context, key, :whole => true)

    # see if the token is a default html token
    object = Tr8n.config.default_token_value(key) if object.nil?

    #if object.nil?
    #  raise Tr8n::Exception.new("Missing value for a token: #{full_name}")
    #end

    object = object.to_s if object.nil?

    value = token_value(object, options, language)
    label.gsub(full_name, value)
  end

  def sanitized_name
    name(:parens => true)
  end

  # return sanitized form
  def prepare_label_for_translator(label, language)
    label.gsub(full_name, sanitized_name)
  end

  # return tokenless form
  def prepare_label_for_suggestion(label, index, language)
    label.gsub(full_name, "(#{index})")
  end

  def to_s
    full_name
  end
end
