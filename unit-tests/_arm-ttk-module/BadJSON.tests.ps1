
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Push-Location -Path "$here"

describe Import-JSON {
    it 'Will report the name of the file along with any issues' {
        Import-Json -FilePath .\Bad.json -ErrorAction SilentlyContinue -ErrorVariable err
        "$err" | should -BeLike '*Bad.json*'
    }
}

Pop-Location
