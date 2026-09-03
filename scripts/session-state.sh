#!/bin/bash
# 会话状态快照脚本
# 用途：在关键门禁点生成会话状态快照，供上下文恢复时快速加载

set -e

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
STATE_DIR=".session_state"
SNAPSHOT_FILE="${STATE_DIR}/snapshot_${TIMESTAMP}.json"

# 创建状态目录
mkdir -p "$STATE_DIR"

# 提取当前工程上下文
extract_context() {
    local project_name=""
    local task_dir=""
    local stage=""
    local checkpoint=""

    # 尝试从最近的操作记录中提取
    if [ -f "document/*/*/prd/prd-任务操作记录.md" ]; then
        local latest_record=$(find document -name "prd-任务操作记录.md" -o -name "tech-任务操作记录.md" | sort | tail -1)
        if [ -n "$latest_record" ]; then
            project_name=$(echo "$latest_record" | cut -d'/' -f2)
            task_dir=$(echo "$latest_record" | cut -d'/' -f3)
            stage=$(grep -m1 "当前阶段" "$latest_record" | sed 's/.*: //')
        fi
    fi

    cat > "$SNAPSHOT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project_name": "$project_name",
  "task_dir": "$task_dir",
  "stage": "$stage",
  "checkpoint": "$checkpoint",
  "files": {
    "project_summary": "document/$project_name/产品工程摘要.md",
    "product_rules": "document/$project_name/产品通用规则.md",
    "tech_rules": "document/$project_name/技术通用规则.md",
    "task_result": "document/$project_name/$task_dir/prd/prd-任务结果摘要.md",
    "task_log": "document/$project_name/$task_dir/prd/prd-任务操作记录.md"
  }
}
EOF

    echo "✅ 会话状态已保存: $SNAPSHOT_FILE"
}

# 显示最近的快照
list_snapshots() {
    echo "📋 最近的会话快照："
    ls -lt "$STATE_DIR"/snapshot_*.json | head -5
}

# 执行
case "${1:-save}" in
    save)
        extract_context
        ;;
    list)
        list_snapshots
        ;;
    *)
        echo "用法: $0 {save|list}"
        exit 1
        ;;
esac
