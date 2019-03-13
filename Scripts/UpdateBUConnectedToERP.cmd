@echo off
chcp 65001

SET db_name=%Base%
SET server=ru-s-mosc-da03

SET "lockmessage=Плановое обновление базы"
 ::Время через которое пользователей выкенет принудительно (в сек). Время блокировки в кластере 1с.Ставлю 5 мин 
SET time_for_user_to_finish_job=300
SET lock_code=123455
SET v8version=8.3.13.1513
SET "racpath="C:\Program Files (x86)\1cv8\%v8version%\bin\rac.exe""

SET "repo_dev_dest=\\ru-s-mosc-da03\_ConfStorage\BUH3"
SET db_user=Администратор

SET db_name=buh3_alo_test_erp2
SET db_pwd=sapphire730
SET repo_dev_user=Администратор_%db_name%
SET repo_dev_pwd=%db_pwd%
SET "ConnectionString=/IBConnectionString""Srvr=%server%;Ref=%db_name%;"""

echo %db_name%

echo 1. Устанавливается блокировка базы
call deployka session lock -rac %racpath% -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockmessage "%lockmessage%" -lockuccode %lock_code% -v8version %v8version%
echo 2. Принудительное завершение работы оставшихся пользователей
call deployka session kill -rac %racpath% -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockuccode %lock_code% -v8version %v8version%
echo 3. Обновление конфигурации из хранилища
call deployka loadrepo "%ConnectionString%" "%repo_dev_dest%" -db-user %db_user% -db-pwd %db_pwd% -storage-user %repo_dev_user% -storage-pwd %repo_dev_pwd% -uccode %lock_code% -v8version %v8version%
echo 4. Обновление базы данных
call deployka dbupdate "%ConnectionString%" -db-user %db_user% -db-pwd %db_pwd% -uccode %lock_code% -v8version %v8version%
echo 5. Разблокировка базы
call deployka session unlock -rac %racpath% -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -v8version %v8version%
echo -----------------------