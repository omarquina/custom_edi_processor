# Lee de la BD y lo transforma en un archivo edi 315 para ser enviado vía FTP a ambas compañías en Caucedo
require 'tiny_tds'
require 'ostruct'
require 'net/ftp'
require 'net/sftp'
require 'fileutils'
require "erb"
require 'logger'
require_relative '../lib/notificacion'

=begin
origen = FromSciUsa.new
origen.clasificador = Clasificador

releasesFromSci = ReleaseFromSci.new
releasesFromSci.clasificador = ClasificadorPorEmpresa

relesesFromSci.notificadores << Ftp1.new

origenes << ReleaseFromSci.execute
origenes << HoldFromSCI.execute


origenes.notificar(   ).notificar
=end

dataserver= 'USMIAVS029.bremat.local\MSQL2008'
dataserver= 'USMIAVS033.bremat.local\MSQL2008'
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: dataserver, database: "SCI", encoding: 'UTF-8', use_utf16: 'false'

# OBTENER los equipos a "LIBERAR" de ambos puertos
caucedo_release_data = []
hit_release_data = []

results = client.execute("EXEC EnvioNotificacionesSolvencia 2,NULL,'EDI'")
puts results.methods.sort.to_s
puts results.entries[0]
puts "RESULTS: #{Notificacion.new results.entries[0]}"
exit

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

