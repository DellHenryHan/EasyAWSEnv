function log($item){
    $time=Get-Date -format "yyyy-MM-dd HH:mm:ss"
    "$time $item"|out-file C:\setup\setup.log -Append
}
if($PSScriptRoot){
    $basedir=$PSScriptRoot
}
else{
    $basedir=split-path -parent $MyInvocation.MyCommand.Definition
}
if(-not (Test-Path C:\setup)){
    New-Item C:\setup -ItemType Directory -Force
}
if($env:run_as){
    log ("+"*10+"Process scripts at startup. Current user: $env:run_as"+"+"*10)
    schtasks /delete /tn ps_executor /f
    schtasks /create /tn ps_executor /ru $env:run_as /rp $env:run_pwd /tr ("PowerShell -STA -NonInteractive -ExecutionPolicy bypass -file $basedir\ps_executer.ps1") /RL HIGHEST /sc once /st 00:00
}
else{
    log ("+"*10+"Process scripts at startup. Current user: System"+"+"*10)
    if(-not (schtasks /query /tn ps_executor)){
        schtasks /create /tn ps_executor /ru System /tr ("PowerShell -STA -NonInteractive -ExecutionPolicy bypass -file $basedir\ps_executer.ps1") /RL HIGHEST /sc once /st 00:00
    }
    else{
        schtasks /change /tn ps_executor /ru System
    }
}
schtasks /run /tn ps_executor