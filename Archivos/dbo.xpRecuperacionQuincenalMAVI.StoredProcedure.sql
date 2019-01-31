SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[xpRecuperacionQuincenalMAVI]
@Agente			VARCHAR(10),
@Categoria		VARCHAR(50),
@Institucion	VARCHAR(10),
@Familia		VARCHAR(50),		-- al SP a través del 
@Equipo			VARCHAR(10)		

AS BEGIN
	DECLARE
	@Qna	INT,
	@Qc1	DATETIME,					
	@Qc2	DATETIME,					
	@Qa1	DATETIME,					
	@Qa2	DATETIME,
	@R1		CHAR(8),
	@R2		CHAR(8),
	@M1		CHAR(16),
	@M2		CHAR(16),
	--@Categoria VARCHAR(50),
	@Mes CHAR(2),
	@Anio CHAR(4),
	@MesAnt CHAR(2)/*,
	@Agente			VARCHAR(10),
	@IDCat	INT,
	@Institucion	VARCHAR(10),
	@Familia		VARCHAR(50),		
	@Equipo			VARCHAR(10)

	select 
	@Agente='',
	@IDCat=3,
	@Institucion='',
	@Familia='',
	@Equipo=''*/
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
	--select @qna,@mes,@mesant,@qc1,@qc2,@qa1,@qa2,@r1,@r2,@m1,@m2
	 --SELECT @Categoria=Categoria FROM VentasCanalMavi WHERE ID=@IDCat 
	 
		CREATE TABLE #TablaA(Documento VARCHAR(50)COLLATE Database_Default NULL,
							 Numero VARCHAR(50) COLLATE Database_Default NULL,							 
							 Agente VARCHAR(10) COLLATE Database_Default NULL,
							 FechaVencimiento DATETIME,
							 Referencia VARCHAR(100) COLLATE Database_Default NULL,
							 Quincena INT NULL,
							 Factura VARCHAR(50) COLLATE Database_Default NULL,
							 NFactura VARCHAR(50) COLLATE Database_Default NULL,
							 CV INT NULL, 
							 Total FLOAT NULL, 
							 Vencido FLOAT NULL, 
							 Moratorios FLOAT NULL)
		INSERT #TablaA 
	   (Documento, Numero, Agente, FechaVencimiento, Referencia, Quincena, Factura, NFactura, CV, Total, Vencido, Moratorios)
		SELECT DISTINCT
		  rm.Documento, rm.Numero, rm.AgenteCobrador,rm.FechaVencimiento, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta, (SELECT SUM(c2.Saldo) FROM Cxc c2 WITH(NOLOCK) WHERE c2.Origen=c.Origen AND c2.OrigenID=c.OrigenID) ,c.Saldo,(SELECT dbo.FN_MAVICALCULAMORATORIOS(c.ID))
		FROM
		  MaviRecuperacion rm WITH(NOLOCK),
		  Cxc c WITH(NOLOCK),
		  VentasCanalMavi vc WITH(NOLOCK)
		WHERE
		  rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND
		  rm.Quincena=(@Qna-1) AND rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria AND
		  rm.AgenteCobrador<>'SIN AGENTE' AND c.Estatus <> 'CANCELADO'
		GROUP BY
		  c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento,rm.FechaVencimiento, rm.CanalVenta, c.Saldo/*c.Importe*/, c.ID
		UPDATE #TablaA SET Referencia=Documento+' '+Numero,
		  Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
  --select * from #TablaA
		CREATE TABLE #TablaB(Documento VARCHAR(50) COLLATE Database_Default NULL,
							 Numero VARCHAR(50) COLLATE Database_Default NULL,
							 Agente VARCHAR(10) COLLATE Database_Default NULL,
							 Referencia VARCHAR(100) COLLATE Database_Default NULL,
							 Quincena INT NULL, 
							 Factura VARCHAR(50) COLLATE Database_Default NULL,
							 NFactura VARCHAR(50) COLLATE Database_Default NULL,
							 CV INT NULL,
							 Total FLOAT NULL, 
							 Vencido FLOAT NULL,
							 Moratorios FLOAT NULL)
		INSERT #TablaB(Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, Total, Vencido, Moratorios)
		SELECT DISTINCT
		  rm.Documento, rm.Numero, rm.AgenteCobrador, 'Referencia'=c.Origen+' '+c.OrigenID, MAX(rm.Quincena), c.Origen, c.OrigenID, rm.CanalVenta, (SELECT SUM(c2.Saldo) FROM Cxc c2 WHERE c2.Origen=c.Origen AND c2.OrigenID=c.OrigenID), c.Importe,(SELECT dbo.FN_MAVICALCULAMORATORIOS(c.ID))
		FROM
		  MaviRecuperacion rm WITH(NOLOCK),
		  Cxc c WITH(NOLOCK),
		  VentasCanalMavi vc WITH(NOLOCK)
		WHERE
		  rm.Documento=c.Mov AND rm.Numero=c.MovID AND ISNULL(c.Saldo,0)>=0 AND rm.AgenteCobrador<>'SIN AGENTE' AND
		  rm.Quincena=CASE WHEN (@Qna-2)=0 THEN 24 ELSE @Qna-2 END AND
		  rm.CanalVenta=vc.ID AND vc.Categoria=@Categoria 
		GROUP BY
		  c.Origen, c.OrigenID, rm.Numero, rm.AgenteCobrador, rm.Documento, rm.CanalVenta, c.Importe, c.ID
		UPDATE #TablaB SET Referencia=Documento+' '+Numero,
		  Factura=Documento, NFactura=Numero WHERE ISNULL(Referencia,'')=''
	--select * from #tablab
		CREATE TABLE #TablaC(Documento VARCHAR(50) COLLATE Database_Default NULL,
								   Numero VARCHAR(50) COLLATE Database_Default NULL,
								   Agente VARCHAR(10) COLLATE Database_Default NULL,
								   Referencia VARCHAR(100) COLLATE Database_Default NULL,
								   Quincena INT NULL, 
								   Factura VARCHAR(50) COLLATE Database_Default NULL,
								   NFactura VARCHAR(50) COLLATE Database_Default NULL,
								   CV INT NULL, 
								   Total FLOAT NULL, 
								   Vencido FLOAT NULL)
		INSERT #TablaC (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, Total, Vencido)
		SELECT DISTINCT
		  b.Documento, b.Numero, b.Agente, b.Referencia, b.Quincena, b.Factura, b.NFactura, b.CV, b.Total, b.Vencido
		FROM
		  #TablaA a, #TablaB b
		WHERE
		  a.Factura=b.Factura AND a.NFactura=b.NFactura AND a.Agente=b.Agente
	--select * from #tablac
		CREATE TABLE #TablaSalieron(Documento VARCHAR(50) COLLATE Database_Default NULL,
										 Numero VARCHAR(50) COLLATE Database_Default NULL, 
										 Agente VARCHAR(10) COLLATE Database_Default NULL, 
										 Referencia VARCHAR(100) COLLATE Database_Default NULL,
										 Quincena INT NULL,
										 Factura VARCHAR(50) COLLATE Database_Default NULL,
										 NFactura VARCHAR(50) COLLATE Database_Default NULL,
										 CV INT NULL, 
										 Total FLOAT NULL,
										 Vencido FLOAT NULL)
		INSERT #TablaSalieron (Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, Total, Vencido)
		SELECT DISTINCT
		  Documento, Numero, Agente, Referencia, Quincena, Factura, NFactura, CV, Total, Vencido
		FROM
		  #TablaB
		WHERE
		  Referencia NOT IN (SELECT Referencia FROM #TablaC)
	--select * from #tablasalieron
		CREATE TABLE #TablaH(Cliente VARCHAR(10) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaH (Cliente, Agente)
		SELECT DISTINCT
		  Cliente, AgenteCobrador
		FROM
		  MaviRecuperacion WITH(NOLOCK)
		WHERE
		  Quincena=(@Qna-1)
	--select * from #tablah
		CREATE TABLE #TablaI(Referencia VARCHAR(100) COLLATE Database_Default NULL,
							  Total FLOAT NULL, 
							  Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaI (Referencia, Total, Agente)
		SELECT DISTINCT
		  Referencia, Total, Agente
		FROM
		  #TablaA
	--select * from #tablai
		CREATE TABLE #TablaJ (Referencia VARCHAR(100) COLLATE Database_Default NULL,
							  Vencido FLOAT NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaJ (Referencia, Vencido, Agente)
		SELECT DISTINCT
		  a.Referencia, SUM(a.Vencido+a.Moratorios), a.Agente
		FROM
		  #TablaA a
	   WHERE
		  a.FechaVencimiento <= @Qc2
		  GROUP BY a.Referencia, a.Agente
		
  --select * from #tablaj
		CREATE TABLE #TablaL(Origen VARCHAR(50) COLLATE Database_Default NULL, 
							  OrigenID VARCHAR(50) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL, 
							  Total FLOAT NULL,
							  Referencia VARCHAR(100) COLLATE Database_Default NULL)
		INSERT #TablaL (Origen, OrigenID, Agente, Total, Referencia)
		SELECT
	    c2.Mov, c2.MovID, e.Agente, c2.Importe+c2.Impuestos, ISNULL(c2.Origen,c2.Mov)+' '+ISNULL(c2.OrigenID,c2.MovID)
		FROM
		Cxc c WITH(NOLOCK), cxcd d WITH(NOLOCK), cxc c2 WITH(NOLOCK), embarque e WITH(NOLOCK), embarqued ed WITH(NOLOCK), embarquemov em  WITH(NOLOCK)
		where c.id=d.id and d.aplica=c2.mov and d.aplicaid=c2.movid and
		c.Estatus='CONCLUIDO' AND
		c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
		E.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
		c.Mov='Cobro' AND
		ISNULL(c.Saldo,0)=0
		and d.aplica=em.mov and d.aplicaid=em.movid and em.id=ed.embarquemov and ed.id=e.id 
		INSERT #TablaL (Origen, OrigenID, Agente, Total, Referencia)
		SELECT DISTINCT
		  s.Factura, s.NFactura, s.Agente, c2.Importe+c2.Impuestos, s.Referencia
		FROM
		  #TablaSalieron s,
		  Cxc c2 WITH(NOLOCK)
		WHERE
		  s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
		  c2.Estatus='CONCLUIDO' AND
		  c2.UltimoCambio BETWEEN @Qc1 AND @Qc2
	--select * from #tablal
		CREATE TABLE #TablaEnie(Origen VARCHAR(50) COLLATE Database_Default NULL,
								OrigenID VARCHAR(50) COLLATE Database_Default NULL, 
								Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaEnie (Origen, OrigenID, Agente)
		SELECT DISTINCT
		  ISNULL(c2.Origen,c2.Mov), ISNULL(c2.OrigenID,c2.MovID), e.Agente
		FROM
		Cxc c WITH(NOLOCK), cxcd d WITH(NOLOCK), cxc c2 WITH(NOLOCK), embarque e WITH(NOLOCK), embarqued ed WITH(NOLOCK), embarquemov em  WITH(NOLOCK)
		where c.id=d.id and d.aplica=c2.mov and d.aplicaid=c2.movid and
		c.Estatus='CONCLUIDO' AND
		c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
		E.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
		c.Mov='Cobro' AND
		ISNULL(c.Saldo,0)=0
		and d.aplica=em.mov and d.aplicaid=em.movid and em.id=ed.embarquemov and ed.id=e.id 
	    
	 INSERT #TablaEnie (Origen, OrigenID, Agente) --cobros o documentos realizados en la quincena 16
		SELECT DISTINCT
		  s.Factura, s.NFactura, s.Agente
		FROM
		  #TablaSalieron s,
		  Cxc c2 WITH(NOLOCK)
		WHERE
		  s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
		  c2.Estatus='CONCLUIDO' AND
		  c2.UltimoCambio BETWEEN @Qc1 AND @Qc2
	--select * from #tablaenie
		CREATE TABLE #TablaO(Origen VARCHAR(50) COLLATE Database_Default NULL,
							  OrigenID VARCHAR(50) COLLATE Database_Default NULL, 
							  Agente VARCHAR(10) COLLATE Database_Default NULL) --cobros realizados en la quincena 15
		INSERT #TablaO (Origen, OrigenID, Agente)
		SELECT DISTINCT
		  ISNULL(c2.Origen,c2.Mov), ISNULL(c2.OrigenID,c2.MovID), e.Agente
		FROM
		Cxc c WITH(NOLOCK), cxcd d WITH(NOLOCK), cxc c2 WITH(NOLOCK), embarque e WITH(NOLOCK), embarqued ed WITH(NOLOCK), embarquemov em  WITH(NOLOCK)
		where c.id=d.id and d.aplica=c2.mov and d.aplicaid=c2.movid and
		c.Estatus='CONCLUIDO' AND
		c.FechaEmision BETWEEN @Qa1 AND @Qa2 AND
		E.FechaEmision BETWEEN @Qa1 AND @Qa2 AND
		c.Mov='Cobro' AND
		ISNULL(c.Saldo,0)=0
		and d.aplica=em.mov and d.aplicaid=em.movid and em.id=ed.embarquemov and ed.id=e.id 

		INSERT #TablaO (Origen, OrigenID, Agente)
		SELECT DISTINCT
		  s.Factura, s.NFactura, s.Agente
		FROM
		  #TablaSalieron s,
		  Cxc c2 WITH(NOLOCK)
		WHERE
		  s.Documento=c2.Mov AND s.Numero=c2.MovID AND ISNULL(c2.Saldo,0)>0 AND
		  c2.Estatus='CONCLUIDO' AND
		  c2.UltimoCambio BETWEEN @Qa1 AND @Qa2
	--select * from #tablao

		CREATE TABLE #TablaP(Origen VARCHAR(50) COLLATE Database_Default NULL, 
							  OrigenID VARCHAR(50) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaP (Origen, OrigenID, Agente)
		SELECT DISTINCT
		  e.Origen, e.OrigenID, e.Agente
		FROM
		  #TablaEnie e INNER JOIN #TablaO o
		ON
		  e.Origen=o.Origen AND e.OrigenID=o.OrigenID AND e.Agente=o.Agente
	--select * from #tablap
		CREATE TABLE #TablaQ(Origen VARCHAR(50) COLLATE Database_Default NULL,
							 OrigenID VARCHAR(50) COLLATE Database_Default NULL,
							 Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaQ (Origen, OrigenID, Agente) -- regresa los cobros aun no concluidos 
		SELECT DISTINCT
		   e.Origen, e.OrigenID, e.Agente
		FROM
		   #TablaEnie e LEFT OUTER JOIN #TablaO o
		ON
		  e.Origen=o.Origen AND e.OrigenID=o.OrigenID AND e.Agente=o.Agente
		WHERE
		  o.Origen IS NULL
	--select * from #tablaq
		CREATE TABLE #TablaT (Mov CHAR(20) COLLATE Database_Default NULL, 
							  MovID VARCHAR(20) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL)
		INSERT #TablaT (Mov, MovID, Agente)
		SELECT DISTINCT
		  c.Mov, c.MovID, c.Agente
		FROM
		  Cxc c WITH(NOLOCK)
		WHERE
		  c.Mov IN('Nota Credito','Nota Credito VIU','Cancela Credilana','Cancela Prestamo') AND c.Concepto IN('ADJUDICACION + DE 12','ADJUDICACION 1 A 12','OK ADJUDICACION + DE 12','OK ADJUDICACION 1 A 12','OK ADJ CREDILANA/PP + DE 12','ADJ CREDILANA/PP + DE 12') AND c.Estatus='CONCLUIDO' AND
		  c.FechaEmision BETWEEN @Qc1 AND @Qc2 AND
		  ISNULL(c.Agente,'')<>'' AND EXISTS(SELECT a.referencia FROM #TablaA a, CxcD d WITH(NOLOCK) 
			where c.id=d.id and a.documento=d.aplica  and a.numero=d.aplicaid)
	--select * from #tablaT
		CREATE TABLE #TablaU(Mov CHAR(20) COLLATE Database_Default NULL,
							  MovID VARCHAR(20) COLLATE Database_Default NULL,
							  Agente VARCHAR(10) COLLATE Database_Default NULL) 
		INSERT #TablaU (Mov, MovID, Agente)
		SELECT DISTINCT
		  c.Mov, c.MovID, c.Agente
		FROM
		  Cxc c WITH(NOLOCK)
		WHERE
		  c.Mov IN('Nota Credito','Nota Credito VIU','Cancela Credilana','Cancela Prestamo') AND c.Concepto IN('ADJUDICACION + DE 12','ADJUDICACION 1 A 12','OK ADJUDICACION + DE 12','OK ADJUDICACION 1 A 12','OK ADJ CREDILANA/PP + DE 12','ADJ CREDILANA/PP + DE 12') AND c.Estatus='CONCLUIDO' AND
		  c.FechaEmision BETWEEN @Qa1 AND @Qa2 AND
		  ISNULL(c.Agente,'')<>'' AND EXISTS(SELECT b.referencia FROM #TablaB b, CxcD d WITH(NOLOCK) 
			where c.id=d.id and b.documento=d.aplica  and b.numero=d.aplicaid)
	--select * from #tablau
		CREATE TABLE #TablaTotal(Codigo VARCHAR(10) COLLATE Database_Default NULL, Nombre VARCHAR(100) COLLATE Database_Default NULL, CampoA INT NULL, CampoB INT NULL, CampoC INT NULL,
		  CampoF INT NULL, CampoH INT NULL, CampoI FLOAT NULL, CampoJ FLOAT NULL, CampoL FLOAT NULL, CampoPN INT NULL, CampoEnie INT NULL, CampoO INT NULL, CampoP INT NULL, CampoQ INT NULL,
		  CampoT INT NULL, CampoU INT NULL, Celula VARCHAR(10) COLLATE Database_Default NULL, Equipo VARCHAR(150) COLLATE Database_Default NULL, Familia VARCHAR(50) COLLATE Database_Default NULL, Categoria VARCHAR(50) COLLATE Database_Default NULL, R1 CHAR(8) COLLATE Database_Default NULL,
		  R2 CHAR(8) COLLATE Database_Default NULL, M1 CHAR(16) COLLATE Database_Default NULL, M2 CHAR(16) COLLATE Database_Default NULL)

	IF (@Categoria='Credito Menudeo' OR @Categoria='ASOCIADOS')
	  BEGIN
		INSERT #TablaTotal (Codigo, Nombre, CampoA, CampoB, CampoC, CampoF, CampoH, CampoI, CampoJ, CampoL, CampoPN,
		  CampoEnie, CampoO, CampoP, CampoQ, CampoT, CampoU, Celula, Equipo, Familia, Categoria, R1, R2, M1, M2)
		SELECT
		  ag.Agente,
		  ag.Nombre,
		  'CampoA'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaA WHERE Agente=ag.Agente),
		  'CampoB'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaB WHERE Agente=ag.Agente),
		  'CampoC'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC WHERE Agente=ag.Agente),
		  'CampoF'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron WHERE Agente=ag.Agente),
		  'CampoH'=(SELECT COUNT(DISTINCT(Cliente)) FROM #TablaH WHERE Agente=ag.Agente),
		  'CampoI'=(SELECT SUM(Total) FROM #TablaI WHERE Agente=ag.Agente),
		  'CampoJ'=(SELECT SUM(Vencido) FROM #TablaJ WHERE Agente=ag.Agente),
		  'CampoL'=(SELECT SUM(Total) FROM #TablaL WHERE Agente=ag.Agente),
		  'CampoPN'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaL WHERE Agente=ag.Agente),
		  'CampoEnie'=(SELECT COUNT(Origen) FROM #TablaEnie WHERE Agente=ag.Agente),
		  'CampoO'=(SELECT COUNT(Origen) FROM #TablaO WHERE Agente=ag.Agente),
		  'CampoP'=(SELECT COUNT(Origen) FROM #TablaP WHERE Agente=ag.Agente),
		  'CampoQ'=(SELECT COUNT(Origen) FROM #TablaQ WHERE Agente=ag.Agente),
		  'CampoT'=(SELECT COUNT(MovID) FROM #TablaT WHERE Agente=ag.Agente),
		  'CampoU'=(SELECT COUNT(MovID) FROM #TablaU WHERE Agente=ag.Agente),
		  'Celula'=(SELECT Equipo FROM EquipoAgente WITH(NOLOCK) WHERE Agente=ea.Equipo),
		  'Equipo'=ISNULL(ea.Equipo,''),
		  ag.Familia,
		  ag.Categoria,
		  @R1, @R2, @M1, @M2
		FROM
		  Agente ag WITH(NOLOCK) LEFT OUTER JOIN EquipoAgente ea WITH(NOLOCK)
		ON
		  ag.Agente=ea.Agente

		UPDATE #TablaTotal SET Celula='' WHERE ISNULL(Celula,'')=''
	--select * from #tablatotal    
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
	--select * from #tablatotal
	  END
	 ELSE
	  BEGIN
		INSERT #TablaTotal (Codigo, Nombre, CampoA, CampoB, CampoC, CampoF, CampoH, CampoI, CampoJ, CampoL, CampoPN,
		  CampoEnie, CampoO, CampoP, CampoQ, CampoT, CampoU, Celula, Equipo, Familia, Categoria, R1, R2, M1, M2)
		SELECT
		  ag.Agente,
		  ag.Nombre,
		  'CampoA'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaA WHERE Agente=ag.Agente),
		  'CampoB'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaB WHERE Agente=ag.Agente),
		  'CampoC'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaC WHERE Agente=ag.Agente),
		  'CampoF'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaSalieron WHERE Agente=ag.Agente),
		  'CampoH'=(SELECT COUNT(DISTINCT(Cliente)) FROM #TablaH WHERE Agente=ag.Agente),
		  'CampoI'=(SELECT SUM(Total) FROM #TablaI WHERE Agente=ag.Agente),
		  'CampoJ'=(SELECT SUM(Vencido) FROM #TablaJ WHERE Agente=ag.Agente),
		  'CampoL'=(SELECT SUM(Total) FROM #TablaL WHERE Agente=ag.Agente),
		  'CampoPN'=(SELECT COUNT(DISTINCT(Referencia)) FROM #TablaL WHERE Agente=ag.Agente),
		  'CampoEnie'=(SELECT COUNT(Origen) FROM #TablaEnie WHERE Agente=ag.Agente),
		  'CampoO'=(SELECT COUNT(Origen) FROM #TablaO WHERE Agente=ag.Agente),
		  'CampoP'=(SELECT COUNT(Origen) FROM #TablaP WHERE Agente=ag.Agente),
		  'CampoQ'=(SELECT COUNT(Origen) FROM #TablaQ WHERE Agente=ag.Agente),
		  'CampoT'=(SELECT COUNT(MovID) FROM #TablaT WHERE Agente=ag.Agente),
		  'CampoU'=(SELECT COUNT(MovID) FROM #TablaU WHERE Agente=ag.Agente),
		  'Celula'='',
		  'Equipo'=ISNULL((SELECT TOP(1) vc.Cadena FROM VentasCanalMavi vc WITH(NOLOCK), #TablaC c WHERE c.CV=vc.ID AND c.Agente=ag.Agente),''),
		  '',
		  'Categoria'=(SELECT TOP(1) vc.Categoria FROM VentasCanalMavi vc WITH(NOLOCK), #TablaC c WHERE c.CV=vc.ID AND c.Agente=ag.Agente),
		  @R1, @R2, @M1, @M2
		FROM
		  Agente ag

		IF (@Agente='' AND @Institucion='')
		  BEGIN
			SELECT * FROM #TablaTotal WHERE (CampoA<>0 OR CampoB<>0)
			  ORDER BY Equipo
		  END
		ELSE IF(@Agente<>'')
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

	DROP TABLE #TablaA
	DROP TABLE #TablaB
	DROP TABLE #TablaC
	DROP TABLE #TablaSalieron
	DROP TABLE #TablaH
	DROP TABLE #TablaJ
	DROP TABLE #TablaL
	DROP TABLE #TablaEnie
	DROP TABLE #TablaI
	DROP TABLE #TablaO
	DROP TABLE #TablaP
	DROP TABLE #TablaQ
	DROP TABLE #TablaT
	DROP TABLE #TablaU
	DROP TABLE #TablaTotal

END
GO
