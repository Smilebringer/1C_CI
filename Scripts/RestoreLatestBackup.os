Перем Параметры;

Функция ЗаполнитьПараметрыСкрипта(АргументыКоманднойСтроки)
	
	Параметры = Новый Структура;
	Параметры.Вставить("АдресСервера", АргументыКоманднойСтроки[0]);
	Параметры.Вставить("ИмяБазыИсточника", АргументыКоманднойСтроки[1]);
	Параметры.Вставить("ИмяБазыПриемника", АргументыКоманднойСтроки[2]);
	Параметры.Вставить("РежимОтладки", Ложь);
		
КонецФункции


Функция ВыполнитьЗапрос(ТекстЗапроса, ВозвращатьРезультат = Ложь) Экспорт

	ТекстОшибки = "";
	Если ТекстЗапроса = "" Тогда
		ТекстОшибки = "Не указан запрос!";
		Возврат Ложь;
	КонецЕсли;

	Если Параметры.РежимОтладки Тогда
		Сообщить("Попытка выполнить запрос:");
		Сообщить(ТекстЗапроса);	
	КонецЕсли;

	Попытка
		Соединение  = Новый COMОбъект("ADODB.Connection");
				Соединение.ConnectionString =
				"Provider=SQLOLEDB.1;
				|Trusted_Connection=Yes;
				|Data Source=" + Параметры.АдресСервера + "
				|";			

		Соединение.ConnectionTimeout = 30;
		Соединение.CommandTimeout = 600;
		
		Соединение.Open();
		// Выполним запрос
		Если ВозвращатьРезультат Тогда
			Результат = Соединение.Execute(ТекстЗапроса);
		Иначе
			Соединение.Execute(ТекстЗапроса,,128);
			Результат = Истина;
			// Закроем соединение
			Соединение.Close();
		КонецЕсли;
    Исключение
		ТекстОшибки = ОписаниеОшибки() + Символы.ПС + 
		"Текст запроса: " + Символы.ПС + 
		ТекстЗапроса + Символы.ПС;
		Сообщить(ТекстОшибки);
        Возврат Неопределено;
    КонецПопытки;
	
	Возврат Результат;	
	
КонецФункции		

Процедура ВосстановитьПоследнийБэкап()

	Если Параметры.ИмяБазыПриемника = "erp2_al" Тогда
		Сообщить("Нельзя разворачивать бэкап на рабочую!");	
		Возврат;
	КонецЕсли;

	ТекстЗапроса = 
	"-- Declare variables to be set
	|DECLARE
	|    @FromDatabaseName nvarchar(128),
	|    @ToDatabaseName nvarchar(128);
	| 
	|SET @FromDatabaseName = '" + Параметры.ИмяБазыИсточника + "';
	|SET @ToDatabaseName = '" + Параметры.ИмяБазыПриемника + "';
	| 
	|-- Get latest database backup for the FromDatabase
	|DECLARE @BackupFile nvarchar(260);
	|
	|SELECT @BackupFile=[physical_device_name] FROM [msdb].[dbo].[backupmediafamily]
	|    WHERE [media_set_id] =(SELECT TOP 1 [media_set_id] FROM msdb.dbo.backupset
	|    WHERE database_name=@FromDatabaseName AND type='D' ORDER BY backup_start_date DESC);
	|    
	|-- Get ToDatabase filenames
	|DECLARE
	|    @ToDatabaseFile nvarchar(260),
	|    @ToDatabaseLog nvarchar(260);
	| 
	|SELECT @ToDatabaseFile = f.physical_name FROM sys.master_files f RIGHT JOIN sys.databases d ON f.database_id = d.database_id
	|    WHERE d.name = @ToDatabaseName AND f.type_desc = 'ROWS';
	| 
	|SELECT @ToDatabaseLog = f.physical_name FROM sys.master_files f RIGHT JOIN sys.databases d ON f.database_id = d.database_id
	|    WHERE d.name = @ToDatabaseName AND f.type_desc = 'LOG';   
	|
	|-- Get backup logical names 
	|DECLARE
	|	@ToDatabaseFile_LogicalName nvarchar(50),
	|	@ToDatabaseLog_LogicalName nvarchar(50);  
	|	
	|DECLARE @FileList TABLE
	|	(
	|	LogicalName nvarchar(128) NOT NULL,
	|	PhysicalName nvarchar(260) NOT NULL,
	|	Type char(1) NOT NULL,
	|	FileGroupName nvarchar(120) NULL,
	|	Size numeric(20, 0) NOT NULL,
	|	MaxSize numeric(20, 0) NOT NULL,
	|	FileID bigint NULL,
	|	CreateLSN numeric(25,0) NULL,
	|	DropLSN numeric(25,0) NULL,
	|	UniqueID uniqueidentifier NULL,
	|	ReadOnlyLSN numeric(25,0) NULL ,
	|	ReadWriteLSN numeric(25,0) NULL,
	|	BackupSizeInBytes bigint NULL,
	|	SourceBlockSize int NULL,
	|	FileGroupID int NULL,
	|	LogGroupGUID uniqueidentifier NULL,
	|	DifferentialBaseLSN numeric(25,0)NULL,
	|	DifferentialBaseGUID uniqueidentifier NULL,
	|	IsReadOnly bit NULL,
	|	IsPresent bit NULL,
	|	TDEThumbprint varbinary(32) NULL
	|);
	|
	|INSERT INTO @FileList EXEC('restore filelistonly from disk=''' + @BackupFile+'''')
	|
	|SELECT @ToDatabaseFile_LogicalName = LogicalName FROM @FileList WHERE Type = 'D'
	|SELECT @ToDatabaseLog_LogicalName = LogicalName FROM @FileList WHERE Type = 'L'
	|
	|-- Restore the database
	|EXEC('ALTER DATABASE [' + @ToDatabaseName + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE');
	|EXEC('RESTORE DATABASE [' + @ToDatabaseName + '] FROM DISK = ''' + @BackupFile + ''' WITH FILE = 1,
	|	MOVE ''' + @ToDatabaseFile_LogicalName + ''' TO ''' + @ToDatabaseFile + ''',
	|	MOVE ''' + @ToDatabaseLog_LogicalName + ''' TO ''' + @ToDatabaseLog + ''', NOUNLOAD, REPLACE, STATS = 5');
	|
	|EXEC('ALTER DATABASE [' + @ToDatabaseName + '] SET MULTI_USER');";

	ВыполнитьЗапрос(ТекстЗапроса);

	// Если Не Выборка.BOF Тогда
	
	// 	Выборка.MoveFirst();
	
	// 	Сообщить(Выборка.Fields("Path").Value);
	
	// КонецЕсли;

КонецПроцедуры

ЗаполнитьПараметрыСкрипта(АргументыКоманднойСтроки);

ВосстановитьПоследнийБэкап();