class StringCodeco < OpenStruct
  
  def initialize origen,filtro=""
    self.origen = origen
  end

  def procesar &block
     
  end
  
  def each_line &block
    origen.split("\n").each { |line| yield line }
  end

end
