#!/usr/bin/env python3
"""
batch_upgrade_templates.py - 批量升级 .do 模板添加社区命令支持

升级内容:
1. 添加 estout 依赖声明
2. 添加 esttab 依赖检查
3. 在导出部分添加 esttab RTF 输出
"""

import re
from pathlib import Path

DO_DIR = Path(r"c:\Users\Lenovo\Desktop\stata_service\tasks\do")

# 要升级的模板列表
TEMPLATES_TO_UPGRADE = [
    "T18_ols_multiple.do",
    "T19_ols_robust_se.do",
    "T20_ols_cluster_se.do", 
    "T21_ols_with_interaction.do",
    "T22_ols_fe_entity_dummies.do",
    "T23_ols_time_dummies.do",
    "T24_ols_model_comparison.do",
    "T31_panel_fe_basic.do",
    "T32_panel_re_basic.do",
    "T33_panel_fe_re_hausman.do",
    "T34_diff_in_diff_2x2.do",
    "T35_diff_in_diff_event_study.do",
]


def upgrade_template(filepath: Path) -> bool:
    """升级单个模板"""
    content = filepath.read_text(encoding='utf-8')
    original = content
    
    task_id = filepath.stem.split('_')[0]  # e.g., T18
    
    # 1. 检查是否已升级
    if 'estout source=ssc' in content:
        print(f"  {filepath.name}: 已升级，跳过")
        return False
    
    # 2. 添加 estout 依赖声明（在 DEPENDENCIES 部分）
    if '* DEPENDENCIES:' in content:
        content = content.replace(
            '* DEPENDENCIES:\n*   - stata source=built-in',
            '* DEPENDENCIES:\n*   - stata source=built-in purpose="core commands"\n*   - estout source=ssc purpose="publication-quality tables (optional)"'
        )
    
    # 3. 修改 Stata 版本注释
    content = content.replace(
        '(official commands only)',
        '(official + community commands)'
    )
    
    # 4. 在依赖检查部分添加 esttab 检查
    dep_check_pattern = r'(\* ============ 依赖检查 ============\s*\ndisplay "SS_DEP_CHECK\|pkg=stata\|source=built-in\|status=ok")\s*\n\n'
    
    esttab_check = r'''\1

* 检查 esttab (可选依赖，用于论文级表格)
local has_esttab = 0
capture which esttab
if _rc {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=missing"
    display ">>> estout 未安装，将使用基础 CSV 导出"
} 
else {
    display "SS_DEP_CHECK|pkg=estout|source=ssc|status=ok"
    local has_esttab = 1
}

'''
    
    content = re.sub(dep_check_pattern, esttab_check, content)
    
    # 5. 在导出部分后添加 esttab 输出（在 CSV 导出后）
    # 查找 "回归结果已导出" 或类似字样后添加
    esttab_output_block = f'''

* ============ 论文级表格输出 (esttab) ============
if `has_esttab' {{
    display ""
    display ">>> 导出论文级表格: table_{task_id}_paper.rtf"
    
    esttab using "table_{task_id}_paper.rtf", replace ///
        cells(b(star fmt(3)) se(par fmt(3))) ///
        stats(N r2 r2_a, fmt(%9.0fc %9.3f %9.3f) ///
              labels("Observations" "R²" "Adj. R²")) ///
        title("Regression Results") ///
        star(* 0.10 ** 0.05 *** 0.01) ///
        note("Standard errors in parentheses. * p<0.10, ** p<0.05, *** p<0.01")
    
    display "SS_OUTPUT_FILE|file=table_{task_id}_paper.rtf|type=table|desc=publication_table"
    display ">>> 论文级表格已导出 ✓"
}}
else {{
    display ""
    display ">>> 跳过论文级表格 (estout 未安装)"
}}
'''
    
    # 查找导出完成后的位置（在 "已导出" 后的 restore 之后）
    restore_pattern = r'(display ">>> .+已导出"\s*\nrestore)'
    
    # 只在第一个 restore 后添加
    match = re.search(restore_pattern, content)
    if match:
        insert_pos = match.end()
        content = content[:insert_pos] + esttab_output_block + content[insert_pos:]
    
    # 6. 添加输出文件声明到头部
    output_pattern = r'(\* OUTPUTS:\n(?:\*   - [^\n]+\n)+)'
    
    def add_rtf_output(m):
        outputs = m.group(1)
        if 'paper.rtf' not in outputs:
            # 在最后一个输出文件前添加
            lines = outputs.rstrip().split('\n')
            # 在 result.log 之前插入
            new_line = f'*   - table_{task_id}_paper.rtf type=table desc="Publication-quality table"'
            for i, line in enumerate(lines):
                if 'result.log' in line:
                    lines.insert(i, new_line)
                    break
            else:
                lines.insert(-1, new_line)
            return '\n'.join(lines) + '\n'
        return outputs
    
    content = re.sub(output_pattern, add_rtf_output, content)
    
    if content != original:
        filepath.write_text(content, encoding='utf-8')
        print(f"  {filepath.name}: upgrade complete [OK]")
        return True
    else:
        print(f"  {filepath.name}: no change needed")
        return False


def main():
    print("=" * 60)
    print("Stata Template Batch Upgrade - Adding esttab support")
    print("=" * 60)
    
    upgraded = 0
    skipped = 0
    
    for filename in TEMPLATES_TO_UPGRADE:
        filepath = DO_DIR / filename
        if filepath.exists():
            if upgrade_template(filepath):
                upgraded += 1
            else:
                skipped += 1
        else:
            print(f"  {filename}: file not found, skipped")
            skipped += 1
    
    print("=" * 60)
    print(f"Upgraded: {upgraded} files")
    print(f"Skipped: {skipped} files")
    print("=" * 60)


if __name__ == "__main__":
    main()
