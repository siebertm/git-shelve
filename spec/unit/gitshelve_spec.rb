require File.dirname(__FILE__) + "/../spec_helper.rb"

describe GitShelve::Shelve do
  include GitShelveSpecHelper
  
  before(:each) do
    @path = File.expand_path(File.dirname(__FILE__) + "/tmpgit")
    setup_repo(@path)
    
    @shelve = GitShelve::Shelve.new("mybranch", @path)
  end
  
  after(:each) do
    teardown_repo(@path)
  end
  
  it_should_behave_like "All GitShelves"
  
  describe ".get" do
    it "should raise ObjectNotFoundError when it could not find the specified object" do
      lambda {
        @shelve.get("e30b41f7fbe195d45e702f3cafd0f48ab8d62a50")
      }.should raise_error(GitShelve::ObjectNotFoundError)
    end
  end
end

