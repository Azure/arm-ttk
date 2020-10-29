param(
[string]
$Parameter = '.+?'
)

@"
parameters                              # the parameters keyword
\s{0,}                                  # optional whitespace
\(                                      # opening parenthesis
\s{0,}                                  # more optional whitespace
'                                       # a single quote, followed by the parameter name
(?<ParameterName>
$($Parameter -replace '\s','\s')    
)
'                                       # a single quote
\s{0,}                                  # more optional whitespace
\)                                      # closing parenthesis
"@

