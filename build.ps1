$virtual_environment_path = Get-Location | Join-Path -ChildPath ".venv"

$fasm_memory_limit = 65536 # 64 megabytes memory

$fasm_compiler_path = Join-Path -Path $virtual_environment_path -ChildPath "FASM.EXE"
New-Alias -Name FASM -Value $fasm_compiler_path
$Env:INCLUDE = Join-Path -Path $virtual_environment_path -ChildPath "INCLUDE"

$src_favicon_path = Get-Location | Join-Path -ChildPath "src" | Join-Path -ChildPath "favicon" | Join-Path -ChildPath "favicon.asm"
$bin_favicon_path = Get-Location | Join-Path -ChildPath "src" | Join-Path -ChildPath "favicon.ico"
Write-Host "[*] Build $src_favicon_path to $bin_favicon_path"
FASM -m $fasm_memory_limit $src_favicon_path $bin_favicon_path

New-Item -Path "bin" -ItemType Directory -Force | Out-Null

$src_lambda_dll_path = Get-Location | Join-Path -ChildPath "src" | Join-Path -ChildPath "lambda_dll.asm"
$bin_lambda_dll_path = Get-Location | Join-Path -ChildPath "bin" | Join-Path -ChildPath "lambda.dll"
Write-Host "[*] Build $src_lambda_dll_path to $bin_lambda_dll_path"
FASM -m $fasm_memory_limit $src_lambda_dll_path $bin_lambda_dll_path

$src_lambda_exe_path = Get-Location | Join-Path -ChildPath "src" | Join-Path -ChildPath "lambda_exe.asm"
$bin_lambda_exe_path = Get-Location | Join-Path -ChildPath "bin" | Join-Path -ChildPath "lambda.exe"
Write-Host "[*] Build $src_lambda_exe_path to $bin_lambda_exe_path"
FASM -m $fasm_memory_limit $src_lambda_exe_path $bin_lambda_exe_path
