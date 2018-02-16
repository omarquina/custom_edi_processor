# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'fileutils'
require "erb"

# Clase base para las liberaciones
class Release < OpenStruct
  attr_accessor :siglas_equipo,:equipo_6_digitos,:equipo_ultimo_digito
  attr_accessor :template_dir
  def get_binding; return binding(); end;
 
  def numero_equipo
    @numero_equipo ||= (!self.equipo.index("-").nil?) ? self.equipo.split("-")[1] : self.equipo[4..10]
  end

  def codigo_del_mensaje
    Time.now.to_i.to_s[0..5]
  end

  def siglas_equipo
	  @siglas_equipo ||= (!self.equipo.index("-").nil?) ? self.equipo.split("-")[0] : self.equipo[0..3]
  end

  def equipo_6_digitos
	  @equipo_6_digitos ||= self.numero_equipo[0..5]
  end

  def equipo_ultimo_digito
	  @equipo_ultimo_digito ||= self.numero_equipo[6]
  end

  def fecha
    Time.now.strftime("%Y%m%d")
  end

  def hora
    Time.now.strftime("%H%M")
  end

  def equipo_ajustado
    self.equipo.delete('-')
  end

  def template_dir
    @template_dir ||= File.join(".","templates")
  end

  def filename
    equipo_ajustado+".edi"
  end
## Escritura vía FTP
  def contenido

  end 
### <MAPPING>
#<TODO: EXTRAER y mejorar>
  def map
    @map ||= template.result(self.get_binding)
  end

  def template
    @template ||= ERB.new(contenido)
  end 

  def contenido
    File.read(self.template_filename)
  end
## <MAPPING>
end

class ReleaseCaucedo < Release
  TEMPLATE_NAME='315_caucedo.erb'
  #<MAPPING>
  def estatus
    #puts "STATUS SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSsss: #{self.status}"
    self.status == :release ? 'UA' : 'PU'
  end
  #</MAPPING>

  def template_filename
    File.join(template_dir,TEMPLATE_NAME)
  end

  def output_filename
    File.join("outputs","caucedo","315",self.filename)
  end

  def output message=''
    File.write(output_filename,map)
    # Enviar vía FTP
  end
end

class ReleaseHIT < Release
  TEMPLATE_FLENAME="315_hit.erb"

  def estatus
    'MS'
  end

  def template_filename
    File.join(template_dir,TEMPLATE_FILENAME)
  end

  def filename
    "HIT-"+self.equipo_ajustado+".edi"
  end
 
  def output_filename
    File.join("outputs","hit","315",self.filename)
  end

  def output message=''
    File.write(output_filename,map)
    # Enviar vía FTP
  end

  def self.base_filename
    @@filename_base = ["outputs","hit","315"]
    Date.today
    Dir.mkdir(File.join(*@@filename_base),'') 
  end
end

### FTP controller
class FTPUpdater
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
    ftp.chdir(File.join(DIRECTORY))
    puts "LISTADO de FTP: "+(ftp.list.inspect)
    ftp
    #<TODO: capture errors>
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
end

class FTPUpdaterDpworld < FTPUpdater
  USUARIO='ZZVECO'
  PASSWORD='s9rM=6xi'
  SERVER='ftpus.veconinter.com'
end

class FTPUpdaterSTWD < FTPUpdater
  USUARIO='bremat\ftp_stonewood'
  PASSWORD='st123456**'
  SERVER='ftpus.veconinter.com'
end

class FTPUpdaterHIT < FTPUpdater
  USUARIO='bremat\ftp_hit'
  PASSWORD='hi123456**'
  SERVER='ftpus.veconinter.com'
end

class FTPUpdaterTest < FTPUpdater
  USUARIO='omarquina'
  PASSWORD='OrCaItO6562'
  SERVER='localhost'
  DIRECTORY=['/home','omarquina','custom_edi_processor','ftp','test']

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
    puts "FTP: #{ftp.inspect}"
    puts "LOGIN "+(ftp.login USUARIO,PASSWORD).to_s
    ftp.chdir(File.join(DIRECTORY))
    puts "LISTADO de FTP: "+(ftp.list.inspect)
    ftp
    #<TODO: capture errors>
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
end
##### Por definir donde deben colocarse
def outputs data
  data.each do |data|
    puts "  data mapping: #{data.map}"
    data.output
  end
end

#### Origen de los datos
# Leer de la BD

# datos obtenidos de la BD

####
#=begin
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: 'USMIAVS029.bremat.local\MSQL2008', database: "SCI", encoding: 'UTF-8', use_utf16: 'false'
#results = client.execute("EXEC EnvioNotificacionesSolvencia 0,'EDI','2018-02-01'")
#results = client.execute("SELECT TOP 1 * FROM tfactura")
#results.each do |result|
#  puts "SQL RESUlt: #{result.inspect}"
#end
#=end

# OBTENER los equipos a "LIBERAR" de ambos puertos
caucedo_release_data = []
hit_release_data = []

puts "RELEASE"
results = client.execute("EXEC EnvioNotificacionesSolvencia 0,NULL,'EDI'")

results.each do |fila|
	puts "FILA: #{fila.to_s}"
        equipo = fila["equipoId"]
        puerto = fila["ptocreacion"]
        status = :release
        params = { equipo: equipo, status: status }
        case puerto
          when "DOCAU" 
            caucedo_release_data << ReleaseCaucedo.new( params )
          when "DOHAI"
	    hit_release_data << ReleaseHIT.new( params )
        end
end
puts "CAUCEDO: #{caucedo_release_data.size}"
puts "HIT: #{hit_release_data.size}"
# OBTENER los equipos a "Bloquear" de ambos puertos
puts "HOLD"
results = client.execute("EXEC EnvioNotificacionesSolvencia 4,NULL,'EDI'")
caucedo_hold_data = []
hit_hold_data = []

results.each do |fila|
	puts "FILA: #{fila.to_s}"
        equipo = fila["equipo"]
        puerto = fila["ptocreacion"]
        status = :release
        params = { equipo: equipo, status: status }
        case puerto
          when /DOCAU/i
            caucedo_hold_data << ReleaseCaucedo.new( params)
          when /DOHAI/i
	    hit_hold_data << ReleaseHIT.new( params )
        end
end
puts "CAUCEDO HOLD: #{caucedo_hold_data.size}"
puts "HIT HOLD: #{hit_hold_data.size}"
################################################################################
# ajuste de datos para mappear respectivo a cada salida
incomming_data = []

test = false
if test
  #require File.join('.','caucedo_test')
  #incomming_data += @caucedo_objects
  require File.join('.','hit_test')
  incomming_data += @hit_objects
else
  incomming_data += caucedo_release_data
  incomming_data += hit_release_data
  incomming_data += caucedo_hold_data
  incomming_data += hit_hold_data
end

puts "Incoming DATA: #{incomming_data.inspect}"
# mapeo de salida
messages = []
################### <SPIKES>
=begin
template_dir = File.join(".","templates")
puts "TAMPLAtE DIr: #{template_dir}"
template_file = File.join(template_dir,"315_caucedo.erb")
content = File.read(template_file)
template = ERB.new(content,0,'<')
#puts "  incomming_data.binding: #{incomming_data}"
puts "BInding: #{incomming_data[0].get_binding.inspect}"
puts "template exists: #{File.exists?(template_file)}"
objeto = incomming_data[0]
puts "equipo: #{objeto.equipo}"
puts "equipo numero: #{objeto.numero_equipo}"
puts "equipo SIGLAS: #{objeto.siglas_equipo}"
puts "equipo 6 digitos: #{objeto.equipo_6_digitos}"
puts "equipo ultimo digito: #{objeto.equipo_ultimo_digito}"
=end
########</SPIKES>
#### PROCESAR data de entrada
# PARA TEST 
=begin
incomming_data.each do |objeto|
  puts "--------------------------------------"
  contenido = File.read(objeto.template_filename)
  template = ERB.new(contenido)
  message = template.result(objeto.get_binding)
  puts "  equipo: #{objeto.equipo}, siglas: #{objeto.siglas_equipo}, numero: #{objeto.numero_equipo}"
  puts "------"
  puts "ERB. template: #{message}"
  messages << {objeto: objeto,mensaje: message}
  ## process de output
  objeto.output message
  #File.write(File.join("outputs","caucedo","315",objeto.filename+".edi"),message)
end
=end

# Generación de archivos
# CAUCECO
puts "CAUCEDO RELEASE:"
outputs caucedo_release_data 
=begin
caucedo_release_data.each do |data|
  puts "data mapping: #{data.map}"
  data.output
end
=end
# transferencia de archivos
errors,success=FTPUpdaterTest.move caucedo_release_data
FTPUpdaterTest.clean
errors
exit
puts "CAUCEDO HOLD:"
caucedo_hold_data.each do |data|
  puts "    data mapping: #{data.map}"
  data.output 
end
# envío de archivos vía FTP
# CAUCEDO
FTPUpdaterTest.move caucedo_release_data
FTPUpdaterTest.clean

# notificación de la operación a personal clave vía email

