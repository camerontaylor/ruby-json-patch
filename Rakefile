# -*- ruby -*-

require 'rubygems'
require 'hoe'

Hoe.plugins.delete :rubyforge
Hoe.plugin :minitest
Hoe.plugin :gemspec # `gem install hoe-gemspec`
Hoe.plugin :git     # `gem install hoe-git`

Hoe.spec 'hana' do
  developer('Cameron Taylor', 'camerontaylor@gmail.com')
  self.readme_file   = 'README.md'
  self.history_file  = 'CHANGELOG.rdoc'
  self.extra_rdoc_files  = FileList['*.rdoc']
  extra_dev_deps << ["minitest", "~> 5.0"]
end
