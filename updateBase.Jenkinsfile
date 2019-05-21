def lockmessage
def time_for_user_to_finish_job
def v8version
def repo_Usr
def lock_code

pipeline {
    agent 
    {
        label 'update'
    }
    
    environment {
        cred_base_1c = credentials('25694fd8-f160-44d8-baba-566e521d2dd6')
        cred_repo_dev = credentials('repo-erp-cred')
        racpath = "\"C:\\Program Files (x86)\\1cv8\\${env.v8version}\\bin\\rac.exe\""
     }
       
    stages {
        stage("Обновление базы тестового контура") {
            steps {
                script {
                    lock_code = "\"112233\""
                    lockmessage = "\"Плановое обновление базы\""
                    time_for_user_to_finish_job = 300
                    lockParams = "-lockmessage ${lockmessage} -lockuccode ${lock_code} -lockstartat \"${time_for_user_to_finish_job}\""
                    ConnectionString = "/IBConnectionString\"Srvr=\"${env.Server1C}\";Ref=${env.db_name};\""
                    repo_dev_Usr = "${env.cred_repo_dev_Usr}_${env.db_name}"
                }
                echo "1. Устанавливается блокировка базы. 5 минут пользователям для завершения работы"
                cmd("deployka session lock -rac ${env.racpath} -ras ${env.Server1C}:1545 -db ${env.db_name} -db-user ${env.cred_base_1c_Usr} -db-pwd ${env.cred_base_1c_Psw} -v8version \"${env.v8version}\" ${lockParams}")
                sleep time_for_user_to_finish_job.toInteger()
                
                echo "2. Принудительное завершение работы оставшихся пользователей"
                cmd("deployka session kill -rac ${env.racpath} -ras ${env.Server1C}:1545 -db ${env.db_name} -db-user ${env.cred_base_1c_Usr} -db-pwd ${env.cred_base_1c_Psw} -v8version \"${env.v8version}\" ${lockParams}")
                
                echo "3. Обновление конфигурации из хранилища"
                cmd("deployka loadrepo ${ConnectionString} ${env.repo_dev_dest} -db-user ${env.cred_base_1c_Usr} -db-pwd ${env.cred_base_1c_Psw} -storage-user ${repo_dev_Usr} -storage-pwd ${env.cred_repo_dev_Psw} -uccode ${lock_code} -v8version \"${env.v8version}\"")
                
                echo "4. Обновление базы данных"
                cmd("deployka dbupdate ${ConnectionString} -db-user ${env.cred_base_1c_Usr} -db-pwd ${env.cred_base_1c_Psw} -v8version \"${env.v8version}\" -uccode ${lock_code} -allow-warnings")
                
                echo "5. Выполнение обновление в пользовательском режиме, запрет работы с внешними ресурсами"
                cmd("runner run --ibconnection ${ConnectionString} --db-user ${env.cred_base_1c_Usr} --db-pwd ${env.cred_base_1c_Psw} --uccode ${lock_code} --command \"ЗапуститьОбновлениеИнформационнойБазы;ЗавершитьРаботуСистемы;\" --execute C:\\Jenkins\\ЗакрытьПредприятие.epf --v8version %v8version%")
                
                echo "6. Разблокировка базы"
                cmd("deployka session unlock -rac ${env.racpath} -ras ${env.Server1C}:1545 -db ${env.db_name} -db-user ${env.cred_base_1c_Usr} -db-pwd ${env.cred_base_1c_Psw} -v8version \"${env.v8version}\"")
            }
        }
    } 
}

def cmd(command, status = false) {
    isunix = isUnix();
    if (isunix) {
        sh returnStatus: status, script: "${command}"
    }
    else {
        powershell returnStatus: status, script: "chcp 65001\n${command}"
    }
}