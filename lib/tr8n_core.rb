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

module Tr8nCore
  module Generators
    module Cache
    end
  end
end

module Tr8n
  module Tokens
  end

  module Rules
  end

  module Decorators
  end

  module CacheAdapters
  end
end

[
 "tr8n/base.rb",
 "tr8n",
 "tr8n/rules_engine",
 "tr8n/tokens",
 "tr8n/decorators",
 "tr8n/cache",
 "tr8n/cache/generators",
 "tr8n_core/ext",
 "tr8n_core/modules",
 "tr8n_core/generators/cache",
].each do |f|
  if f.index('.rb')
    file = File.expand_path(File.join(File.dirname(__FILE__), f))
    require(file)
    next
  end

  Dir[File.expand_path("#{File.dirname(__FILE__)}/#{f}/*.rb")].sort.each do |file|
    require(file)
  end
end

