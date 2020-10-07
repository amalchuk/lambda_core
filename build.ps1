# Copyright 2020 Andrew Malchuk. All rights reserved.
# This project is licensed under the terms of the MIT License.

$Global:ProgressPreference = "SilentlyContinue"
$VirtualEnvironmentPath = Get-Location | Join-Path -ChildPath ".venv"
$VirtualEnvironmentExists = Test-Path -Path $VirtualEnvironmentPath

if ($VirtualEnvironmentExists -eq $False) {
  Write-Host "Download the flat assembler" -ForegroundColor DarkBlue

  $FASMDownloadUrl = "https://flatassembler.net/fasmw17325.zip"
  $FASMDestinationPath = Get-Location | Join-Path -ChildPath "flat_assembler.zip"
  Invoke-WebRequest -Uri $FASMDownloadUrl -OutFile $FASMDestinationPath

  $FASMDestinationPath | Expand-Archive -DestinationPath $VirtualEnvironmentPath -Force
  $FASMDestinationPath | Remove-Item -Force

  $VirtualEnvironmentProperties = Get-ItemProperty -Path $VirtualEnvironmentPath
  $VirtualEnvironmentProperties.Attributes += "Hidden"
}

$FASMCompilerPath = Join-Path -Path $VirtualEnvironmentPath -ChildPath "FASM.EXE"
New-Alias -Name FASM -Value $FASMCompilerPath
$Env:INCLUDE = Join-Path -Path $VirtualEnvironmentPath -ChildPath "INCLUDE"

$SourceCodePath = Get-Location | Join-Path -ChildPath "src"
$BinaryCodePath = Get-Location | Join-Path -ChildPath "bin"
$BinaryPathExists = Test-Path -Path $BinaryCodePath

if ($BinaryPathExists -eq $False) {
  New-Item -Path $BinaryCodePath -ItemType Directory -Force | Out-Null
}

$SourceFaviconPath = Join-Path -Path $SourceCodePath -ChildPath "favicon" | Join-Path -ChildPath "favicon.asm"
$BinaryFaviconPath = Join-Path -Path $SourceCodePath -ChildPath "favicon.ico"
Write-Host "Build $SourceFaviconPath to $BinaryFaviconPath" -ForegroundColor DarkBlue
FASM $SourceFaviconPath $BinaryFaviconPath | Out-Null

if (!$?) {
  Write-Error -Message "Failed to build the $SourceFaviconPath" -Category ParserError -ErrorAction Stop
}

$SourceLambdaDLLPath = Join-Path -Path $SourceCodePath -ChildPath "lambda_dll.asm"
$BinaryLambdaDLLPath = Join-Path -Path $BinaryCodePath -ChildPath "lambda.dll"
Write-Host "Build $SourceLambdaDLLPath to $BinaryLambdaDLLPath" -ForegroundColor DarkBlue
FASM $SourceLambdaDLLPath $BinaryLambdaDLLPath | Out-Null

if (!$?) {
  Write-Error -Message "Failed to build the $SourceLambdaDLLPath" -Category ParserError -ErrorAction Stop
}

$SourceLambdaEXEPath = Join-Path -Path $SourceCodePath -ChildPath "lambda_exe.asm"
$BinaryLambdaEXEPath = Join-Path -Path $BinaryCodePath -ChildPath "lambda.exe"
Write-Host "Build $SourceLambdaEXEPath to $BinaryLambdaEXEPath" -ForegroundColor DarkBlue
FASM $SourceLambdaEXEPath $BinaryLambdaEXEPath | Out-Null

if (!$?) {
  Write-Error -Message "Failed to build the $SourceLambdaEXEPath" -Category ParserError -ErrorAction Stop
}

Write-Host "Done" -ForegroundColor DarkGreen
$Global:ProgressPreference = "Continue"
