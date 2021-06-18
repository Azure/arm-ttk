<#
.Synopsis
    Tests the -JSONContent commands in arm-ttk
.Description
    Tests Find-JSONContent and Resolve-JSONContent
#>

describe Find-JSONContent {
    it 'Is used to find content in JSON by a key' {
        $jsonText = '{
            a: {
                b: {
                    c: [0,1,2]
                }
            }
        }'

        $jsonObject = $jsonText | ConvertFrom-Json
        $foundIt = Find-JsonContent -InputObject $jsonObject -Key c
        $foundIt.JSONPath | Should -Be a.b.c
    }

    it 'Will return the index within a list' {
        $jsonText = '{
            a: {
                b: {
                    c: [{d:1},{e:2}]
                }
            }
        }'
        $jsonObject = $jsonText | ConvertFrom-Json
        $foundIt = Find-JsonContent -InputObject $jsonObject -Key d
        $foundIt.JSONPath | Should -Be 'a.b.c[0].d'
    }

    it 'Will return the index within a list when provided a -Value' {
        $jsonText = '{
            a: {
                b: {
                    c: [{d:1},{e:2}]
                }
            }
        }'
        $jsonObject = $jsonText | ConvertFrom-Json
        $foundIt = Find-JsonContent -InputObject $jsonObject -Key e
        $foundIt.JSONPath | Should -Be 'a.b.c[1].e'
    }

    it 'Will return multiple results when mutliple keys match' {
        $jsonText = '{
            a: {
                b: {
                    c: [0,1,2],
                    c2: 3
                }
            }
        }'

        $jsonObject = $jsonText | ConvertFrom-Json
        $foundIt = Find-JsonContent -InputObject $jsonObject -Key c* -Like
        $foundIt.Count | Should -Be 2
        $foundIt | Select-Object -ExpandProperty JSONPath | Should -Match 'a\.b\.c(\d)?'
    }    
}

describe Resolve-JSONContent {
    it 'Can return the line/column of a JSON match' {
        $resolved = Resolve-JSONContent -JSONPath 'a.b' -JSONText '{
            "a": {
                "b": {
                    "c": [0,1,2]
                }
            }
        }'
        $resolved.Line | Should -Be 3
    }

    it 'Can return the line/column of a JSON match of a list index' {
        $resolved = Resolve-JSONContent -JSONPath 'a.b.c[1]' -JSONText @'
{
    "a": {
        'b': {
            c: [0,1,2]
        }
    }
}
'@
        $resolved.Line | Should -Be 4
        $resolved.Content | Should -Be "1"
    }
}
