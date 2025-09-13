#!/bin/bash

read -p "Enter your commit message: " text
git add .
git commit -m "$text"
git push origin main