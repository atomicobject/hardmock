desc "Rewrite index.html"
task :index do
  require 'erb'
  @title = "Hardmock - mock objects for Ruby"
  @plugin_install = ""
  @header_html = File.read("page_header.html")
  html = ERB.new(File.read("index.erb")).result(binding)
  fname = "index.html"
  File.open(fname,"w") do |f|
    f.print html
  end
  puts "Wrote #{fname}"
end

task :default => :index
