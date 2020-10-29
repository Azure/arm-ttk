Regular Expressions
========

This directory contains Regular Expressions definitions that are used throughout arm-ttk.  

These Regular Expressions can be used anywhere within arm-ttk.

Regular Expressions definitions can be written in two formats:

*.regex.txt pattern files
*.regex.ps1 pattern generators

These regular expressions can be used within arm-ttk by calling a PowerShell ScriptBlock that matches the name of the directory/file.

### Using Patterns


.regex.txt files will contain a single Regular Expression.

This expression can be used anywhere within arm-ttk.  

For instance, using the pattern ARM_Expression, we can find all expressions within the text of a template:

~~~PowerShell
$templateText | & ${?<ARM_Expression>}
~~~


### Using Generators

.regex.ps1 files will contain Regular Expression generators.

These are PowerShell scripts that produce a regular expression based off of input.

For instance, we can find all of the references to the VMSize parameter.

~~~PowerShell
$templateText | & ${?<ARM_Parameter>} -Parameter 'VMSize'
~~~

Generators need not require parameters.  To find all parameters referenced throughout the template, use:

~~~PowerShell
$templateText | & ${?<ARM_Parameter>}
~~~



To see how these are used end to end, see [How to Write Tests](../Writing_TTK_Tests.md).
