# Clase base para las liberaciones
class Release < OpenStruct
  attr_accessor :siglas_equipo,:equipo_6_digitos,:equipo_ultimo_digito
  attr_accessor :template_dir,:exito
  def get_binding; return binding(); end;
 
  def exito!
    self.exito = true
  end

  def error!
    self.exito = false
  end

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

  def equipo
    self.equipoId
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
### <EDI MAPPING>
#<TODO: EXTRAER y mejorar>
  def map
    @map ||= template.result(self.get_binding)
  end

  def template
    @template ||= ERB.new( contenido )
  end 

  def contenido
    File.read( self.template_filename )
  end
## <EDI MAPPING>

# <XML MAPPING>
  def to_xml
    xml = XMLBuilder.new
    #puts "XML: #{xml.inspect}"
    #xml.sSolvenciaNotificaciones do |sSolvenciaNotificaciones|
=begin
    xml.sSolvenciaNotificaciones do
      xml.solvenciaId self.solvenciaId.to_i.to_s
      xml.equipoId self.equipoId
      xml.manifiestoId self.manifiestoId.to_i.to_s
      xml.solvenciaNotifId self.solvenciaNotifId.to_i.to_s
      xml.status notificar_status.to_i.to_s
    end
    #xml.str#.delete!("\n")
=end
    xml = "<sSolvenciaNotificaciones>\n"
    xml << "  <solvenciaId>#{self.solvenciaId.to_i}</solvenciaId>\n"
    xml << "  <equipoId>#{self.equipoId}</equipoId>\n"
    xml << "  <manifiestoId>#{self.manifiestoId.to_i}</manifiestoId>\n"
    xml << "  <solvenciaNotifId>#{self.solvenciaNotifId.to_i}</solvenciaNotifId>\n"
    xml << "  <status>#{notificar_status.to_i}</status>\n"
    xml << "</sSolvenciaNotificaciones>"
  end
# </XML MAPPING>
  def procesar_exito
    result =  case self.status
      when 0,2
        2
      when 4,6
        6 
    end
  end

  def procesar_fallo
    case self.status
      when 0,2
        3
      when 4,6
        7
     end
  end

  def notificar_status
      exito ?  procesar_exito : procesar_fallo
  end

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
    case self.status
      when :release,0,2
        'UA'
      when :hold,4,6
        'PU' 
    end
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

  def extra_filename
    @extra_filename ||= case self.status
      when :release,0,2
        "-L"
      when :hold,4,6
        "-I"
      end 
  end

  def filename
    self.equipo_ajustado+self.extra_filename+".edi"
  end
 
end

class ReleaseSTWD < ReleaseCaucedo

end

class ReleaseHIT < Release
  TEMPLATE_FLENAME="315_hit.erb"

  def estatus
    self.status == :release ? 'MS' : 'UT'
    case self.status
      when :release,0,2
        'MS'
      when :hold,4,6
        'UT' 
    end
  end

  def template_name
    @template_name ||= '315_hit.erb'
  end

  def template_filename
    File.join(template_dir,template_name)
  end

  def extra_filename
    @extra_filename ||= case self.status
      when :release,0,2
        "-L"
      when :hold,4,6
        "-I"
      end 
  end

  def filename
    self.equipo_ajustado+self.extra_filename+".edi"
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

