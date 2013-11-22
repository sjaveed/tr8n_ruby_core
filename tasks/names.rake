require 'pp'
#require "active_support/core_ext"

task :names do
  names = {}
  src = File.expand_path(File.join(File.dirname(__FILE__), "..", "spec", "fixtures", "translations", "ru", "names.txt"))
  File.open(src, "r") do |input|
    while (name = input.gets)
      name = name.strip
      next if name.length == 0
      names[name] = {
        'gender' => '',
        'nom' => name,
        'gen' => '',
        'dat' => '',
        'acc' => '',
        'ins' => '',
        'pre' => '',
        'pos' => '',
      }
    end 
  end

  pp names
  dest = File.expand_path(File.join(File.dirname(__FILE__), "..", "spec", "fixtures", "translations", "ru", "names1.json"))
  File.open(dest, "w") do |output|
    output.write(names.to_json)
  end
end