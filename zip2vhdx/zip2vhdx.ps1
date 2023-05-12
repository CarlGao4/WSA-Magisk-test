[CmdletBinding()]
param (
    [String]$zip
)

if ($zip.Length -eq 0) {
    Write-Error "Argument zip must be specified"
    exit 1
}

$ErrorActionPreference = "Stop"
$StartDir = $PWD
$zipfile = (Get-ChildItem $zip)[0]

Set-Location $PSScriptRoot

Copy-Item -Path .\Blank-VHD.vhdx -Destination ("..\" + $zipfile.BaseName + ".vhdx") || exit 1
$vhdx = (Get-ChildItem ("..\" + $zipfile.BaseName + ".vhdx"))[0]

'select vdisk file="' + $vhdx.FullName + '"' > diskpart.txt
'attach vdisk noerr' >> diskpart.txt
'select partition 2' >> diskpart.txt
'remove all noerr' >> diskpart.txt
'assign letter=W' >> diskpart.txt

$p = Start-Process -NoNewWindow -Wait "diskpart.exe" "/s diskpart.txt"
if ($p.ExitCode -ne 0) {
    exit 1
}

$p = Start-Process -NoNewWindow -Wait "7z.exe" ("x " + $zipfile.FullName + " ..\" + $zipfile.BaseName)
if ($p.ExitCode -ne 0) {
    exit 1
}

if ((Test-Path -Path ("..\" + $zipfile.BaseName + "\MakePri.ps1")) -eq $true) {
    Start-Process -NoNewWindow -Wait (Get-Process -Id $PID).Path "-ExecutionPolicy Bypass -File MakePri.ps1" -WorkingDirectory ($PSScriptRoot + "\..")
}

Move-Item ("..\" + $zipfile.BaseName) -Destination "W:\"

'select vdisk file="' + $vhdx.FullName + '"' > diskpart.txt
'select partition 2' >> diskpart.txt
'attributes volume set readonly' >> diskpart.txt
'detach vdisk noerr' >> diskpart.txt
Start-Process -NoNewWindow -Wait "diskpart.exe" "/s diskpart.txt"

("artifact_name=" + $vhdx.Name) >> $env:GITHUB_OUTPUT
("artifact_path=" + $vhdx.FullName) >> $env:GITHUB_OUTPUT

try {
    Remove-Item -Force -Recurse diskpart.txt
}
catch {}
try {
    Remove-Item -Force -Recurse ("..\" + $zipfile.BaseName)
}
catch {}
Set-Location $StartDir