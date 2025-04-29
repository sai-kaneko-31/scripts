#! /bin/bash

set -eu

MCP_SERVERS_DIR="./mcp_servers"

if [ ! -d "$MCP_SERVERS_DIR" ]; then
    git clone git@github.com:modelcontextprotocol/servers.git $MCP_SERVERS_DIR
fi

CURSOR_DIR=".cursor"
MCP_CONFIG="$CURSOR_DIR/mcp.json"

if [ ! -d "$CURSOR_DIR" ]; then
    mkdir -p "$CURSOR_DIR"
fi

if [ ! -f "$MCP_CONFIG" ]; then
    echo -n "GitHub Personal Access Token を入力してください: "
    read -s PAT
    echo

    if [ -z "$PAT" ]; then
        echo "PAT が入力されていません。処理を終了します。"
        exit 1
    fi
    # 新規ファイル作成
    cat > "$MCP_CONFIG" << EOF
{
  "mcpServers": {
    "github": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm", 
        "-e",
        "GITHUB_PERSONAL_ACCESS_TOKEN",
        "mcp/github"
      ],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "$PAT"
      }
    }
  }
}
EOF
    echo "mcp.json を作成しました"
else
    # 既存ファイルの確認と更新
    if grep -q "github" "$MCP_CONFIG"; then
        echo "github の設定は既に存在します"
    else
        echo -n "GitHub Personal Access Token を入力してください: "
        read -s PAT
        echo

        if [ -z "$PAT" ]; then
            echo "PAT が入力されていません。処理を終了します。"
            exit 1
        fi
        # github 設定を追加
        TMP_FILE=$(mktemp)
        if ! command -v jq &> /dev/null; then
            echo "jq コマンドが見つかりません。インストールしますか? [y/N]: "
            read -r INSTALL_JQ
            if [[ "$INSTALL_JQ" =~ ^[Yy]$ ]]; then
                if command -v apt-get &> /dev/null; then
                    sudo apt-get update && sudo apt-get install -y jq
                elif command -v yum &> /dev/null; then
                    sudo yum install -y jq
                elif command -v brew &> /dev/null; then
                    brew install jq
                else
                    echo "パッケージマネージャーが見つかりません。jq を手動でインストールしてください。"
                    exit 1
                fi
            else
                echo "jq のインストールをスキップします。処理を終了します。"
                exit 1
            fi
        fi
        jq '.mcpServers += {"github":{"command":"docker","args":["run","-i","--rm","-e","GITHUB_PERSONAL_ACCESS_TOKEN","mcp/github"],"env":{"GITHUB_PERSONAL_ACCESS_TOKEN":"'"$PAT"'"}}}' "$MCP_CONFIG" > "$TMP_FILE"
        mv "$TMP_FILE" "$MCP_CONFIG"
        echo "github の設定を追加しました"
    fi
fi

# .gitignore に mcp servers 関連のファイルを追加
if ! grep -q "## mcp servers" .gitignore; then
    cat << 'EOF' >> .gitignore

## mcp servers
./setup_mcp_servers.sh
./.cursor/mcp.json
./mcp_servers/

EOF
    echo "mcp servers 関連のファイルを .gitignore に追加しました"
else
    echo "mcp servers 関連のファイルは既に .gitignore に存在します"
fi
