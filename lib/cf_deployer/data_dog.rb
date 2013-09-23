class DataDog
  def emit(&block)
    block.call
  end
end