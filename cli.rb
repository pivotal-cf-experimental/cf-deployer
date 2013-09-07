class Cli
  class Options < Struct.new(:release_name, :deploy_branch, :deploy_env, :promote_branch, :tag, :tokens, :interactive)    
    def tokens?
      !!tokens
    end
    
    def interactive?
      !!interactive
    end
  end
  
  def initialize(args)
    @args = args
    @options = Options.new("cf-release", "master", nil, nil, nil, true, true)
  end
  
  def parse!
    parser.parse!(@args)
    
    if @options.deploy_env.nil?
      puts "deploy_env is required\n\n"
      puts parser
      exit 1
    end
    
    @options
  end
  
  private
  
  def parser
    @parser ||= OptionParser.new do |opts|
      opts.banner = "Example: ci_deploy.rb -d tabasco"

      opts.on(
        "-r RELEASE_NAME", 
        "--release RELEASE_NAME", 
        %Q{Release repositories to deploy (i.e. "cf-release" or "cf-services-release") DEFAULT: #{@options.release_name}}
      ) do |release_name|
        @options.release_name = release_name
      end  

      opts.on(
        "-b DEPLOY_BRANCH", 
        "--branch DEPLOY_BRANCH", 
        %Q{Release repository branch to deploy (i.e. "master", "a1", "rc") DEFAULT: #{@options.deploy_branch}}
      ) do |deploy_branch|
        @options.deploy_branch = deploy_branch
      end

      opts.on(
        "-d DEPLOY_ENV",
        "--deploy DEPLOY_ENV",
        %Q{Name of environment to deploy to (i.e. "tabasco", "a1")}
      ) do |deploy_env|
        @options.deploy_env = deploy_env
      end

      opts.on(
        "-p PROMOTE_BRANCH",
        "--promote PROMOTE_BRANCH",
        %Q{Branch to promote to after a successful deploy (i.e. "release-candidate", "deployed-to-prod")}
      ) do |promote_branch|
        @options.promote_branch = promote_branch
      end

      opts.on(
        "-t TAG",
        "--tag-with TAG",
        %Q{Tag to establish after a successful deploy (i.e. "v138")}
      ) do |tag|
        @options.tag = tag
      end

      opts.on(
        "--[no-]tokens", 
        %Q{Adding service tokens DEFAULT true}
      ) do |tokens|
        @options.tokens = tokens
      end
      
      opts.on(
        "-i", 
        "--[no-]interactive", 
        %Q{Run bosh interactively DEFAULT: #{@options.interactive}}
      ) do |interactive|
        @options.interactive = interactive
      end
    end
  end
end
