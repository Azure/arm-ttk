<#
.Synopsis
    Matches a ARM Function
.Description
    Matches a Azure Resource Manager function and it's arguments 
#>
param(
# One or more function names.  By default, will match any function.
[string[]]
$FunctionName = '\w+'
)

# Lookbehind to find the right context
@'
(?<=       # We don't want to include the preceeding character, so we use a lookbehind (?<=).
    (?>    # It can only be one of the following (?> atomic match):
    \[     # A bracket (the function could be the first thing in the template expression)
    |      # OR
    \(     # An open parenthesis (the function may be contained in another function)
    |      # OR
    ,      # A comma (the function may be contained in another function and not the first argument in that function)
    )      # and the (?>  ) syntax says this is not included in the match because we need to check for expressions explicitly below    
    \s{0,} # We also don't need to include any preceeding whitespace in the match itself
)
'@ + # Match and capture the function name
@"
(?<FunctionName>  # We want to capture the function name
    (?>
        $($FunctionName -join '|')
    )
)
"@ + # Match the function arguments
@'
\s{0,}
(?<Parameters>\( # Match the opening parenthesis
    (?>
        [^\(\)]+        # Match any non-parenthesis
        | \((?<Depth>)  # If an open parenthesis is matched, increment depth
        | \)(?<-Depth>) # If a close paranthesis is match, decrement depth
    )*(?(Depth)(?!))    # continue matching until there is no depth
\)) # match the closing parenthesis
'@