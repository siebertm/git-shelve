require File.dirname(__FILE__) + "/../spec_helper.rb"

describe GitShelve::ReplicatedShelve do
  include GitShelveSpecHelper

  before(:each) do
    @path1 = File.expand_path(File.dirname(__FILE__) + "/tmpgit1")
    @path2 = File.expand_path(File.dirname(__FILE__) + "/tmpgit2")

    setup_repo(@path1)
    setup_repo(@path2)
    
    @shelve = GitShelve::ReplicatedShelve.new("mybranch", @path1)
    @shelve2 = GitShelve::ReplicatedShelve.new("mybranch", @path2)
  end
  
  after(:each) do
    teardown_repo(@path1)
    teardown_repo(@path2)
  end

  it_should_behave_like "All GitShelves"
  
  describe ".add_remote" do
    it "should add a remote" do
      @shelve.remotes.should be_empty
      @shelve.add_remote("pathspec")
      @shelve.remotes.should include("pathspec")
    end
  end
  
  describe ".fetch" do
    it "should fetch objects from a given remote repository" do
      @shelve.add_remote(@path2)

      # try 3 times to be sure it works :)
      3.times do |n|
        sha1 = @shelve2.put("this is data number #{n} from remote")
        sha2 = @shelve.put("this is data number #{n} from me")

        # make sure our object is not already in our "local" repo
        lambda { @shelve.get_without_fetch(sha1) }.should raise_error(GitShelve::ObjectNotFoundError)

        @shelve.fetch

        lambda { @shelve.get_without_fetch(sha1) }.should_not raise_error(GitShelve::ObjectNotFoundError)

        @shelve.get_without_fetch(sha1).should == "this is data number #{n} from remote"
        @shelve.get_without_fetch(sha2).should == "this is data number #{n} from me"
      end
      
      @shelve.fsck.should_not match(/dangling/)
      @shelve.fsck.should_not match(/error/)
    end
  end
  
  describe ".push" do
    it "should first call fetch, then push" do
      @shelve.add_remote(@path2)
      @shelve2.add_remote(@path1)
      
      @shelve2.should_receive(:fetch_from).with(@path1).once
      @shelve2.should_receive(:push_to).with(@path1).once
      @shelve2.push
    end
    
    it "should send objects to a remote repository" do
      @shelve.add_remote(@path2)
      @shelve2.add_remote(@path1)
    
      # try 3 times to be sure it works :)
      3.times do |n|
        sha1 = @shelve2.put("this is data number #{n} from remote")
        sha2 = @shelve.put("this is data number #{n} from me")
    
        # make sure our object is not already in our "local" repo
        lambda { @shelve.get_without_fetch(sha1) }.should raise_error(GitShelve::ObjectNotFoundError)
    
        @shelve2.push
    
        lambda { @shelve.get_without_fetch(sha1) }.should_not raise_error(GitShelve::ObjectNotFoundError)
        
        @shelve.get_without_fetch(sha1).should == "this is data number #{n} from remote"
        @shelve.get_without_fetch(sha2).should == "this is data number #{n} from me"
      end
      
      @shelve.fsck.should_not match(/dangling/)
      @shelve.fsck.should_not match(/error/)
    end
  end
  
  describe ".get" do
    it "should try to fetch when it doesn't find the specified objct locally" do
      @shelve.should_receive(:fetch)
      first_time = true
      @shelve.stub!(:get_without_fetch).and_return {
        if first_time
          first_time = false
          raise GitShelve::ObjectNotFoundError
        else
          "test data"
        end
      }
      
      @shelve.get("20eda216cefdf21109f8306a5138a820956fd0f3").should == "test data"
    end
  end
end