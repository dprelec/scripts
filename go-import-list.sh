#!/bin/sh

# list all imported libs in Go projects under current directory
#ag --go --nofilename "^\s*([a-zA-Z0-9]+\s*)?\"[^\"]+\"\s+$" | sed "s/import//" | awk '{ print $1 " " $2 }' | sort | dos2unix | uniq  

fd -e go | ag -v vendor | xargs perl ~/bin/go-imports.pl
