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

Write-Host "Copying VHDX"
Copy-Item -Path .\Blank-VHD.vhdx -Destination ("..\" + $zipfile.BaseName + ".vhdx") || exit 1
$vhdx = (Get-ChildItem ("..\" + $zipfile.BaseName + ".vhdx"))[0]

try {
    Remove-Item -Force -Recurse ..\mount
}
catch {}
New-Item -ItemType Directory -Path ".." -Name mount

Write-Host "Mounting VHDX"
'select vdisk file="' + $vhdx.FullName + '"' > diskpart.txt
'attach vdisk noerr' >> diskpart.txt
'select partition 2' >> diskpart.txt
'remove all noerr' >> diskpart.txt
'assign mount="' + (Get-ChildItem "..\mount")[0].FullName + '"' >> diskpart.txt

$p = Start-Process -NoNewWindow -Wait "diskpart.exe" "/s diskpart.txt"
if ($p.ExitCode -ne 0) {
    exit 1
}

Write-Host "Extracting file"
$p = Start-Process -NoNewWindow -Wait "7z.exe" ('x "' + $zipfile.FullName + '" ..\extract')
if ($p.ExitCode -ne 0) {
    exit 1
}

if (((Test-Path -Path ("..\extract\MakePri.ps1")) -eq $true) -and ((Test-Path -Path ("..\" + $zipfile.BaseName + "\MakePri.exe")) -eq $true)) {
    Write-Host "Running MakePri.ps1"
    Start-Process -NoNewWindow -Wait (Get-Process -Id $PID).Path "-ExecutionPolicy Bypass -File MakePri.ps1" -WorkingDirectory ($PSScriptRoot + "\..")
}

Write-Host "Moving files into VHDX"
New-Item -ItemType Directory -Path ..\mount -Name $zipfile.BaseName
Move-Item ..\extract\* -Destination ("..\mount\" + $zipfile.BaseName)

Write-Host "Unmounting VHDX"
'select vdisk file="' + $vhdx.FullName + '"' > diskpart.txt
'select partition 2' >> diskpart.txt
'attributes volume set readonly noerr' >> diskpart.txt
'detach vdisk noerr' >> diskpart.txt
Start-Process -NoNewWindow -Wait "diskpart.exe" "/s diskpart.txt"

("artifact_name=" + $vhdx.Name) >> $env:GITHUB_OUTPUT
("artifact_path=" + $vhdx.FullName) >> $env:GITHUB_OUTPUT
Write-Host ("Compressed size: " + $vhdx.Length)

try {
    Remove-Item -Force diskpart.txt
}
catch {}
try {
    Remove-Item -Force -Recurse ("..\extract")
}
catch {}
Set-Location $StartDir