require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rubygems'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
load 'rcov.rake'

HARDMOCK_VERSION = "1.2.0"

task :default => [ :alltests ]

desc "Run all the tests"
Rake::TestTask.new("alltests") { |t|
  t.libs << "test"
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
}

def add_rdoc_options(options)
  options << '--line-numbers' << '--inline-source' << '--main' << 'README' << '--title' << 'Hardmock'
end

desc "Generate RDoc documentation"
Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "Hardmock: Strict expectation-based mock object library " 
#  rdoc.options << '--line-numbers' << '--inline-source' << '-A cattr_accessor=object' << '--main' 
  add_rdoc_options(rdoc.options)
  rdoc.rdoc_files.include('lib/**/*.rb', 'README','CHANGES','LICENSE')
}

task :showdoc => [ :rerdoc ] do
  sh "open doc/index.html"
end

desc "Generate and upload api docs to rubyforge"
task :upload_doc => :rerdoc do
  sh "scp -r doc/* rubyforge.org:/var/www/gforge-projects/hardmock/doc"
  sh "scp -r homepage/* rubyforge.org:/var/www/gforge-projects/hardmock/"
end



gem_spec = Gem::Specification.new do | s |
  s.name = "hardmock"
  s.version = HARDMOCK_VERSION
  s.author = "David Crosby"
  s.email = "crosby@atomicobject.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "A strict, ordered, expectation-oriented mock object library."
  s.rubyforge_project = 'hardmock'
  s.homepage = "http://hardmock.rubyforge.org"
  s.autorequire =  'hardmock'

  s.files = FileList['{lib,test}/**/*.rb', '[A-Z]*'].exclude('TODO').to_a

  s.require_path = "lib"
  s.test_files = Dir.glob("test/**/*test.rb")

  s.has_rdoc = true
  s.extra_rdoc_files = ["README","CHANGES","LICENSE"]
  add_rdoc_options(s.rdoc_options)
end

Rake::GemPackageTask.new(gem_spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :verify_svn_clean do
	# Get clean
	sh 'svn up'
	status = `svn status` 
	raise "Please get checked-in and cleaned up before releasing.\n#{status}" unless status == ""
end

desc "Create a release tar.gz file."
task :release => [:verify_svn_clean, :alltests, :upload_doc, :repackage] do
  require 'fileutils'
  include FileUtils::Verbose
  proj_root = File.expand_path(File.dirname(__FILE__))
  begin 
    cd proj_root


    # Tag the release by number, then re-tag for stable release (makes nicey nicey for Rails plugin installation)
    sh "svn cp . svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/rel-#{HARDMOCK_VERSION} -m 'Releasing version #{HARDMOCK_VERSION}'"
    sh "svn del svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/hardmock -m 'Preparing to update stable release tag'"
    sh "svn cp . svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/hardmock -m 'Updating stable tag to version #{HARDMOCK_VERSION}'"
 
    puts "UPLOAD #{Dir['pkg/*.*']} TO RUBYFORGE RELEASE ZONE"
  end
end


namespace :ci do
  desc "Continuous integration target"
  task :continuous => [ 'alltests', 'rcov:coverage' ] 
end
