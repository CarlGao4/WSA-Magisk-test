$StartDir = $PWD
Set-Location $PSScriptRoot

foreach ($i in (Get-ChildItem ..\output)) {
    foreach ($j in (Get-ChildItem)) {
        Start-Process -Wait -NoNewWindow (Get-Process -Id $PID).Path ('.\zip2vhdx.ps1 "' + $j + '"')
    }
}

Set-Location $StartDir