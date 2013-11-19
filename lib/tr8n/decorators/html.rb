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

class Tr8n::Decorators::Html < Tr8n::Decorators::Base

  def decorate(translation_key, language, label, options = {})
    return label if options[:skip_decorations]
    #return label if translation_key.language == language
    return label unless Tr8n.config.current_translator and Tr8n.config.current_translator.inline?
    return label if translation_key.locked? and not Tr8n.config.current_translator.manager?

    element = 'span'
    if options[:use_div]
      element = 'div'
    end

    if translation_key.id.nil?
      return "<#{element} class='tr8n_pending'>#{label}</#{element}>".html_safe
    end

    classes = ['tr8n_translatable']
    
    if translation_key.locked?
      if Tr8n.config.current_translator.feature_enabled?(:show_locked_keys)
        classes << 'tr8n_locked'
      else
        return label
      end
    elsif language.default?
      classes << 'tr8n_not_translated'
    elsif options[:fallback] 
      classes << 'tr8n_fallback'
    elsif options[:translated]
      classes << 'tr8n_translated'
    else
      classes << 'tr8n_not_translated'
    end  

    html = "<#{element} class='#{classes.join(' ')}' data-translation_key_id='#{translation_key.id}'>"
    html << label
    html << "</#{element}>"
    html.html_safe
  end  

end