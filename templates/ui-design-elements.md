# UI 设计要素模板

> 本模板定义了原型设计中的 UI 设计要素（设计令牌）。所有颜色使用 #RRGGBB 十六进制格式。
> 可以直接使用此模板，也可以在任务目录中放入自定义的 `ui-design-elements.md` 覆盖。

> **引用关系（与需求包联动）**：本文件是 `skills/page-specs/SKILL.md` 中「页面状态」「业务规则（产品行为）」章节的**视觉令牌来源**。
> - 02-page-specs 中描述的页面状态（空 / 加载中 / 错误 / 受限）在视觉表达上应引用本文件的色板与组件令牌。
> - 业务规则驱动的反馈（成功 / 警告 / 危险 / 提示）映射到本文件的 `success / warning / danger / info` 色板。
> 注意：本文件属**视觉层**（主要供第二部分 Pencil 原型生成使用）；需求包阶段只描述状态与行为，不依赖本文件即可成立。

---

## 色板

```json
{
  "colors": {
    "primary": "#007AFF",
    "primary_light": "#4DA3FF",
    "primary_dark": "#0055CC",
    "secondary": "#FF9500",
    "success": "#34C759",
    "warning": "#FFCC00",
    "danger": "#FF3B30",
    "info": "#5AC8FA",
    "background": "#F5F5F5",
    "surface": "#FFFFFF",
    "surface_secondary": "#F0F0F0",
    "border": "#E0E0E0",
    "divider": "#EEEEEE",
    "text_primary": "#333333",
    "text_secondary": "#666666",
    "text_tertiary": "#999999",
    "text_on_primary": "#FFFFFF",
    "text_link": "#007AFF",
    "disabled": "#CCCCCC",
    "overlay": "rgba(0,0,0,0.4)",
    "shadow": "rgba(0,0,0,0.1)"
  }
}
```

## 字体层级

```json
{
  "typography": {
    "heading_large": { "fontFamily": "PingFang SC", "fontSize": 28, "fontWeight": "bold", "lineHeight": 36 },
    "heading_medium": { "fontFamily": "PingFang SC", "fontSize": 22, "fontWeight": "bold", "lineHeight": 30 },
    "heading_small": { "fontFamily": "PingFang SC", "fontSize": 18, "fontWeight": "semibold", "lineHeight": 26 },
    "title": { "fontFamily": "PingFang SC", "fontSize": 17, "fontWeight": "semibold", "lineHeight": 24 },
    "body": { "fontFamily": "PingFang SC", "fontSize": 16, "fontWeight": "regular", "lineHeight": 24 },
    "body_small": { "fontFamily": "PingFang SC", "fontSize": 14, "fontWeight": "regular", "lineHeight": 22 },
    "caption": { "fontFamily": "PingFang SC", "fontSize": 12, "fontWeight": "regular", "lineHeight": 18 },
    "label": { "fontFamily": "PingFang SC", "fontSize": 11, "fontWeight": "regular", "lineHeight": 16 }
  }
}
```

## 间距体系

```json
{
  "spacing": {
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 24,
    "xxl": 32,
    "page_margin": 16,
    "card_gap": 12,
    "element_gap": 8,
    "section_gap": 20
  }
}
```

## 圆角

```json
{
  "border_radius": {
    "none": 0,
    "sm": 4,
    "md": 8,
    "lg": 12,
    "xl": 16,
    "full": "50%",
    "button": 8,
    "card": 12,
    "input": 8,
    "modal": 16,
    "avatar": "50%"
  }
}
```

## 组件尺寸

```json
{
  "dimensions": {
    "navigation_bar_height": 44,
    "tab_bar_height": 49,
    "status_bar_height": 44,
    "button_small": { "height": 32, "padding_h": 12 },
    "button_medium": { "height": 40, "padding_h": 16 },
    "button_large": { "height": 48, "padding_h": 20 },
    "input_height": 40,
    "input_height_large": 48,
    "icon_small": 16,
    "icon_medium": 24,
    "icon_large": 32,
    "avatar_small": 24,
    "avatar_medium": 40,
    "avatar_large": 56,
    "card_min_height": 80,
    "banner_height": 180,
    "thumbnail_size": 80
  }
}
```

## 阴影

```json
{
  "shadows": {
    "none": "none",
    "sm": "0 1px 3px rgba(0,0,0,0.08)",
    "md": "0 2px 8px rgba(0,0,0,0.1)",
    "lg": "0 4px 16px rgba(0,0,0,0.12)",
    "xl": "0 8px 24px rgba(0,0,0,0.15)",
    "card": "0 2px 8px rgba(0,0,0,0.1)",
    "modal": "0 8px 24px rgba(0,0,0,0.2)"
  }
}
```

## 组件样式

```json
{
  "component_styles": {
    "navigation_bar": {
      "backgroundColor": "#FFFFFF",
      "foregroundColor": "#333333",
      "borderBottom": "1px solid #E0E0E0"
    },
    "tab_bar": {
      "backgroundColor": "#FFFFFF",
      "activeColor": "#007AFF",
      "inactiveColor": "#999999",
      "borderTop": "1px solid #E0E0E0"
    },
    "button_primary": {
      "backgroundColor": "#007AFF",
      "textColor": "#FFFFFF",
      "borderRadius": 8,
      "fontSize": 16
    },
    "button_outline": {
      "borderColor": "#007AFF",
      "textColor": "#007AFF",
      "backgroundColor": "transparent",
      "borderRadius": 8,
      "borderWidth": 1
    },
    "card": {
      "backgroundColor": "#FFFFFF",
      "borderRadius": 12,
      "padding": 16,
      "shadow": "0 2px 8px rgba(0,0,0,0.1)"
    },
    "input": {
      "backgroundColor": "#F5F5F5",
      "borderRadius": 8,
      "borderColor": "#E0E0E0",
      "textColor": "#333333",
      "placeholderColor": "#999999",
      "height": 40,
      "paddingH": 12
    },
    "tag": {
      "backgroundColor": "#F0F0F0",
      "textColor": "#666666",
      "borderRadius": 4,
      "paddingH": 8,
      "height": 24,
      "fontSize": 12
    },
    "badge": {
      "backgroundColor": "#FF3B30",
      "textColor": "#FFFFFF",
      "borderRadius": 9,
      "minWidth": 18,
      "height": 18,
      "fontSize": 11
    }
  }
}
```

## 图标规范
* 图标库：统一使用 Material Symbols Rounded。
* 图标尺寸：仅使用 16px、20px、24px 三种，与文字系统对齐。
* 图标颜色：继承父级文字颜色，若需独立指定，使用 --text-secondary 或 --primary。
* 关键约束：生成图标时，必须同时设置 fontSize、width、height 三个属性，且值相等。

## 组件规范
> 使用 `mcp_pencil_set_variables` 注入设计令牌，用`reusable: true`创建`Button/Primary`等组件通过`ref`进行复用，并以 ComponentName/Size/Variant 格式命名。
> Web端设计的列表结构，原则上都需要搜索组件和分页组件。搜索组件默认带基于 “ID“/“编号“ 的输入型搜索、基于 “名称“ 的输入型搜索、基于“类型“/“状态“下拉选择型搜索、基于“时间“的范围型搜索，有“搜索“和“重置“按钮；分页器包括当前页、可以下拉选择的单次分页数量、往前可以选择的页数、往后可以选择的页数，分页器要封装为一个设计组件。移动端及 H5 页面设计，无需显示分页组件。

## 状态-令牌映射参考

> 本节为 `02-page-specs.md` 的「页面状态」「业务规则（产品行为）」提供**视觉令牌映射**，便于原型生成阶段（Pencil）与技术架构 Agent 对齐表现层。
> 需求包阶段**仅需引用状态名称**，无需绑定以下令牌；以下令牌在第二部分原型生成时由 pencil-executor 注入。

| 产品状态 / 业务反馈 | 语义 | 建议令牌 |
|-------------------|------|---------|
| 正常态 | 数据加载完成、可操作 | surface / text_primary |
| 空态 | 无数据（列表 / 搜索无结果） | text_tertiary（空提示文案） + surface_secondary（占位区底） |
| 加载中态 | 数据请求中 | text_secondary（骨架 / 转圈） |
| 错误态 | 操作失败 / 数据异常 | danger (#FF3B30) 提示色 + text_on_primary（按钮） |
| 受限态 | 无权限 / 角色不可用 | disabled (#CCCCCC) 置灰 + text_tertiary |
| 成功反馈（业务规则触发） | 创建 / 更新 / 删除成功 | success (#34C759) |
| 警告反馈（业务规则触发） | 需确认 / 临界 | warning (#FFCC00) |
| 信息提示 | 普通引导 | info (#5AC8FA) / text_link |
| 危险操作（业务规则触发） | 删除 / 不可逆 | danger (#FF3B30) + button 反白 |

> 映射原则：状态与反馈的**语义**由 02-page-specs 定义，**视觉值**由本文件提供；原型生成阶段据此注入 Pencil 设计令牌，技术架构 Agent 可据此推导界面表现层约束。
