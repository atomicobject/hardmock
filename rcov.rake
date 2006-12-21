
begin
require 'rcov/rcovtask'

namespace :rcov do

  desc "Generate code coverage HTML report in pkg/coverage"
  Rcov::RcovTask.new(:coverage) do |t|
    t.test_files = FileList['test/unit/**/*.rb'] + FileList['test/functional/**/*.rb']
    t.verbose = true
    t.output_dir = "coverage"
  end

end

rescue 
  puts "RCOV TASK DISABLED"
end
