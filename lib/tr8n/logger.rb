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

require 'logger'

module Tr8n

  def self.logger
    @logger ||= begin
      logfile_path = File.expand_path(Tr8n.config.log_path)
      logfile_dir = logfile_path.split("/")[0..-2].join("/")
      FileUtils.mkdir_p(logfile_dir) unless File.exist?(logfile_dir)
      logfile = File.open(logfile_path, 'a')
      logfile.sync = true
      Tr8n::Logger.new(logfile)
    end
  end

  class Logger < ::Logger

    def format_message(severity, timestamp, progname, msg)
      "[#{timestamp.strftime("%D %T")}]: #{"  " * stack.size}#{msg}\n"
    end

    def add(severity, message = nil, progname = nil, &block)
      return unless Tr8n.config.logger_enabled?
      super
    end

    def stack
      @stack ||= []
    end

    def trace_api_call(path, params)
      debug("api: [/#{path}] #{params.inspect}")
      stack.push(caller)
      t0 = Time.now
      if block_given?
        ret = yield
      end
      t1 = Time.now
      stack.pop
      debug("call took #{t1 - t0} seconds")
      ret
    end

    def trace(message)
      debug(message)
      stack.push(caller)
      t0 = Time.now
      if block_given?
        ret = yield
      end
      t1 = Time.now
      stack.pop
      debug("execution took #{t1 - t0} seconds")
      ret
    end

  end

end

