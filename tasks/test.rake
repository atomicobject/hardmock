require 'rake/testtask'

namespace :test do

  desc "Run all the tests"
  Rake::TestTask.new("all") { |t|
    t.libs << "test"
    t.pattern = 'test/**/*_test.rb'
    t.verbose = true
  }

end
