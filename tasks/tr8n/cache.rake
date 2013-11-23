require 'json'
require 'tr8n_core'

namespace :tr8n do
  namespace :generate_cache do
    task :file do
      Tr8n.config.init_application
      g = Tr8nCore::Generators::Cache::File.new
      g.run
    end
    #task :cdb do
    #  Tr8n.config.init_application
    #  g = Tr8nCore::Generators::Cache::Cdb.new
    #  g.run
    #end
  end
end
