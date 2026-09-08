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
    local system_dir=""
    local stage=""
    local checkpoint=""

    # 尝试从最近的操作记录中提取
    local latest_record=$(find document \( -name "prd-系统操作记录.md" -o -name "tech-系统操作记录.md" \) -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -1)
    if [ -n "$latest_record" ]; then
        project_name=$(echo "$latest_record" | cut -d'/' -f2)
        system_dir=$(echo "$latest_record" | cut -d'/' -f3)
        stage=$(grep -m1 "当前阶段" "$latest_record" | sed 's/.*: //')
    fi

    cat > "$SNAPSHOT_FILE" <<EOF
{
  "timestamp": "$TIMESTAMP",
  "project_name": "$project_name",
  "system_dir": "$system_dir",
  "stage": "$stage",
  "checkpoint": "$checkpoint",
  "files": {
    "project_summary": "document/$project_name/项目级产品摘要.md",
    "generic_exception": "document/$project_name/通用异常处理.md",
    "generic_validation": "document/$project_name/通用校验规则.md",
    "tech_standards": "document/$project_name/$system_dir/tech/系统级技术标准.md",
    "system_result": "document/$project_name/$system_dir/prd/prd-系统结果摘要.md",
    "system_log": "document/$project_name/$system_dir/prd/prd-系统操作记录.md"
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
