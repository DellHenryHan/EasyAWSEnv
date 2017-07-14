Get-NetIPInterface|%{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses}
schtasks /end /tn 'ps_executor'
schtasks /delete /tn 'ps_executor' /f
schtasks /end /tn 'setup'
schtasks /delete /tn 'setup' /f
remove-item c:\setup -Recurse -Force
new-item -ItemType Directory c:\setup
if(-not (Get-ChildItem 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall'|?{$_.GetValue('DisplayName') -like 'Git*'})){
Invoke-WebRequest 'https://github.com/git-for-windows/git/releases/download/v2.13.0.windows.1/Git-2.13.0-64-bit.exe' -OutFile c:\setup\git.exe
Start-Process c:\setup\git.exe '/silent' -PassThru | Wait-Process
}
$env:path +=';C:\Program Files\Git\bin'
cd c:\setup
bash -c 'git clone https://github.com/DellHenryHan/EasyAWSEnv.git easyawsenv'
schtasks /create /tn 'setup' /xml c:\setup\easyawsenv\task_execution.xml /f
Get-ChildItem Env:\step*|%{[Environment]::SetEnvironmentVariable($_.Name,'','Machine')}
[Environment]::SetEnvironmentVariable('run_as','','Machine')
Restart-Computer -Force