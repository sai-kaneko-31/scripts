#!/bin/bash

################################
## 事前準備
## - IAM Role を作成すること
##   （参考： https://dev.classmethod.jp/articles/shuntaka-pr-agent-with-bedrock/）
################################

TMP_DIR="./tmp"

mkdir -p $TMP_DIR

echo -n "IAM Role ARN を入力してください: "
read -r IAM_ROLE_ARN

if [ -z "$IAM_ROLE_ARN" ]; then
    echo "IAM Role ARN が入力されていません。処理を終了します。"
    exit 1
fi


cat << EOF > $TMP_DIR/run-pr-agent.yml
name: Run PR Agent
on:
  pull_request:
    types: [opened, reopened, ready_for_review]

jobs:
  pr_agent_job:
    if: \${{ github.event.sender.type != 'Bot' }}
    runs-on: ubuntu-latest
    permissions:
      issues: write
      pull-requests: write
      contents: write
      id-token: write
    name: Run pr agent on every pull request
    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${IAM_ROLE_ARN}
          aws-region: us-east-1
      - name: PR Agent action step
        id: pragent
        uses: Codium-ai/pr-agent@main
        env:
          GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}  
EOF

cat<< EOF > $TMP_DIR/.pr_agent.toml
model = "bedrock/anthropic.claude-3-5-sonnet-20241022-v2:0"
model_turbo = "bedrock/anthropic.claude-3-7-sonnet-20250219-v1:0"
fallback_models = ["bedrock/anthropic.claude-3-sonnet-20240229-v1:0"]

[pr_reviewer]
extra_instructions = "answer in Japanese"

[pr_description]
extra_instructions = "answer in Japanese"

[pr_code_suggestions]
extra_instructions = "answer in Japanese"

[pr_add_docs]
extra_instructions = "answer in Japanese"

[pr_questions]
extra_instructions = "answer in Japanese"

[pr_update_changelog]
extra_instructions = "answer in Japanese"

[pr_test]
extra_instructions = "answer in Japanese"

[pr_improve_component]
extra_instructions = "answer in Japanese"
EOF

mkdir -p ./.github/workflows
cp $TMP_DIR/run-pr-agent.yml ./.github/workflows/run-pr-agent.yml
cp $TMP_DIR/.pr_agent.toml ./.pr_agent.toml

rm -rf $TMP_DIR
