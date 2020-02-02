#!/bin/bash

hugo -D
cd public
git status
git add .
DATA=$(date +%Y-%m-%d-%T)
git commit -m "autopush $DATA"
git push origin master
