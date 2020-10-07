$Global:ProgressPreference = "SilentlyContinue"
$VirtualEnvironmentPath = Get-Location | Join-Path -ChildPath ".venv"
$VirtualEnvironmentExists = Test-Path -Path $VirtualEnvironmentPath

if ($VirtualEnvironmentExists -eq $False) {
  Write-Host "[*] Download the flat assembler 1.73.25 for Windows"

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
Write-Host "[*] Build $SourceFaviconPath to $BinaryFaviconPath"
FASM $SourceFaviconPath $BinaryFaviconPath

$SourceLambdaDLLPath = Join-Path -Path $SourceCodePath -ChildPath "lambda_dll.asm"
$BinaryLambdaDLLPath = Join-Path -Path $BinaryCodePath -ChildPath "lambda.dll"
Write-Host "[*] Build $SourceLambdaDLLPath to $BinaryLambdaDLLPath"
FASM $SourceLambdaDLLPath $BinaryLambdaDLLPath

$SourceLambdaEXEPath = Join-Path -Path $SourceCodePath -ChildPath "lambda_exe.asm"
$BinaryLambdaEXEPath = Join-Path -Path $BinaryCodePath -ChildPath "lambda.exe"
Write-Host "[*] Build $SourceLambdaEXEPath to $BinaryLambdaEXEPath"
FASM $SourceLambdaEXEPath $BinaryLambdaEXEPath

Write-Host "[*] Done"
$Global:ProgressPreference = "Continue"
