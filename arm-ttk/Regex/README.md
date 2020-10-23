Regular Expressions
========

This directory contains Regular Expressions definitions that are used throughout arm-ttk.  

These Regular Expressions can be used anywhere within arm-ttk.

Regular Expressions definitions can be written in two formats:


*.regex.txt pattern files, which declare case-insenitive patterns that allow comments
*.regex.ps1 pattern generators, which should return an expression based off of input.

These regular expressions can be used within arm-ttk by calling a PowerShell ScriptBlock that matches the name of the directory/file.

For example, you can use run ``` & ${?<ARM_List_Function>} -Match $json ``` to find any reference to list functions in an Azure Resource Manager template.

ARM_List_Function is defined in /Regex/ARM/List_Function.regex.txt.

You can also run ``` & ${?<ARM_Parameter>} -Parameter 'MyParameter' -Match $json ``` to find all references to an Azure Resource Manager parameter.

ARM_Parameter is defined in /Regex/ARM/Parameter.regex.ps1