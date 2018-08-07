@echo off
chcp 65001

:: Переменные для управления скриптом
::Имя базы данных
SET db_name="" 
::Имя сервера 1с
SET server=""
::Имя пользователя 1с
SET db_user=""
::Пароль пользователя 1с
SET db_pwd=""

::Сообщения, устанавливаемое в консоли кластера 1с при блокировке сеансов
SET "lockmessage=Плановое обновление базы"
 ::Время через которое пользователей выкенет принудительно (в сек). Время блокировки в кластере 1с.Ставлю 5 мин 
SET time_for_user_to_finish_job=300
::Код разрешения, устанавливаемый в консоли кластера 1с
SET lock_code=123455

::Путь к хранилищу конфигурации
SET "repo_dev_dest="
::Пользователь хранилища
SET repo_dev_user=""
::Пароль пользователя хранилища
SET repo_dev_pwd=""

::Строка подключения к базе
SET "ConnectionString=/IBConnectionString""Srvr=%server%;Ref=%db_name%;"""

echo 1. Устанавливается блокировка базы. 5 минут пользователям для завершения работы
::deployka session lock -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockmessage "%lockmessage%" -lockstartat %time_for_user_to_finish_job% -lockuccode %lock_code%
call deployka session lock -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockmessage "%lockmessage%" -lockuccode %lock_code% -lockstartat 600
echo.

echo Таймаут %time_for_user_to_finish_job% секунд для завершения работы пользователям
waitfor SomethingThatIsNeverHappening /t %time_for_user_to_finish_job% 2>NUL
echo.

echo 2. Принудительное завершение работы оставшихся пользователей
call deployka session kill -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockuccode %lock_code%
echo.

echo 3. Обновление конфигурации из хранилища
call deployka loadrepo "%ConnectionString%" "%repo_dev_dest%" -db-user %db_user% -db-pwd %db_pwd% -storage-user %repo_dev_user% -storage-pwd %repo_dev_pwd% -uccode %lock_code%
echo.

echo 4. Обновление базы данных
call deployka dbupdate "%ConnectionString%" -db-user %db_user% -db-pwd %db_pwd% -uccode %lock_code%
echo.

echo 5. Разблокировка базы
call deployka session unlock -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd%
