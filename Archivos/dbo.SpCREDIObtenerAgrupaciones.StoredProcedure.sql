DECLARE @Agrupador
es varchar(max);
                  SELECT
@Agrupadores = conc                        at(@Agrupadores, concat('[', concat(Nombre, '],')))
FROM CREDICAg






rupador
SELECT
@Agrupadores = SUBSTRING(@Agr                   upadores, 1, LEN(@Agrupadores) - 1)
DECLARE @query nvarchar(max) = N'