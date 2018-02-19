# Se lee del directorio de los archivos
#

# se obtienen los datos importantes:
# Equipo
# Fecha de operación
# Tipo de operación
# BL (creo que si es gate out), no siempre viene en los movimientos


# leer de FTP

require 'net/ftp'
class FTPUpdaterTest #< FTPUpdater
  USUARIO='bremat\ftp_hit'
  PASSWORD='hi123456**'
  SERVER='ftpus.veconinter.com'
  DIRECTORY=['/Liberaciones']
  DIRECTORY=['Movimientos']

  def self.ftp
    puts "GETINg ftp class attribute"
    @@ftp ||= init 
  end

  def self.ftp=(value)
    puts "ASIGNANDO variable de clase ftp #{value}"
    @@ftp = value
  end

  def self.init
    puts "INIt"
    ftp = Net::FTP.new(SERVER)
    ftp.passive = true
    puts "FTP: #{ftp.inspect}"
    puts "LOGIN "+(ftp.login USUARIO,PASSWORD).to_s
    puts "FTP Cambio de directorioo pwd: #{ftp.pwd}"
    result = ftp.chdir(File.join(DIRECTORY))
    puts "FTP Cambio de directorioo pwd: #{ftp.pwd}"
    #puts "LISTADO INICIAL de FTP: "+(ftp.ls('1518735722495VEC_CODECO.edi'))
    #puts "LISTADO de FTP: "+(ftp.list.inspect)
    #<TODO: capture errors>
    ftp 
  end

  def self.move data
    errors = []
    success = []

    data.each do |objeto|
      begin
        puts "MOVE: file to move #{objeto.output_filename}"
        result = ftp.puttextfile( objeto.output_filename )
        puts "    RESULT: #{result}"
        puts "    LISTADO FTP: #{ftp.list.inspect}"
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        puts "    stacktrace: #{e.backtrace}"
        errors << objeto
      end
        #files = ftp.chdir('pub/lang/ruby/contrib')
        #files = ftp.list('n*')
        #ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
    end

    [errors,success]
    ensure
      ftp.close
  end

  def self.clean
    FileUtils.rm_rf(Dir.glob(File.join(DIRECTORY,'*')))
  end

  def self.get_files localdir="inputs/"
    #puts "leer: listado: #{ftp.nlst('*')}"
    #files = ftp.ls('*')
    #puts "   1rst FILE: #{files[0].inspect}"
    filenames = ftp.nlst('*')
    #puts "   1rst FILE 2: #{files2[0].inspect}"
    filenames.each do |filename|
      #puts "   LEER Copiando archivo: #{filename}"
      local_filename = File.join(localdir,filename)
      ftp.gettextfile( filename , local_filename )
      #puts "   FILES COPIADOS: "+Dir.entries(localdir).to_s
    end
    #puts "    LOCAL DIR: #{Dir.entries(localdir).inspect}"
    ensure
    ftp.close
  end
end

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

puts "OBJETOS OBTENIDOS: #{objetos.inspect}"
