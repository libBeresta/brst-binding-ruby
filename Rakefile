require "bundler/gem_tasks"

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  # rspec is a dev dependency; fine if absent in production
end

desc "Regenerate FFI bindings from libBeresta gen/data/*.lsp"
task :generate, [:gen_data_dir] do |_, args|
  data_dir = args[:gen_data_dir] || ENV["BRST_GEN_DATA_DIR"] ||
             File.expand_path("../libBeresta/gen/data", __dir__)
  ruby "-Igenerator/lib", "generator/bin/brst-binding-ruby-gen",
       "--data-dir", data_dir,
       "--out-dir", "lib/brst/binding/ruby"
end

task default: :spec
