#!/bin/sh

LOCAL_READLINK=readlink

# https://stackoverflow.com/questions/3466166/how-to-check-if-running-in-cygwin-mac-or-linux
unameOut="$(uname -s)"
case "${unameOut}" in
    Darwin*)    LOCAL_READLINK=greadlink;;
esac

pwsh -noprofile -nologo -command "Import-Module '$(dirname $(${LOCAL_READLINK} -f $0))/arm-ttk.psd1'; Test-AzTemplate $@ ; if (\$Error.Count) { exit 1}"
