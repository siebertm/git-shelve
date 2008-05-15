# ==== GitShelve
# GitShelve makes it possible to store arbitrary data in a separate branch
# of a git repository
# This class was inspired and is loosely based upon John Wiegley's 
# git_shelve.py and git-issues python scripts (http://github.com/jwiegley/git-issues/tree/master)
#
# === Example Usage
#
#   shelve = GitShelve.new("mybranch", "/path/to/repository.git")
#   sha1 = shelve.put("some data")
#
#   shelve.get(sha1)
#   #-> "some data"
#
#   sha1 = shelve.put do |f|
#     # f is an IO object streaming directly into git!
#     f.write("i can ")
#     f.write("stream my data ")
#     f.write("in chunks!")
#   end
#
#   shelve.get(sha1)
#   #-> "i can stream my data in chunks!"
#
#   shelve.get(sha1) do |f|
#     # this works the same with get!
#     data = f.read
#   end
#
#   data
#   #-> "i can stream my data in chunks!"
#
# === Author
# Michael Siebert <siebertm85@googlemail.com>
#
# This piece of software wouldn't be possible without Git. Thanks
# go out to the people who invented git!
class GitShelve
  
  # Creates and initilializes a new Gitshelve object
  # 
  # ==== Parameters
  #   branch<String>:: the name of the branch to store objects in
  #   repo<String>:: the path to the git repository to work on. Defaults to the current directory
  def initialize(branch, repo = ".")
    @branch = branch
    @repository = File.expand_path(repo)
    @head = nil
  end
  
  # get a file from the repository
  #
  # ==== Parameters
  #   sha1<String>:: the SHA1 of the object to retrieve
  #   &block:: if you supply a block, it gets yield with the IO object so you can read data directly from that stream
  #
  # ==== Returns
  #   String:: the object's data if you didn't supply a block, otherwise nothing
  def get(sha1, &block)
    git('cat-file', 'blob', sha1, :strip => false, &block)
  end
  
  # saves data to the repository
  #
  # ==== Parameters
  #   data<String>:: the data to store
  #   &block:: if you supply a block, it gets yield with the IO object so you can write data directly to that stream
  #
  # ==== Returns
  #   String:: the SHA1 of the saved data (keep this!)
  def put(data = nil, &block)
    # write blob into repo
    sha1 = git('hash-object', '-w', "--stdin", :input => data, &block)
    sha1_first = sha1[0..1]
    sha1_last = sha1[2..-1]
    
    # Merge this blob with existing issue blobs that share the same
    # first two hash digits
    ls_tree = git('ls-tree', '-r', current_head, '--', sha1_first)
    ls_tree.gsub!(/\t#{sha1_first}\//, "\t")
    ls_tree.gsub!(/100644 blob #{sha1}\t#{sha1_last}/, '')
    ls_tree += "\n" unless ls_tree.empty?
    
    tree = git('mktree', :input => "#{ls_tree}100644 blob #{sha1}\t#{sha1_last}\n")
    
    # Merge it into the tree of issues overall
    ls_tree = git('ls-tree', current_head)
    ls_tree.gsub!(/040000 tree [0-9a-f]{40}\t#{sha1_first}\n/, '')
    ls_tree += "\n" unless ls_tree.empty?
    

    tree = git('mktree', :input => "#{ls_tree}040000 tree #{tree}\t#{sha1_first}\n")

    # Commit the merged tree (though at this moment it's a dangling commit)
    commit = git('commit-tree', tree, '-p', current_head, :input => "Added #{sha1}")

    # Update the HEAD of the branch to point to the commit we
    # just made.
    update_head(commit)
    
    sha1
  end
  
  protected
  
  # returns the sha1 of the branch
  # ==== Returns
  #   String:: SHA1-Hash
  def current_head
    git("rev-parse", @branch, "2>&1")
  rescue GitError
    create_branch
  end
  
  # Make the current branch point to the new head
  # ==== Parameters
  #   new_head<SHA1>
  #
  # ==== Returns
  #   SHA1:: new_head
  def update_head(new_head)
    if @head
      git('update-ref', 'refs/heads/%s' % @branch, new_head, @head)
    else
      git('update-ref', 'refs/heads/%s' % @branch, new_head)
    end

    @head = new_head
  end
  
  # try smart when creating the branch.
  # first checks if there is a remote branch and uses this if there is.
  # otherwise, creates a commit and from there the branch
  #
  # ==== Returns
  #   String:: the SHA1 hash of the branches HEAD
  def create_branch
    begin
      hash = git('rev-parse', "origin/#{@branch}", "2>&1")
    rescue GitError
      hash = git('hash-object', '-w', '--stdin', :input => "Created #{@branch} branch\n")
      hash = git('mktree', :input => "100644 blob #{hash}\tproject\n")
      hash = git('commit-tree', hash, :input => "created #{@branch} branch")
    end

    git('branch', @branch, hash)
    hash
  end
  
  # passes the command over to git
  # 
  # ==== Parameters
  #   cmd<String>:: the git command to execute
  #   *rest:: any number of String arguments to the command, followed by an options hash
  #   &block:: if you supply a block, you can communicate with git throught a pipe. NEVER even think about closing the stream!
  #
  # ==== Options
  #   :strip<Boolean>:: true to strip the output String#strip, false not to to it
  #
  # ==== Raises
  #   GitError:: if git returns non-null, an Exception is raised
  #
  # ==== Returns
  #   String:: if you didn't supply a block, the things git said on STDOUT, otherwise noting
  def git(cmd, *rest, &block)
    if rest.last.kind_of?(Hash)
      options = rest.last
      args = rest[0..-2]
    else
      options = {}
      args = rest
    end
    
    options[:strip] = true unless options.key?(:strip)
    
    ENV["GIT_DIR"] = @repository
    cmd = "git-#{cmd} #{args.join(' ')}"

    result = ""
    IO.popen(cmd, "w+") do |f|
      if input = options.delete(:input)
        f.write(input)
        f.close_write
      elsif block_given?
        yield f
        f.close_write
      end
      
      result = ""
      
      while !f.eof
        result << f.read
      end
    end
    status = $?
    
    result.strip! if options[:strip] == true
    
    if status != 0
      raise GitError.new("Error: #{cmd} returned #{status}. Result: #{result}")
    end
    
    result
  end
end

class GitError < Exception
end