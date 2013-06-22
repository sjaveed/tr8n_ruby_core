class Tr8n::Decorators::Default < Tr8n::Decorators::Base
  attributes :language, :translation_key, :label, :options

  def decorate
    label
  end
  
end