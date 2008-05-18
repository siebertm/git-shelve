module GitShelve
  class ReplicatedShelve < Shelve
    def initialize(branch, repo = ".", remotes = [])
      @remotes = remotes
      
      super(branch, repo)
    end
    
    
    attr_reader :remotes
    
    # Add a remote repository to fetch from or push to
    #
    # ==== Parameters
    #   pathspec<String>:: the path to the repository. see http://www.kernel.org/pub/software/scm/git/docs/git-push.html#URLS for URLs git should understand
    #
    # ==== Raises
    #   ArgumentError:: when the pathspec is empty
    def add_remote(pathspec)
      raise ArgumentError("pathspec must be valid! (pathspec=#{pathspec.inspect})") if pathspec.nil? || pathspec.empty?
      @remotes << pathspec unless @remotes.include?(pathspec)
    end
    
    # tries to get the object with the given sha1.
    # if it does not exist and pull_before is false, it pulls the changes
    # and tries again
    #
    # ==== Parameters
    #   sha1<String>:: the SHA1 Hash of the object
    #   pull_before<Boolean>:: if true, it pulls from the remote before
    #                          trying to get the object (do this if you know
    #                          the objects not local). defaults to false
    #   &block:: if you supply a block, it gets yield with the IO object so you can read data directly from that stream
    #
    # ==== Raises
    #   ObjectNotFoundError:: if the object cannot be found
    #
    # ==== Returns
    #   String:: the object's data if you didn't supply a block, otherwise nothing
    def get_with_fetch(sha1, allow_fetch = true, &block)
      do_fetch = false unless do_fetch
      
      if do_fetch
        fetch
      end
      
      get_without_fetch(sha1, &block)
    rescue ObjectNotFoundError
      if allow_fetch && do_fetch == false
        do_fetch = true
        retry
      else
        raise
      end
    end
    alias_method :get_without_fetch, :get
    alias_method :get, :get_with_fetch
    
    # fetches data from all remote repositories
    def fetch
      remotes.each do |remote|
        fetch_from(remote)
      end
    end
    
    # sends its data to all remote repositories
    def push
      remotes.each do |remote|
        fetch_from(remote)
        push_to(remote)
      end      
    end
    
    
    protected
    
    def fetch_from(remote)
      git('fetch-pack', '--no-progress', remote, @branch, '2>/dev/null')
      
      # get the head
      commit = git('ls-remote', '--heads', remote, @branch).split("\t").first
      
      headname = headname_for(remote)
      if git_status('rev-parse', headname, '2>&1') == 0
        git('update-ref', headname, commit, headname)
      else
        git('update-ref', headname, commit)
      end
    end
    
    def push_to(remote)
      git('send-pack', '--verbose', remote, "#{@branch}:#{headname_for(remote)}", '2>&1')
    end
    
    def headname_for(remote)
      "refs/heads/#{remote.gsub(/[^a-zA-Z0-9_-]/, "_")}"
    end
    
  end
end