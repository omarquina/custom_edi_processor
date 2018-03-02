USE [SCI]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create procedure [dbo].[EDI_insertar_MovimientosRespuesta]
 @puertoid varchar(5)
,@blid varchar(20)
,@equipoid varchar(12)
,@tipo varchar(6)
,@fechamov datetime

AS
SET NOCOUNT ON

if @tipo in ('EIROUT', 'EIRIN')
begin
 if not exists (select * from EDI_MovimientosRespuesta where blid = @blid and equipoid = @equipoid and tipo = @tipo and fechamov = @fechamov and manifiestoid is null))
 begin
  insert into EDI_MovimientosRespuesta (puertoid, blid, equipoid, tipo, fechamov)
  VALUES(@puertoid, @blid, @equipoid, @tipo, @fechamov)
 end
end
else
begin
 select ('NO PUDO PROCESAR LOS REGINTROS, EL TIPO ESTÁ ERRADO, DEBE SER EIROUT O EIRIN')
end

RETURN(0)
