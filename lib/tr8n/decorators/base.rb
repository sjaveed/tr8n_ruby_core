class Tr8n::Decorators::Base < Tr8n::Base
  attributes :language, :translation_key, :label, :options

  def self.decorator(translation_key, language, label, options = {})
    # Tr8n.config.decorator_type
    Tr8n::Decorators::Default.new(
      :translation_key => translation_key,
      :language => language,
      :label => label,
      :options => options
    )
  end

  def decorate
    raise Tr8n::Exception.new("Must be implemented by the extending class")
  end

end
