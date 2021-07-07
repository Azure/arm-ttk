function Resolve-JSONContent
{
    <#
    .Synopsis
        Resolves JSONPaths to a location within a string.
    .Description
        Resolves the location of content within a JSON file
    .Link
        Find-JSONContent
    .Example
        Resolve-JSONContent -JSONPath 'a.b' -JSONText '{
            "a": {
                "b": {
                    "c": [0,1,2]
                }
            }
        }'
    .Example
        Resolve-JSONContent -JSONPath 'a.b.c[1]' -JSONText '{
            a: {
                b: {
                    c: [0,1,2]
                }
            }
        }'
    #>
    param(
    # The Path to an instance within JSON
    [Parameter(ValueFromPipelineByPropertyName)]
    [string]
    $JSONPath,

    # The JSON text.
    [string]
    $JSONText
    )
    begin {
        $jsonProperty = [Regex]::new(@'
(?<=             # After 
[\{\,]           # a bracket or comma
)
\s{0,}           # Match optional Whitespace
(?<Quoted>["'])? # the opening quote            
(?<Name>         # Capture the Name, which is:
.+?              # Anything until...
)
(?=
    (?(Quoted)((?<!\\)\k<Quoted>)|([\s:]))
)
(?:         # Match but don't store:
    (?(Quoted)(\k<Quoted>))
\s{0,}     # a double-quote, optional whitespace:
)
:
(?<JSON_Value>
\s{0,}                            # Match preceeding whitespace
(?>                               # A JSON value can be:
    (?<IsTrue>true)               # 'true'
    |                             # OR
    (?<IsFalse>false)             # 'false'
    |                             # OR
    (?<IsNull>null)               # 'null'
    |                             # OR
    (?<Object>                    # an object, which is
        \{                        # An open brace
(?>                               # Followed by...
    [^\{\}]+|                     # any number of non-brace character OR
    \{(?<Depth>)|                 # an open brace (in which case increment depth) OR
    \}(?<-Depth>)                 # a closed brace (in which case decrement depth)
)*(?(Depth)(?!))                  # until depth is 0.
\}                                # followed by a closing brace
    )
    |                             # OR
    (?<List>                      # a list, which is
        \[                        # An open bracket
(?>                               # Followed by...
    [^\[\]]+|                     # any number of non-bracket character OR
    \[(?<Depth>)|                 # an open bracket (in which case increment depth) OR
    \](?<-Depth>)                 # a closed bracket (in which case decrement depth)
)*(?(Depth)(?!))                  # until depth is 0.
\]                                # followed by a closing bracket
    )
    |                             # OR
    (?<String>                    # A string, which is
        "                         # an open quote  
        .*?                       # followed by anything   
        (?=(?<!\\)"               # until the closing quote
    )
    |                             # OR
    (?<Number>                    # A number, which
        (?<Decimals>
(?<IsNegative>\-)?                # It might be start with a -
(?:(?>                            # Then it can be either: 
    (?<Characteristic>\d+)        # One or more digits (the Characteristic)
    (?:\.(?<Mantissa>\d+)){0,1}   # followed by a period and one or more digits (the Mantissa)
    |                             # Or it can be
    (?:\.(?<Mantissa>\d+))        # just a Mantissa      
))
(?:                               # Optionally, there can also be an exponent
    E                             # which is the letter 'e'  
    (?<Exponent>[+-]\d+)          # followed by + or -, followed by digits.
)?
)
    ) 
    )
)
\s{0,}                            # Optionally match following whitespace
)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')

        
        $jsonList = [Regex]::new(@'
(?>
    \[\s{1,}\]                  # An open bracket
    |
    \[
        (?:
(?<JSON_Value>
\s{0,}                            # Match preceeding whitespace
(?>                               # A JSON value can be:
    (?<IsTrue>true)               # 'true'
    |                             # OR
    (?<IsFalse>false)             # 'false'
    |                             # OR
    (?<IsNull>null)               # 'null'
    |                             # OR
    (?<Object>                    # an object, which is
        \{                        # An open brace
(?>                               # Followed by...
    [^\{\}]+|                     # any number of non-brace character OR
    \{(?<Depth>)|                 # an open brace (in which case increment depth) OR
    \}(?<-Depth>)                 # a closed brace (in which case decrement depth)
)*(?(Depth)(?!))                  # until depth is 0.
\}                                # followed by a closing brace
    )
    |                             # OR
    (?<List>                      # a list, which is
        \[                        # An open bracket
(?>                               # Followed by...
    [^\[\]]+|                     # any number of non-bracket character OR
    \[(?<Depth>)|                 # an open bracket (in which case increment depth) OR
    \](?<-Depth>)                 # a closed bracket (in which case decrement depth)
)*(?(Depth)(?!))                  # until depth is 0.
\]                                # followed by a closing bracket
    )
    |                             # OR
    (?<String>                    # A string, which is
        "                         # an open quote  
        .*?                       # followed by anything   
        (?=(?<!\\)"               # until the closing quote
    )
    |                             # OR
    (?<Number>                    # A number, which
        (?<Decimals>
(?<IsNegative>\-)?                # It might be start with a -
(?:(?>                            # Then it can be either: 
    (?<Characteristic>\d+)        # One or more digits (the Characteristic)
    (?:\.(?<Mantissa>\d+)){0,1}   # followed by a period and one or more digits (the Mantissa)
    |                             # Or it can be
    (?:\.(?<Mantissa>\d+))        # just a Mantissa      
))
(?:                               # Optionally, there can also be an exponent
    E                             # which is the letter 'e'  
    (?<Exponent>[+-]\d+)          # followed by + or -, followed by digits.
)?
)
    ) 
    )
)
\s{0,}                            # Optionally match following whitespace
)
            (?:,)?
        ){1,}
    \]
)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')

        $jsonPathParts = [Regex]::new(@'
(?>
(^|\.)(?<Property>\w+)
|
\[(?<Index>\d+)\]
)
'@, 'IgnoreCase,IgnorePatternWhitespace', '00:00:05')
    }

    process {
        $cursor  = 0
        $counter = 0
        $indexMatch = $null         
         
        $gotThisFar = @()
        :nextPathPart foreach ($part in $jsonPathParts.Matches($JSONPath)) {
            $propMatch = $null
            $listMatch = $null
            if ($part.Groups['Property'].Success) {
                foreach ($propMatch in $jsonProperty.Matches($JSONText, $cursor)) {
                    if ($propMatch.Groups['Name'].Value -eq $part.Groups['Property'].Value) {
                        $cursor = $propMatch.Groups['Name'].Index + $propMatch.Groups['Name'].Length
                        $gotThisFar += $part
                        continue nextPathPart
                    }
                }
                if ($VerbosePreference -ne 'silentlyContinue') {
                    Write-Verbose "Unable to find $($gotThisFar -join '')$($part) around index $($cursor)"
                }
                $cursor = $null
            } elseif ($part.Groups['Index'].Success) {
                $targetIndex = $part.Groups['Index'].Value
                $listMatch = $jsonList.Match($JSONText, $cursor)
                $values = $listMatch.Groups["JSON_Value"].Captures
                if ($targetIndex -gt $values.Count) {
                    if ($VerbosePreference -ne 'silentlyContinue') {
                        Write-Verbose "$($gotThisFar -join '')$($part) is out of bounds.  Array has $($values.Count) items."
                    }
                    $cursor = $null
                    $gotThisFar += $part
                    continue nextPathPart
                }
                for ($i = 0; $i -lt $values.Count; $i++)  {
                    if ($i -eq $targetIndex) {
                        $indexMatch = $values[$i]
                        $cursor = $values[$i].Index 
                        continue nextPathPart
                    }
                }                
            }

            if (-not $cursor) {
                if ($VerbosePreference -ne 'silentlyContinue') {
                    Write-Verbose "Could not resolve $($gotThisFar -join '')$($part)"
                }
                break
            }
        }

        if (-not $cursor) { return }
        
        if ($propMatch) { # If our last part of the path was a property        
            $propMatchIndex  = $propMatch.Groups["Name"].Index - 1 # Subtract one for initial quote
            $propMatchLength = ($propMatch.Groups["JSON_Value"].Index + $propMatch.Groups["JSON_Value"].Length) - 
                                $propMatch.Groups["Name"].Index + 1  # Add one for initial quote
            [PSCustomObject][Ordered]@{
                JSONPath = $JSONPath
                JSONText = $JSONText
                Index    = $propMatchIndex
                Length   = $propMatchLength
                Line     = [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Matches(
                                $JSONText, $propMatchIndex
                           ).Count
                Content  = $JSONText.Substring($propMatchIndex, $propMatchLength)
                Column   = $propMatch.Groups["Name"].Index - 1 + $(
                                $m = [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Match(
                                    $JSONText, $propMatch.Groups["Name"].Index - 1)
                                $m.Index + $m.Length
                            ) + 1
                PSTypeName = 'JSON.Content.Location'
            }
        } elseif ($listMatch) {
            
            [PSCustomObject][Ordered]@{
                PSTypeName = 'JSON.Content.Location'
                JSONPath = $JSONPath
                JSONText = $JSONText
                Index    = $indexMatch.Index
                Length   = $indexMatch.Length
                Content  = $JSONText.Substring($indexMatch.Index, $indexMatch.Length)
                Line     = [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Matches(
                                $JSONText, $indexMatch.Index
                           ).Count
                Column   = $listMatch.Groups["ListItem"].Index + $(
                                $m = [Regex]::new('(?>\r\n|\n|\A)', 'RightToLeft').Match(
                                    $JSONText, $indexMatch.Index)
                                $m.Index + $m.Length
                            ) + 1
            }
            
        }

        
    }
}
