# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'

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

end

class ReleaseCaucedo < Release
  def estatus
    #puts "STATUS SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSsss: #{self.status}"
    self.status == 'release' ? 'UA' : 'PU'
  end

  def template_filename
    File.join(template_dir,"315_caucedo.erb")
  end

  def output message
    File.write(File.join("outputs","caucedo","315",self.filename),message)
    # Enviar vía FTP
  end
end

class ReleaseHIT < Release
  def estatus
    'MS'
  end

  def template_filename
    File.join(template_dir,"315_hit.erb")
  end

  def filename
    "HIT-"+self.equipo_ajustado+".edi"
  end
 
  def output message
    File.write(File.join("outputs","hit","315",self.filename),message)
    # Enviar vía FTP
    ftp = Net::FTP.new('example.com')
    ftp.login
    files = ftp.chdir('pub/lang/ruby/contrib')
    files = ftp.list('n*')
    ftp.getbinaryfile('nif.rb-0.91.gz', 'nif.gz', 1024)
    ftp.close
  end
end

### FTP controller
class FTPUpdater
 


  def self.move

  end

end

#### Origen de los datos
# Leer de la BD

# datos obtenidos de la BD

####
#=begin
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: 'USMIAVS029.bremat.local\MSQL2008', database: "SCI"
results = client.execute("EXEC EnvioNotificacionesSolvencia 0,'EDI','20180201'")
results.each do |fila|
	puts "FILA: #{fila.inspect}"
end
#results = client.execute("SELECT TOP 1 * FROM tfactura")
#results.each do |result|
#  puts "SQL RESUlt: #{result.inspect}"
#end
#=end
################################################################################33
# ajuste de datos para mappear respectivo a cada salida
incomming_data = [ ]

test = true
if test
  require File.join('.','caucedo_test')
  incomming_data += @caucedo_objects
  require File.join('.','hit_test')
  incomming_data += @hit_objects
end

puts "Incoming DATA: #{incomming_data.inspect}"
# mapeo de salida
require "erb"
messages = []
################### <SPIKES>
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
########</SPIKES>
#### PROCESAR data de entrada
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

# Generación de archivos
# CAUCECO



# envío de archivos vía FTP
#
# CAUCEDO


# notificación de la operación a personal clave vía email


