#!/bin/bash -e

git init
git submodule add -f https://github.com/google/eDistantObject eDistantObject
git submodule add -f https://github.com/facebook/fishhook fishhook

replace_string_in_files()
{
  REPLACE_STRING='s/'$1'//g'
  grep -ilr $1 ../* | xargs -I@ sed -i '' $REPLACE_STRING @

}

replace_string_in_files 'third_party\/objective_c\/EarlGreyV2\/Tests\/Functional\/HostDOCategories\/'
replace_string_in_files 'third_party\/objective_c\/EarlGreyV2\/Tests\/Functional\/Sources\/'
replace_string_in_files 'third_party\/objective_c\/EarlGreyV2\/'
replace_string_in_files 'third_party\/objective_c\/eDistantObject\/'
replace_string_in_files 'Tests\/TestRig\/Sources\/'
