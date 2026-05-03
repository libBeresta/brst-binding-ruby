# frozen_string_literal: true

require "fileutils"
require "tmpdir"

# Make sure the gem is loadable before the smoke test loads any FFI module —
# but allow the smoke test itself to skip gracefully when libBeresta is not
# built locally.
$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
