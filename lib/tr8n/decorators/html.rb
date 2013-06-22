class Tr8n::Decorators::Html < Tr8n::Decorators::Base
  attributes :language, :translation_key, :label, :options

  def decorate
    return label if options[:skip_decorations]
    return label if translation_key.language == language
    return label unless Tr8n.config.translator
    return label unless Tr8n.config.translator.inline?
    return label if translation_key.locked? and not Tr8n.config.translator.manager?

    if translation_key.id.nil?
      html = "<tr8n style='border-bottom: 2px dotted #ff0000;'>"
      html << label
      html << "</tr8n>"
      return html.html_safe
    end      

    classes = ['tr8n_translatable']
    
    if locked?
      classes << 'tr8n_locked'
    elsif language.default?
      classes << 'tr8n_not_translated'
    elsif options[:fallback] 
      classes << 'tr8n_fallback'
    else
      classes << (options[:translated] ? 'tr8n_translated' : 'tr8n_not_translated')
    end  

    html = "<tr8n class='#{classes.join(' ')}' translation_key_id='#{id}'>"
    html << label
    html << "</tr8n>"
    html.html_safe
  end  

end