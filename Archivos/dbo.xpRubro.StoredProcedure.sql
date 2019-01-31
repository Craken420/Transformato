SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[xpRubro]
@Agente			VARCHAR(10),
@Institucion	VARCHAR(10),
@Equipo			VARCHAR(10),		-- Parametros de Inicio,
@Familia		VARCHAR(50),		-- el parametro principal
@Categoria		VARCHAR(50),		-- es @Agente
@Desde1			INT,
@Hasta1			INT,
@Desde2			INT,
@Hasta2			INT,
@Desde3			INT,
@Hasta3			INT
AS BEGIN

SET NOCOUNT ON
DECLARE
@Qna	INT,
@Iqc	CHAR(3),
@Fqc	CHAR(3),
@Iac	CHAR(3),
@Fac	CHAR(3),					-- Variables a utilizar para
@Qc1	DATETIME,					-- conversion de fechas
@Qc2	DATETIME,					-- y para elaborar procesos
@Qa1	DATETIME,
@Qa2	DATETIME,
@R1		CHAR(8),
@R2		CHAR(8),
@M1		CHAR(16),
@M2		CHAR(16),
@RD1	CHAR(9),
@RD2	CHAR(9),
@RD3	CHAR(9),
@Mes CHAR(2),
@Anio CHAR(4),
@MesAnt CHAR(2)/*,
@Agente			VARCHAR(10),
@Institucion	VARCHAR(10),
@Equipo			VARCHAR(10),		-- Parametros de Inicio,
@Familia		VARCHAR(50),		-- el parametro principal
@IDCat		INT,		-- es @Agente
@Desde1			INT,
@Hasta1			INT,
@Desde2			INT,
@Hasta2			INT,
@Desde3			INT,
@Hasta3			INT

select 
@Agente='',
@Institucion='',
@Equipo='',		-- Parametros de Inicio,
@Familia='',		-- el parametro principal
@IDCat=3,		-- es @Agente
@Desde1=1,
@Hasta1=15,
@Desde2=16,
@Hasta2=30,
@Desde3=31,
@Hasta3=999999

*/
SET @RD1=CAST(@Desde1 AS CHAR(3))+' - '+CAST(@Hasta1 AS CHAR(3))	-- Juntar los rangos de fechas
SET @RD2=CAST(@Desde2 AS CHAR(3))+' - '+CAST(@Hasta2 AS CHAR(3))	-- DesdeX - HastaX
SET @RD3=CAST(@Desde3 AS CHAR(3))+' - '+CAST(@Hasta3 AS CHAR(3))	-- para mostrar en el reporte
SET @Qna = (SELECT dbo.fnperiodosmavi(GETDATE()))
IF @Qna = 1 
	BEGIN
    SET @Qna = 25
    SET @Anio= (SELECT CAST(YEAR(GETDATE()) - 1 AS CHAR(4)))
	END
	ELSE
	  BEGIN
      SET @Anio= (SELECT CAST(YEAR(GETDATE()) AS CHAR(4)))
      END
SET @Mes= (SELECT CAST(@Qna AS CHAR(2)))
SET @MesAnt= (SELECT CAST((@Qna -1 ) AS CHAR(2)))
SET @Qc1= (SELECT dbo.fninicioquincenaMavi (@Mes,@Anio))
SET @Qc2= (SELECT dbo.fnfinquincenamavi(@Mes,@Anio))
SET @Qa1= (SELECT dbo.fninicioquincenaMavi (@MesAnt,@Anio))
SET @Qa2= (SELECT dbo.fnfinquincenamavi(@MesAnt,@Anio))
SET @R1=CAST(DATEPART(DAY,@Qc1) AS CHAR(2))+' - '+CAST(DATEPART(DAY,@Qc2) AS CHAR(2))
SET @R2=CAST(DATEPART(DAY,@Qa1) AS CHAR(2))+' - '+CAST(DATEPART(DAY,@Qa2) AS CHAR(2))
SET LANGUAGE SPANISH
SET @M1=DATENAME(MONTH,@Qc1)
SET @M2=DATENAME(MONTH,@Qa1)
SET LANGUAGE ENGLISH

--select @qna,@qc1,@qc2,@qa1,@qa2,@r1,@r2,@m1,@m2
--SELECT @Categoria=Categoria FROM VentasCanalMavi WHERE ID=@IDCat 
/* Iniciamos a cargar temporalmente informacion en varias tablas antes de mostrar todo el resultado
   Cada tabla tiene la letra al final del campo que llenará dentro del reporte (@TablaX donde X=
   Campo A, CampoB... etc) */
    CREATE TABLE #TablaA(Documento VARCHAR(50) COLLATE Database_Default NULL, 
							  Numero VARCHAR(50) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL,
							  Referencia VARCHAR(100) COLLATE Database_Default NULL,
							  Quincena INT NULL,
							  Factura VARCHAR(50) COLLATE Database_Default NULL,
							  NFactura VARCHAR(50) COLLATE Database_Default NULL, 
							  CV INT NULL,
							  DV INT NULL)
    INSERT #TablaA (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, DV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta, rm.DiasVencidos
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=(@Qna-1) AND rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.AgenteCobrador<>'SIN AGENTE' and c.Estatus <> 'CANCELADO'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta, rm.DiasVencidos
    UPDATE #TablaA SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablaa' from #tablaa
    CREATE TABLE #TablaB(Documento VARCHAR(50) COLLATE Database_Default NULL,
							   Numero VARCHAR(50) COLLATE Database_Default NULL,
							   Agente VARCHAR(10) COLLATE Database_Default NULL,
							   Referencia VARCHAR(100) COLLATE Database_Default NULL, 
							   Quincena INT NULL,
							   Factura VARCHAR(50) COLLATE Database_Default NULL,
							   NFactura VARCHAR(50) COLLATE Database_Default NULL ,
							   CV INT NULL, 
							   DV INT NULL)
    INSERT #TablaB (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, DV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta, rm.DiasVencidos
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND rm.AgenteCobrador<>'SIN AGENTE' AND
      rm.Quincena=CASE WHEN (@Qna-2)=0 THEN 24 ELSE @Qna-2 END AND
      rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta, rm.DiasVencidos
    UPDATE #TablaB SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablab' from #tablab
    CREATE TABLE #TablaC(Documento VARCHAR(50) COLLATE Database_Default NULL,
							 Numero VARCHAR(50) COLLATE Database_Default NULL,
							 Agente VARCHAR(10) COLLATE Database_Default NULL, 
							 Referencia VARCHAR(100) COLLATE Database_Default NULL,
							 Quincena INT NULL, 
							 Factura VARCHAR(50) COLLATE Database_Default NULL,
							 NFactura VARCHAR(50) COLLATE Database_Default NULL,
							 CV INT NULL)
    INSERT #TablaC (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=(@Qna-1) AND rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde1 AND @Hasta1 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaC SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablac' from #tablac
    CREATE TABLE #TablaE(Documento VARCHAR(50) COLLATE Database_Default NULL,
							 Numero VARCHAR(50) COLLATE Database_Default NULL,
							 Agente VARCHAR(10) COLLATE Database_Default NULL,
							 Referencia VARCHAR(100) COLLATE Database_Default NULL, 
							 Quincena INT NULL,
							 Factura VARCHAR(50) COLLATE Database_Default NULL, 
							 NFactura VARCHAR(50) COLLATE Database_Default NULL,
							 CV INT NULL)
    INSERT #TablaE (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=CASE WHEN (@Qna-2)=0 THEN 24 ELSE @Qna-2 END AND
      rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde1 AND @Hasta1 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaE SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablae' from #tablae
    CREATE TABLE #TablaC1(Documento VARCHAR(50) COLLATE Database_Default NULL, 
								Numero VARCHAR(50) COLLATE Database_Default NULL, 
								Agente VARCHAR(10) COLLATE Database_Default NULL,
							    Referencia VARCHAR(100) COLLATE Database_Default NULL,
							    Quincena INT NULL, 
								Factura VARCHAR(50) COLLATE Database_Default NULL,
							    NFactura VARCHAR(50) COLLATE Database_Default NULL,
							    CV INT NULL)
    INSERT #TablaC1 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=(@Qna-1) AND rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde2 AND @Hasta2 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaC1 SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablac1' from #tablac1
    CREATE TABLE #TablaE1(Documento VARCHAR(50) COLLATE Database_Default NULL,
								 Numero VARCHAR(50) COLLATE Database_Default NULL,
								 Agente VARCHAR(10) COLLATE Database_Default NULL,
								 Referencia VARCHAR(100) COLLATE Database_Default NULL,
								 Quincena INT NULL,
								 Factura VARCHAR(50) COLLATE Database_Default NULL,
								 NFactura VARCHAR(50) COLLATE Database_Default NULL,
								 CV INT NULL)
    INSERT #TablaE1 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=CASE WHEN (@Qna-2)=0 THEN 24 ELSE @Qna-2 END AND
      rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde2 AND @Hasta2 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaE1 SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablae1' from #tablae1
    CREATE TABLE #TablaC2(Documento VARCHAR(50) COLLATE Database_Default NULL, 
								Numero VARCHAR(50) COLLATE Database_Default NULL,
								Agente VARCHAR(10) COLLATE Database_Default NULL,
							    Referencia VARCHAR(100) COLLATE Database_Default NULL,
							    Quincena INT NULL,
							    Factura VARCHAR(50) COLLATE Database_Default NULL,
							    NFactura VARCHAR(50) COLLATE Database_Default NULL,
							    CV INT NULL)
    INSERT #TablaC2 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=(@Qna-1) AND rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde3 AND @Hasta3 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaC2 SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablac2' from #tablac2
    CREATE TABLE #TablaE2(Documento VARCHAR(50) COLLATE Database_Default NULL,
								 Numero VARCHAR(50) COLLATE Database_Default NULL,
								 Agente VARCHAR(10) COLLATE Database_Default NULL,
								 Referencia VARCHAR(100) COLLATE Database_Default NULL, 
								 Quincena INT NULL,
								 Factura VARCHAR(50) COLLATE Database_Default NULL,
								 NFactura VARCHAR(50) COLLATE Database_Default NULL,
								 CV INT NULL)
    INSERT #TablaE2 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(Quincena), c.Origen, c.OrigenID, rm.CanalVenta
    FROM
      MaviRecuperacion rm WITH(NOLOCK),
      Cxc c WITH(NOLOCK),
      VentasCanalMavi vc WITH(NOLOCK)
    WHERE
      rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
      rm.Quincena=CASE WHEN (@Qna-2)=0 THEN 24 ELSE @Qna-2 END AND
      rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
      rm.DiasVencidos BETWEEN @Desde3 AND @Hasta3 AND rm.AgenteCobrador<>'SIN AGENTE'
    GROUP BY
      c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta
    UPDATE #TablaE2 SET Referencia=Documento+' '+Numero,
      Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
--select *,'tablae2' from #tablae2
    DELETE FROM #TablaC WHERE Referencia IN (SELECT Referencia FROM #TablaA WHERE DV>@Hasta1)
    DELETE FROM #TablaC1 WHERE Referencia IN (SELECT Referencia FROM #TablaA WHERE DV>@Hasta2)
    DELETE FROM #TablaC2 WHERE Referencia IN (SELECT Referencia FROM #TablaA WHERE DV>@Hasta3)
    DELETE FROM #TablaE WHERE Referencia IN (SELECT Referencia FROM #TablaB WHERE DV>@Hasta1)
    DELETE FROM #TablaE1 WHERE Referencia IN (SELECT Referencia FROM #TablaB WHERE DV>@Hasta2)
    DELETE FROM #TablaE2 WHERE Referencia IN (SELECT Referencia FROM #TablaB WHERE DV>@Hasta3)

    CREATE TABLE #TablaG(Documento VARCHAR(50) COLLATE Database_Default NULL,
								 Numero VARCHAR(50) COLLATE Database_Default NULL,
								 Agente VARCHAR(10) COLLATE Database_Default NULL,
								 Referencia VARCHAR(100) COLLATE Database_Default NULL,
								 Quincena INT NULL, 
								 Factura VARCHAR(50) COLLATE Database_Default NULL,
								 NFactura VARCHAR(50) COLLATE Database_Default NULL,
								 CV INT NULL)
    INSERT #TablaG(Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      e.Documento, e.Numero, e.Agente, e.Referencia, e.Quincena, e.Factura, e.NFactura, e.CV
    FROM
      #TablaC c, #TablaE e
    WHERE
      c.Factura=e.Factura AND c.NFactura=e.NFactura AND c.Agente=e.Agente
--select *,'tablag' from #tablag
    CREATE TABLE #TablaSalieron(Documento VARCHAR(50) COLLATE Database_Default NULL,
								 Numero VARCHAR(50) COLLATE Database_Default NULL,
								 Agente VARCHAR(10) COLLATE Database_Default NULL,
								 Referencia VARCHAR(100) COLLATE Database_Default NULL,
								 Quincena INT NULL, 
								 Factura VARCHAR(50) COLLATE Database_Default NULL,
								 NFactura VARCHAR(50) COLLATE Database_Default NULL,
								 CV INT NULL)
    INSERT #TablaSalieron (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV
    FROM
      #TablaE
    WHERE
      Referencia NOT IN (SELECT Referencia FROM #TablaG)/*
    INSERT #TablaSalieron (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      c1.Documento, c1.Numero, c1.Agente, c1.Referencia, c1.Quincena, c1.Factura, c1.NFactura, c1.CV
    FROM
      #TablaC c1,
      Cxc c2
    WHERE
      c1.Documento=c2.Mov AND c1.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>=0 AND
      c2.FechaEmision<>c2.UltimoCambio AND c2.UltimoCambio BETWEEN @Qc1 AND @Qc2 AND
      c2.Estatus IN('CONCLUIDO','PENDIENTE')*/
--select *,'tablasalieron' from #tablasalieron
    CREATE TABLE #TablaJ(Mov CHAR(20) COLLATE Database_Default NULL,
						 MovID VARCHAR(20) COLLATE Database_Default NULL,
						 Agente VARCHAR(10) COLLATE Database_Default NULL)
    INSERT #TablaJ (Mov, MovID, Agente)
    SELECT DISTINCT
      c.Mov, c.MovID, c.Agente
    FROM
      Cxc c
    WHERE
      c.Mov IN('Nota Credito','Nota Credito VIU','Cancela Credilana','Cancela Prestamo') AND c.Concepto IN('ADJUDICACION + DE 12','ADJUDICACION 1 A 12','OK ADJUDICACION + DE 12','OK ADJUDICACION 1 A 12','OK ADJ CREDILANA/PP + DE 12','ADJ CREDILANA/PP + DE 12') AND c.Estatus='CONCLUIDO' AND
      c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
      ISNULL(c.Agente,'')<>''
      AND EXISTS(SELECT tc.referencia FROM #TablaC tc, CxcD d  WITH(NOLOCK)
      where c.id=d.id and tc.documento=d.aplica  and tc.numero=d.aplicaid)
--select *,'tablaj' from #tablaj    

    /* Abono */
    CREATE TABLE #TablaM(Origen VARCHAR(50) COLLATE Database_Default NULL,
						 OrigenID VARCHAR(50) COLLATE Database_Default NULL,
						 Agente VARCHAR(10)  COLLATE Database_Default NULL)
    INSERT #TablaM (Origen, OrigenID, Agente)
    SELECT
      ISNULL(c2.Origen,c2.Mov), ISNULL(c2.OrigenID,c2.MovID), e.Agente
    FROM
      Cxc c WITH(NOLOCK)
	JOIN CxcD d WITH(NOLOCK)
	ON c.ID=d.ID
	JOIN Cxc c2 WITH(NOLOCK)
	ON d.Aplica=c2.Mov AND d.AplicaID=c2.MovID
    JOIN EmbarqueMov em WITH(NOLOCK)
	ON d.Aplica=em.Mov AND d.AplicaID=em.MovID
	JOIN Embarqued ed WITH(NOLOCK)
	ON em.id=ed.embarquemov 
	JOIN Embarque e WITH(NOLOCK)
	ON e.id = ed.id 
	WHERE
    c.Estatus='CONCLUIDO' AND
    c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
    e.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
	c.Mov='Cobro' AND
	ISNULL(c.Saldo,0)=0 AND
	ISNULL(c2.OrigenID,c2.MovID) IN (SELECT NFactura FROM #TablaSalieron)
    INSERT #TablaM(Origen, OrigenID, Agente)
    SELECT DISTINCT
      s.Factura, s.NFactura, s.Agente
    FROM
      #TablaSalieron s,
      Cxc c2 WITH(NOLOCK)
    WHERE
      s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
      c2.Estatus IN('CONCLUIDO') AND c2.FechaEmision<>c2.UltimoCambio AND
      c2.UltimoCambio BETWEEN @Qc1 AND @Qc2
--select *,'tablam' from #tablam
   CREATE TABLE #TablaG1(Documento VARCHAR(50) COLLATE Database_Default NULL,
						 Numero VARCHAR(50) COLLATE Database_Default NULL,
						 Agente VARCHAR(10) COLLATE Database_Default NULL,
						 Referencia VARCHAR(100) COLLATE Database_Default NULL, 
						 Quincena INT NULL, 
						 Factura VARCHAR(50) COLLATE Database_Default NULL,
						 NFactura VARCHAR(50) COLLATE Database_Default NULL,
						 CV INT NULL) 
    INSERT #TablaG1 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      e.Documento, e.Numero, e.Agente, e.Referencia, e.Quincena, e.Factura, e.NFactura, e.CV
    FROM
      #TablaC1 c, #TablaE1 e
    WHERE
      c.Factura=e.Factura AND c.NFactura=e.NFactura AND c.Agente=e.Agente
--select *,'tablag1' from #tablag1
    CREATE TABLE #TablaSalieron1(Documento VARCHAR(50) COLLATE Database_Default NULL,
									Numero VARCHAR(50) COLLATE Database_Default NULL,
									Agente VARCHAR(10) COLLATE Database_Default NULL,
									Referencia VARCHAR(100) COLLATE Database_Default NULL,
								    Quincena INT NULL,
								    Factura VARCHAR(50) COLLATE Database_Default NULL,
								    NFactura VARCHAR(50) COLLATE Database_Default NULL,
								    CV INT NULL)
    INSERT #TablaSalieron1 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV
    FROM
      #TablaE1
    WHERE
      NFactura NOT IN (SELECT NFactura FROM #TablaG1)
    /*INSERT #TablaSalieron1 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      c1.Documento, c1.Numero, c1.Agente, c1.Referencia, c1.Quincena, c1.Factura, c1.NFactura, c1.CV
    FROM
      #TablaC1 c1,
      Cxc c2
    WHERE
      c1.Documento=c2.Mov AND c1.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>=0 AND
      c2.UltimoCambio BETWEEN @Qc1 AND @Qc2 AND
      c2.Estatus IN('CONCLUIDO','PENDIENTE')*/
--select *,'tablasalieron1' from #tablasalieron1
    CREATE TABLE #TablaJ1(Mov CHAR(20) COLLATE Database_Default NULL,
						 MovID VARCHAR(20) COLLATE Database_Default NULL, 
						 Agente VARCHAR(10) COLLATE Database_Default NULL)
    INSERT #TablaJ1 (Mov, MovID, Agente)
    SELECT DISTINCT
      c.Mov, c.MovID, c.Agente
    FROM
      Cxc c WITH(NOLOCK)
    WHERE
      c.Mov IN('Nota Credito','Nota Credito VIU','Cancela Credilana','Cancela Prestamo') AND c.Concepto IN('ADJUDICACION + DE 12','ADJUDICACION 1 A 12','OK ADJUDICACION + DE 12','OK ADJUDICACION 1 A 12','OK ADJ CREDILANA/PP + DE 12','ADJ CREDILANA/PP + DE 12') AND c.Estatus='CONCLUIDO' AND
      c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
      ISNULL(c.Agente,'')<>'' --tc1
      AND EXISTS(SELECT c1.referencia FROM #TablaC1 c1, CxcD d  WITH(NOLOCK)
        where c.id=d.id and c1.documento=d.aplica  and c1.numero=d.aplicaid)
--select *,'tablaj1' from #tablaj1
    CREATE TABLE #TablaM1(Origen VARCHAR(50) COLLATE Database_Default NULL, 
						OrigenID VARCHAR(50) COLLATE Database_Default NULL,
						Agente VARCHAR(10) COLLATE Database_Default NULL)
    INSERT #TablaM1 (Origen, OrigenID, Agente)
    SELECT
      ISNULL(c2.Origen,c2.Mov), ISNULL(c2.OrigenID,c2.MovID), e.Agente
    FROM
      Cxc c WITH(NOLOCK)
	JOIN CxcD d WITH(NOLOCK)
	ON c.ID=d.ID
	JOIN Cxc c2 WITH(NOLOCK)
	ON d.Aplica=c2.Mov AND d.AplicaID=c2.MovID
    JOIN EmbarqueMov em WITH(NOLOCK)
	ON d.Aplica=em.Mov AND d.AplicaID=em.MovID
	JOIN Embarqued ed WITH(NOLOCK)
	ON em.id=ed.embarquemov 
	JOIN Embarque e WITH(NOLOCK)
	ON e.id = ed.id 
	WHERE
    c.Estatus='CONCLUIDO' AND
    c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
    e.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
    c.Mov='Cobro' AND
	ISNULL(c.Saldo,0)=0 AND
    ISNULL(c2.OrigenID,c2.MovID) IN (SELECT NFactura FROM #TablaSalieron1)
    INSERT #TablaM1 (Origen, OrigenID, Agente) 
    SELECT DISTINCT
      s.Factura, s.NFactura, s.Agente
    FROM
      #TablaSalieron1 s,
      Cxc c2 WITH(NOLOCK)
    WHERE
      s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
      c2.Estatus='Concluido' AND c2.FechaEmision<>c2.UltimoCambio AND
      c2.UltimoCambio BETWEEN @Qc1 AND @Qc2
--select *,'tablam1' from #tablam1
    CREATE TABLE #TablaG2(Documento VARCHAR(50) COLLATE Database_Default NULL,
						 Numero VARCHAR(50) COLLATE Database_Default NULL,
						 Agente VARCHAR(10) COLLATE Database_Default NULL,
						 Referencia VARCHAR(100) COLLATE Database_Default NULL,
						 Quincena INT NULL,
						 Factura VARCHAR(50) COLLATE Database_Default NULL,
						 NFactura VARCHAR(50) COLLATE Database_Default NULL,
						 CV INT NULL)
    INSERT #TablaG2 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      e.Documento, e.Numero, e.Agente, e.Referencia, e.Quincena, e.Factura, e.NFactura, e.CV
    FROM
      #TablaC2 c, #TablaE2 e
    WHERE
      c.Factura=e.Factura AND c.NFactura=e.NFactura AND c.Agente=e.Agente
--select * from #tablae2
--select *,'tablag2' from #tablag2
    CREATE TABLE #TablaSalieron2(Documento VARCHAR(50) COLLATE Database_Default NULL,
								 Numero VARCHAR(50) COLLATE Database_Default NULL,
								 Agente VARCHAR(10) COLLATE Database_Default NULL,
								 Referencia VARCHAR(100) COLLATE Database_Default NULL,
								 Quincena INT NULL, 
								 Factura VARCHAR(50) COLLATE Database_Default NULL,
								 NFactura VARCHAR(50) COLLATE Database_Default NULL,
								 CV INT NULL)
    INSERT #TablaSalieron2 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV
    FROM
      #TablaE2
    WHERE
      Referencia NOT IN (SELECT Referencia FROM #TablaG2)
    /*INSERT #TablaSalieron2 (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV)
    SELECT DISTINCT
      c1.Documento, c1.Numero, c1.Agente, c1.Referencia, c1.Quincena, c1.Factura, c1.NFactura, c1.CV
    FROM
      #TablaC2 c1,
      Cxc c2
    WHERE
      c1.Documento=c2.Mov AND c1.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>=0 AND
      c2.UltimoCambio BETWEEN @Qc1 AND @Qc2 AND
      c2.Estatus IN('CONCLUIDO','PENDIENTE')*/
--select *,'tablasalieron2' from #tablasalieron2
    CREATE TABLE #TablaJ2(Mov CHAR(20) COLLATE Database_Default NULL,
						 MovID VARCHAR(20) COLLATE Database_Default NULL,
						 Agente VARCHAR(10) COLLATE Database_Default NULL)
    INSERT #TablaJ2 (Mov, MovID, Agente)
    SELECT DISTINCT
      c.Mov, c.MovID, c.Agente
    FROM
      Cxc c WITH(NOLOCK)
    WHERE
      c.Mov IN('Nota Credito','Nota Credito VIU','Cancela Credilana','Cancela Prestamo') AND c.Concepto IN('ADJUDICACION + DE 12','ADJUDICACION 1 A 12','OK ADJUDICACION + DE 12','OK ADJUDICACION 1 A 12','OK ADJ CREDILANA/PP + DE 12','ADJ CREDILANA/PP + DE 12') AND c.Estatus='CONCLUIDO' AND
      c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
      ISNULL(c.Agente,'')<>'' 
      AND EXISTS(SELECT c2.referencia FROM #TablaC2 c2, CxcD d  WITH(NOLOCK)
        where c.id=d.id and c2.documento=d.aplica  and c2.numero=d.aplicaid)
--select *,'tablaj2' from #tablaj2
    CREATE TABLE #TablaM2(Origen VARCHAR(50) COLLATE Database_Default NULL,
						 OrigenID VARCHAR(50) COLLATE Database_Default NULL,
						 Agente VARCHAR(10) COLLATE Database_Default NULL)
    INSERT #TablaM2 (Origen, OrigenID, Agente)
    SELECT
      ISNULL(c2.Origen,c2.Mov), ISNULL(c2.OrigenID,c2.MovID), e.Agente
    FROM
      Cxc c WITH(NOLOCK)
	JOIN CxcD d WITH(NOLOCK)
	ON c.ID=d.ID
	JOIN Cxc c2 WITH(NOLOCK)
	ON d.Aplica=c2.Mov AND d.AplicaID=c2.MovID
    JOIN EmbarqueMov em WITH(NOLOCK)
	ON d.Aplica=em.Mov AND d.AplicaID=em.MovID
	JOIN Embarqued ed WITH(NOLOCK)
	ON em.id=ed.embarquemov 
	JOIN Embarque e WITH(NOLOCK)
	ON e.id = ed.id 
	WHERE
    c.Estatus='CONCLUIDO' AND
    c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
    e.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
    c.Mov='Cobro' AND
	ISNULL(c.Saldo,0)=0 AND
    ISNULL(c.OrigenID,c2.MovID) IN (SELECT NFactura FROM #TablaSalieron2)
    INSERT #TablaM2 (Origen, OrigenID, Agente)
    SELECT DISTINCT
      s.Factura, s.NFactura, s.Agente
    FROM
      #TablaSalieron2 s,
      Cxc c2 WITH(NOLOCK)
    WHERE
      s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
      c2.Estatus='Concluido' AND c2.FechaEmision<>c2.UltimoCambio AND
      c2.UltimoCambio BETWEEN @Qc1 AND @Qc2
--select *,'tablam2' from #tablam2
    CREATE TABLE #TablaTotal(Codigo VARCHAR(10) COLLATE Database_Default NULL, Nombre VARCHAR(100) COLLATE Database_Default NULL, CampoA INT NULL, CampoB INT NULL, CampoC INT NULL, CampoE INT NULL,
      CampoG INT NULL, CampoSalieron INT NULL, CampoJ INT NULL, CampoM INT NULL, CampoC1 INT NULL, CampoE1 INT NULL, CampoG1 INT NULL, CampoSalieron1 INT NULL,
      CampoJ1 INT NULL, CampoM1 INT NULL, CampoC2 INT NULL, CampoE2 INT NULL, CampoG2 INT NULL, CampoSalieron2 INT NULL, CampoJ2 INT, CampoM2 INT NULL,
      Celula VARCHAR(10) COLLATE Database_Default NULL, Equipo VARCHAR(10) COLLATE Database_Default NULL, Familia VARCHAR(50) COLLATE Database_Default NULL, Categoria VARCHAR(50) COLLATE Database_Default NULL, RD1 CHAR(9) COLLATE Database_Default NULL,
      RD2 CHAR(9)COLLATE Database_Default NULL, RD3 CHAR(9) COLLATE Database_Default NULL, R1 CHAR(8) COLLATE Database_Default NULL, R2 CHAR(8) COLLATE Database_Default NULL, M1 CHAR(16) COLLATE Database_Default NULL, M2 CHAR(16) COLLATE Database_Default NULL)

IF (@Categoria='Credito Menudeo' OR @Categoria='ASOCIADOS')
BEGIN
    INSERT #TablaTotal (Codigo, Nombre, CampoA, CampoB, CampoC, CampoE, CampoG, CampoSalieron, CampoJ, CampoM, CampoC1,
      CampoE1, CampoG1, CampoSalieron1, CampoJ1, CampoM1, CampoC2, CampoE2, CampoG2, CampoSalieron2, CampoJ2, CampoM2,
      Equipo, Familia, Categoria, Celula, RD1, RD2, RD3, R1, R2, M1, M2)
    SELECT
      ag.Agente,
      ag.Nombre,
      'CampoA'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaA WHERE Agente=ag.Agente),
      'CampoB'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaB WHERE Agente=ag.Agente),
      'CampoC'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC WHERE Agente=ag.Agente),
      'CampoE'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE WHERE Agente=ag.Agente),
      'CampoG'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG WHERE Agente=ag.Agente),
      'CampoSalieron'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron WHERE Agente=ag.Agente),
      'CampoJ'=(SELECT COUNT(Mov) FROM #TablaJ WHERE Agente=ag.Agente),
      'CampoM'=(SELECT COUNT(Origen) FROM #TablaM WHERE Agente=ag.Agente),
      'CampoC1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC1 WHERE Agente=ag.Agente),
      'CampoE1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE1 WHERE Agente=ag.Agente),
      'CampoG1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG1 WHERE Agente=ag.Agente),
      'CampoSalieron1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron1 WHERE Agente=ag.Agente),
      'CampoJ1'=(SELECT COUNT(Mov) FROM #TablaJ1 WHERE Agente=ag.Agente),
      'CampoM1'=(SELECT COUNT(Origen) FROM #TablaM1 WHERE Agente=ag.Agente),
      'CampoC2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC2 WHERE Agente=ag.Agente),
      'CampoE2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE2 WHERE Agente=ag.Agente),
      'CampoG2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG2 WHERE Agente=ag.Agente),
      'CampoSalieron2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron2 WHERE Agente=ag.Agente),
      'CampoJ2'=(SELECT COUNT(Mov) FROM #TablaJ2 WHERE Agente=ag.Agente),
      'CampoM2'=(SELECT COUNT(Origen) FROM #TablaM2 WHERE Agente=ag.Agente),
      'Equipo'=ISNULL(ea.Equipo,''),
      ag.Familia,
      ag.Categoria,
      'Celula'=(SELECT Equipo FROM EquipoAgente WITH(NOLOCK) WHERE Agente=ea.Equipo),
      @RD1, @RD2, @RD3, @R1, @R2, @M1, @M2
    FROM
      Agente ag WITH(NOLOCK) LEFT OUTER JOIN EquipoAgente ea WITH(NOLOCK)
    ON
      ag.Agente=ea.Agente
    UPDATE #TablaTotal SET Celula='' WHERE ISNULL(Celula,'')=''
    IF (@Agente='' AND @Equipo='' AND @Familia='')
      BEGIN
        SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0)
          ORDER BY Equipo, Familia
      END
    ELSE IF (@Agente<>'')
      BEGIN
        SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Codigo=@Agente
          ORDER BY Equipo, Familia
      END
    ELSE IF (@Equipo<>'')
      BEGIN
        IF (@Familia<>'')
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND (Equipo=@Equipo OR Celula=@Equipo) AND Familia=@Familia
              ORDER BY Equipo, Familia
          END
        ELSE
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND (Equipo=@Equipo OR Celula=@Equipo)
              ORDER BY Equipo, Familia
          END
      END
    ELSE IF (@Familia<>'')
      BEGIN
        IF (@Equipo<>'')
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND (Equipo=@Equipo OR Celula=@Equipo) AND Familia=@Familia
              ORDER BY Equipo, Familia
          END
        ELSE
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Familia=@Familia
              ORDER BY Equipo, Familia
          END
      END
--select *,'tablatotal' from #tablatotal
END
ELSE
BEGIN
    INSERT #TablaTotal(Codigo, Nombre, CampoA, CampoB, CampoC, CampoE, CampoG, CampoSalieron, CampoJ, CampoM, CampoC1,
      CampoE1, CampoG1, CampoSalieron1, CampoJ1, CampoM1, CampoC2, CampoE2, CampoG2, CampoSalieron2, CampoJ2, CampoM2,
      Equipo, Familia, Categoria, Celula, RD1, RD2, RD3, R1, R2, M1, M2)
    SELECT
      ag.Agente,
      ag.Nombre,
      'CampoA'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaA WHERE Agente=ag.Agente),
      'CampoB'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaB WHERE Agente=ag.Agente),
      'CampoC'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC WHERE Agente=ag.Agente),
      'CampoE'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE WHERE Agente=ag.Agente),
      'CampoG'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG WHERE Agente=ag.Agente),
      'CampoSalieron'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron WHERE Agente=ag.Agente),
      'CampoJ'=(SELECT COUNT(Mov) FROM #TablaJ WHERE Agente=ag.Agente),
      'CampoM'=(SELECT COUNT(Origen) FROM #TablaM WHERE Agente=ag.Agente),
      'CampoC1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC1 WHERE Agente=ag.Agente),
      'CampoE1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE1 WHERE Agente=ag.Agente),
      'CampoG1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG1 WHERE Agente=ag.Agente),
      'CampoSalieron1'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron1 WHERE Agente=ag.Agente),
      'CampoJ1'=(SELECT COUNT(Mov) FROM #TablaJ1 WHERE Agente=ag.Agente),
      'CampoM1'=(SELECT COUNT(Origen) FROM #TablaM1 WHERE Agente=ag.Agente),
      'CampoC2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC2 WHERE Agente=ag.Agente),
      'CampoE2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaE2 WHERE Agente=ag.Agente),
      'CampoG2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaG2 WHERE Agente=ag.Agente),
      'CampoSalieron2'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron2 WHERE Agente=ag.Agente),
      'CampoJ2'=(SELECT COUNT(Mov) FROM #TablaJ2 WHERE Agente=ag.Agente),
      'CampoM2'=(SELECT COUNT(Origen) FROM #TablaM2 WHERE Agente=ag.Agente),
      'Equipo'=(SELECT TOP(1) vc.Cadena FROM VentasCanalMavi vc WITH(NOLOCK), #TablaA a WHERE a.CV=vc.ID and a.Agente=ag.Agente),
      '',
      'Categoria'=(SELECT TOP(1) vc.Categoria FROM VentasCanalMavi vc WITH(NOLOCK), #TablaA a WHERE a.CV=vc.ID and a.Agente=ag.Agente),
      'Celula'='',
      @RD1, @RD2, @RD3, @R1, @R2, @M1, @M2
    FROM
      Agente ag
   
    IF (@Agente='' AND @Institucion='')
      BEGIN
        SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0)
          ORDER BY Equipo
      END
    ELSE IF (@Agente<>'')
      BEGIN
        IF (@Institucion='')
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Codigo=@Agente
             ORDER BY Equipo
          END
        ELSE
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Codigo=@Agente AND Equipo=(SELECT Cadena FROM VentasCanalMavi WITH(NOLOCK) WHERE Clave=@Institucion)
              ORDER BY Equipo
          END
      END
    ELSE IF (@Institucion<>'')
      BEGIN
        IF (@Agente='')
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Equipo=(SELECT Cadena FROM VentasCanalMavi WITH(NOLOCK) WHERE Clave=@Institucion)
              ORDER BY Equipo
          END
        ELSE
          BEGIN
            SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0) AND Equipo=(SELECT Cadena FROM VentasCanalMavi WITH(NOLOCK) WHERE Clave=@Institucion) AND Codigo=@Agente
              ORDER BY Equipo
          END
      END
END
DROP TABLE #tablaa
DROP TABLE #tablab
DROP TABLE #tablac
DROP TABLE #tablae
DROP TABLE #tablac1
DROP TABLE #tablae1
DROP TABLE #tablac2
DROP TABLE #tablae2
DROP TABLE #tablag
DROP TABLE #tablasalieron
DROP TABLE #tablaj    
DROP TABLE #tablam
DROP TABLE #tablag1
DROP TABLE #tablasalieron1
DROP TABLE #tablaj1
DROP TABLE #tablam1
DROP TABLE #tablag2
DROP TABLE #tablasalieron2
DROP TABLE #tablaj2
DROP TABLE #tablam2
DROP TABLE #tablatotal
END
GO
