Gem::Specification.new do |s|
  s.name = "git_shelve"
  s.version = "0.1"
  s.date = "2008-05-18"
  s.summary = "Store arbitrary data in a git repository"
  s.authors = ["Michael Siebert"]
  s.email = "siebertm85@googlemail.com"
  s.homepage = "http://www.siebert-wd.de/projects/git-shelve"
  s.description = "GitShelve makes it possible to store arbitrary data in a separate branch of a git repository"
  s.has_rdoc = true
  s.files = %w(git_shelve.gemspec LICENSE README.textile lib/git_shelve.rb lib/git_shelve/shelve.rb lib/git_shelve/replicated_shelve.rb spec/all_git_shelves.rb spec/spec_helper.rb spec/unit/gitshelve_spec.rb spec/unit/replicated_shelve_spec.rb)
  s.test_files = %w(spec/all_git_shelves.rb spec/spec_helper.rb spec/unit/gitshelve_spec.rb spec/unit/replicated_shelve_spec.rb)
  s.rdoc_options = ["--main", "README.textile"]
  s.extra_rdoc_files = ["LICENSE", "README.textile"]
end