powershell.exe -noprofile -nologo -command "Import-Module '%~dp0arm-ttk.psd1'; Test-AzTemplate %*; if ($Errors.Count) { exit 1}"
