Import-Module ./ttk/arm-ttk/ -Force -PassThru | Out-Host
Get-ChildItem -Recurse -Filter *.json |
    Where-Object Path -notlike '*ttk*' |
    Test-AzTemplate
