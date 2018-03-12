class FileCodeco < OpenStruct
  #attr_accessor :origen
  #def initialize origen,filtro=""
  #  self.origen = origen
  #end 

  def movimientos
      
  end 

#  def each_line &block
#  end

  def procesar
      
  end

  def file
    puts "FILECODECO#file: dir: #{directorio}, filename: #{ filename}"
    @file ||= File.open(File.join(directorio,filename),"r")
  end
  
  def each_line &block
    puts " FILECODECO: EACH LINE"
    file.each_line &block 
  end
end
