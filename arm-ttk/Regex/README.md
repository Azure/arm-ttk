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

For example, the expression ARM_Expression is defined in [/Regex/ARM/Expression.regex.txt](./ARM/Expression.regex.txt)

### Using Patterns


.regex.txt files will contain a single Regular Expression.

This expression can be used anywhere within arm-ttk.

For instance, using the pattern ARM_Expression, we can find all matches for the expression within $templatetext:

~~~PowerShell
$templateText | & ${?<ARM_Expression>}
~~~

ARM_Expression is defined in [/Regex/ARM/Expression.regex.txt](./ARM/Expression.regex.txt)


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

ARM_Parameter is defined in [/Regex/ARM/Expression.regex.ps1](./ARM/Parameter.regex.ps1)


---


To see how these are used end to end, see [How to Write Tests](../Writing_TTK_Tests.md).
