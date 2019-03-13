:: Переменные для управления скриптом
:: Путь к 1с
SET "Path1c=C:\Program Files (x86)\1cv8\8.3.13.1513\bin\1cv8.exe"
::Имя базы данных
SET "db_name=buh3_alo_test_ult"
::Имя сервера 1с
SET "server=ru-s-mosc-da03"
::Файл для записи результатов тестирования
SET "OutFie=C:\Users\mikhail.chernyshev\Documents\1C\Tasks\Потеря данных\Тестирование целостности.txt"

"%Path1c%" DESIGNER /IBConnectionString "Srvr=""%server%"";Ref=""%db_name%"";" /WA+ /IBCheckAndRepair -LogAndRefsIntegrity -TestOnly /Out "%OutFie%" -NoTruncate