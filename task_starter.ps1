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
    Unregister-ScheduledTask -TaskName "ps_executor" -Confirm:$false
    $Time = New-ScheduledTaskTrigger -At 00:00 -Once
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-STA -NonInteractive -ExecutionPolicy bypass -file $basedir\ps_executer.ps1"
    while($true){
        $Error.Clear()
        Register-ScheduledTask -TaskName "ps_executor" -User $env:run_as -Password $env:run_pwd -Trigger $Time -Action $action -RunLevel Highest
        if($Error.Count -eq 0){
            Break
        }else{
            log("Fail to register related scheduledTask within admin credential, retry it after 60s")
            sleep 60
        }
    }    
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