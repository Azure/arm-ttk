function Resolve-JSONContent
{
    <#
    .Synopsis
        Resolves JSONPaths to a location within a string.
    .Description
        Resolves the location of content within a JSON file
    .Link
        Find-JSONContent
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
(?:         # Match but don't store:
[\{\,]      # A bracket or comma
\s{0,}      # Optional Whitespace
"           # the opening quote
)            
(?<Name>    # Capture the Name, which is:
.+?         # Anything until...
(?=(?<!\\)")# a closing quote (as long as it's not preceeded by a \) 
)
(?:         # Match but don't store:
"\s{0,}     # a double-quote, optional whitespace:
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
         

        :nextPathPart foreach ($part in $jsonPathParts.Matches($JSONPath)) {
            $propMatch = $null
            $listMatch = $null
            if ($part.Groups['Property'].Success) {
                foreach ($propMatch in $jsonProperty.Matches($JSONText, $cursor)) {
                    if ($propMatch.Groups['Name'].Value -eq $part.Groups['Property'].Value) {
                        $cursor = $propMatch.Groups['Name'].Index + $propMatch.Groups['Name'].Length
                        continue nextPathPart
                    }
                }
                
            } elseif ($part.Groups['Index'].Success) {
                $targetIndex = $part.Groups['Index'].Value
                $listMatch = $jsonList.Match($JSONText, $cursor)
                $values = $listMatch.Groups["JSON_Value"].Captures
                for ($i = 0; $i -lt $values.Count; $i++)  {
                    if ($i -eq $targetIndex) {
                        $cursor = $values[$i].Index 
                        continue nextPathPart
                    }
                }
                
            }
        }

        if (-not $cursor) { return }
        
        if ($propMatch) { # If our last part of the path was a property
            [PSCustomObject]@{
                JSONPath = $JSONPath
                Index    = $propMatch.Groups["Name"].Index - 1 # Subtract one for initial quote
                Length   = ($propMatch.Groups["JSON_Value"].Index + $propMatch.Groups["JSON_Value"].Length)  - 
                    $propMatch.Groups["Name"].Index + 1  # Add one for initial quote
            }
        } else {
            [PSCustomObject]@{
                JSONPath = $JSONPath
                Index    = $propMatch.Groups["ListItem"].Index
                Length   = $propMatch.Groups["ListItem"].Length
            }
            
        }

        
    }
}
