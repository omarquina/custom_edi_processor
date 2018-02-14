USE [SCI]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
create procedure [dbo].[as400_contratos_cierre_equipos]
AS
SET NOCOUNT ON
declare @archivoid  numeric(10,0)
,@nombrearchivo varchar(200)
,@navieraid varchar(5)
,@equipoid varchar(12)
,@mov varchar(20)
,@fechaMov datetime
,@contrato varchar(50)

set @navieraid = 'SEMUS'

SET @fechaMov = GETDATE()

set @nombrearchivo = 'AS400_Contratos ' + convert(varchar(30), getdate(), 100)

select co.manifiestoid, ob.manifiestopaisid, ol.equipoid, co.Contrato,  into #tempo from AS400_ContratosxBLRespuesta co
join oBL ob on ob.manifiestoid = co.manifiestoid and ob.blid like  '%' + co.blid + '%'
join omanifiesto ma on ma.manifiestoid = co.manifiestoid
join (select max(equipoid) equipoid, manifiestoid, BLSYS from oListadeCargaxBL group by  manifiestoid, BLSYS) ol on ob.manifiestoid = ol.manifiestoid and ob.BLSYS = ol.BLSYS

-- Inserta el header para cierre de equipos
exec transact_otrackingdescarga 1 
,@archivoid output 
,@nombrearchivo 
,@navieraid


DECLARE cont_lote CURSOR
FOR SELECT * FROM #tempo

OPEN cont_lote

FETCH NEXT
FROM c_lote
INTO 

 -- Inserta información general
 exec transact_otracking 1
  ,@archivoid
        ,@equipoid 
        ,'CONTRATO'
        ,@fechaMov
        ,@navieraid
        ,@navieraid
        ,Null
        ,Null
        ,Null
        ,@contrato
        ,0
        ,Null
        ,Null
        , rq(15) = Trim(rs(0))
            rq(16) = CStr(empresapaisid(nroMenu))
            rq(17) = Null
            rq(18) = Null
            rq(19) = Null




RETURN(0)

GO