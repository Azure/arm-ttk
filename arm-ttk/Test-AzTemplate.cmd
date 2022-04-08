powershell.exe -noprofile -nologo -command "Import-Module '%~dp0arm-ttk.psd1'; Test-AzTemplate %*; if ($Error.Count) { exit 1}"
