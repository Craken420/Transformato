SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

-- ========================================================================================================================================  
-- NOMBRE   		: xpRelacionChequeMAVI  
-- NOMBRE			: XPRELACIONCHEQUEMAVI  
-- AUTOR			: ¿?  
-- FECHA CREACION	: ¿?  
-- DESARROLLO		: RM0790 RELACION DE CHEQUES  
-- MODULO			: CONTA  
-- DESCRIPCION		: EXEC XPRELACIONCHEQUEMAVI '2012/08/01', '2012/08/31'
--					: EXEC XPRELACIONCHEQUEMAVI '', ''
--					: EXEC XPRELACIONCHEQUEMAVI ' ', ' '
--					: EXEC XPRELACIONCHEQUEMAVI 'NULL', 'NULL'
--					: EXEC XPRELACIONCHEQUEMAVI NULL, NULL
-- ========================================================================================================================================  
-- ========================================================================================================================================  
-- FECHA Y AUTOR MODIfICACION:     26/10/2010      Por: Andres Velazquez, se estAndarizo para enviarse a MAVISQL  
--
-- FECHA Y AUTOR MODIfICACION:     13/08/2012      Por: miguel de la mora, se valida que el reporte no arroje los cheques donde no aplique 
--														para Prestamo y Retencion.
-- FECHA Y AUTOR MODIfICACION:     17/08/2012      Por: miguel de la mora, se cambiaron lAs formulAs para subtotal, iva y total en Gastos 
--														y Gastos diversos con retencion
-- FECHA Y AUTOR MODIfICACION:     17/08/2012      Por: Carmen Quintana, Se agregó la expresión 'WITH(NOLOCK)' a las tablas, se cambiaron
--														las variables tipo tabla a tablas temporales y se agrgó la instrucción para la
--														salida de un archivo tipo ASCII(.txt)
-- ========================================================================================================================================  
  
CREATE PROCEDURE  [dbo].[xpRelacionChequeMAVI]
	@TIPO VARCHAR(25),
	@CHEFECHAD VARCHAR(20),
	@CHEFECHAA VARCHAR(20)
AS  
	BEGIN  
		DECLARE
			@CONSULTA		VARCHAR(4000),
			@CONSULTA2		VARCHAR(4000),
			@CONSULTA3		VARCHAR(4000),
			@FILTROCONC		VARCHAR(200),
			@RUTAARCHIVO	VARCHAR(4000),
			@RUTAARCHIVO2	VARCHAR(4000),
			@FECHA			VARCHAR(4000),
			@FECHA2			VARCHAR(4000)

		IF @CHEFECHAD='1899/12/30' OR @CHEFECHAD='' OR @CHEFECHAD=' ' OR @CHEFECHAD='NULL' OR @CHEFECHAD IS NULL
			BEGIN  
				IF @CHEFECHAA='1899/12/30' OR @CHEFECHAA='' OR @CHEFECHAA=' ' OR @CHEFECHAA='NULL' OR @CHEFECHAA IS NULL
					BEGIN  
						SET @FECHA=''  
						SET @FECHA2=''  
					END  
				ELSE  
					BEGIN  
						SET @FECHA='			AND D.FECHAEMISION < '+CHAR(39)+CONVERT(VARCHAR(15), (DATEADD(DAY, 1, (CONVERT(DATETIME, @CHEFECHAA)))),112)+CHAR(39)  
						SET @FECHA2='			AND a.FECHAEMISION < '+CHAR(39)+CONVERT(VARCHAR(15), (DATEADD(DAY, 1, (CONVERT(DATETIME, @CHEFECHAA)))),112)+CHAR(39)  
					END  
			END  
		ELSE  
			BEGIN  
				IF @CHEFECHAA='1899/12/30'  
					BEGIN  
						SET @FECHA='			AND D.FECHAEMISION > '+CHAR(39)+@CHEFECHAD+CHAR(39)   
						SET @FECHA2='			AND a.FECHAEMISION > '+CHAR(39)+@CHEFECHAD+CHAR(39)   
					END  
				ELSE  
					BEGIN     
						SET @FECHA='			AND D.FECHAEMISION BETWEEN '+CHAR(39)+@CHEFECHAD+CHAR(39)+' AND '+CHAR(39)+CONVERT(VARCHAR(15),(DATEADD(DAY, 1, (CONVERT(DATETIME, @CHEFECHAA)))),112)+CHAR(39)  
						SET @FECHA2='			AND a.FECHAEMISION BETWEEN '+CHAR(39)+@CHEFECHAD+CHAR(39)+' AND '+CHAR(39)+CONVERT(VARCHAR(15),(DATEADD(DAY, 1, (CONVERT(DATETIME, @CHEFECHAA)))),112)+CHAR(39)  
					END  
			END  

	IF UPPER(@TIPO) = 'CHEQUES'
		BEGIN
			IF EXISTS(SELECT Name FROM SysObjects WHERE Name='RM0790CadenaAnalitico' AND TYPE='U')            
				DROP TABLE RM0790CadenaAnalitico

			CREATE TABLE RM0790CadenaAnalitico (ID int identity primary key, Dato varchar(4000))

			INSERT INTO RM0790CadenaAnalitico (Dato)
					SELECT Dato = '|DID|DMOV|DMOVID|PROVEEDOR|NOMBRE|RFC|TIPOTERCERO|TIPOOPERACION|FECHAEMISION'+
								  '|DINERO|DINEROID|DINEROCTADINERO|DINEROCONCILIADO|DINEROFECHACONCILIACION'+
								  '|OID|ORIGEN|ORIGENID|OMOV|OMOVID|SUBTOTAL|IVA|IMPORTE|MODULO|'

			SET @CONSULTA='	INSERT INTO  RM0790CadenaAnalitico (Dato)
		SELECT DATO = 
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.did),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dmov,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dmovid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(D.PROVEEDOR,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(e.nombre,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(e.rfc,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(e.tipotercero,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(e.tipooperacion,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, D.FECHAEMISION, 103),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(D.DINERO,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(D.DINEROID,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(D.DINEROCTADINERO,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, D.DINEROCONCILIADO),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, D.DINEROFECHACONCILIACION, 103),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.oid),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.origen,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.origenid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.omov,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.omovid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, ((C.IMPORTE * D.IVAFISCAL)/ .16)),'+char(39)+''+char(39)+')+
			'+CHAR(39)+'|'+CHAR(39)+'+isnull(convert(varchar, (c.importe * d.ivafiscal)),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, c.importe),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+
		'FROM MOVFLUJO A WITH(NOLOCK)
			LEFT JOIN CXP B WITH(NOLOCK) ON B.MOV=A.OMOV AND B.MOVID=A.OMOVID
			LEFT JOIN CXPD C WITH(NOLOCK) ON C.APLICA=A.OMOV AND C.APLICAID=A.OMOVID AND C.ID=A.DID
			LEFT JOIN CXP D WITH(NOLOCK) ON D.MOV=A.DMOV AND D.MOVID=A.DMOVID
			LEFT JOIN PROV E WITH(NOLOCK) ON E.PROVEEDOR=D.PROVEEDOR
		where a.dmov='+char(39)+'pago'+char(39)+'
			AND D.ESTATUS='+char(39)+'CONCLUIDO'+char(39)+char(13)+@FECHA

			EXEC (@CONSULTA)

			SELECT @RutaArchivo = Valor FROM TablaStD WHERE TablaSt='RUTAS REPORTES BURO Y CARTERA' AND Nombre='CARTERA' 

			SELECT @RutaArchivo='bcp "SELECT dato FROM ' + DB_NAME() + '.dbo.RM0790CadenaAnalitico WITH(NOLOCK)" queryout "' + @RutaArchivo + 'RM0790Analitico.txt" -c -T'
				  
			EXEC xp_cmdshell @RutaArchivo

			IF EXISTS(SELECT Name FROM SysObjects WHERE Name='RM0790CadenaAnalitico' AND TYPE='U')            
			DROP TABLE RM0790CadenaAnalitico       
		END

	IF UPPER(@TIPO) = 'ANTICIPOS'
		BEGIN
			IF EXISTS(SELECT Name FROM SysObjects WHERE Name='RM0790CadenaAnticipos' AND TYPE='U')            
				DROP TABLE RM0790CadenaAnticipos

			CREATE TABLE RM0790CadenaAnticipos (ID int identity primary key, Dato varchar(4000))

			INSERT INTO RM0790CadenaAnticipos (Dato)
					SELECT Dato = '|OID|OMOV|OMOVID|PROVEEDOR|NOMBRE|RFC|TIPOTERCERO|TIPOOPERACION'+
								  '|FECHAEMISION|IMPORTE|IMPUESTOS|TOTAL|DINERO|DINEROID|DINEROCTADINERO'+
								  '|DINEROCONCILIADO|DINEROFECHACONCILIACION|MODULO|'

			SET @CONSULTA2='	INSERT INTO RM0790CadenaAnticipos (Dato)
		SELECT DATO = 
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, c.oid), '+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(c.omov,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(c.omovid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.proveedor,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.nombre,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.rfc,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.tipotercero,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.tipooperacion,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.fechaemision, 103),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.importe),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.impuestos),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, (a.importe + a.impuestos)),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dinero,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dineroid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.DINEROCTADINERO,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.DINEROCONCILIADO),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.DINEROFECHACONCILIACION,103), '+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+'+char(39)+'CXP'+char(39)+'+'+char(39)+'|'+char(39)+CHAR(13)+
'		from movflujo c WITH(NOLOCK) 
			left join cxp a WITH(NOLOCK) on a.id=c.oid AND A.MOV=C.OMOV AND A.MOVID=C.OMOVID
			LEFT JOIN PROV b WITH(NOLOCK) ON b.PROVEEDOR=a.PROVEEDOR
		where omov='+char(39)+'Anticipo'+char(39)+'
			and c.omodulo in ('+char(39)+'gas'+char(39)+','+char(39)+'cxp'+char(39)+')
			and c.dmov='+char(39)+'Solicitud Cheque'+char(39)+'
			and a.dinero in ('+char(39)+'cheque'+char(39)+','+char(39)+'cheque electronico'+char(39)+')'+char(13)+@FECHA2

			SET @CONSULTA3='UNION ALL
		SELECT DATO = 
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, c.oid), '+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(c.omov,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(c.omovid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.Acreedor,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.nombre,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.rfc,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.tipotercero,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(b.tipooperacion,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.fechaemision, 103),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.importe),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.impuestos),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, (a.importe + a.impuestos)),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dinero,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.dineroid,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(a.DINEROCTADINERO,'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.DINEROCONCILIADO),'+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+isnull(convert(varchar, a.DINEROFECHACONCILIACION,103), '+char(39)+''+char(39)+')+
			'+char(39)+'|'+char(39)+'+'+char(39)+'GASTO'+char(39)+'+'+char(39)+'|'+char(39)+CHAR(13)+
'		from movflujo c WITH(NOLOCK) 
			left join GASTO a WITH(NOLOCK) on a.id=c.oid AND A.MOV=C.OMOV AND A.MOVID=C.OMOVID
			LEFT JOIN PROV b WITH(NOLOCK) ON b.PROVEEDOR=a.Acreedor
		where omov='+char(39)+'Anticipo'+char(39)+'
			and c.omodulo in ('+char(39)+'gas'+char(39)+','+char(39)+'cxp'+char(39)+')
			and c.dmov='+char(39)+'Solicitud Cheque'+char(39)+'
			and a.dinero in ('+char(39)+'cheque'+char(39)+','+char(39)+'cheque electronico'+char(39)+')'+char(13)+@FECHA2

			EXEC (@CONSULTA2+@CONSULTA3)

			SELECT @RutaArchivo2 = Valor FROM TablaStD WHERE TablaSt='RUTAS REPORTES BURO Y CARTERA' AND Nombre='CARTERA' 

			SELECT @RutaArchivo2='bcp "SELECT dato FROM ' + DB_NAME() + '.dbo.RM0790CadenaAnticipos WITH(NOLOCK)" queryout "' + @RutaArchivo2 + 'RM0790Anticipos.txt" -c -T'
			  
			EXEC xp_cmdshell @RutaArchivo2

			IF EXISTS(SELECT Name FROM SysObjects WHERE Name='RM0790CadenaAnticipos' AND TYPE='U')            
				DROP TABLE RM0790CadenaAnticipos       

		END

END
GO
