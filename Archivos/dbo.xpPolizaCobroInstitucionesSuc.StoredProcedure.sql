SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[xpPolizaCobroInstitucionesSuc] @FechaEmision datetime
AS
BEGIN

  TRUNCATE TABLE TMaviTipoFactura
  INSERT INTO TMaviTipoFactura
    SELECT
      C.ID,
      FechaEmision = C.FechaEmision,
      D.Renglon,
      A.PadreMavi,
      A.PadreIdMavi,
      EsSaldo = NULL,
      TipoFactura =
                   CASE
                     WHEN A.Usuario = 'ADMIN' THEN 'FSI'
                     ELSE 'TN0'
                   END,
      Caso = 'SEGVIDA',
      FechaSegVida = NULL,
      FactorSegVida = NULL,
      SumaAsegSegVida = NULL,
      ExigibleSegVida = NULL,
      Asistencia = 0,
      Etapa = 0,
      Condicion = NULL,
      ImpteVenta = 0
    FROM CxC C WITH (NOLOCK)
    JOIN CxCD D WITH (NOLOCK)
      ON D.ID = C.ID
    JOIN CxC A WITH (NOLOCK)
      ON D.Aplica = A.Mov
      AND D.AplicaID = A.MovId
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'Concluido'
    AND ISNULL(D.Aplica, '') NOT IN ('Redondeo', '')
    AND ISNULL(D.Importe, 0) <> 0
    AND C.FechaEmision = @FechaEmision
    AND C.GenerarPoliza = 1
    AND A.Padremavi = 'Seguro Vida'

  UPDATE M WITH (ROWLOCK)
  SET M.FechaSegVida = C.FechaEmision,
      M.FactorSegVida =
                       CASE
                         WHEN C.FechaEmision <= '20130531' THEN 0.5500
                         WHEN C.FechaEmision <= '20150210' THEN 0.7500
                         WHEN C.FechaEmision <= '20171231' THEN 0.5333
                         ELSE 0.6566
                       END,
      M.SumaAsegSegVida =
                         CASE
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA 250,000 PESOS' THEN 250
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA 200,000 PESOS' THEN 200
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA 150,000 PESOS' THEN 150
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA 100,000 PESOS' THEN 100
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA $75,000 PESOS' THEN 75
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA $50,000 PESOS' THEN 50
                           WHEN ISNULL(B.Articulo, '') = 'CERTIFICADO SEGURO DE VIDA $30,000 PESOS' THEN 30
                           ELSE 0
                         END,
      M.Etapa =
               CASE
                 WHEN C.FechaEmision <= '20130531' THEN 1
                 WHEN C.FechaEmision <= '20150210' THEN 2
                 WHEN C.FechaEmision <= '20171231' THEN 3
                 ELSE 4
               END
  FROM TMaviTipoFactura M
  JOIN Cxc C WITH (NOLOCK)
    ON M.PadreMavi = C.Mov
    AND M.PadreIdmavi = C.MovId
  LEFT JOIN BonifSIMavi B WITH (NOLOCK)
    ON B.IDCxc = C.Id

  UPDATE M WITH (ROWLOCK)
  SET M.SumaAsegSegVida =
                         CASE
                           WHEN SumaAsegSegVida = 0 THEN CAST(RIGHT(D.Articulo, 5) AS float)
                           ELSE SumaAsegSegVida
                         END,
      M.Impteventa = E.Importe + E.Impuestos,
      M.Condicion = E.Condicion,
      M.Asistencia =
                    CASE
                      WHEN LEFT(D.Articulo, 4) = 'VIAS' THEN 1
                      ELSE 0
                    END
  FROM TMaviTipoFactura M
  JOIN Venta E WITH (NOLOCK)
    ON E.Mov = M.padremavi
    AND E.MovId = M.padreidmavi
  JOIN VentaD D WITH (NOLOCK)
    ON E.Id = D.Id
  WHERE M.Caso = 'SEGVIDA'

  UPDATE M WITH (ROWLOCK)
  SET M.FactorSegVida = ROUND((ImpteVenta / Co.DANumeroDocumentos) / SumaAsegSegVida, 4)
  FROM TMaviTipoFactura M
  JOIN Condicion Co WITH (NOLOCK)
    ON Co.Condicion = M.Condicion
  WHERE M.Caso = 'SEGVIDA'
  AND M.Etapa >= 3
  AND M.Asistencia = 0

  UPDATE M WITH (ROWLOCK)
  SET M.ExigibleSegVida = (M.FactorSegVida * M.SumaAsegSegVida) + (CASE
    WHEN M.Asistencia = 1 THEN 30.00
    ELSE 0.00
  END)
  FROM TMaviTipoFactura M


  TRUNCATE TABLE ConexionPolizaCobroInstMavi
  DECLARE @renglon int
  SET @renglon = 0

  --01 Cargo a Cta 112-03-XXXXX - 'Deudores (Instituciones)' (Todas los movimientos)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = C.Sucursal,
      Cuenta = MAX(REPLACE(Co.Cuenta, '112-03', '112-06')),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = SUM(D.Importe),
      Haber = MAX(0.00),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(1),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    LEFT JOIN VentasCanalMavi V WITH (NOLOCK)
      ON V.Id = C.ClienteEnviarA
    LEFT JOIN VentasCanalMavi V2 WITH (NOLOCK)
      ON V2.Id = C2.ClienteEnviarA
    LEFT JOIN Concepto Co WITH (NOLOCK)
      ON Co.Modulo = 'DIN'
      AND Co.Concepto = '('
      + STR(CASE
        WHEN ISNULL(V.Categoria, '') <> 'INSTITUCIONES' THEN V2.Id
        ELSE V.Id
      END, 2)
      + ') ' +
              CASE
                WHEN ISNULL(V.Categoria, '') <> 'INSTITUCIONES' THEN V2.Clave
                ELSE V.Clave
              END
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND C.FechaEmision = @FechaEmision
    --And C.Id In (8540192)
    GROUP BY C.Id,
             C.Sucursal,
             C.ClienteEnviarA

  -- 03 Cargo a Cta 110-99 - 'Intereses por Cobrar a Clientes' (Prestamos de Dinero)
  DECLARE @Prestamos AS TABLE (
    IdCobro int,
    Mov varchar(20),
    MovId varchar(20),
    Cte varchar(10),
    Sucursal int,
    Canal int,
    FechaEmision datetime,
    IdPadre int,
    Total money,
    PorcFinan float,
    IvaFiscal float,
    SubFinan money,
    IvaFinan money,
    TotFinan money
  )

  INSERT INTO @Prestamos
    SELECT
      IdCobro = C.Id,
      Mov = MAX(C.Mov),
      MovId = MAX(C.MovId),
      Cte = MAX(C.Cliente),
      Sucursal = MAX(C.Sucursal),
      Canal = MAX(C.ClienteEnviarA),
      FechaEmision = MAX(C.FechaEmision),
      IDPadre = C2.Id,
      Total = SUM(D.Importe),
      PorcFinan = MAX(0.00),
      IvaFiscal = MAX(0.00),
      SubFinan = MAX(0.00),
      IvaFinan = MAX(0.00),
      TotFinan = MAX(0.00)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND D.Aplica = 'Cta Incobrable NV'
    AND C.FechaEmision = @FechaEmision --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C2.Id

  UPDATE FCI
  SET FCI.PorcFinan = CAST(C2.Financiamiento AS float) / CAST(C2.Importe + C2.Impuestos AS float),
      FCI.IvaFiscal = CAST(C2.Impuestos AS float) / CAST(C2.Financiamiento AS float)
  FROM @Prestamos FCI
  JOIN CXCD D WITH (NOLOCK)
    ON D.Id = FCI.IdPadre
  JOIN CXC C WITH (NOLOCK)
    ON C.Mov = D.APlica
    AND C.MovID = D.APlicaId
  JOIN CXC C2 WITH (NOLOCK)
    ON C2.Mov = C.PadreMavi
    AND C2.MovId = C.PadreIdMavi

  INSERT INTO @Prestamos
    SELECT
      IdCobro = C.Id,
      Mov = MAX(C.Mov),
      MovId = MAX(C.MovId),
      Cte = MAX(C.Cliente),
      Sucursal = MAX(C.Sucursal),
      Canal = MAX(C.ClienteEnviarA),
      FechaEmision = MAX(C.FechaEmision),
      IDPadre = C3.Id,
      Total = SUM(D.Importe),
      PorcFinan = MAX(CAST(C3.Financiamiento AS float) / CAST(C3.Importe + C3.Impuestos AS float)),
      IvaFiscal = MAX(CAST(C3.Impuestos AS float) / CAST(C3.Financiamiento AS float)),
      SubFinan = MAX(0.00),
      IvaFinan = MAX(0.00),
      TotFinan = MAX(0.00)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    JOIN Cxc C3 WITH (NOLOCK)
      ON C3.Mov = C2.PadreMavi
      AND C3.MovID = C2.PadreIdMavi
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND C2.PadreMavi IN ('Credilana', 'Refinanciamiento', 'Prestamo Personal')
    AND C.FechaEmision = @FechaEmision --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C3.Id,
             CAST(C2.Impuestos AS float) / CAST(C2.Importe + C2.Impuestos AS float)

  UPDATE @Prestamos
  SET IvaFinan = Total * PorcFinan * IvaFiscal,
      TotFinan = Total * PorcFinan

  UPDATE @Prestamos
  SET SubFinan = TotFinan - IvaFinan

  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('110-99-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = SUM(C.TotFinan),
      Haber = MAX(0.00),
      MovID = MAX(C.MovID),
      IDOrigen = C.IDCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(3),
      Canal = MAX(C.Canal)
    FROM @Prestamos C
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 04 Cargo a Cta 205-01 - 'Iva Trasl P/A Ventas al 15%' (Facturas/Notas Cargo Instituciones con Fecha Emision <= 31/Dic/2009)
  DECLARE @MvtosIvas15 AS TABLE (
    IdCobro int,
    Mov varchar(20),
    MovId varchar(20),
    Cte varchar(10),
    Sucursal int,
    Canal int,
    FechaEmision datetime,
    IdPadre int,
    Total float,
    Tipo varchar(10),
    IvaFiscal float,
    Iva15 float,
    Iva16 float
  )

  INSERT INTO @MvtosIvas15
    SELECT
      IdCobro = R.IdCobro,
      Mov = MAX(R.Mov),
      MovId = MAX(R.MovId),
      Cte = MAX(R.Cte),
      Sucursal = MAX(R.Sucursal),
      Canal = MAX(R.Canal),
      FechaEmision = MAX(R.FechaEmision),
      IdPadre = R.IdPadre,
      Total = SUM(R.Total),
      Tipo = MAX(R.Tipo),
      R.IvaFiscal,
      0.00,
      0.00
    FROM (SELECT
      IdCobro = C.Id,
      Mov = C.Mov,
      MovId = C.MovId,
      Cte = C.Cliente,
      C.Sucursal,
      Canal = C.ClienteEnviarA,
      FechaEmision = C.FechaEmision,
      IDPadre = C3.Id,
      Total = CAST(D.Importe AS float),
      IvaFiscal = CAST(C2.Impuestos AS float) / (CAST(C2.Importe AS float) + CAST(C2.Impuestos AS float)),
      Tipo =
            CASE
              WHEN C3.FechaEmision <= '20091231' THEN 'Iva15'
              ELSE 'IvaAct'
            END
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    JOIN Cxc C3 WITH (NOLOCK)
      ON C3.Mov = C2.PadreMavi
      AND C3.MovID = C2.PadreIdMavi
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND C2.PadreMavi NOT IN ('Credilana', 'Refinanciamiento', 'Cta Incobrable NV', 'Prestamo Personal',
    'Seguro Auto', 'Seguro Vida', 'Cancela Seg Auto', 'Cancela Seg Vida',
    'Nota Credito', 'Cancela Credilana', 'Nota Credito VIU', 'Nota Credito Mayoreo', 'Cancela Prestamo')
    AND C.FechaEmision = @FechaEmision
    --And C.Id In (8540156)
    ) R
    GROUP BY R.IdCobro,
             R.IdPadre,
             R.IvaFiscal

  UPDATE @MvtosIvas15
  SET Iva15 = ROUND((Total / 1.15) * 0.15, 4),
      Iva16 = ROUND(Total * IvaFiscal, 4)

  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('205-01-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = SUM(Iva15),
      Haber = MAX(0.00),
      MovID = MAX(C.MovID),
      IDOrigen = C.IDCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(4),
      Canal = MAX(Canal)
    FROM @MvtosIvas15 C
    WHERE C.Tipo = 'Iva15'
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 05 Cargo a Cta 520-01-00080 - '1% Diferencia de IVA' (Facturas ó Cargos Instituciones con Fecha Emision <= 31/Dic/2009)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('520-01-00080'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = SUM(Iva16 - Iva15),
      Haber = MAX(0.00),
      MovID = MAX(C.MovID),
      IDOrigen = C.IDCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(5),
      Canal = MAX(Canal)
    FROM @MvtosIvas15 C
    WHERE C.Tipo = 'Iva15'
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 06 Cargo a Cta 205-02 - 'Iva Trasl P/A Ventas al 16%' Todos los casos excepto:
  -- a) Facturas ó Cargos Instituciones con Fecha Emision >= 31/Dic/2009
  -- b) Prestamos de Dinero, Seguros Auto, Seguro Vida, Notas de Credito (en sus diferentes versiones)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('205-02-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = SUM(Iva16),
      Haber = MAX(0.00),
      MovID = MAX(C.MovID),
      IDOrigen = C.IdCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(6),
      Canal = MAX(Canal)
    FROM @MvtosIvas15 C
    WHERE C.Tipo = 'IvaAct'
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 7 Abono a Cta 110-01-00000 - 'Clientes' (Todos los casos)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = C.Sucursal,
      Cuenta = '110-01-00000',
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM(D.Importe),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(7),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND C2.PadreMavi NOT IN ('Seguro Vida', 'Seguro Auto', 'Cancela Seg Vida', 'Cancela Seg Auto')
    AND C.FechaEmision = @FechaEmision --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C.Sucursal

  -- 8 Abono a Cta 206-01-00000 - 'Acreedores Diversos' (Seguros de Auto)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = C.Sucursal,
      Cuenta = '206-01-00000',
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM(D.Importe),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(8),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN Cxc C2 WITH (NOLOCK)
      ON C2.Mov = D.Aplica
      AND C2.MovId = D.AplicaId
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND C2.PadreMavi IN ('Seguro Auto', 'Cancela Seg Auto')
    AND C.FechaEmision = @FechaEmision --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C.Sucursal

  -- 9 Abono a Cta 540-02 - 'Intereses Credilana' (Prestamos de Dinero)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('540-02-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM(SubFinan),
      MovID = MAX(C.MovID),
      IDOrigen = C.IDCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(9),
      Canal = MAX(Canal)
    FROM @Prestamos C
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 10 Abono a Cta 204-06 - 'Iva Trasl Ints Prestamos P' (Prestamos de Dinero)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('204-06-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM(IvaFinan),
      MovID = MAX(C.MovID),
      IDOrigen = C.IdCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(10),
      Canal = MAX(Canal)
    FROM @Prestamos C
    GROUP BY C.IdCobro,
             C.Sucursal

  -- 11 Abono a Cta 204-02 - 'Iva Trasl Ventas al 16%' Todos los casos excepto:
  -- a) Notas de Credito en sus diferentes versiones
  -- b) Seguro Auto y Seguro Vida
  -- c) Credilanas, Refinanciamientos y Cta Incobrable NV
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.IdCobro, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      C.Sucursal,
      Cuenta = MAX('204-02-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM(Iva16),
      MovID = MAX(C.MovId),
      IDOrigen = C.IdCobro,
      ContactoEspecifico = MAX(C.Cte),
      Orden = MAX(11),
      Canal = MAX(Canal)
    FROM @MvtosIvas15 C
    GROUP BY C.IdCobro,
             C.Sucursal


  --12 Abono a Cta 206-10-00001 - 'Cobros por Seguros - Chubb Seguros México S.A.' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('206-10-00001'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * Tf.SumaAsegSegVida *
                                                                                        CASE
                                                                                          WHEN C.FechaEmision <= '20171231' THEN .2200
                                                                                          ELSE 0.2708
                                                                                        END),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(12),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA' --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso

  --13 Abono a Cta 206-10-00002 - 'Cobros Seguros - Club Asistencia S.A. de C.V.' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('206-10-00002'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * 30.00 * 0.4),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(13),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA'
    AND Tf.Asistencia = 1
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso

  --14 Abono a Cta 560-27-00000 - 'Otros Ingresos - Comision por Seguros de Asistencia' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('560-27-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * 30.00 * 0.6 / 1.16),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(14),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA' --And C.Id In (8538150,8538168)
    AND Tf.Asistencia = 1
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso

  --15 Abono a Cta 560-11 - 'Otros Ingresos - Comision por Venta de Seguros' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('560-11-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID),
      Debe = MAX(0.00),
      Haber = SUM((D.Importe - (((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * Tf.SumaAsegSegVida *
                                                                                                       CASE
                                                                                                         WHEN C.FechaEmision <= '20171231' THEN .2200
                                                                                                         ELSE 0.2708
                                                                                                       END) + (CASE
        WHEN Tf.Asistencia = 1 THEN (CAST(D.Importe AS float) / Tf.ExigibleSegVida) * 30.00
        ELSE 0.00
      END))) / 1.16),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(15),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA' --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso

  --16 Abono a Cta 204-04-00000 - 'Iva Trasladado - Iva Trasl Otros Ingresos Club Asistencia' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('204-04-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID + ' Club Asistencia'),
      Debe = MAX(0.00),
      Haber = SUM(((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * 30.00 * 0.6 / 1.16) * 0.16),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(16),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA' --And C.Id In (8538150,8538168)
    AND Tf.Asistencia = 1
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso

  --17 Abono a Cta 204-04-00000 - 'Iva Trasladado - Otros Ingresos Chubb' (Seguros Vida)
  SELECT
    @renglon = COUNT(1)
  FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)
  INSERT ConexionPolizaCobroInstMavi
    SELECT
      Renglon = (ROW_NUMBER() OVER (ORDER BY C.Id, C.Sucursal) + @renglon) * 2048,
      FechaEmision = MAX(C.FechaEmision),
      Sucursal = MAX(C.Sucursal),
      Cuenta = MAX('204-04-00000'),
      Concepto = MAX(C.Mov + ' ' + C.MovID + ' Chubb'),
      Debe = MAX(0.00),
      Haber = SUM(((D.Importe - (
      ((CAST(D.Importe AS float) / Tf.ExigibleSegVida) * Tf.SumaAsegSegVida *
                                                                             CASE
                                                                               WHEN C.FechaEmision <= '20171231' THEN .2200
                                                                               ELSE 0.2708
                                                                             END) +
      (CASE
        WHEN Tf.Asistencia = 1 THEN (CAST(D.Importe AS float) / Tf.ExigibleSegVida) * 30.00
        ELSE 0.00
      END)
      )) / 1.16) * 0.16),
      MovID = MAX(C.MovID),
      IDOrigen = C.ID,
      ContactoEspecifico = MAX(C.Cliente),
      Orden = MAX(17),
      Canal = MAX(C.ClienteEnviarA)
    FROM Cxc C WITH (NOLOCK)
    JOIN CxcD D WITH (NOLOCK)
      ON C.Id = D.Id
    JOIN TMaviTipoFactura Tf WITH (NOLOCK)
      ON Tf.Id = D.Id
      AND Tf.Renglon = D.Renglon
    WHERE C.Mov = 'Cobro Instituciones'
    AND C.Estatus = 'CONCLUIDO'
    AND C.GenerarPoliza = 1
    AND C.PolizaId IS NULL
    AND Tf.Caso = 'SEGVIDA' --And C.Id In (8538150,8538168)
    GROUP BY C.Id,
             C.Sucursal--, Tf.Caso


  DECLARE @Sucursal int,
          @Canal int

  BEGIN
    DECLARE crCxcSucursal CURSOR FOR

    SELECT DISTINCT
      Sucursal,
      Canal
    FROM ConexionPolizaCobroInstMavi WITH (NOLOCK)

    OPEN crCxcSucursal
    FETCH NEXT FROM crCxcSucursal INTO @Sucursal, @Canal
    WHILE @@FETCH_STATUS <> -1
    BEGIN
      IF @@FETCH_STATUS <> -2
      BEGIN
        EXEC [xpPolizaCobroInstituciones] @FechaEmision,
                                          @Sucursal,
                                          @Canal
        FETCH NEXT FROM crCxcSucursal INTO @Sucursal, @Canal
      END
    END
    CLOSE crCxcSucursal
    DEALLOCATE crCxcSucursal
  END

  RETURN
END

GO
