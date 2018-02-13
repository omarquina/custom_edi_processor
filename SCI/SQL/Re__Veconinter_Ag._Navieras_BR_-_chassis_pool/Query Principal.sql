--USE SCI
ALTER PROCEDURE CrearSolvenciasExpress
@empresaPaisId DT_EmpresaPaisId

AS

SET NOCOUNT ON

DECLARE @equipoId CHAR(12), @fechaRetiro DATETIME, @manifiestoIdInicial INT, @manifiestoId INT, @pagaDG BIT, @finDiasLibres DATETIME
	, @solvenciaPaisId NUMERIC(10,0), @solvenciaID NUMERIC(10,0)

DECLARE c_equipos
CURSOR FOR
SELECT b.equipoId, a.manifiestoId, CONVERT(DATETIME, CONVERT(CHAR(10), GETDATE(), 103)) + 365 FROM oManifiesto a
JOIN oListaDecargaxBl b ON a.manifiestoId = b.manifiestoId
LEFT JOIN sSolvenciaxItems c ON b.manifiestoId = c.manifiestoId AND b.equipoId = c.equipoId AND c.fechaRetiro >= CONVERT(DATETIME, CONVERT(CHAR(10), GETDATE(), 103))
WHERE a.empresaPaisId = @empresaPaisId AND b.status = '0' AND c.equipoId IS NULL
OPEN c_equipos
FETCH c_equipos INTO @equipoId, @manifiestoIdInicial, @fechaRetiro
WHILE @@FETCH_STATUS = 0
BEGIN

reiniciar:

SET @finDiasLibres = NULL

DECLARE @ticketID INT, @formareintegro VARCHAR(100), @clientePaisId INT, @ce_blsys INT, @cambio_dl NUMERIC(7,2),
	@retorno INT, @grantotal_dl NUMERIC(20,2), @grantotal_bs NUMERIC(20,2), @w_error VARCHAR(300), @clienteId INT,
	@ce_fechatraque DATETIME, @serie CHAR(1), @ce_blid CHAR(20), @pagaseguro BIT, @ce_tipoid CHAR(5), @retiva TINYINT,
	@paga_dm BIT, @retislr TINYINT, @paga_dg TINYINT, @totaldemora_dl NUMERIC(20,2), @seguro TINYINT, @totaldemora_bs NUMERIC(20,2),
	@libid CHAR(10), @totaldg_dl NUMERIC(20,2), @ce_tipocliente TINYINT, @totaldg_bs NUMERIC(20,2), @ce_categoriaid CHAR(1),
	@totalfac_dl NUMERIC(20,2), @navieraid CHAR(5), @totalfac_bs NUMERIC(20,2), @totalgtoadmin_dl NUMERIC(20,2),
	@paga_gtoadmin TINYINT, @totalseguro_dl NUMERIC(20,2), @paga_pena TINYINT, @totalseguro_bs NUMERIC(20,2),
	@totalgtoadmin_bs NUMERIC(20,2), @retenciones_dl NUMERIC(20,2), @retenciones_bs NUMERIC(20,2), @ptocreacion CHAR(5),
	@totalret_dl NUMERIC(12,2), @totalret_bs NUMERIC(12,2), @monedapaisid BIT

EXEC SCI..TKobtener_ticket @ticketID OUTPUT, 2

SET @formareintegro = 'Desconocida'

SELECT 
	@clientePaisId = ISNULL( clientePaisIdRenuncia, clientePaisId ) 
	, @ptocreacion = ptoDestinoId
	, @clienteId = ISNULL(clienteId, clienteIdRenuncia)
FROM 
	SCI..vwmanifiestos
WHERE 
	clientepaisid=ISNULL( clientePaisIdRenuncia, clientepaisId ) 
	AND status IN ('0','1') 
	AND equipoid=@equipoid
	AND empresapaisid=@empresaPaisId

EXEC SCI..CMv3_InsertarEquipoCodv7 @manifiestoId OUTPUT, @ce_fechatraque OUTPUT, @ce_blsys OUTPUT, @ce_blid OUTPUT,
	@ce_tipoid OUTPUT, @ticketID, @fecharetiro, @clientePaisId, @equipoid, @paga_dm OUTPUT, @paga_dg OUTPUT,
	@seguro OUTPUT, @libid OUTPUT, @ce_tipocliente, @ce_categoriaid, @navieraid OUTPUT, @paga_gtoadmin OUTPUT,
	@paga_pena OUTPUT, @empresaPaisId 

SET @cambio_dl = NULL

EXEC @retorno = SCI..CMv3_calcular_montosv9  @ticketID,  @cambio_dl, @serie,  @clientePaisId, @pagaseguro, @retiva,
	@retislr, @totaldemora_dl OUTPUT, @totaldemora_bs OUTPUT, @totaldg_dl OUTPUT, @totaldg_bs OUTPUT,
	@totalfac_dl OUTPUT, @totalfac_bs OUTPUT, @grantotal_dl OUTPUT, @grantotal_bs OUTPUT, @totalseguro_dl OUTPUT,
	@totalseguro_bs OUTPUT, @totalgtoadmin_dl OUTPUT, @totalgtoadmin_bs OUTPUT, @totalret_dl OUTPUT, @totalret_bs OUTPUT,
	@monedapaisid OUTPUT

SET @grantotal_dl = ROUND( ISNULL( @grantotal_dl,0)- ISNULL(@retenciones_dl,0),2) 
SET @grantotal_bs = ROUND( ISNULL( @grantotal_bs,0)- ISNULL(@retenciones_bs,0),2) 

IF @retorno <>0
BEGIN
	SELECT fl_descripcion + ISNULL(fl_equipoid,'') FROM MilleniumV2..TSFacturalog WHERE ticketID=@ticketID AND fl_severidad>0
	SET @w_error = 'Error: ' + ISNULL(@w_error,'')
	INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), @w_error
	--RAISERROR (@w_error,16,-1) WITH SETERROR		
END

declare @ticketid3 INT, @ticketid2 INT
DECLARE @usuario CHAR(20), @pass CHAR(20), @dir VARCHAR(200), @dirWeb VARCHAR(200)
declare @preliquid INT, @preliquidt VARCHAR(200), @cmd VARCHAR(2000)
SELECT ticketid,* FROM sci..TSFACTURAXITEM WHERE @ticketid=ticketid

IF @grantotal_dl = 0 BEGIN
	SELECT @solvenciaPaisId = MAX(solvenciaPaisId)+1 FROM sSolvencia WHERE serie = 'A' AND empresaPaisId = @empresaPaisId
	SET @solvenciaPaisId = ISNULL(@solvenciaPaisId,1)
	INSERT INTO sSolvencia (solvenciaPaisId, empresaPaisId, serie, fecha, clienteId, usuario, ptoCreacion, fecha_imp, usuario_imp, fecha_mod, usuario_mod, descripcion, descripcion2)
	SELECT @solvenciaPaisId, @empresaPaisId, 'A' serie, GETDATE(), @clienteId, SUSER_NAME(), @ptocreacion, NULL, NULL, NULL, NULL, NULL, NULL
	 
	SELECT @solvenciaId = MAX(solvenciaId) FROM sSolvencia

	INSERT INTO sSolvenciaxItems (solvenciaId, equipoId, fechaRetiro, manifiestoId, tipoId, fAtraque, blSys, blId, serie, lib_id, diasLibres, finDiasLibres)
	SELECT @solvenciaId, @equipoId, @fechaRetiro, @manifiestoIdInicial, a.tipoId, c.fechAtraque, a.blSys, b.blId, 'A' serie, d.lib_id, NULL diasLibres, NULL finDiasLibres
	FROM oListaDeCargaxBl a
	JOIN oBl b ON a.manifiestoId = b.manifiestoId AND a.blSys = b.blSys
	JOIN oManifiesto c ON a.manifiestoId = c.manifiestoId
	JOIN aProdLCExtra d ON a.manifiestoId = d.manifiestoId AND a.equipoId = d.equipoId
	WHERE a.manifiestoId = @manifiestoIdInicial AND a.equipoId = @equipoId

	INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), 'Solvencia Express Creada'
END
ELSE BEGIN

	SELECT @finDiasLibres = b.finDiasLibres 
	FROM tsFactura a
	JOIN tsFacturaxItem b ON a.ticketId = b.ticketId AND a.serie = b.serie AND a.facturaId = b.facturaId
	WHERE a.ticketId = @ticketId AND a.manifiestoId = @manifiestoIdInicial AND b.equipoId = @equipoId AND b.concepto IN (0, 1, 2) AND b.montoCobrar > 0
	select @finDiasLibres '@finDiasLibres', @fechaRetiro '@fechaRetiro', @equipoId '@equipoId'
	IF @finDiasLibres IS NULL BEGIN
		INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), 'Genera pagos independientes de demora, así que no genera Release Express'
	END ELSE IF @finDiasLibres < GETDATE() BEGIN
		INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), 'La demora inicia hoy o en una fecha anterior, por lo que ya no se puede generar un Release Express'
	END ELSE IF @fechaRetiro <> @finDiasLibres BEGIN
		INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), 'se recalcula el Release Express hasta la fecha de vencimiento de los días libres'
		SET @fechaRetiro = @finDiasLibres
		GOTO reiniciar
	END ELSE BEGIN
		INSERT INTO sSolvenciaExpress_Log SELECT @manifiestoIdInicial, @equipoId, GETDATE(), 'Se recalculó el Release Express hasta la fecha de vencimiento de días libres y sigue generANDo pagos que impide la creación del Release, verificar'
		SELECT 'Sigue generANDo factura con la misma fecha de retiro????' SalidaInterpretar, @finDiasLibres '@finDiasLibres', @fechaRetiro '@fechaRetiro', @equipoId, @manifiestoIdInicial, @fechaRetiro
	END

END

salir:
FETCH c_equipos INTO @equipoId, @manifiestoIdInicial, @fechaRetiro
END
CLOSE c_equipos
DEALLOCATE c_equipos

GO
/*
sp_help ssolvencia
select top 1 * from ssolvencia a
*/

BEGIN TRANSACTION

update odiaslibresv2 set diaslibres = 70 where navieraid = 'zimdo'

update b set valor = '0' from rgregla a
join rgretornoregla b on a.reglaid = b.reglaid AND a.claseid = b.claseid AND b.valor = '100'
where a.claseid = 147
--order by a.rgid desc

--UPDATE oManifiesto SET fechAtraque = '20180208', fechaDescarga = '20180208', fechaFinOp = '20180208' WHERE manifiestoId = 20714
--DELETE sSolvenciaxItems WHERE equipoId = 'DEMO-0000002'

-- SELECT TOP 10 * FROM CAMBIO WHERE EMPRESAPAISID = 14 ORDER BY CAMBFECHA DESC
INSERT INTO cambio SELECT 14, '20180211', 41.18, 'osantiago', NULL, 0

EXEC CrearSolvenciasExpress 14

EXEC EnvioNotificacionesSolvencia

SELECT TOP 100 * FROM sSolvenciaExpress_Log ORDER BY fecha DESC
SELECT TOP 10 * FROM SSOLVENCIA ORDER BY SOLVENCIAID DESC
SELECT TOP 10 * FROM SSOLVENCIAXITEMS ORDER BY SOLVENCIAID DESC
select * from sSolvenciaNotificaciones ORDER BY SOLVENCIAnotificacionID DESC

ROLLBACK

/*
CREATE TABLE sSolvenciaExpress_Log
(
	manifiestoId DT_manifiestoId,
	equipoId CHAR(12),
	fecha DATETIME,
	mensaje VARCHAR(200)
)
*/