
drop proc BACKUP_DO_SISTEMA
go
CREATE PROCEDURE BACKUP_DO_SISTEMA

AS
/* *DECLARA VARIAVEIS  */
DECLARE @DIA VARCHAR(20)
DECLARE @BasePrincipal VARCHAR(200)
DECLARE @caminho VARCHAR(200)
DECLARE @DatabaseName AS VARCHAR(255);

set datefirst 7

/* TRADUZ DIA PARA PORTUGUES  */
SET @DIA = CASE datepart(dw,getdate())
   WHEN 1 THEN 'Domingo'
   WHEN 2 THEN 'Segunda'   
   WHEN 3 THEN 'Terça'
   WHEN 4 THEN 'Quarta'
   WHEN 5 THEN 'Quinta'
   WHEN 6 THEN 'Sexta'
   WHEN 7 THEN 'sabado'
  END

DECLARE db_cursor CURSOR FOR 
SELECT name 
FROM sys.databases 
where name in ('teste','sisfrutos','matriz')
--WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb'); -- Exclui os bancos de dados de sistema
--- *** o select no sys.database vai retornar TODAS as bases
----*** de dados atachadas no servidor. Escolha as bases desejadas
----*** usando IN , ou use NOT IN para selecionar todas as base 
--- *** EXCETO as as Bases de dados do proprio SQL (master, tempdb...)

OPEN db_cursor
FETCH NEXT FROM db_cursor INTO @DatabaseName;

WHILE @@FETCH_STATUS = 0
BEGIN
 	set @caminho = 'f:\lixo\backup\'+@DatabaseName+'_'+@DIA+'_bkp'
	BACKUP DATABASE @DatabaseName TO  DISK = @caminho

    FETCH NEXT FROM db_cursor INTO @DatabaseName;
END
CLOSE db_cursor
DEALLOCATE db_cursor


/* INSTRUÇÃO DE BACKUP */
--BACKUP DATABASE @DatabaseName TO  DISK = @BasePrincipal
--BACKUP DATABASE sisfrutos_BS TO  DISK = @BaseMatriz
--BACKUP DATABASE sisfrutos_faz TO  DISK = @filia1
--BACKUP DATABASE NFE_mtz TO  DISK = @filia1
--BACKUP DATABASE NFE_faz TO  DISK = @filia2


GO


