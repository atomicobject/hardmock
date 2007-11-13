
namespace :release do

  desc "Generate and upload api docs to rubyforge"
  task :upload_doc => 'doc:rerdoc' do
    sh "scp -r doc/* rubyforge.org:/var/www/gforge-projects/hardmock/doc"
    sh "scp -r homepage/* rubyforge.org:/var/www/gforge-projects/hardmock/"
  end

  task :verify_svn_clean do
    sh 'svn up'
    status = `svn status` 
    raise "Please get checked-in and cleaned up before releasing.\n#{status}" unless status == ""
  end

  desc "Release: tag svn version, update stable tag, build and upload docs for hardmock-#{HARDMOCK_VERSION}"
  task :all => ["test:all", "gem:repackage", "release:verify_svn_clean", "release:upload_doc" ] do
    require 'fileutils'
    include FileUtils::Verbose
    begin 
      # Tag the release by number, then re-tag for stable release (makes nicey nicey for Rails plugin installation)
      sh "svn cp . svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/rel-#{HARDMOCK_VERSION} -m 'Releasing version #{HARDMOCK_VERSION}'"
      sh "svn del svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/hardmock -m 'Preparing to update stable release tag'"
      sh "svn cp . svn+ssh://dcrosby42@rubyforge.org/var/svn/hardmock/tags/hardmock -m 'Updating stable tag to version #{HARDMOCK_VERSION}'"
   
      puts "\n!!! NOW YOU MUST UPLOAD #{Dir['pkg/*.*'].join(', ')} TO RUBYFORGE RELEASE ZONE"
    end
  end

end
