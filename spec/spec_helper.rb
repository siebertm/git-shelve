require "rubygems"
require "spec"
require "mocha"

require "lib/git_shelve"
require File.dirname(__FILE__) + "/all_git_shelves"

module GitShelveSpecHelper
  def setup_repo(path)
    `mkdir -p #{path} && GIT_DIR=#{path} git --bare init`
  end
  
  
  def teardown_repo(path)
    `rm -rf #{path}`
  end
end