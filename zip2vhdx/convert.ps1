$StartDir = $PWD
Set-Location $PSScriptRoot

foreach ($i in (Get-ChildItem ..\output)) {
    foreach ($j in (Get-ChildItem)) {
        .\zip2vhdx.ps1 "$j"
    }
}

Set-Location $StartDir