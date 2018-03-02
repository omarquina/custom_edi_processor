class Movimiento
  attr_reader :file,:objetos
  def initialize file
    @file = file
    objetos = []
  end

  def procesar
   file.each_line do |line|
      puts "   LINE: #{line}"
     case line
       when /^EQD\+CN\+(\w*)\+.*'$/ # se crea un registro
       #status = :inicio
       indice+=1
      nuevo_objeto = true
      puts "   EQUIPO: #{$1}"
      objetos[indice] = { origen: nil,destino: nil, hora: nil,fecha:nil , tipo:nil , equipo: $1 , bl: nil }
      #loc = 0
    when /^LOC\+9\+(\w*):.*'$/ # DESTINO
      if nuevo_objeto
        puts "   DESTINO: #{$1}"
        objetos[indice][:destino] = $1
        objetos[indice][:tipo] = :gate_in if $1 == 'DOHAI'
      end
    when /^LOC\+11\+(\w*):.*'$/ # Origen
      if nuevo_objeto
        puts "   ORIGEN: #{$1}"
        puts "   ORIGEN objetos[#{indice}]}"
        objetos[indice][:origen] = $1
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
end

  def moviemientos
    objetos
  end

end
