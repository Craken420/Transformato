  DECLARE @Agrupadores varchar(max);
  SELECT
    @Agrupadores = concat(@Agrupadores, concat('[', concat(Nombre, '],')))
  FROM CREDICAgrupador WITH (NOLOCK)
  SELECT
    @Agrupadores = SUBSTRING(@Agrupadores, 1, LEN(@Agrupadores) - 1)

  DECLARE @query nvarchar(max) = N'
		