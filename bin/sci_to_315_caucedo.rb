#!/usr/bin/ruby

# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require "erb"
require 'logger'
require 'xmlbuilder'
require_relative '../lib/release'

class NotificadorSCI
  def self.to_xml data
    #xml = XMLBuilder.new
    #xml.List do
    #  data.each {|element| xml.add element.to_xml }
    #end
    #xml.str
    # =================================
    content = ""
    data.each {|objeto| content += objeto.to_xml+"\n" }
    xml = "<List>\n"
    xml << "#{content.to_s}"
    xml << "</List>"
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
        objeto.exito!
        success << objeto
      rescue => e
        puts "ERROR: #{e.message}"
        $LOG.error "    ERROR copiando: #{objeto.output_filename}"
        $LOG.error "          mensaje: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        objeto.error!
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
        objeto.exito!
      rescue => e
        puts "ERROR: #{e.message}"
        #puts "    stacktrace: #{e.backtrace}"
        errors << objeto
        objeto.error!
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
    #self.directory= ['ZZVECO','Response']
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
    #self.directory= ['STWD']
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

def clasificador origen,params
  origen.each do |data|
    params.each do |filter,objeto|
      objeto << Notificacion.new(data) if filter == [ origen['ptocreacion'],origen['solvenciaNotidId'] ]
    end
  end
end

#TO-FIX: maybe create Data object
def basic_clasificator origen,dpworld_data,stwd_data,hit_data
  origen.each do |params|
	puts "FILA: #{params.to_s}"
        $LOG.debug "   LIBERACION: #{params.to_s}"
        case [ params['ptocreacion'] , params['solvenciaNotifId'] ]
            when ['DOCAU',1]
              dpworld_data << ReleaseCaucedo.new( params )
            when ['DOCAU',4]
              stwd_data << ReleaseSTWD.new( params )
            when ['DOHAI',2]
	      hit_data << ReleaseHIT.new( params )
        end
  end
  [dpworld_data,stwd_data,hit_data]
end

#### Origen de los datos
# Leer de la BD

# datos obtenidos de la BD

####
#=begin
#dataserver= 'USMIAVS029.bremat.local\MSQL2008'
dataserver= 'USMIAVS033.bremat.local\MSQL2008'
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: dataserver, database: "SCI", encoding: 'UTF-8', use_utf16: 'false'

config=<<-SQLCONF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_WARNINGS ON
SET ANSI_PADDING ON
set quoted_identifier ON
set arithabort ON
SQLCONF
client.execute(config)


# OBTENER los equipos a "LIBERAR" de ambos puertos
dpworld_release_data = []
stwd_release_data = []
hit_release_data = []

dpworld_hold_data = []
stwd_hold_data = []
hit_hold_data = []

status_notificacion = 0
#status_notificacion = 2
results_liberacion = client.execute("EXEC EnvioNotificacionesSolvencia #{status_notificacion},NULL,'EDI'")
puts "RESULTS_liberacion.size: #{results_liberacion.count}"
status_notificacion = 4
#status_notificacion = 6


# OBTENER los equipos a "BLOQUEAR" de ambos puertos
results_bloqueo = client.execute("EXEC EnvioNotificacionesSolvencia #{status_notificacion},NULL,'EDI'")
##<TODO nota"Si no hay objetos">
if results_liberacion.count == 0 and results_bloqueo.count == 0
  puts "SALIENDO en el principio: "," results_liberacion.size: #{results_liberacion.count}","results_bloqueo.size: #{results_bloqueo.count}"
  exit 0
end
# LOGGER 
logname = File.join('.','logs',Time.now.strftime("%d-%m-%Y_%H%M%S.log"))
$LOG = Logger.new(logname)
puts "RELEASE"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "OBTENIENDO LIBERACIONES"
# <TOCOMMENT nota="luego de probar">
#results = results.entries[0..1]

#<TODO nota="mejorar este proceso de clasificación para unificar el procesamiento">
#clasificador {['DOCAU',1]: dpworld_release_data,['DOCAU',4]: stwd_release_data ,['DOHAI',2]: hit_release_data }
#results = results.entries[0..1]
basic_clasificator results_liberacion,dpworld_release_data,stwd_release_data,hit_release_data

# <TOCOMMENT nota="luego de probar">
#results = results.entries[0..1]
basic_clasificator results_bloqueo,dpworld_hold_data,stwd_hold_data,hit_hold_data
puts "  DPWORLD_RELASE_DATA: #{dpworld_release_data.inspect}"
puts "  STWD_RELASE_DATA: #{stwd_release_data.inspect}"
puts "  HIT_RELASE_DATA: #{hit_release_data.inspect}"
#exit
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "    TOTAL LIBERACIONES:" 
puts "DPWORLD:  #{dpworld_release_data.size}"
puts "STWD:     #{stwd_release_data.size}"
$LOG.debug "        DPWORLD: #{dpworld_release_data.size}"
$LOG.debug "        STWD: #{stwd_release_data.size}"
$LOG.debug "-----------------------------------------------------------"
puts "HIT: #{hit_release_data.size}"
$LOG.debug "        HAINA: #{hit_release_data.size}"
#exit
# OBTENER los equipos a "Bloquear" de ambos puertos
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "-----------------------------------------------------------"
puts "HOLD"
$LOG.debug "OBTENIENDO LOS BLOQUEOS"

puts "  DPWORLD_HOLD_DATA: #{dpworld_hold_data.inspect}"
puts "  STWD_HOLD_DATA: #{stwd_hold_data.inspect}"
puts "  HIT_HOLD_DATA: #{hit_hold_data.inspect}"
$LOG.debug "-----------------------------------------------------------"
$LOG.debug "    TOTAL de BLOQUEOS:"
puts "DPWORLD HOLD: #{dpworld_hold_data.size}"
puts "STWD HOLD: #{stwd_hold_data.size}"
$LOG.debug "        DPWORLD: #{dpworld_hold_data.size}"
$LOG.debug "        STWD: #{stwd_hold_data.size}"
$LOG.debug "-----------------------------------------------------------"
puts "HIT HOLD: #{hit_hold_data.size}"
$LOG.debug "        HAINA: #{hit_hold_data.size}"
################################################################################
# ajuste de datos para mappear respectivo a cada salida
incomming_data = []

messages = []

# Generación de archivos
# CAUCECO
puts "CAUCEDO RELEASE:"

$LOG.debug "-- CAUCEDO --"
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "ESCRIBIENDO A DISCO ARCHiVOS EDI"
$LOG.debug "-------------------------------------------------------------"
outputs dpworld_release_data 
outputs dpworld_hold_data 
#outputs stwd_release_data 
#outputs stwd_hold_data 
#resultado = `unix2dos outputs/*`
$LOG.debug "    RELEASES CAUCEDO"

=begin
	$LOG.debug "Transferencia FTP a STONEWOOD" 
	ftpSTWD = FTPUpdaterSTWD.new
         #errorsReleaseDpworld , successReleaseDpworld = ftpSTWD.move dpworld_release_data
	errorsReleaseStwd,successReleaseStwd=ftpSTWD.move stwd_release_data
	$LOG.debug "    Transferencias con:" 
	$LOG.debug "       ERR:  #{errorsReleaseStwd.size}"
	$LOG.debug "       SUCCESS: #{successReleaseStwd.size}"
=end

#=begin
$LOG.debug "Transferencia FTP a DPWOrld" 
ftpDpworld = FTPUpdaterDpworld.new
errorsReleaseDpworld , successReleaseDpworld = ftpDpworld.move dpworld_release_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsReleaseDpworld.inspect}"
$LOG.debug "     SUCCESS: #{successReleaseDpworld.inspect}"
puts "     ERR:  #{errorsReleaseDpworld.inspect}"
puts "     SUCCESS: #{successReleaseDpworld.inspect}"
#=end

# CAUCEDO
puts "CAUCEDO HOLD:"
$LOG.debug "HOLD CAUCEDO"
# envío de archivos vía FTP
=begin
	$LOG.debug "Transferencia FTP a STONEWOOD" 
	ftpSTWD = FTPUpdaterSTWD.new
	errorsHoldStwd,successHoldStwd=ftpSTWD.move stwd_hold_data
	$LOG.debug "    Transferencias con:" 
	$LOG.debug "       ERR:  #{errorsHoldStwd.size}"
	$LOG.debug "       SUCCESS: #{successHoldStwd.size}"
=end
#=begin
$LOG.debug "Transferencia FTP a DPWOrld" 
ftpDpworld = FTPUpdaterDpworld.new
errorsHoldDpworld,successHoldDpworld=ftpDpworld.move dpworld_hold_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsHoldDpworld.inspect} "
$LOG.debug "     SUCCESS: #{successHoldDpworld.inspect} "
#=end


# notificación de la operación a personal clave vía email

puts "HAINA RELEASE:"

$LOG.debug "-- CAUCEDO --"
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "ESCRIBIENDO A DISCO ARCHiVOS EDI"
outputs hit_release_data
outputs hit_hold_data 
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "    RELEASES HAINA"

#=begin
$LOG.debug "Transferencia FTP a HAINA" 
ftpHIT = FTPUpdaterHIT.new
errorsReleaseHIT,successReleaseHIT=ftpHIT.move hit_release_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsReleaseHIT.inspect} "
$LOG.debug "     SUCCESS: #{successReleaseHIT.inspect} "
#=end
$LOG.debug "-------------------------------------------------------------"
$LOG.debug "HOLD HAINA"
#=begin
$LOG.debug "Transferencia FTP a HAINA" 
ftpHIT = FTPUpdaterHIT.new
errorsHoldHIT,successHoldHIT=ftpHIT.move hit_hold_data
$LOG.debug "   Transferencias con:" 
$LOG.debug "     ERR:  #{errorsHoldHIT.inspect}"
$LOG.debug "     SUCCESS: #{successHoldHIT.inspect}"
#=end

# NOTIFICAR SCI

######################################################
######################################################
# RELEASE DPWORLD
#
#puts successReleaseDpworld[0].to_xml
# HOLD DPWORLD
#
# RELEASE STONEWOOD
#
# HOLD STONEWOOD
#
# RELEASE HAINA
#
# SUCCESS
puts "-------------------------"
data = successReleaseHIT + successHoldHIT + errorsReleaseHIT + errorsHoldHIT
data += errorsHoldDpworld + successHoldDpworld + errorsReleaseDpworld + successReleaseDpworld
#data += errorsHoldStwd + successHoldStwd + errorsReleaseStwd + successReleaseStwd
data.compact!
data
notificacion = NotificadorSCI.to_xml data
puts "XML FINAL: \n#{notificacion}"

#
# ACTUALIZACIÓN SCI
config=<<CONFSQL
SET ANSI_DEFAULTS ON
SET QUOTED_IDENTIFIER ON
SET CURSOR_CLOSE_ON_COMMIT OFF
SET IMPLICIT_TRANSACTIONS OFF
SET TEXTSIZE 2147483647
SET CONCAT_NULL_YIELDS_NULL ON
CONFSQL

client.execute(config)#.do
puts "COMANDO SQL: \n#{"EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,\'#{notificacion}\'"}"
$LOG.debug "COMANDO SQL: \n#{"EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,\'#{notificacion}\'"}"

if data.empty?
  $LOG.debug "NO HAY OBJETOS PARA ACTUALIZAR"
  exit 0
end
dataserver= 'USMIAVS033.bremat.local\MSQL2008'
client.close
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: dataserver, database: "SCI", encoding: 'UTF-8', use_utf16: 'false'

 client.execute("SET CONCAT_NULL_YIELDS_NULL ON").do
 client.execute("SET TEXTSIZE 2147483647 ").do
 client.execute("SET ANSI_WARNINGS ON").do
 client.execute("SET ANSI_PADDING ON").do
 client.execute("SET CURSOR_CLOSE_ON_COMMIT OFF").do
 client.execute("SET QUOTED_IDENTIFIER ON").do
 client.execute("SET ANSI_NULL_DFLT_ON ON").do
 client.execute("SET IMPLICIT_TRANSACTIONS OFF").do
 client.execute("set arithabort off").do
 client.execute("set numeric_roundabort off").do

results = client.execute("EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,'#{notificacion}'").do
puts "==============================================================="
puts "Procesado de SCI: "

puts "  RESULTS: "
$LOG.debug "------ RESULTS ---------------"
puts "Se actualizo SCI: #{client.return_code}"
$LOG.debug "Se actualizo SCI: #{client.return_code}"
$LOG.debug "   XML: \n#{notificacion}"
#exit
