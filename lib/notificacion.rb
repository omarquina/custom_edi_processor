class Notificacion < OpenStruct
# 

   def notificadores
     @notificadores ||= []
   end

   def notificar
     self.notificadores.map(:exec)
   end
  
end
