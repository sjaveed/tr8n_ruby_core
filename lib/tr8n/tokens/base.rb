#--
# Copyright (c) 2010-2013 Michael Berkovich, tr8nhub.com
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

class Tr8n::Tokens::Base
  
  def self.register_data_tokens(label)
    tokens = []
    Tr8n.config.data_token_classes.each do |token_class|
      tokens << token_class.parse(label)
    end
    tokens.flatten
  end

  def self.register_decoration_tokens(label)
    tokens = []
    Tr8n.config.decoration_token_classes.each do |token_class|
      tokens << token_class.parse(label)
    end
    tokens.flatten
  end

  def self.expression
    raise Tr8n::Exception.new("This method must be implemented in the extending class")
  end

  def self.parse(label)
    tokens = []
    label.scan(expression).uniq.each do |token_array|
      tokens << self.new(label, token_array.first) 
    end
    tokens
  end

  def initialize(label, token)
    @label = label
    @full_name = token 
  end

  def original_label
    @label
  end

  def full_name
    @full_name
  end

  def declared_name
    @declared_name ||= full_name.gsub(/[{}\[\]]/, '')
  end

  def name
    @name ||= declared_name.split(':').first.strip
  end

  def sanitized_name
    "{#{name}}"
  end

  def name_key
    name.to_sym
  end

  def pipeless_name
    @pipeless_name ||= declared_name.split('|').first
  end

  def case_key
    return nil unless declared_name.index('::')
  
    @case_key ||= begin
      cases = declared_name.scan(/((::[\w]+)+)/).flatten.uniq
      if cases.any?
        cases.last.gsub("::", "")
      else
        nil
      end
    end
  end

  def supports_cases?
    true
  end

  def supports_rules?
    true
  end

  def has_case_key?
    not case_key.nil?
  end

  def caseless_name
    @caseless_name ||= begin
      if has_case_key?
        pipeless_name.gsub("::#{case_key}", "")
      else  
        pipeless_name
      end
    end
  end

  def name_with_case
    return name unless has_case_key?
    "#{name}::#{case_key}"
  end

  def name_for_case(case_key)
    "#{name}::#{case_key}"
  end

  def sanitized_name_for_case(case_key)
    "{#{name_for_case(case_key)}}"
  end

  ##############################################################################
  # Token of a form {user:gender,value}  
  def types
    return nil unless caseless_name.index(':')
    @types ||= begin 
      parts = caseless_name.split(':')
      if parts.size == 1 # provided : without a type
        nil
      else
        parts.last.split(',').collect{|part| part.strip}
      end
    end
  end

  # Token type can either be defined inline or configured through a suffix
  # {user:gender} or {user}  - user will respond to gender rule in both cases
  #
  # TODO: make it possible for a token to respond to multiple types
  # {user:gender,value::pos}
  def has_types?
    not (types.nil? or types.empty?)
  end

  def associated_rule_types
    @associated_rule_types ||= has_types? ? types : Tr8n.config.rule_types_by_token_name(name)
  end

  # get languages rules that correspond to this token
  def language_rule_classes
    @language_rule_classes ||= begin
      rule_classes = [] 
      associated_rule_types.each do |type|
        unless Tr8n.config.rule_class_by_type(type)
          raise Tr8n::Exception.new("Undefined rule type #{type} for #{full_name}")
        end
        rule_classes << Tr8n.config.rule_class_by_type(type)
      end 
      rule_classes
    end
  end

  def transformable_language_rule_classes
    @transformable_language_rule_classes ||= language_rule_classes.select{|klass| klass.transformable?}
  end

  def sanitize_token_value(object, value, options, language)
    value = "#{value.to_s}" unless value.is_a?(String)
  
    unless options[:skip_html_escaping] || Tr8n.config.block_options[:skip_html_escaping]
      if options[:sanitize_values] and not value.html_safe?
        value = ERB::Util.html_escape(value)
      end
    end

    if has_case_key?
      value = apply_case(object, value, options, language)
    end
  
    value
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
      return sanitize_token_value(object, object.to_s, options, language)
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
           parametrized_value.gsub!("{$#{i}}", sanitize_token_value(object, val, options.merge(:skip_decorations => true), language))  
        end
      end
      return sanitize_token_value(object, parametrized_value, options, language)
    end

    # if second param is symbol, invoke the method on the object with the remaining values
    if method.is_a?(Symbol)
      if object.is_a?(Hash)
        return sanitize_token_value(object, object[:method], options.merge(:sanitize_values => true), language)
      end        
      return sanitize_token_value(object, object.send(method, *params), options.merge(:sanitize_values => true), language)
    end

    # if second param is lambda, call lambda with the remaining values
    if method.is_a?(Proc)
      return sanitize_token_value(object, method.call(*params_with_object), options, language)
    end
  
    raise Tr8n::Exception.new("Invalid array second token value: #{full_name} in #{original_label}")
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
  #                           :translate_items => false,
  #                           :minimizable => true,
  #                           :and_or => 'and'
  #                         }
  #                       ]
  #                      ]})
  # 
  # acceptable params:  expandable, 
  #                     to_sentence, 
  #                     limit, 
  #                     separator, 
  #                     translate_items,
  #                     minimizable
  #
  ##############################################################################
  def default_list_options 
    {
      :translate_items => false,
      :expandable => true,
      :minimizable => true,
      :to_sentence => true,
      :limit => 4,
      :separator => ", ",
      :description => nil,
      :and_or => 'and'
    }
  end

  def token_array_value(token_value, options, language) 
    objects = token_value.first
  
    list_options = default_list_options
  
    if token_value.size == 3 and token_value[1].is_a?(Array)
      list_options.merge!(token_value.last) 
    end

    # get actual values for the objects
    objects = objects.collect do |obj|
      if token_value[1].is_a?(Array)
        value = evaluate_token_method_array(obj, [obj] + token_value[1], options, language)
      else
        value = evaluate_token_method_array(obj, token_value, options, language)
      end

      if list_options[:translate_items]
        value = language.translate(value, list_options[:description], {}, options)
      end

      value
    end

    # if there is only one element in the array, use it and get out
    return objects.first if objects.size == 1 

    return objects.join(list_options[:separator]) unless list_options[:to_sentence]

    list_options[:expandable] = false if options[:skip_decorations]

    joiner = language.translate(list_options[:and_or], nil, {}, options)

    if objects.size <= list_options[:limit]
      return "#{objects[0..-2].join(list_options[:separator])} #{joiner} #{objects.last}"
    end

    display_ary = objects[0..(list_options[:limit]-1)]
    remaining_ary = objects[list_options[:limit]..-1]
  
    others = language.translate("{num||other}", list_options[:description], {:num => remaining_ary.size}, options)

    unless list_options[:expandable]
      return "#{display_ary.join(list_options[:separator])} #{joiner} #{others}"
    end             

    # TODO: move to decorators
    guid = Tr8n::Helper.guid     

    html = ["#{display_ary.join(list_options[:separator])}"]
    html << "<span id=\"tr8n_other_link_#{guid}\">"
    html << " #{joiner} "
    html << "<a href='#' onClick=\"Tr8n.Effects.hide('tr8n_other_link_#{guid}'); Tr8n.Effects.show('tr8n_other_elements_#{guid}'); return false;\">"
    html << others
    html << "</a></span>"

    html << "<span id=\"tr8n_other_elements_#{guid}\" style='display:none'>" 
    html << list_options[:separator]
    html << "#{remaining_ary[0..-2].join(list_options[:separator])} #{joiner} #{others}"
    if list_options[:minimizable]
      html << "<a href='#' style='font-size:smaller;white-space:nowrap' onClick=\"Tr8n.Effects.show('tr8n_other_link_#{guid}'); Tr8n.Effects.hide('tr8n_other_elements_#{guid}'); return false;\"> "
      html << language.translate("{laquo} less", nil, {}, options)    
      html << "</a>"
    end
    html << "</span>"
    html.join
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
    end
    
    if object.is_a?(Hash) 
      # if object is a hash, it must be of a form: {:object => {}, :value => "", :attribute => ""}
      # either value can be passed, or the attribute. attribute will be used first
      if object[:object].nil?
        return raise Tr8n::Exception.new("Hash token is missing an object key for a token: #{full_name}")
      end

      value = object[:value]

      unless object[:attribute].nil?
        if object[:object].is_a?(Hash)
          value = object[:object][object[:attribute]]
        else
          value = object[:object].send(object[:attribute])
        end
      end

      if value.nil?
        return raise Tr8n::Exception.new("Hash object is missing a value or attribute key for a token: #{full_name}")
      end

      object = value
    end

    # simple token
    sanitize_token_value(object, object.to_s, options, language)    
  end

  def allowed_in_translation?
    true
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
  def apply_case(object, value, options, language)
    return value unless Tr8n.config.application.enable_language_cases?
    lcase = language.case_for(case_key)
    return value unless lcase
    lcase.apply(object, value, options)
  end

  def substitute(translation_key, language, label, values, options)
    # get the object from the values
    object = values[name_key]

    # see if the token is a default html token  
    object = language.application.default_data_token(name_key) if object.nil?

    if object.nil? and not values.key?(name_key) 
      raise Tr8n::Exception.new("Missing value for a token: #{full_name}")
    end
  
    if object.nil? and not Tr8n.config.allow_nil_token_values?
      raise Tr8n::Exception.new("Token value is nil for a token: #{full_name}")
    end
  
    object = object.to_s if object.nil?
  
    value = token_value(object, options, language)
    label.gsub(full_name, value)
  end

  def to_s
    full_name
  end
end