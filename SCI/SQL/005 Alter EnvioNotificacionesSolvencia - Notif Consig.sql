ALTER TABLE sSolvenciaNotificaciones
ADD emailDestinatario VARCHAR(200)

ALTER TABLE sSolvenciaNotificaciones
ADD emailCopia VARCHAR(200)

ALTER TABLE sSolvenciaNotificacionConfig
ALTER COLUMN puertoId DT_puertoId NULL

ALTER TABLE sSolvenciaNotificaciones
ADD solvenciaNotificacionId INT IDENTITY

GO

IF NOT EXISTS(SELECT * FROM sSolvenciaNotificacionConfig WHERE destinatario = 'CONSIGNATARIO') BEGIN
	INSERT INTO sSolvenciaNotificacionConfig
	SELECT 'ZIMDO' navieraId, NULL puertoId, 'CONSIGNATARIO' destinatario, 'EMAIL'tipo, NULL emailDestinatario, 'osantiago' emailCopia, 14, 'osantiago', GETDATE() 
END

GO
-- Se crea el procedimiento que selecciona segun la configuraci�n las solvencias que deben ser notificadas, envia las que corresponda a email, y les actualiza el estatus
-- OSantiago 07/02/2018 Agrego una opci�n para retornar un listado de equipos en un status espec�fico
-- OSantiago 07/02/2018 Agrego una opci�n para asignar estatus a un listado espec�fico
-- OSantiago 11/02/2018 Agrego la funcionalidad de env�ar correos a los consignatarios
ALTER PROCEDURE EnvioNotificacionesSolvencia
@listadoEstatus INT = NULL -- El valor pasado por par�metro debe corresponder al status del que se quiere retornar el listado
, @listadoDesde DATETIME = NULL -- A partir de esta fecha se obtendran los registros 
, @listadoTipo CHAR(20) = NULL -- EDI, EMAIL
, @xmlActualizarStatus XML = NULL
AS

INSERT INTO sSolvenciaNotificaciones (solvenciaNotifId, equipoId, manifiestoId, solvenciaId, status, fechaStatus, emailDestinatario, emailCopia)
SELECT d.solvenciaNotifId, b.equipoid, b.manifiestoid, b.solvenciaid, 0 status, GETDATE(), d.emailDestinatario, d.emailCopia
FROM sSolvencia a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaId
JOIN oManifiesto c ON b.manifiestoId = c.manifiestoId
JOIN sSolvenciaNotificacionConfig d ON c.navieraId = d.navieraId AND c.ptoDestinoId = ISNULL(d.puertoId, c.ptoDestinoId) -- AND d.tipo = 'EMAIL'
LEFT JOIN sSolvenciaNotificaciones e ON d.solvenciaNotifId = e.solvenciaNotifId AND b.equipoid = e.equipoId AND b.manifiestoid = e.manifiestoId
WHERE e.manifiestoId IS NULL

DECLARE @correo VARCHAR(500), @resultado TINYINT, @clienteId INT
DECLARE Clientes CURSOR FOR
SELECT DISTINCT d.clienteId
FROM sSolvenciaNotificaciones a
JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL' AND c.destinatario = 'CONSIGNATARIO'
JOIN sSolvencia d ON a.solvenciaId = d.solvenciaId
WHERE a.status = 0 -- Emitido
OPEN clientes
FETCH clientes INTO @clienteId
WHILE @@FETCH_STATUS = 0 BEGIN
    SET @correo = NULL
    EXEC @resultado = buscarEmail @clienteid, @correo OUTPUT, NULL, 1
    IF @resultado = 0 BEGIN
        UPDATE a SET emailDestinatario = @correo
		FROM sSolvenciaNotificaciones a
		JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL' AND c.destinatario = 'CONSIGNATARIO'
		JOIN sSolvencia d ON a.solvenciaId = d.solvenciaId
		WHERE a.status = 0 -- Emitido
			AND d.clienteId = @clienteId
    END ELSE BEGIN
        UPDATE a SET status = 3
		FROM sSolvenciaNotificaciones a
		JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EMAIL' AND c.destinatario = 'CONSIGNATARIO'
		JOIN sSolvencia d ON a.solvenciaId = d.solvenciaId
		WHERE a.status = 0 -- Emitido
			AND d.clienteId = @clienteId
    END
FETCH clientes INTO @clienteId
END
CLOSE clientes
DEALLOCATE clientes

INSERT INTO sendmail (recipients, copy_recipients, message, subject, isHTML, OrigenNombre, OrigenId)
SELECT a.emailDestinatario, a.emailCopia,
'Release Nro: ' + CONVERT(VARCHAR, d.solvenciaPaisId) + '</BR>' + 
'Consignatario: ' + RTRIM(e.cliNombre) + '</BR>' + 
'RNC Consignatario: ' + RTRIM(e.cliRif) + '</BR>' + 
'Contenedor: ' + UPPER(a.equipoId) + '</BR>' + 
'Tipo Contenedor: ' + UPPER(f.tipoId) + ' - ' + RTRIM(UPPER(g.tipoDescrip)) + '</BR>' + 
'Fecha de Descarga: ' + CONVERT(VARCHAR, h.fechAtraque, 103) + '</BR>' + 
'Naviera: ' + RTRIM(UPPER(i.navNombre)) + '</BR>' + 
'Puerto: ' + RTRIM(UPPER(j.ptoDescrip)) + '</BR>' + 
'Release v�lido hasta el: ' + CONVERT(VARCHAR, b.fechaRetiro, 103) message,
'Release Contenedor ' + UPPER(a.equipoId) subject,
1 isHTML,
'sSolvencia' OrigenNombre, a.solvenciaNotificacionId OrigenId
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
JOIN SendMail d ON d.OrigenNombre = 'sSolvencia' AND d.OrigenId = a.solvenciaNotificacionId AND d.subject LIKE '%' + a.equipoId + '%'
WHERE a.status = 1 -- Emitido
AND (d.errores = 3 OR d.Enviado IS NOT NULL)

UPDATE a SET status = 4, fechaStatus = GETDATE()  -- 4 A notificar Hold
FROM sSolvenciaNotificaciones a
JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaid  AND a.equipoId = b.equipoid AND a.manifiestoId = b.manifiestoid 
JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId AND c.tipo = 'EDI'
WHERE a.status = 2 AND b.fechaRetiro < GETDATE()

IF COALESCE(@listadoEstatus , @listadoTipo, @listadoDesde) IS NOT NULL BEGIN
	SELECT a.solvenciaId, a.equipoId, a.manifiestoId, a.fechaStatus, a.solvenciaNotifId, c.tipo, a.status
	FROM sSolvenciaNotificaciones a
	JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaid  AND a.equipoId = b.equipoid AND a.manifiestoId = b.manifiestoid 
	JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId
	WHERE 
		a.status = ISNULL( @listadoEstatus, a.status)
		 AND c.tipo = ISNULL( @listadoTipo, c.tipo)
		 AND a.fechaStatus >= ISNULL(@listadoDesde, a.fechaStatus)
END

IF @xmlActualizarStatus IS NOT NULL BEGIN
	SELECT 
		T.X.value('(solvenciaId/text())[1]', 'int') solvenciaId,
		T.X.value('(equipoId/text())[1]', 'varchar(12)') equipoId,
		T.X.value('(manifiestoId/text())[1]', 'int') manifiestoId,
		T.X.value('(solvenciaNotifId/text())[1]', 'int') solvenciaNotifId,
		T.X.value('(status/text())[1]', 'int') status
	INTO #tempsSolvenciaNotificaciones
	FROM @xmlActualizarStatus.nodes('/List/sSolvenciaNotificaciones') AS T(X)

	UPDATE a SET status = d.status, fechaStatus = GETDATE() 
	FROM sSolvenciaNotificaciones a
	JOIN sSolvenciaxItems b ON a.solvenciaId = b.solvenciaId  AND a.equipoId = b.equipoId AND a.manifiestoId = b.manifiestoId 
	JOIN sSolvenciaNotificacionConfig c ON a.solvenciaNotifId = c.solvenciaNotifId
	JOIN #tempsSolvenciaNotificaciones d ON a.solvenciaId = d.solvenciaId AND a.equipoId = d.equipoId AND a.manifiestoId = d.manifiestoId 
		AND a.solvenciaNotifId = d.solvenciaNotifId AND a.status = d.status

END

GO

BEGIN TRANSACTION

DECLARE @xmlActualizarStatus XML
SET @xmlActualizarStatus= 
	'<List>
		<sSolvenciaNotificaciones>
			<solvenciaId>32004</solvenciaId>
			<equipoId>DEMO-0000001</equipoId>
			<manifiestoId>20107</manifiestoId>
			<solvenciaNotifId>2</solvenciaNotifId>
			<status>0</status>
		</sSolvenciaNotificaciones>
	</List>'

EXEC EnvioNotificacionesSolvencia
	@listadoEstatus = 0
	, @listadoDesde = '20180101'
	, @listadoTipo = 'EDI'
	, @xmlActualizarStatus = @xmlActualizarStatus

ROLLBACK

GO
