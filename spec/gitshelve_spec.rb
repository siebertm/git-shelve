require "rubygems"
require "spec"
require "lib/git_shelve"

describe GitShelve do
  def setup_repo(path)
    `mkdir #{path} && cd #{path} && git --bare init`
  end
  
  
  def teardown_repo(path)
    if File.exist?(File.join(path, "HEAD"))
      `rm -rf #{path}`
    end
  end
  
  before(:each) do
    @path = File.expand_path(File.dirname(__FILE__) + "/tmpgit")
    setup_repo(@path)
    
    @shelve = GitShelve.new("mybranch", @path)
  end
  
  after(:each) do
    teardown_repo(@path)
  end
  
  it "should return an sha1 hash when saving a blob" do
    @shelve.put("hallo").length.should == 40
  end
  
  it "should be able to retrieve the data of an existing sha1 hash" do
    sha1 = @shelve.put("hallo test\n123\n")
    
    @shelve.get(sha1).should == "hallo test\n123\n"
  end
  
  it "should be able to retrieve a (large) file in chunks by supplying a block" do
    orig_data = "hallo test\n123\n"*2000
    sha1 = @shelve.put(orig_data)
    
    data = ""
    @shelve.get(sha1) do |f|
      while !f.eof
        data << f.read(200)
      end
    end
    
    data.should == orig_data
  end
  
  it "should be able to store a (large) file in chunks by supplying a block" do
    chunk = "hallo test\n123\n"
    
    sha1 = @shelve.put do |f|
      2000.times do
        f.write(chunk)
      end
    end

    @shelve.get(sha1).should == chunk*2000
  end
  
  it "should return the same sha1 hash when another object with the same contents is stored" do
    sha1 = @shelve.put("hallo test\n123\n")
    sha2 = @shelve.put("hallo test\n123\n")
    `git-fsck 2>/dev/null | grep dangling | wc -l`.strip.should == "0"
    `git-fsck 2>/dev/null | grep error | wc -l`.strip.should == "0"
    
    sha1.should == sha2
  end
end