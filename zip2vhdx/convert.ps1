$StartDir = $PWD
Set-Location $PSScriptRoot

foreach ($i in (Get-ChildItem ..\output)) {
    foreach ($j in (Get-ChildItem $i)) {
        Start-Process -Wait -NoNewWindow (Get-Process -Id $PID).Path ('.\zip2vhdx.ps1 "' + $j.FullName + '"')
    }
}

Set-Location $StartDir