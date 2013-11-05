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

class Tr8n::Translator < Tr8n::Base
  belongs_to :application
  attributes :id, :name, :email, :gender, :mugshot, :link, :inline
  attributes :voting_power, :rank, :level, :locale, :manager, :code, :access_token 

  def self.authorize(application, username, password, options = {})
    data = application.get('oauth/request_token', {:grant_type => :password, :username => username, :password => password})
    init(application, data['access_token'])
  end

  def self.init(application, access_token)
    application.get('translator', {:access_token => access_token}, {:class => Tr8n::Translator, :attributes => {
      :application => application, 
      :access_token => access_token
    }})
  end

  def applications
    application.get("translator/applications", {:access_token => access_token}, {:class => Tr8n::Application})
  end  

  def translations
    application.get("translator/translations", {:access_token => access_token}, {:class => Tr8n::Application})
  end  

end