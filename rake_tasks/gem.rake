require 'rake/gempackagetask'
require File.expand_path(File.dirname(__FILE__) + "/rdoc_options.rb")

namespace :gem do

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

    s.files = FileList[
      '{lib,test}/**/*.rb', 
      'Rakefile', 
      'config/environment.rb',
      "lib/tasks/rdoc_options.rb",
      "lib/tasks/rdoc.rake",
      "lib/tasks/test.rake",
    ]

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

end
