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

class Tr8n::Component < Tr8n::Base
  belongs_to :application
  attributes :key, :name, :description, :state

  def sources
    application.get("component/sources", {:key => key}, {:class => Tr8n::Source, :application => application})
  end

  def translators
    application.get("component/translators", {:key => key}, {:class => Tr8n::Translator, :application => application})
  end

  def languages
    application.get("component/languages", {:key => key}, {:class => Tr8n::Language, :application => application})
  end

  def register_source(source)
    application.post("component/register_source", {:key => key, :source => source.source})
  end

  def restricted?
    state == 'restricted'
  end

  def live?
    state == 'live'
  end

  def translator_authorized?(translator)
    return true unless restricted?
    translators.include?(translator)
  end

  #######################################################################################################
  ##  Cache Methods
  #######################################################################################################

  def self.cache_prefix
    'c@'
  end

  def self.cache_key(key)
    "#{cache_prefix}_[#{key}]"
  end
end
