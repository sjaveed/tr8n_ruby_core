require 'json'
require 'tr8n_core'

namespace :tr8n do
  namespace :cache_adapters do
    task :files do
      Tr8n.config.init_application("http://localhost:3000", "default", "sample")
      g = Tr8nCore::Generators::Cache::File.new
      g.run
    end
  end
end
