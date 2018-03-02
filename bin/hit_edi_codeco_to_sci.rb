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
# leer de FTP


localdir = File.join('.','inputs','hit')
#FTPUpdaterTest.get_files localdir
#Procesar Archivos CODECO
objetos = []
filename = Dir.entries(localdir)[0]

file = File.open(filename,"r")
#1518704164684VEC_CODECO.edi
file = File.open( File.join( '.' , 'inputs' , 'hit' , '1518704164684VEC_CODECO.edi' ) )
status = 0
indice = -1
loc = nil
nuevo_objeto = false

$LOG = Logger.new(File.join('.','logs',Time.now.strftime("%d-%m-%Y_%H%M%S.log")))

files = FTPHitReader.new.files(1) do |file| 
  puts "Leyendo: #{file}"
  Movimiento.new file
end

files.map! do |file|
   
   Movimiento.new( file )
end
 
files.each do |movimiento|
  movimiento.procesar
  puts "Movimientos: #{movimiento.movimientos}"
end

 
#end

puts "OBJETOS OBTENIDOS: #{objetos.inspect}"
