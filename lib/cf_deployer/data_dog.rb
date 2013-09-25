module CfDeployer
  class DataDog
    def emit(&block)
      block.call
    end
  end
end