-- Configurações
DECLARE 
    @Qt_Tentativas_Para_Alertar INT = 10, 
    @Fl_Envia_Email BIT = 1    

--------------------------------------------------------------
-- Cria as tabelas temporárias
--------------------------------------------------------------

IF (OBJECT_ID('tempdb..#Arquivos_Log') IS NOT NULL) DROP TABLE #Arquivos_Log
CREATE TABLE #Arquivos_Log ( 
    [idLog] INT, 
    [dtLog] NVARCHAR(30) COLLATE SQL_Latin1_General_CP1_CI_AI, 
    [tamanhoLog] INT 
)

IF (OBJECT_ID('tempdb..#Login_Failed') IS NOT NULL) DROP TABLE #Login_Failed
CREATE TABLE #Login_Failed (
    [LogNumber] TINYINT,
    [LogDate] DATETIME, 
    [ProcessInfo] NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AI, 
    [Text] NVARCHAR(MAX) COLLATE SQL_Latin1_General_CP1_CI_AI,
    [Username] AS LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(REPLACE([Text], 'Login failed for user ''', ''), 1, CHARINDEX('. Reason:', REPLACE([Text], 'Login failed for user ''', '')) - 2), CHAR(10), ''), CHAR(13), ''))),
    [IP] AS LTRIM(RTRIM(REPLACE(REPLACE(REPLACE((SUBSTRING([Text], CHARINDEX('[CLIENT: ', [Text]) + 9, LEN([Text]))), ']', ''), CHAR(10), ''), CHAR(13), '')))
)

IF (OBJECT_ID('tempdb..##Tentativas_Conexao') IS NOT NULL) DROP TABLE ##Tentativas_Conexao
CREATE TABLE ##Tentativas_Conexao ( 
    [LogNumber] TINYINT, 
    [LogDate] DATETIME, 
    [ProcessInfo] NVARCHAR(50), 
    [Text] NVARCHAR(MAX),
    [Username] NVARCHAR(256),
    [IP] NVARCHAR(50)
)


IF (OBJECT_ID('tempdb..##Tentativas_Conexao_Por_IP') IS NOT NULL) DROP TABLE ##Tentativas_Conexao_Por_IP
CREATE TABLE ##Tentativas_Conexao_Por_IP ( 
    [IP] NVARCHAR(256),
    Qt_Tentativas INT
)

IF (OBJECT_ID('tempdb..##Tentativas_Conexao_Por_Usuario') IS NOT NULL) DROP TABLE ##Tentativas_Conexao_Por_Usuario
CREATE TABLE ##Tentativas_Conexao_Por_Usuario ( 
    [Username] NVARCHAR(256),
    Qt_Tentativas INT
)


--------------------------------------------------------------
-- Importa os arquivos do ERRORLOG
--------------------------------------------------------------

INSERT INTO #Arquivos_Log
EXEC sys.sp_enumerrorlogs


--------------------------------------------------------------
-- Loop para procurar por falhas de login nos arquivos
--------------------------------------------------------------

DECLARE
    @Contador INT = 0,
    @Total INT = (SELECT COUNT(*) FROM #Arquivos_Log),
    @Ultima_Hora VARCHAR(19) = FORMAT(DATEADD(HOUR, -1, GETDATE()), 'yyyy-MM-dd HH:mm:00'),
    @Agora VARCHAR(19) = CONVERT(VARCHAR(19), GETDATE(), 121)
    

WHILE(@Contador < @Total)
BEGIN
    
    -- Pesquisa por senha incorreta
    INSERT INTO #Login_Failed (LogDate, ProcessInfo, [Text]) 
    EXEC master.dbo.xp_readerrorlog @Contador, 1, N'Password did not match that for the login provided', NULL, @Ultima_Hora, @Agora

    -- Pesquisa por tentar conectar com usuário que não existe
    INSERT INTO #Login_Failed (LogDate, ProcessInfo, [Text]) 
    EXEC master.dbo.xp_readerrorlog @Contador, 1, N'Could not find a login matching the name provided.', NULL, @Ultima_Hora, @Agora

    -- Atualiza o número do arquivo de log
    UPDATE #Login_Failed
    SET LogNumber = @Contador
    WHERE LogNumber IS NULL

    SET @Contador += 1
    
END


--------------------------------------------------------------
-- Salva as tentativas realizadas, já excluindo a lista de exceções
--------------------------------------------------------------

INSERT INTO ##Tentativas_Conexao
SELECT
    A.*
FROM 
    #Login_Failed A
WHERE
    A.[IP] NOT LIKE '%local machine%'
ORDER BY
    A.LogDate

    
INSERT INTO ##Tentativas_Conexao_Por_IP
SELECT
    [IP],
    COUNT(*) AS Quantidade
FROM
    ##Tentativas_Conexao
GROUP BY
    [IP]
ORDER BY
    2 DESC


INSERT INTO ##Tentativas_Conexao_Por_Usuario
SELECT
    [Username],
    COUNT(*) AS Quantidade
FROM
    ##Tentativas_Conexao
GROUP BY
    [Username]
ORDER BY
    2 DESC


select * from  ##Tentativas_Conexao_Por_IP order by Qt_Tentativas desc
select * from  ##Tentativas_Conexao_Por_usuario order by Qt_Tentativas desc
    
