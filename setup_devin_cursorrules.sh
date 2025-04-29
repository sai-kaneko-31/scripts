#!/bin/bash

set -eu

TMP_DIR="./.tmp"

if [ ! -d "$TMP_DIR" ]; then
    mkdir $TMP_DIR
fi

git clone git@github.com:grapeot/devin.cursorrules.git $TMP_DIR/devin.cursorrules

cp -r $TMP_DIR/devin.cursorrules/tools ./

if [ ! -d "./.cursor/rules" ]; then
    mkdir -p ./.cursor/rules
fi

if [ ! -f "./.cursor/rules/xx_devin_cursorrules.mdc" ]; then
    cat << 'EOF' > ./.cursor/rules/xx_devin_cursorrules.mdc
---
description: To use devin.cursorrules if needed.
globs: **/*
alwaysApply: true
---

EOF

    sed 's/\.cursorrules/\.cursor\/rules\/issues\/${task-slug:+${issue-num}-}${task-slug}.md/g' $TMP_DIR/devin.cursorrules/.cursorrules >> ./.cursor/rules/xx_devin_cursorrules.mdc

    cat << 'EOF' >> .gitignore

## devin.cursorrules
./setup_devin_cursorrules.sh
./tools
./.cursor/rules/xx_devin_cursorrules.mdc

EOF
fi

rm -rf $TMP_DIR