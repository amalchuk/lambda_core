$Global:ProgressPreference = "SilentlyContinue"
Write-Host "[*] Download the flat assembler 1.73.25 for Windows"

$fasm_download_url = "https://flatassembler.net/fasmw17325.zip"
$fasm_destination_path = Join-Path -Path $PSScriptRoot -ChildPath "fasm.zip"
Invoke-WebRequest -Uri $fasm_download_url -OutFile $fasm_destination_path

$virtual_environment_path = Join-Path -Path $PSScriptRoot -ChildPath ".venv"
$virtual_environment_path | Remove-Item -Recurse -Force

$fasm_destination_path | Expand-Archive -DestinationPath $virtual_environment_path -Force
$fasm_destination_path | Remove-Item -Force

Write-Host "[*] Done"
$Global:ProgressPreference = "Continue"
