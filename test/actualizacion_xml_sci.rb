require 'tiny_tds'

dataserver= 'USMIAVS029.bremat.local\MSQL2008'
dataserver= 'USMIAVS033.bremat.local\MSQL2008'
client = TinyTds::Client.new username: 'sa', password: 'avila', dataserver: dataserver, database: "SCI", encoding: 'UTF-8'

client.execute("SET CONCAT_NULL_YIELDS_NULL ON").do
client.execute("SET ANSI_WARNINGS ON").do
client.execute("SET ANSI_PADDING ON").do

notificacion = "<List>\n"
notificacion << "<sSolvenciaNotificaciones>\n"
notificacion << "  <solvenciaId>34115</solvenciaId>\n"
notificacion << "  <equipoId>trlu-1711269</equipoId>\n"
notificacion << "  <manifiestoId>20834</manifiestoId>\n"
notificacion << "  <solvenciaNotifId>4</solvenciaNotifId>\n"
notificacion << "  <status>2</status>\n"
notificacion << "</sSolvenciaNotificaciones>\n"
notificacion << "</List>"

puts "NOTIFICAICON: '#{notificacion}'"
results = client.execute("EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,'#{notificacion}'")

puts "RESULT: #{results.entries}"

contenido2 = <<XML
<sSolvenciaNotificaciones><solvenciaId>34126</solvenciaId><equipoId>GESU-8098773</equipoId><manifiestoId>20859</manifiestoId><solvenciaNotifId>1</solvenciaNotifId><status>2</status></sSolvenciaNotificaciones><sSolvenciaNotificaciones><solvenciaId>34126</solvenciaId><equipoId>GESU-8098773</equipoId><manifiestoId>20859</manifiestoId><solvenciaNotifId>4</solvenciaNotifId><status>2</status></sSolvenciaNotificaciones>
XML

puts "CONTENIDO2: #{contenido2}"

notificacion2 = "<List>\n"
notificacion2 << contenido2
notificacion2 << "</List>"

puts "NOTIFICAICON 2: '#{notificacion2}'"
results = client.execute("EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,'#{notificacion2}'")
puts "   RESULT: #{results.entries}"
puts "------------------"

contenido3 =<<-XML
<sSolvenciaNotificaciones>
  <solvenciaId>34124</solvenciaId>
  <equipoId>FIBU-1240866</equipoId>
  <manifiestoId>20859</manifiestoId>
  <solvenciaNotifId>4</solvenciaNotifId>
  <status>2</status>
</sSolvenciaNotificaciones>
XML

notificacion3 = "<List>\n"
notificacion3 << contenido3
notificacion3 << "</List>" 

puts "Notificacion 3: #{notificacion3}"

puts "NOTIFICAICON 3: '#{notificacion2}'"
results = client.execute("EXEC EnvioNotificacionesSolvencia NULL,NULL,NULL,'#{notificacion3}'")
puts "   RESULT: #{results.entries}"
puts "------------------"
