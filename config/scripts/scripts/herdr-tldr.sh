#!/bin/bash

read -r -p "Enter tldr: " query
[[ -z $query ]] && exit 0

tldr "$query"

printf '\nPress Enter to close...'
read -r
