describe "All GitShelves", :shared => true do
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
    
    sha1.should == sha2
    @shelve.fsck.should_not match(/dangling/)
    @shelve.fsck.should_not match(/error/)
    
  end
end