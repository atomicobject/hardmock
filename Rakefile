require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

task :default => [ :testall ]

desc "Run the unit tests in test/unit"
Rake::TestTask.new("testall") { |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
}

Rake::TestTask.new("hardmock") { |t|
  t.libs << "test"
#  t.pattern = 'test/functional/*_test.rb'
  t.test_files = [
#    "test/functional/auto_verify_test.rb",
#    "test/functional/direct_mock_usage_test.rb",
    "test/functional/hardmock_test.rb",
    "test/functional/assert_error_test.rb",
  ]
  t.verbose = true
}

Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Hardmock: Strict expectation-based mock object library " 
  rdoc.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object'
  rdoc.rdoc_files.include('lib/**/*.rb')
}

desc "Generate and upload api docs to rubyforge"
task :upload_doc => :rerdoc do
	user = ENV['user']
	raise "Please specify 'user' parameter" unless user
	sh "scp -r doc/* #{user}@rubyforge.org:/var/www/gforge-projects/hardmock/"
end

#desc "Create a release tar.gz file."
#task :release => [:testall, :upload_doc] do
#	version = ENV['VERSION']
#	raise "Please specify VERSION" unless version
#
#	require 'fileutils'
#	include FileUtils::Verbose
#	proj_root = File.expand_path(File.dirname(__FILE__))
#	begin 
#		cd proj_root
#
#		sh 'svn up'
#		status = `svn status` 
#		raise "!!! Please MAKE SURE TO CHECKIN TO SVN before releasing.\n#{status}" unless status == ""
#
#		sh "svn cp . https://bear.atomicobject.com/svn/devtools/tags/cmock-#{version} -m 'Releasing version #{version}'"
#
#		rm_rf 'release'
#		mkdir 'release'
#		sh 'svn export . release/cmock'
#		cd 'release'
#		sh "tar cvzf ../cmock-#{version}.tar.gz cmock"
#	ensure
#		cd proj_root
#		rm_rf 'release'
#	end
#end
