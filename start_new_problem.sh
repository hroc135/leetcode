#!/bin/bash

git checkout main

# 入力引数を取得
problem_name="$1"

branch_name=$(echo "$problem_name" | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}}1' | sed -e 's/[.]//g' -e 's/ //g')
git checkout -b "$branch_name"
cp README.md $branch_name.md
