@echo off
rem %1 - полный номер версии 1С:Предприятия
rem %2 - пользователь службы

set SrvUserName=%1
set SrvUserPwd=""
set CtrlPort=1540
set AgentName=ru-s-mosc-da03
set RASPort=1545
set SrvcName="1C:Enterprise 8.3 Remote Server"
set BinPath="\"D:\Program Files\1cv8\8.3.10.2615\bin\ras.exe\" cluster --service --port=%RASPort% %AgentName%:%CtrlPort%"
set Desctiption="1C: Сервер администрирования 1С:Предприятия 8.3"
sc stop %SrvcName%
sc delete %SrvcName%
sc create %SrvcName% binPath= %BinPath% start= auto obj= %SrvUserName% password= %SrvUserPwd% displayname= %Desctiption%