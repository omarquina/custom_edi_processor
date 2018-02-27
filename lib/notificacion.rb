class Notificacion < OpenStruct
 
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
#end


   def notificadores
     @notificadores ||= []
   end

   def notificar
     self.notificadores.map(:exec)
   end
  
end
