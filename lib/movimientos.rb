require 'string_codeco'
require 'FileCodeco'

class Movimientos #< Array
  #include Enumerable 
  attr_accessor :current
  attr_accessor :origenes,:directorio
  attr_accessor :movimientos

  def objeto
    @objeto ||= Movimiento
  end
 
  def crear_objeto #origen=""
    puts "MOVIMIENTOS#nuevo_objeto"
    self.current = objeto.new #origen
    self.movimientos << self.current
    puts "   CURRENT: #{current}"
    #current
  end

  def process_origenes origenes,directorio
    origenes.map! do |origen|
     # case origen
     #   when String
     #     StringCodeco.new origen
     #   when File
     #     FileCodeco.new( filename: origen , directorio: directorio )
     # end
    end
  end

  def initialize origenes=[],directorio="."
    self.origenes = origenes #process_origenes origenes,directorio
    self.directorio = directorio 
    self.movimientos = []
  end

#  def movimientos
#    self
#  end

  def reset

  end

  def close_current
    self.current = nil
  end 

  def procesar
    puts "MOVIMIENTOS#procesar"
    origenes.map! do |origen|
       #origen.procesar do |line| 
       puts "ORIGEN.class: #{origen.inspect}"
       origen.each_line do |line|
         puts "LINE: #{line}"
         case line
           when /^EQD\+CN\+(\w*)\+.*'$/ # se crea un registro
        #status = :inicio
          #indice+=1
          #nuevo_objeto = true
          puts "   EQUIPO: #{$1}"
          #objetos[indice] = { origen: nil,destino: nil, hora: nil,fecha:nil , tipo:nil , equipo: $1 , bl: nil }
          crear_objeto #origen
          current.origen_de_datos = origen
          current.equipo = $1
          #objetos.current
          #loc = 0
        when /^LOC\+9\+(\w*):.*'$/ # DESTINO
          #if nuevo_objeto
          if current
            puts "   ORIGEN: #{$1}"
            current.origen = $1
            current.tipo = :gate_in if $1 == 'DOHAI'
            #objetos[indice][:origen] = $1
            #objetos[indice][:tipo] = :gate_in if $1 == 'DOHAI'
          end
       when /^LOC\+11\+(\w*):.*'$/ # Origen
         #if nuevo_objeto
         if current
           puts "   Destino: #{$1}"
           #puts "   DESTINO #{objetos[indice]}"
           current.destino = $1
           current.tipo = :gate_out if $1 == 'DOHAI' 
           #objetos[indice][:destino] = $1
           #objetos[indice][:tipo] = :gate_out if $1 == 'DOHAI' 
         end
       when /^FTX\+BL\+(\w*)'$/
         puts "    BL: #{$1}"
         #objetos[indice][:bl] = $1
         current.bl = $1
       when /^CNT\+16\:1'$/
         puts "    CERRANDO el objeto"
         nuevo_objeto = false
         close_current
       when /^DTM\+\d:(\w{8})(\w{4}):.*'$/ 
         #if nuevo_objeto
         if current
           puts "      FECHA: #{$1}"
           puts "      HORA: #{$2}"
           current.fecha = $1
           current.hora = $2 
           #objetos[indice][:fecha] = $1
           #objetos[indice][:hora]  = $2
         end
      end
   end
   puts " Objetos Obtenidos: #{movimientos.inspect}"
  end
   self
end
#  end

  def procesar_ 
    indice = -1
    #objetos = []
    nuevo_objeto = false
    each_line do |line|
      puts "LINE: #{line}"
      case line
        when /^EQD\+CN\+(\w*)\+.*'$/ # se crea un registro
        #status = :inicio
          indice+=1
          nuevo_objeto = true
          puts "   EQUIPO: #{$1}"
          objetos[indice] = { origen: nil,destino: nil, hora: nil,fecha:nil , tipo:nil , equipo: $1 , bl: nil }
          #objetos.current
          #loc = 0
        when /^LOC\+9\+(\w*):.*'$/ # DESTINO
          if nuevo_objeto
            puts "   ORIGEN: #{$1}"
            objetos[indice][:origen] = $1
            objetos[indice][:tipo] = :gate_in if $1 == 'DOHAI'
          end
       when /^LOC\+11\+(\w*):.*'$/ # Origen
         if nuevo_objeto
           puts "   Destino: #{$1}"
           #puts "   DESTINO #{objetos[indice]}"
           objetos[indice][:destino] = $1
           objetos[indice][:tipo] = :gate_out if $1 == 'DOHAI' 
         end
       when /^FTX\+BL\+(\w*)'$/
         puts "    BL: #{$1}"
         objetos[indice][:bl] = $1
       when /^CNT\+16\:1'$/
         puts "    CERRANDO el objeto"
         nuevo_objeto = false
       when /^DTM\+\d:(\w{8})(\w{4}):.*'$/ 
         if nuevo_objeto
           puts "      FECHA: #{$1}"
           puts "      HORA: #{$2}"
           objetos[indice][:fecha] = $1
           objetos[indice][:hora]  = $2
         end
      end
   end
   puts " Objetos Obtenidos: #{objetos.inspect}"
  self
end

end
