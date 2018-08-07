@echo off
chcp 65001

:: Переменные для управления скриптом
::Имя базы данных
SET db_name=""
::Имя сервера 1с
SET server=""
::Имя базы данных (обычно рабочая) из которой найти последни бэкап и восстановить в указанную базу
SET prod_db_name=""
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

::Установить блокировку базы
echo 1. Устанавливается блокировка базы. 5 минут пользователям для завершения работы
call deployka session lock -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockmessage "%lockmessage%" -lockuccode %lock_code% -lockstartat %time_for_user_to_finish_job%
echo.

echo Таймаут %time_for_user_to_finish_job% секунд для завершения работы пользователям
waitfor SomethingThatIsNeverHappening /t %time_for_user_to_finish_job% 2>NUL
echo.

echo 2. Принудительное завершение работы оставшихся пользователей
call deployka session kill -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd% -lockuccode %lock_code%
echo.

echo 3. Разворачиваем последний бэкап
set command_text=oscript "C:\Program Files (x86)\Jenkins\jobs\Актуализация данных тестовой базы из бэкапа рабочей\UpdateProd.os.exe" %server% %prod_db_name% %db_name%
runas /user:ALFRGIS\ADM_M.Chernyshev /savecred "%command_text%"
echo.

echo Таймаут 5 минут для ожидание разворачивания бэкапа
waitfor SomethingThatIsNeverHappening /t 300 2>NUL
echo.

echo 4. Подключение базы к хранилищу
call vanessa-runner bindrepo %repo_dev_dest% %repo_dev_user% %repo_dev_pwd% --BindAlreadyBindedUser --ibconnection "%ConnectionString%" --db-user %db_user% --db-pwd %db_pwd%
echo.

echo 5. Обновление базы данных
call deployka dbupdate "%ConnectionString%" -db-user %db_user% -db-pwd %db_pwd% -uccode %lock_code%
echo.

echo 6. Выполнение обновление в пользовательском режиме, запрет работы с внешними ресурсами
call deployka run "%ConnectionString%" -db-user %db_user% -db-pwd %db_pwd% -uccode %lock_code% -command "ЗапуститьОбновлениеИнформационнойБазы;ЗавершитьРаботуСистемы;" -execute "C:\Program Files (x86)\Jenkins\jobs\Актуализация данных тестовой базы из бэкапа рабочей\ЗакрытьПредприятие.epf"
echo.

echo 7. Разблокировка базы
call deployka session unlock -rac "C:\Program Files (x86)\1cv8\8.3.10.2615\bin\rac.exe" -ras %server%:1545 -db %db_name% -db-user %db_user% -db-pwd %db_pwd%