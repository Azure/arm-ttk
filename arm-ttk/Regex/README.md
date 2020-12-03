Regular Expressions
===================

This directory contains Regular Expressions definitions that are used throughout arm-ttk.  

These Regular Expressions can be used anywhere within arm-ttk.
They are defined beneath the module root of arm-ttk in the [/Regex](.) folder.

Regular Expressions definitions can be written in two formats:

```
*.regex.txt pattern files
*.regex.ps1 pattern generators
```

These regular expressions can be used within arm-ttk by calling a PowerShell ScriptBlock that derived from the name of the directory/file.

For example, the expression ARM_Template_Expression is defined in [/Regex/ARM/Template_Expression.regex.txt](./ARM/Template_Expression.regex.txt)

### Using Patterns


.regex.txt files will contain a single Regular Expression.

This expression can be used anywhere within arm-ttk.

For instance, using the pattern ARM_Template_Expression, we can find all matches for the expression within $templatetext:

~~~PowerShell
$templateText | ?<ARM_Template_Expression>
~~~

ARM_Template_Expression is defined in [/Regex/ARM/Template_Expression.regex.txt](./ARM/Template_Expression.regex.txt)

### Writing Patterns

Pattern files are regular expressions defined in a .regex.txt file beneath [/Regex](.).


All patterns will be created with the options IgnoreCase and IgnorePatternWhitespace.  
This allows you to put comments in your RegEx 

For instance, a simple commented RegEx to look for the newGuid() function would be:

```
newGuid # Match guid
\s?     # optional whitespace
\(      # Match open parenthesis
\s?     # optional whitespace
\)      # Match closing parenthesis
```


### Using Generators

.regex.ps1 files will contain Regular Expression generators.

These are PowerShell scripts that produce a regular expression based off of input.

For instance, we can find all of the references to the VMSize parameter.

~~~PowerShell
$templateText | ?<ARM_Parameter> -Parameter 'VMSize'
~~~

Generators need not require parameters.  To find all parameters referenced throughout the template, use:

~~~PowerShell
$templateText | ?<ARM_Parameter>
~~~

ARM_Parameter is defined in [/Regex/ARM/Parameter.regex.ps1](./ARM/Parameter.regex.ps1)


### Writing Generators

Generators are defined in a .regex.ps1 file beneath [/Regex](.)

Generators dynamically produce a regular expression based off of input.

For example, the source for ARM_Parameter is:

~~~PowerShell
<#
.Synopsis
    Matches an ARM parameter
.Description
    Matches an Azure Resource Manager template parameter.
#>
param(
# Match any parameter by default
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
~~~



---


To see how these are used end to end, see [How to Write Tests](../Writing_TTK_Tests.md).
