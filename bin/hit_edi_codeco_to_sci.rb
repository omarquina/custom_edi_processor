# Se lee del directorio de los archivos
#

# se obtienen los datos importantes:
# Equipo
# Fecha de operación
# la Orlando, buen día
#
# Si, se va a mantener el banner de ICI, de igual manera para evaluar la ubicación requerimos que por favor nos mandes una captura.
#
# Quedo atenta a tus comentarios
#
# Saludos cordiales
#
# Tipo de operación
# BL (creo que si es gate out), no siempre viene en los movimientos
$: << './lib/'
puts "CLASSPATH: #{$:}"
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require "erb"
require 'logger'
require 'xmlbuilder'
require 'ftphit_reader'
require 'movimiento'
require 'movimientos'
# leer de FTP


localdir = File.join('.','inputs','hit')
#FTPUpdaterTest.get_files localdir
#Procesar Archivos CODECO
objetos = []
filename = Dir.entries(localdir)[0]

#file = File.open(filename,"r")
#1518704164684VEC_CODECO.edi
#file = File.open( File.join( '.' , 'inputs' , 'hit' , '1518704164684VEC_CODECO.edi' ) )
status = 0
indice = -1
loc = nil
nuevo_objeto = false
<<<<<<< HEAD

$LOG = Logger.new(File.join('.','logs',Time.now.strftime("%d-%m-%Y_%H%M%S.log")))

=begin
files = FTPHitReader.new.files(1) do |file| 
  puts "Leyendo: #{file}"
  Movimiento.new(file).procesar 
=======
file.each_line do |line|
  puts "   LINE: #{line}"
  case line
    when /^EQD\+CN\+(\w*)\+.*'$/ # se crea un registro
      #status = :inicio
      indice+=1
      nuevo_objeto = true
      puts "   EQUIPO: #{$1}"
      objetos[indice] = { origen: nil,destino: nil, hora: nil, fecha:nil,tipo:nil,equipo: $1, bl: nil }
      #loc = 0
    when /^LOC\+9\+(\w*):.*'$/ # DESTINO
      if nuevo_objeto
        puts "   DESTINO: #{$1}"
        objetos[indice][:destino] = $1
        objetos[indice][:tipo] = :gate_in if $1 != 'DOHAI'
      end
      #loc+=1
      # objetos[indice][:origen ]  =   if loc == 0
      # objetos[indice][:destino] =   if loc != 0
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
  
>>>>>>> 41b71feebf854dfe4a0a3f2b7882acd96cd023fb
end
=end

#=begin
filenames = FTPHitReader.new.get_files(1)
movimientos = Movimientos.new(filenames,File.join([".","inputs","hit","processing"])).procesar
#=end
#files.map! do |file|
   #Movimiento.new( file )
#end
 
#files.each do |movimiento|
#  movimiento.procesar
#  puts "Movimientos: #{movimiento.movimientos}"
#end

 
#end

puts "OBJETOS OBTENIDOS: #{movimientos.movimientos.inspect}"

# Actualizar movimientos en SCI
actualizadorSci = ASciMovimientos.new movimientos.movimientos
actualizadorSci.execute

