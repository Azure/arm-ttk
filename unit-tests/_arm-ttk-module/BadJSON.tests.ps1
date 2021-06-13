
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Push-Location -Path "$here"

describe Import-JSON {
    it 'Will report the name of the file along with any issues' {
        Import-Json -FilePath .\bad.json -ErrorAction SilentlyContinue -ErrorVariable err        
        "$err" | should -BeLike '*bad.json*'
    }
}

Pop-Location
