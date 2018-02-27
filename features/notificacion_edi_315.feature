Feature: Enviar notificaciones EDI 315 y reportar su envío

Scenario: Enviar via FTP una notificación de "release"
Given Cuando se notifica que hay un nuevo RELEASE a notificar
| equipo | estatus | puerto | tipo_empresa | solvenciaNotifId |
| XXXX-1234567 | release | DOCAU | PUERTO  | 1                |
When se obtiene el detalle del equipo a notificar
And se genera el archivo EDI con el formato
'''

'''
And se envia via FTP
Then se notifica que fue enviado en formato XML
'''


'''


Scenario: Enviar via FTP una notificación de "HOLD"
Given que se quiere notificar un hold
When se obtiene el detalle del equipo a notificar
And se envia via FTP
Then se notifica que fue enviado

