# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo

require 'tiny_tds'
require 'ostruct'

# Clase base para las liberaciones
class Release < OpenStruct
  attr_accessor :siglas_equipo,:equipo_6_digitos,:equipo_ultimo_digito
  attr_accessor :template_dir
  def get_binding; return binding(); end;

  def codigo_del_mensaje
    Time.now.to_i.to_s[0..6]
  end

  def siglas_equipo
     @siglas_equipo ||= self.equipo.split("-")[0]
  end

  def equipo_6_digitos
	  @equipo_6_digitos ||= self.equipo.split("-")[1][0..5]
  end

  def equipo_ultimo_digito
	  @equipo_ultimo_digito ||= self.equipo.split("-")[1][6]
  end

  def fecha

  end

  def hora

  end

  def template_dir
    @template_dir ||= File.join(".","templates")
  end

  def filename
	  self.equipo.delete('-')+".edi"
  end
end

class ReleaseCaucedo < Release
  def estatus
    #puts "STATUS SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSsss: #{self.status}"
    self.status == 'release' ? 'UA' : 'PU'
  end

  def template_filename
    File.join(template_dir,"315_caucedo.erb")
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
	  "HIT-"+self.equipo.delete('-')+".edi"
  end
 
end

#### Origen de los datos
# Leer de la BD

# datos obtenidos de la BD

####
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: 'USMIAVS029.bremat.local\MSQL2008', database: "SCI"
#results = client.execute("SELECT TOP 1 * FROM tfactura")
#results.each do |result| 
#  puts "SQL RESUlt: #{result.inspect}"
#end

results = client.execute("EXEC EnvioNotificacionesSolvencia NULL,'20180201'")
results.each do |fila|
	puts "FILA: #{fila.inspect}"
end

# ajuste de datos para mappear respectivo a cada salida
incomming_data = [
	ReleaseCaucedo.new( { equipo: "ZCSU-7037300" , status: 'release' } ) ,
	ReleaseCaucedo.new( { equipo: "ZCSU-8475933" , status: 'hold'    } ) ,
	ReleaseHIT.new( { equipo: "TCNU-2507427" , status: 'release'    } ) ,
	ReleaseHIT.new( { equipo: "ZCSU-8650487" , status: 'hold'    } ) ,
                 ]

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
puts "equipo 6 digitos: #{objeto.equipo_6_digitos}"
puts "equipo ultimo digito: #{objeto.equipo_ultimo_digito}"
########</SPIKES>
#### PROCESAR data de entrada
incomming_data.each do |objeto|
  contenido = File.read(objeto.template_filename)
  template = ERB.new(contenido)	    
  message = template.result(objeto.get_binding)
  puts "ERB. template: #{message}"
  messages << {output_filename: objeto.equipo,mensaje: message}
  File.write(File.join("outputs","caucedo","315",objeto.filename+".edi"),message)
end

# Generación de archivos
# CAUCECO



# envío de archivos vía FTP
#
# CAUCEDO


# notificación de la operación a personal clave vía email


