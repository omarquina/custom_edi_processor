#!/usr/bin/ruby

# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require "erb"
require 'logger'


# Clase base para las liberaciones
class Release < OpenStruct
  attr_accessor :siglas_equipo,:equipo_6_digitos,:equipo_ultimo_digito
  attr_accessor :template_dir
  def get_binding; return binding(); end;
 
  def numero_equipo
    @numero_equipo ||= (!self.equipo.index("-").nil?) ? self.equipo.split("-")[1] : self.equipo[4..10]
  end

  def codigo_del_mensaje
    @codigo ||= Time.now.to_f.to_s.delete(".")[-9..-1]
  end

  def siglas_equipo
    @siglas_equipo ||= (!self.equipo.index("-").nil?) ? self.equipo.upcase.split("-")[0] : self.equipo[0..3].upcase
  end

  def equipo_6_digitos
     @equipo_6_digitos ||= self.numero_equipo[0..5]
  end

  def equipo_ultimo_digito
    @equipo_ultimo_digito ||= self.numero_equipo[6]
  end

  def fecha
   @fecha ||= Time.now.strftime("%Y%m%d")
  end

  def hora
    @hora ||= Time.now.strftime("%H%M")
  end

  def equipo_ajustado
    @equipo_ajustado ||= self.equipo.delete('-').upcase
  end

  def template_dir
    @template_dir ||= File.join(".","templates")
  end

  def filename
    @filename ||= equipo_ajustado+".edi"
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

  def template_name
    @template_name ||= '315_caucedo.erb'
  end

  def tamplate_dir
    @tamplate_dir ||= 'templates'
  end

  def template_filename
    File.join( template_dir , template_name )
  end

  #<MAPPING>
  def estatus
    #puts "STATUS: #{self.status}"
    self.status == :release ? 'UA' : 'PU'
  end
  #</MAPPING>

  def outputdir
    @outputdir ||= File.join ["outputs","caucedo","315"]
  end
  
  def output_filename
    File.join(outputdir , self.filename)
  end

  def output message=''
    File.write(output_filename,map)
    # Enviar vía FTP
  end
end

class ReleaseSTWD < ReleaseCaucedo

end

class ReleaseHIT < Release
  TEMPLATE_FLENAME="315_hit.erb"

  def estatus
    self.status == :release ? 'MS' : 'UT'
  end

  def template_name
    @template_name ||= '315_hit.erb'
  end

  def template_filename
    File.join(template_dir,template_name)
  end

  def filename
    self.equipo_ajustado+".edi"
  end
 
  def outputdir
    @outputdir ||= File.join ["outputs","hit","315"]
  end

  def output_filename
    File.join(outputdir,self.filename)
  end

  def output message=''
    File.write(output_filename,map)
    # Enviar vía FTP
  end

  def self.base_filename
    @@filename_base = ["outputs","hit","315"]
    #year = Date.today.year
    #month = Date.today.month
    #dia = Date.today.day
    #Dir.mkdir(File.join(@@filename_base),'')
  end
end

### FTP controller
class FTPUpdater
  attr_writer :logger
  
  def config
    
  end

  def initialize params={}
    
  end

  def logger
    @logger ||= Logger.new
  end

  def ftp
    #puts "GETINg ftp class attribute"
    @ftp ||= init
  end

  def ftp=(value)
    #puts "ASIGNANDO variable de clase ftp #{value}"
    @ftp = value
  end

  def init
    puts "INIt"
    ftp = Net::FTP.new(server)
    ftp.passive = true
    #puts "FTP: #{ftp.inspect}"
    ftp.login usuario,password
    ftp.chdir( File.join( directory ) )
    #puts "LISTADO de FTP: "+( ftp.list.inspect )
    ftp
    #<TODO: capture errors>
  end

  def pre_envio
    #puts "    PRE_ENVIO_FTP:"
    result = `unix2dos #{data.outputdir}`
    #puts "    RESULTADO DE PRE_ENVIO_FTP: #{}"
    result
  end

  def move data
    errors = []
    success = [] 
    #pre_envio data
    $LOG.debug "--------------------------------------------------------"
    data.each do |objeto|
      begin
        puts "MOVE #{self.class.name}: file to move #{objeto.output_filename}"
        $LOG.debug "   Copiando: #{objeto.output_filename}"
        result = ftp.puttextfile( objeto.output_filename )
        #puts "    RESULT: #{result}"
        #puts "    LISTADO FTP: #{ftp.list.inspect}"
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        $LOG.error "    ERROR copiando: #{objeto.output_filename}"
        $LOG.error "          mensaje: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        errors << objeto
      end
    end

    
    $LOG.debug "-------------------------------------------------------------"
    $LOG.debug "   LISTADO de Archivos Transferidos: "
    ftp.ls.each do |filename|
      puts "   REMOTE FILE: #{filename}"
      $LOG.debug "      #{filename}"
    end
 
    [errors,success]
    ensure
      ftp.close
  end

  def clean
    FileUtils.rm_rf(Dir.glob(File.join(directory,'*')))
  end
end

class SFTPUpdater
  def ftp
    #puts "GETINg ftp class attribute"
    @ftp ||= init 
  end

  def ftp=(value)
    #puts "ASIGNANDO variable de clase ftp #{value}"
    @ftp = value
  end

  def connection
    #Net::FTP.new(SERVER)
    Net::SFTP.start(server,usuario,password: password)
    #ftp.passive = true
  end

  def init
    #puts "INIt"
    ftp = connection
    #puts "FTP: #{ftp.inspect}"
    #puts "LOGIN "+(ftp.login USUARIO,PASSWORD).to_s
    # ftp.chdir(File.join(DIRECTORY))
    #puts "LISTADO de FTP: "+(ftp.list.inspect)
    ftp
    #<TODO: capture errors>
  end

  def pre_envio
    
  end

  def move data
    errors = []
    success = [] 

    #pre_envio

    data.each do |objeto|
      begin
        puts "MOVE: file to move #{objeto.output_filename}"
        $LOG.debug "     Copiando: #{objeto.output_filename}"
        #result = ftp.puttextfile( objeto.output_filename )
        result = ftp.upload!( objeto.output_filename,File.join(directory,objeto.filename) )
        #puts "    RESULT: #{result}"
        #puts "    LISTADO FTP: #{ftp.list.inspect}"
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        errors << objeto
      end
        #files = ftp.chdir('pub/lang/ruby/contrib')
        #files = ftp.list('n*')
        #ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
    end

$LOG.debug "-------------------------------------------------------------"
$LOG.debug "LISTADO DE ARCHIVOS TRANSFERIDOS"
    ftp.dir.foreach(directory) do |file|
$LOG.debug "    #{file.longname}"

      puts "  FILE Remoto: #{file.longname}"
    end


    [errors,success]
    ensure
     # ftp.close
  end

  def clean
    FileUtils.rm_rf(Dir.glob(File.join(directory,'*')))
  end
end

class FTPUpdaterDpworld < SFTPUpdater
  USUARIO='ZZVECO'
  PASSWORD='s9rM=6xi'
  SERVER='edi.caucedo.com'
  DIRECTORY=['ZZVECO'] 

  attr_accessor :usuario,:password,:server,:directory

  def initialize params={}
    self.usuario = 'ZZVECO'
    self.password = 's9rM=6xi'
    self.server='edi.caucedo.com'
    self.directory= ['ZZVECO']
  end
end

class FTPUpdaterSTWD < FTPUpdater
  USUARIO='bremat\ftp_stonewood'
  PASSWORD='st123456**'
  SERVER='ftpus.veconinter.com'
  DIRECTORY=['ZIM']

  attr_accessor :usuario,:password,:server,:directory

  def initialize params={}
    self.usuario = 'bremat\ftp_stonewood'
    self.password = 'st123456**'
    self.server='ftpus.veconinter.com'
    self.directory= ['ZIM']
  end
end

class FTPUpdaterHIT < FTPUpdater
  USUARIO='bremat\ftp_hit'
  PASSWORD='hi123456**'
  SERVER='ftpus.veconinter.com'
  DIRECTORY=['Liberaciones']

  attr_accessor :usuario,:password,:server,:directory
  def initialize params={}
    self.usuario = 'bremat\ftp_hit'
    self.password = 'hi123456**'
    self.server='ftpus.veconinter.com'
    self.directory= ['Liberaciones']
    #self.directory = ['Movimientos']
    end
=begin
  def usuario
    @usuario ||= 'bremat\ftp_hit'
  end

  def password
    @password ||= 'hi123456**'
  end
  
  def server
    @server ||= 'ftpus.veconinter.com'
  end

  def directory
    #@directory ||= ['Liberaciones']
    @directory ||= ['Response']
  end
=end
end

class FTPUpdaterTest < FTPUpdater
  USUARIO='omarquina'
  PASSWORD='OrCaItO6562'
  SERVER='localhost'
  DIRECTORY=['/home','omarquina','custom_edi_processor','ftp','test']

  attr_accessor :usuario,:password,:server,:directory

  def initialize params={}
    self.usuario = 'omarquina'
    self.password = 'OrCaItO6562'
    self.server='localhost'
    self.directory= ['/home','omarquina','custom_edi_processor','ftp','test']
  end
=begin
  def ftp
    puts "GETINg ftp class attribute"
    @@ftp ||= init 
  end

  def ftp=(value)
    puts "ASIGNANDO variable de clase ftp #{value}"
    @@ftp = value
  end

  def init
    puts "INIt"
    ftp = Net::FTP.new(server)
    puts "FTP: #{ftp.inspect}"
    puts "LOGIN "+(ftp.login usuario,password).to_s
    ftp.chdir(File.join(directory))
    puts "LISTADO de FTP: "+(ftp.list.inspect)
    ftp
    #<TODO: capture errors>
  end

  def move data
    
    errors = []
    success = [] 

    data.each do |objeto|
      begin
        puts "MOVE: file to move #{objeto.output_filename}"
        result = ftp.puttextfile( objeto.output_filename )
        puts "    RESULT: #{result}"
        #puts "    LISTADO FTP: #{ftp.list.inspect}"
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        puts "    stacktrace: #{e.backtrace}"
        errors << objeto
      end
    end
    [errors,success]
    ensure
      ftp.close
  end

  def clean
    FileUtils.rm_rf(Dir.glob(File.join(DIRECTORY,'*')))
  end

=end
end

##### Por definir donde deben colocarse
def outputs data
  data.each do |data|
    #puts "DATA: #{data.inspect}"
    #puts "  data mapping: #{data.map}"
    #puts "-----"
    data.output
  end
end

#### Origen de los datos
# Leer de la BD

# datos obtenidos de la BD

####
#=begin
dataserver= 'USMIAVS029.bremat.local\MSQL2008'
dataserver= 'USMIAVS033.bremat.local\MSQL2008'
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: dataserver, database: "SCI", encoding: 'UTF-8', use_utf16: 'false'
#results = client.execute("EXEC EnvioNotificacionesSolvencia 0,'EDI','2018-02-01'")
#results = client.execute("SELECT TOP 1 * FROM tfactura")
#results.each do |result|
#  puts "SQL RESUlt: #{result.inspect}"
#end
#=end
$LOG = Logger.new(File.join('.','logs',Time.now.strftime("%d-%m-%Y_%H%M%S.log")))

# OBTENER los equipos a "LIBERAR" de ambos puertos
caucedo_release_data = []
hit_release_data = []

puts "RELEASE"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "OBTENIENDO LIBERACIONES"
results = client.execute("EXEC EnvioNotificacionesSolvencia 0,NULL,'EDI'")

results.each do |fila|
	puts "FILA: #{fila.to_s}"
        $LOG.debug "   LIBERACION: #{fila.to_s}"
        equipo = fila["equipoId"]
        puerto = fila["ptocreacion"]
        status = :release
        tipo_notificacion = fila["solvenciaNotifId"]

        params = { equipo: equipo, status: status,tipo_notificacion: tipo_notificacion }
        case puerto
          when "DOCAU" 
            caucedo_release_data << ReleaseCaucedo.new( params )
          when "DOHAI"
	    hit_release_data << ReleaseHIT.new( params )
        end
end
puts "  CAUCEDO_RELASE_DATA: #{caucedo_release_data.inspect}"
puts "  HIT_RELASE_DATA: #{hit_release_data.inspect}"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "    TOTAL LIBERACIONES:" 
puts "CAUCEDO: #{caucedo_release_data.size}"
$LOG.debug "        CAUCEDO: #{caucedo_release_data.size}"
$LOG.debug "-----------------------------------------------------------"
puts "HIT: #{hit_release_data.size}"
$LOG.debug "        HAINA: #{hit_release_data.size}"
#exit
# OBTENER los equipos a "Bloquear" de ambos puertos
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "-----------------------------------------------------------"
puts "HOLD"
$LOG.debug "OBTENIENDO LOS BLOQUEOS"
results = client.execute("EXEC EnvioNotificacionesSolvencia 4,NULL,'EDI'")
caucedo_hold_data = []
hit_hold_data = []

results.each do |fila|
	puts "FILA: #{fila.to_s}"
        $LOG.debug "    BLOQUEO: #{fila.to_s}"
        equipo = fila["equipoId"]
        puerto = fila["ptocreacion"]
        tipo_notificacion = fila["solvenciaNotifId"]
        status = :hold
        params = { equipo: equipo, status: status,tipo_notificacion: tipo_notificacion }
        case puerto
          when /DOCAU/i
            caucedo_hold_data << ReleaseCaucedo.new( params)
          when /DOHAI/i
	    hit_hold_data << ReleaseHIT.new( params )
        end
end
puts "  CAUCEDO_HOLD_DATA: #{caucedo_hold_data.inspect}"
puts "  HIT_HOLD_DATA: #{hit_hold_data.inspect}"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "    TOTAL de BLOQUEOS:"
puts "CAUCEDO HOLD: #{caucedo_hold_data.size}"
$LOG.debug "        CAUCEDO: #{caucedo_hold_data.size}"
$LOG.debug "-----------------------------------------------------------"
puts "HIT HOLD: #{hit_hold_data.size}"
$LOG.debug "        HAINA: #{hit_hold_data.size}"
################################################################################
# ajuste de datos para mappear respectivo a cada salida
incomming_data = []

test = false
if test
  #require File.join('.','caucedo_test')
  #incomming_data += @caucedo_objects
  #require File.join('.','hit_test')
  #incomming_data += @hit_objects
else
#  incomming_data += caucedo_release_data
#  incomming_data += hit_release_data
#  incomming_data += caucedo_hold_data
#  incomming_data += hit_hold_data
end

#puts "Incoming DATA: #{incomming_data.inspect}"
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

$LOG.debug "-------------------------------------------------------------"
$LOG.debug "ESCRIBIENDO A DISCO ARCHiVOS EDI"
$LOG.debug "-------------------------------------------------------------"
outputs caucedo_release_data 
outputs caucedo_hold_data 
#resultado = `unix2dos outputs/*`
$LOG.debug "    RELEASES CAUCEDO"
#pre_envio_ftp
#exit
=begin
caucedo_release_data.each do |data|
  puts "data mapping: #{data.map}"
  data.output
end
=end
# transferencia de archivos
# PRUEBAS
# RELEASE

#ftpTest = FTPUpdaterTest.new
#errors,success=ftpTest.move caucedo_release_data
#ftpTest.clean
# HOLD
=begin
ftpTest = FTPUpdaterTest.new
ftpTest.move caucedo_hold_data
ftpTest.clean
=end

####
#puts ""
#errors

#=begin
$LOG.debug "Transferencia FTP a STONEWOOD" 
ftpSTWD = FTPUpdaterSTWD.new
errorsStwd,successStwd=ftpSTWD.move caucedo_release_data
$LOG.debug "    Transferencias con:" 
$LOG.debug "       ERR:  #{errorsStwd.size}"
$LOG.debug "       SUCCESS: #{successStwd.size}"
#=end
#=begin
$LOG.debug "Transferencia FTP a DPWOrld" 
ftpDpworld = FTPUpdaterDpworld.new
errorsDpw,successDpw=ftpDpworld.move caucedo_release_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsDpw.inspect} "
$LOG.debug "     SUCCESS: #{successDpw.inspect} "
#=end


#exit
puts "CAUCEDO HOLD:"
$LOG.debug "HOLD CAUCEDO"
#caucedo_hold_data.each do |data|
#  puts "    data mapping: #{data.map}"
#  data.output
#end
# envío de archivos vía FTP
# CAUCEDO
#=begin
$LOG.debug "Transferencia FTP a STONEWOOD" 
ftpSTWD = FTPUpdaterSTWD.new
errorsStwd,successStwd=ftpSTWD.move caucedo_hold_data
$LOG.debug "    Transferencias con:" 
$LOG.debug "       ERR:  #{errorsStwd.size}"
$LOG.debug "       SUCCESS: #{successStwd.size}"
#=end
#=begin
$LOG.debug "Transferencia FTP a DPWOrld" 
ftpDpworld = FTPUpdaterDpworld.new
errorsDpw,successDpw=ftpDpworld.move caucedo_hold_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsDpw.inspect} "
$LOG.debug "     SUCCESS: #{successDpw.inspect} "
#=end

# notificación de la operación a personal clave vía email


puts "HAINA RELEASE:"

$LOG.debug "-------------------------------------------------------------"
$LOG.debug "ESCRIBIENDO A DISCO ARCHiVOS EDI"
outputs hit_release_data 
outputs hit_hold_data 
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "    RELEASES HAINA"

#=begin
$LOG.debug "Transferencia FTP a HAINA" 
ftpHIT = FTPUpdaterHIT.new
errorsHIT,successHIT=ftpHIT.move hit_release_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsHIT.inspect} "
$LOG.debug "     SUCCESS: #{successHIT.inspect} "
#=end
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "HOLD HAINA"
#=begin
$LOG.debug "Transferencia FTP a HAINA" 
ftpHIT = FTPUpdaterHIT.new
errorsHIT,successHIT=ftpHIT.move hit_hold_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsHIT.inspect} "
$LOG.debug "     SUCCESS: #{successHIT.inspect} "
#=end
