-- DROP TABLE sSolvenciaNotificacionConfig
/*
CREATE TABLE sSolvenciaNotificacionConfig (
solvenciaNotifId  INT IDENTITY,
navieraId DT_navieraId,
puertoId DT_puertoId,
destinatario CHAR(20),
tipo CHAR(20),
emailDestinatario VARCHAR(200),
emailCopia VARCHAR(200),
empresaPaisId DT_empresapaisId,
usucreacion VARCHAR(50),
fchcreacion DATETIME
)

INSERT INTO sSolvenciaNotificacionConfig
SELECT 'ZIMDO' navieraId, 'DOHAI' puertoId, 'PUERTO' destinatario, 'EDI'tipo, NULL emailDestinatario, NULL emailCopia, 14, 'osantiago', GETDATE() UNION
SELECT 'ZIMDO' navieraId, 'DOCAU' puertoId, 'PUERTO' destinatario, 'EDI'tipo, NULL emailDestinatario, NULL emailCopia, 14, 'osantiago', GETDATE() UNION
SELECT 'ZIMDO' navieraId, 'DOHAI' puertoId, 'EMPRESA CHASSIS' destinatario, 'EMAIL'tipo, 'osantiago@veconinter.com.ve' emailDestinatario, 'jortega@veconinter.com.ve' emailCopia, 14, 'osantiago', GETDATE() --UNION
--SELECT 'ZIMDO' navieraId, 'DOCAU' puertoId, 'EMPRESA CHASSIS' destinatario, 'EMAIL'tipo, 'osantiago@veconinter.com.ve' emailDestinatario, NULL emailCopia, 14, 'osantiago', GETDATE() 
*/
/*
DROP TABLE sSolvenciaNotificaciones

CREATE TABLE sSolvenciaNotificaciones (
solvenciaNotifId INT NOT NULL,
equipoId CHAR(12) NOT NULL,
manifiestoId DT_manifiestoId NOT NULL,
solvenciaId NUMERIC(10,0),
status SMALLINT, -- 0 Emitido - 1 Enviado Release - 2 Confirmado Release - 3 Error en Notificacion de Release - 4 A notificar Hold - 5 Confirmado el Hold - 6 Error en Notificación del Hold
fechaStatus DATETIME
)
*/
/* Creo las traducciones de los status
--select * from ocodigos
--select * from otipocodigos

INSERT INTO oTipoCodigos SELECT 'Status Notificacion Solvencias' Codigo, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion -- 23
INSERT INTO oCodigos 
SELECT 0 codId,23 tpCodId, 'Emitido' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 1 codId,23 tpCodId, 'Enviado Release' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 2 codId,23 tpCodId, 'Confirmado Release' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 3 codId,23 tpCodId, 'Error notificando Release' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 4 codId,23 tpCodId, 'A notificar Hold' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 5 codId,23 tpCodId, 'Confirmado Hold' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion UNION
SELECT 6 codId,23 tpCodId, 'Error notificando Hold' descripcion, 1 idiomaId, 0 stReg, 'osantiago' usuCreacion, GETDATE() fchCreacion 
*/
ALTER PROCEDURE EnvioNotificacionesSolvencia

AS

INSERT INTO sSolvenciaNotificaciones
SELECT d.solvenciaNotifId, b.equipoid, b.manifiestoid, b.solvenciaid, 0 status, GETDATE()
FROM sSolvencia a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaId
JOIN oManifiesto c ON b.manifiestoId = c.manifiestoId
JOIN sSolvenciaNotificacionConfig d ON c.navieraId = d.navieraId AND c.ptoDestinoId = d.puertoId -- AND d.tipo = 'EMAIL'
LEFT JOIN sSolvenciaNotificaciones e ON d.solvenciaNotifId = e.solvenciaNotifId AND b.equipoid = e.equipoId AND b.manifiestoid = e.manifiestoId
WHERE e.manifiestoId IS NULL

INSERT INTO sendmail (recipients, copy_recipients, message, subject, isHTML, OrigenNombre, OrigenId)
SELECT c.emailDestinatario, c.emailCopia,
'Release Nro: ' + CONVERT(VARCHAR, d.solvenciaPaisId) + '</BR>' + 
'Consignatario: ' + RTRIM(e.cliNombre) + '</BR>' + 
'RNC Consignatario: ' + RTRIM(e.cliRif) + '</BR>' + 
'Contenedor: ' + UPPER(a.equipoId) + '</BR>' + 
'Tipo Contenedor: ' + UPPER(f.tipoId) + ' - ' + RTRIM(UPPER(g.tipoDescrip)) + '</BR>' + 
'Fecha de Descarga: ' + CONVERT(VARCHAR, h.fechAtraque, 103) + '</BR>' + 
'Naviera: ' + RTRIM(UPPER(i.navNombre)) + '</BR>' + 
'Puerto: ' + RTRIM(UPPER(j.ptoDescrip)) + '</BR>' + 
'Release válido hasta el: ' + CONVERT(VARCHAR, b.fechaRetiro, 103) message,
'Release Contenedor ' + UPPER(a.equipoId) subject,
1 isHTML,
'sSolvencia' OrigenNombre, d.solvenciaId OrigenId
FROM sSolvenciaNotificaciones a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaid  AND a.equipoId = b.equipoid AND a.manifiestoId = b.manifiestoid 
JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL'
JOIN sSolvencia d ON a.solvenciaId = d.solvenciaid
JOIN oCliente e ON d.clienteId = e.clienteId
JOIN oListaDeCargaxBL f ON a.equipoId = f.equipoId AND a.manifiestoId = f.manifiestoId
JOIN oTipoEquipo g ON f.tipoId = g.tipoId
JOIN oManifiesto h ON f.manifiestoId = h.manifiestoId
JOIN oNaviera i On h.navieraId = i.navieraId
JOIN oPuerto j ON h.ptoDestinoId = j.puertoId
WHERE a.status = 0 -- Emitido

UPDATE a SET status = 1, fechaStatus = GETDATE()  -- 1 Enviado Release
FROM sSolvenciaNotificaciones a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaid  AND a.equipoId = b.equipoid AND a.manifiestoId = b.manifiestoid 
JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL'
WHERE a.status = 0 -- Emitido

UPDATE a SET status = CASE d.errores WHEN 3 THEN 3 ELSE 2 END, fechaStatus = GETDATE() -- 2 Confirmado Release - 3 Error en Notificacion de Release
FROM sSolvenciaNotificaciones a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaid  AND a.equipoId = b.equipoid AND a.manifiestoId = b.manifiestoid 
JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL'
JOIN SendMail d ON d.OrigenNombre = 'sSolvencia' AND d.OrigenId = a.solvenciaId AND d.subject LIKE '%' + a.equipoId + '%'
WHERE a.status = 1 -- Emitido
AND (d.errores = 3 OR d.Enviado IS NOT NULL)

GO

EXEC EnvioNotificacionesSolvencia

GO

--select * from oPuerto
--select * from oManifiesto
--select * from sSolvencia
--select * from sSolvenciaxitems
--select * from sSolvenciaNotificaciones
-- delete SendMail where origenNombre = 'ssolvencia' and id in (119636, 119637)

-- select * from omanifiesto where empresapaisid = 13
--select top 100 * from sendmail order by id desc
/*

--select * from sSolvenciaNotificaciones where status = 1
-- update sSolvenciaNotificaciones set status = 0 where status = 1
-- update sendmail set enviando = getdate(), enviado = getdate(), errores = 0 where id = 119639
-- update sendmail set  errores = 3 where id = 119639
select * from oGenerales where empresapaisid = 14

http://usmiavs009.bremat.local/WCR2/viewer.aspx?ticket=
*/
-- update oGenerales set rutareportes = 'http://USMIAVS009.bremat.local/WCR2/w.aspx?page=viewer.aspx?ticket=' where empresapaisid = 14
-- update oGenerales set rutareportes = 'http://USMIAVS013.bremat.local/WCR2/w.aspx?page=viewer.aspx?ticket=' where empresapaisid = 13
