Feature: Enviar notificaciones EDI 315 y reportar su envío

Scenario: Enviar via FTP una notificación de "release"
Given Cuando se notifica que hay un nuevo RELEASE a notificar
When se obtiene el detalle del equipo a notificar
And se envia via FTP
Then se notifica que fue enviado


Scenario: Enviar via FTP una notificación de "HOLD"
Given que se quiere notificar un hold
When se obtiene el detalle del equipo a notificar
And se envia via FTP
Then se notifica que fue enviado

