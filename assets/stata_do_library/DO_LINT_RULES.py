#!/usr/bin/env python3
"""
DO_LINT_RULES.py - Do Library 自动门禁检查器 (v1.1)

基于 SS_DO_CONTRACT.md v1.1 硬契约实现。

用法:
    python DO_LINT_RULES.py --path tasks/do/
    python DO_LINT_RULES.py --file tasks/do/T01_desc_overview.do
    python DO_LINT_RULES.py --path tasks/do/ --output lint_report.json

退出码:
    0 - 全部通过
    1 - 存在 CRITICAL 违规 (CI必须失败)
    2 - 仅存在 WARNING (CI可通过)
"""

import argparse
import json
import re
import sys
from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Set


class Severity(Enum):
    CRITICAL = "CRITICAL"  # 硬门禁,CI必须失败
    HIGH = "HIGH"          # 高优先级警告,应修复
    WARNING = "WARNING"    # 软警告,CI可通过
    INFO = "INFO"          # 信息提示


@dataclass
class LintIssue:
    """单个lint问题"""
    rule_id: str
    severity: Severity
    file: str
    line: int
    message: str
    context: str = ""
    suggestion: str = ""


@dataclass
class LintResult:
    """单文件lint结果"""
    file: str
    passed: bool
    issues: List[LintIssue] = field(default_factory=list)
    critical_count: int = 0
    high_count: int = 0
    warning_count: int = 0
    # 提取的元数据
    template_id: str = ""
    template_level: str = ""
    template_module: str = ""
    has_header: bool = False
    anchor_counts: Dict[str, int] = field(default_factory=dict)


class DoLinter:
    """Do文件门禁检查器 - 基于 SS_DO_CONTRACT.md v1.1"""
    
    # =========================================================================
    # 规则定义
    # =========================================================================
    
    # RULE-001: 危险命令
    DANGEROUS_COMMANDS = [
        (r'^\s*erase\s+', 'erase命令会删除文件'),
        (r'^\s*rmdir\s+', 'rmdir命令会删除目录'),
        (r'^\s*!\s*', 'Shell escape可执行任意系统命令'),
        (r'\bshell\s+', 'shell命令可执行任意系统命令'),
        (r'^\s*copy\s+[^"\']*\.\.', 'copy命令跨目录操作'),
    ]
    
    # RULE-002: 硬编码路径
    HARDCODED_PATHS = [
        (r'[A-Z]:\\', 'Windows绝对路径'),
        (r'/home/', 'Linux home目录'),
        (r'/Users/', 'macOS home目录'),
        (r'/tmp/', '临时目录(非隔离)'),
        (r'桌面', '中文桌面路径'),
        (r'/var/', '系统目录'),
    ]
    
    # RULE-003: 交互式命令
    INTERACTIVE_COMMANDS = [
        (r'^\s*pause\b', 'pause会阻塞执行'),
        (r'^\s*sleep\s+', 'sleep会延迟执行'),
        (r'_request\s*\(', '_request()等待用户输入'),
    ]

    # RULE-016: 禁止使用历史占位符变体（必须使用 canonical 形式）
    DEPRECATED_PLACEHOLDERS = {
        "__DEP_VAR__": "__DEPVAR__",
        "__INDEP_VARS__": "__INDEPVARS__",
        "__TIMEVAR__": "__TIME_VAR__",
    }
    
    # RULE-010: 必需锚点 (v1.1 新格式)
    REQUIRED_ANCHORS_V11 = {
        'SS_TASK_BEGIN': r'SS_TASK_BEGIN\|id=',
        'SS_TASK_END': r'SS_TASK_END\|id=',
        'SS_STEP_BEGIN': r'SS_STEP_BEGIN\|step=',
        'SS_STEP_END': r'SS_STEP_END\|step=',
        'SS_DEP_CHECK': r'SS_DEP_CHECK\|pkg=',
        'SS_OUTPUT_FILE': r'SS_OUTPUT_FILE\|file=',
        'SS_METRIC': r'SS_METRIC\|name=',
        'SS_SUMMARY': r'SS_SUMMARY\|key=',
    }
    
    # RULE-011: 头部声明必需字段
    HEADER_FIELDS = ['SS_TEMPLATE:', 'INPUTS:', 'OUTPUTS:', 'DEPENDENCIES:']
    
    # RULE-012: role 枚举值
    VALID_ROLES = {'main_dataset', 'merge_table', 'lookup', 'appendix', 'other'}
    
    # RULE-013: type 枚举值
    VALID_TYPES = {'log', 'table', 'graph', 'model', 'report', 'data'}
    
    # RULE-014: source 枚举值
    VALID_SOURCES = {'built-in', 'ssc', 'net'}
    
    # RULE-015: level 枚举值
    VALID_LEVELS = {'L0', 'L1', 'L2'}
    
    # 社区命令白名单 (从 stata_dependencies.txt 加载)
    WHITELISTED_COMMANDS: Set[str] = set()
    
    # 常见社区命令 (用于检测)
    KNOWN_COMMUNITY_COMMANDS = [
        'reghdfe', 'ftools', 'estout', 'esttab', 'outreg2', 'asdoc',
        'coefplot', 'grc1leg', 'winsor2', 'distinct', 'mdesc', 'missings',
        'ivreg2', 'xtivreg2', 'ranktest', 'xtabond2', 'psmatch2', 'diff',
        'rdrobust', 'rddensity', 'synth', 'synth_runner', 'csdid', 
        'did_multiplegt', 'eventstudyinteract', 'eventdd', 'cem',
        'metan', 'metafunnel', 'metabias', 'asreg', 'rangestat', 
        'xtscc', 'xtfmb', 'xtcsd', 'xttest2', 'xttest3',
        'khb', 'heatplot', 'vioplot', 'tabout',  # sgmediation/medeff 移除,使用 sem 替代
        'dfgls', 'kpss', 'zandrews', 'qreg2', 'bsqreg', 'robreg',
    ]
    
    # 最小要求
    MIN_STEP_COUNT = 3  # 至少3个step (load/analysis/export)
    MIN_METRIC_COUNT = 4  # 至少4个metric
    MIN_SUMMARY_COUNT = 3  # 至少3个summary
    
    def __init__(self, strict: bool = True, whitelist_path: str = None):
        self.strict = strict
        self.results: List[LintResult] = []
        self._load_whitelist(whitelist_path)
    
    def _load_whitelist(self, whitelist_path: str = None):
        """加载社区命令白名单"""
        paths_to_try = [
            whitelist_path,
            Path(__file__).parent.parent / 'stata_dependencies.txt',
            Path(__file__).parent / 'stata_dependencies.txt',
            Path('stata_dependencies.txt'),
        ]
        
        for p in paths_to_try:
            if p and Path(p).exists():
                try:
                    content = Path(p).read_text(encoding='utf-8')
                    for line in content.split('\n'):
                        line = line.strip()
                        if not line or line.startswith('#'):
                            continue
                        # 取第一个token作为包名
                        pkg = line.split()[0].split('#')[0].strip()
                        if pkg:
                            self.WHITELISTED_COMMANDS.add(pkg.lower())
                    break
                except (OSError, UnicodeDecodeError) as e:
                    print(
                        json.dumps(
                            {
                                "event": "do_lint.whitelist_read_failed",
                                "path": str(p),
                                "error": str(e),
                            },
                            ensure_ascii=False,
                        ),
                        file=sys.stderr,
                    )
        
        # 如果没找到白名单，使用已知命令作为默认
        if not self.WHITELISTED_COMMANDS:
            self.WHITELISTED_COMMANDS = set(cmd.lower() for cmd in self.KNOWN_COMMUNITY_COMMANDS)
    
    def lint_file(self, filepath: Path) -> LintResult:
        """检查单个do文件 - v1.1 硬契约"""
        result = LintResult(file=str(filepath), passed=True)
        
        try:
            content = filepath.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            content = filepath.read_text(encoding='gbk')
        
        lines = content.split('\n')

        # ===== 安全性检查 (CRITICAL) =====
        # RULE-016: 禁止使用历史占位符变体
        self._check_deprecated_placeholders(content, result)

        # RULE-001: 危险命令检查
        self._check_dangerous_commands(lines, result)
        
        # RULE-002: 硬编码路径检查
        self._check_hardcoded_paths(lines, result)
        
        # RULE-003: 交互式命令检查
        self._check_interactive_commands(lines, result)
        
        # RULE-004: 输出目录隔离检查
        self._check_output_isolation(lines, result)
        
        # ===== 头部声明检查 (CRITICAL) =====
        # RULE-010: 头部声明区检查
        self._check_header_declaration(content, lines, result)
        
        # ===== 锚点协议检查 (CRITICAL) =====
        # RULE-011: 必需锚点检查 (v1.1格式)
        self._check_required_anchors_v11(content, result)
        
        # RULE-012: 步骤锚点数量检查
        self._check_step_count(content, result)
        
        # RULE-013: 指标数量检查
        self._check_metric_count(content, result)
        
        # RULE-014: 摘要数量检查
        self._check_summary_count(content, result)
        
        # RULE-015: 输出声明检查
        self._check_output_declarations(content, lines, result)
        
        # ===== 依赖检查 (CRITICAL) =====
        # RULE-020: 社区命令白名单检查
        self._check_community_deps(content, lines, result)
        
        # RULE-021: capture后_rc检查
        self._check_capture_rc(lines, result)
        
        # ===== 软警告 (WARNING) =====
        # WARN-001: 全局变量检查
        self._check_global_usage(lines, result)
        
        # WARN-002: 版本声明检查
        self._check_version_declaration(content, result)
        
        # 统计
        result.critical_count = sum(1 for i in result.issues if i.severity == Severity.CRITICAL)
        result.high_count = sum(1 for i in result.issues if i.severity == Severity.HIGH)
        result.warning_count = sum(1 for i in result.issues if i.severity == Severity.WARNING)
        result.passed = result.critical_count == 0 and result.high_count == 0
        
        return result
    
    def _check_dangerous_commands(self, lines: List[str], result: LintResult):
        """RULE-001: 检查危险命令"""
        for i, line in enumerate(lines, 1):
            # 跳过注释行
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            for pattern, desc in self.DANGEROUS_COMMANDS:
                if re.search(pattern, line, re.IGNORECASE):
                    result.issues.append(LintIssue(
                        rule_id="RULE-001",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=i,
                        message=f"危险命令: {desc}",
                        context=line.strip()[:80],
                        suggestion="移除此命令或使用安全替代方案"
                    ))
    
    def _check_hardcoded_paths(self, lines: List[str], result: LintResult):
        """RULE-002: 检查硬编码路径"""
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            for pattern, desc in self.HARDCODED_PATHS:
                if re.search(pattern, line, re.IGNORECASE):
                    # 排除注释中的路径
                    if '/*' in line and '*/' in line:
                        continue
                    result.issues.append(LintIssue(
                        rule_id="RULE-002",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=i,
                        message=f"硬编码路径: {desc}",
                        context=line.strip()[:80],
                        suggestion="使用相对路径,如 'data.dta' 或 'outputs/file.csv'"
                    ))

    def _check_deprecated_placeholders(self, content: str, result: LintResult):
        """RULE-016: 检查历史占位符变体（必须使用 canonical 形式）"""
        found = [(legacy, self.DEPRECATED_PLACEHOLDERS[legacy]) for legacy in self.DEPRECATED_PLACEHOLDERS if legacy in content]
        if not found:
            return

        for legacy, canonical in found:
            result.issues.append(
                LintIssue(
                    rule_id="RULE-016",
                    severity=Severity.CRITICAL,
                    file=result.file,
                    line=0,
                    message=f"禁止使用历史占位符变体: {legacy}",
                    context=legacy,
                    suggestion=f"替换为 canonical 占位符: {canonical}",
                )
            )
    
    def _check_required_anchors(self, content: str, lines: List[str], result: LintResult):
        """RULE-003: 检查必需锚点"""
        for anchor in self.REQUIRED_ANCHORS:
            if anchor not in content:
                result.issues.append(LintIssue(
                    rule_id="RULE-003",
                    severity=Severity.CRITICAL,
                    file=result.file,
                    line=0,
                    message=f"缺少必需锚点: {anchor}",
                    context="",
                    suggestion=f'添加 display "{anchor}:task_id" 到适当位置'
                ))
        
        # 检查SS_OUTPUT_FILE锚点
        output_count = len(re.findall(r'SS_OUTPUT_FILE:', content))
        export_count = len(re.findall(r'export\s+delimited|graph\s+export|save\s+', content, re.IGNORECASE))
        
        if export_count > 0 and output_count == 0:
            result.issues.append(LintIssue(
                rule_id="RULE-005",
                severity=Severity.CRITICAL,
                file=result.file,
                line=0,
                message=f"缺少SS_OUTPUT_FILE锚点 (检测到{export_count}个输出操作)",
                context="",
                suggestion='每个输出文件后添加 display "SS_OUTPUT_FILE:filename"'
            ))
    
    def _check_output_isolation(self, lines: List[str], result: LintResult):
        """RULE-004: 检查输出目录隔离"""
        output_pattern = re.compile(
            r'(save|export\s+delimited|graph\s+export|file\s+open|outsheet|putexcel)\s+',
            re.IGNORECASE
        )
        parent_dir_pattern = re.compile(r'\.\.')
        absolute_path_pattern = re.compile(r'["\'][A-Z]:\\|["\']/[a-z]')
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            if output_pattern.search(line):
                if parent_dir_pattern.search(line):
                    result.issues.append(LintIssue(
                        rule_id="RULE-004",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=i,
                        message="输出使用父目录回溯(..)",
                        context=line.strip()[:80],
                        suggestion="输出必须落入当前目录或子目录"
                    ))
                
                if absolute_path_pattern.search(line):
                    result.issues.append(LintIssue(
                        rule_id="RULE-004",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=i,
                        message="输出使用绝对路径",
                        context=line.strip()[:80],
                        suggestion="使用相对路径"
                    ))
    
    def _check_interactive_commands(self, lines: List[str], result: LintResult):
        """RULE-003: 检查交互式命令"""
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            for pattern, desc in self.INTERACTIVE_COMMANDS:
                if re.search(pattern, line, re.IGNORECASE):
                    result.issues.append(LintIssue(
                        rule_id="RULE-003",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=i,
                        message=f"交互式命令: {desc}",
                        context=line.strip()[:80],
                        suggestion="移除交互式命令，服务器执行不支持"
                    ))
    
    def _check_header_declaration(self, content: str, lines: List[str], result: LintResult):
        """RULE-010: 检查头部声明区"""
        # 检查前100行是否包含必需的头部字段
        header_section = '\n'.join(lines[:100])
        
        for field in self.HEADER_FIELDS:
            if field not in header_section:
                result.issues.append(LintIssue(
                    rule_id="RULE-010",
                    severity=Severity.CRITICAL,
                    file=result.file,
                    line=0,
                    message=f"缺少头部声明字段: {field}",
                    context="",
                    suggestion=f"在文件头部添加 '* {field}' 声明区"
                ))
        
        # 提取SS_TEMPLATE信息
        template_match = re.search(r'\*\s*SS_TEMPLATE:\s*id=(\w+)\s+level=(L\d)\s+module=(\w+)', header_section)
        if template_match:
            result.template_id = template_match.group(1)
            result.template_level = template_match.group(2)
            result.template_module = template_match.group(3)
            result.has_header = True
            
            # 验证level枚举值
            if result.template_level not in self.VALID_LEVELS:
                result.issues.append(LintIssue(
                    rule_id="RULE-015",
                    severity=Severity.CRITICAL,
                    file=result.file,
                    line=0,
                    message=f"无效的level值: {result.template_level}",
                    context="",
                    suggestion=f"level必须是: {', '.join(self.VALID_LEVELS)}"
                ))
    
    def _check_required_anchors_v11(self, content: str, result: LintResult):
        """RULE-011: 检查v1.1必需锚点"""
        anchor_counts = {}
        
        for anchor_name, pattern in self.REQUIRED_ANCHORS_V11.items():
            count = len(re.findall(pattern, content))
            anchor_counts[anchor_name] = count
            
            # SS_TASK_BEGIN 和 SS_TASK_END 必须存在
            if anchor_name in ('SS_TASK_BEGIN', 'SS_TASK_END') and count == 0:
                # 检查是否有旧格式
                if anchor_name == 'SS_TASK_BEGIN':
                    legacy_count = len(re.findall(r'SS_TASK_START:', content))
                    if legacy_count > 0:
                        result.issues.append(LintIssue(
                            rule_id="RULE-011",
                            severity=Severity.HIGH,
                            file=result.file,
                            line=0,
                            message=f"使用旧格式SS_TASK_START，应升级到SS_TASK_BEGIN|id=...|level=...|title=...",
                            context="",
                            suggestion='display "SS_TASK_BEGIN|id=Txxx|level=L0|title=..."'
                        ))
                    else:
                        result.issues.append(LintIssue(
                            rule_id="RULE-011",
                            severity=Severity.CRITICAL,
                            file=result.file,
                            line=0,
                            message=f"缺少必需锚点: {anchor_name}",
                            context="",
                            suggestion=f'添加 display "{anchor_name}|..."'
                        ))
                elif anchor_name == 'SS_TASK_END':
                    legacy_count = len(re.findall(r'SS_TASK_END:(SUCCESS|FAILED)', content))
                    if legacy_count > 0:
                        result.issues.append(LintIssue(
                            rule_id="RULE-011",
                            severity=Severity.HIGH,
                            file=result.file,
                            line=0,
                            message=f"使用旧格式SS_TASK_END:SUCCESS/FAILED，应升级到SS_TASK_END|id=...|status=...|elapsed_sec=...",
                            context="",
                            suggestion='display "SS_TASK_END|id=Txxx|status=ok|elapsed_sec=..."'
                        ))
                    else:
                        result.issues.append(LintIssue(
                            rule_id="RULE-011",
                            severity=Severity.CRITICAL,
                            file=result.file,
                            line=0,
                            message=f"缺少必需锚点: {anchor_name}",
                            context="",
                            suggestion=f'添加 display "{anchor_name}|..."'
                        ))
            
            # SS_DEP_CHECK 必须存在
            elif anchor_name == 'SS_DEP_CHECK' and count == 0:
                result.issues.append(LintIssue(
                    rule_id="RULE-011",
                    severity=Severity.CRITICAL,
                    file=result.file,
                    line=0,
                    message=f"缺少依赖检查锚点: {anchor_name}",
                    context="",
                    suggestion='添加 display "SS_DEP_CHECK|pkg=stata|source=built-in|status=ok"'
                ))
        
        result.anchor_counts = anchor_counts
    
    def _check_step_count(self, content: str, result: LintResult):
        """RULE-012: 检查步骤锚点数量"""
        step_begin_count = len(re.findall(r'SS_STEP_BEGIN\|step=', content))
        step_end_count = len(re.findall(r'SS_STEP_END\|step=', content))
        
        if step_begin_count < self.MIN_STEP_COUNT:
            result.issues.append(LintIssue(
                rule_id="RULE-012",
                severity=Severity.CRITICAL,
                file=result.file,
                line=0,
                message=f"步骤锚点不足: 需要至少{self.MIN_STEP_COUNT}个SS_STEP_BEGIN，当前{step_begin_count}个",
                context="",
                suggestion="添加 load/analysis/export 三个关键步骤的SS_STEP_BEGIN/END锚点"
            ))
        
        if step_begin_count != step_end_count:
            result.issues.append(LintIssue(
                rule_id="RULE-012",
                severity=Severity.WARNING,
                file=result.file,
                line=0,
                message=f"步骤锚点不匹配: {step_begin_count}个BEGIN vs {step_end_count}个END",
                context="",
                suggestion="确保每个SS_STEP_BEGIN都有对应的SS_STEP_END"
            ))
    
    def _check_metric_count(self, content: str, result: LintResult):
        """RULE-013: 检查指标数量"""
        metric_count = len(re.findall(r'SS_METRIC\|name=', content))
        
        if metric_count < self.MIN_METRIC_COUNT:
            result.issues.append(LintIssue(
                rule_id="RULE-013",
                severity=Severity.CRITICAL,
                file=result.file,
                line=0,
                message=f"指标锚点不足: 需要至少{self.MIN_METRIC_COUNT}个SS_METRIC，当前{metric_count}个",
                context="",
                suggestion="添加 n_obs/n_missing/task_success/elapsed_sec 四个必需指标"
            ))
    
    def _check_summary_count(self, content: str, result: LintResult):
        """RULE-014: 检查摘要数量"""
        summary_count = len(re.findall(r'SS_SUMMARY\|key=', content))
        
        if summary_count < self.MIN_SUMMARY_COUNT:
            result.issues.append(LintIssue(
                rule_id="RULE-014",
                severity=Severity.CRITICAL,
                file=result.file,
                line=0,
                message=f"摘要锚点不足: 需要至少{self.MIN_SUMMARY_COUNT}个SS_SUMMARY，当前{summary_count}个",
                context="",
                suggestion="添加至少3个 SS_SUMMARY|key=...|value=... 摘要行"
            ))
    
    def _check_output_declarations(self, content: str, lines: List[str], result: LintResult):
        """RULE-015: 检查输出声明"""
        # 计算输出操作数量（按“唯一输出目标”计数，避免 putexcel/file write 等重复写入导致误报）
        def _normalize_target(t: str) -> str:
            t = t.strip()
            if (t.startswith('"') and t.endswith('"')) or (t.startswith("'") and t.endswith("'")):
                t = t[1:-1].strip()
            return t

        # tempfile 声明的文件属于 Stata 临时文件，不应被视为“对外输出产物”
        tempfile_names: Set[str] = set()
        for m in re.finditer(r'^\s*tempfile\s+(.+)$', content, re.IGNORECASE | re.MULTILINE):
            for name in m.group(1).split():
                name = name.strip()
                if name:
                    tempfile_names.add(name)

        def _is_tempfile_target(t: str) -> bool:
            for mm in re.finditer(r'`([^\'\s]+)\'', t):
                if mm.group(1) in tempfile_names:
                    return True
            return False

        output_targets: Set[str] = set()

        # export delimited using "file.csv"
        for m in re.finditer(r'export\s+delimited\s+(?:using\s+)?["\']([^"\']+)["\']', content, re.IGNORECASE):
            t = _normalize_target(m.group(1))
            if not _is_tempfile_target(t):
                output_targets.add(t)

        # graph export "fig.png"
        for m in re.finditer(r'graph\s+export\s+["\']([^"\']+)["\']', content, re.IGNORECASE):
            t = _normalize_target(m.group(1))
            if not _is_tempfile_target(t):
                output_targets.add(t)

        # save "data.dta", replace / save data.dta, replace
        for m in re.finditer(r'^\s*save\s+([^,\s]+)', content, re.IGNORECASE | re.MULTILINE):
            t = _normalize_target(m.group(1))
            if not _is_tempfile_target(t):
                output_targets.add(t)

        # putexcel set "table.xlsx", replace
        for m in re.finditer(r'putexcel\s+set\s+["\']([^"\']+)["\']', content, re.IGNORECASE):
            output_targets.add(_normalize_target(m.group(1)))

        # file open fh using "outputs/manifest.txt", write replace
        for m in re.finditer(
            r'file\s+open\s+\w+\s+using\s+["\']([^"\']+)["\']\s*,[^\n]*\b(write|append)\b',
            content,
            re.IGNORECASE,
        ):
            output_targets.add(_normalize_target(m.group(1)))

        export_count = len(output_targets)
        
        # 计算SS_OUTPUT_FILE声明数量
        output_file_count = len(re.findall(r'SS_OUTPUT_FILE\|file=', content))
        
        if export_count > 0 and output_file_count == 0:
            result.issues.append(LintIssue(
                rule_id="RULE-015",
                severity=Severity.CRITICAL,
                file=result.file,
                line=0,
                message=f"缺少输出声明: 检测到{export_count}个输出操作，但无SS_OUTPUT_FILE锚点",
                context="",
                suggestion='每个输出文件后添加 display "SS_OUTPUT_FILE|file=xxx|type=table|desc=..."'
            ))
        elif export_count > output_file_count:
            result.issues.append(LintIssue(
                rule_id="RULE-015",
                severity=Severity.WARNING,
                file=result.file,
                line=0,
                message=f"输出声明可能不完整: {export_count}个输出操作，{output_file_count}个声明",
                context="",
                suggestion="确保每个输出文件都有对应的SS_OUTPUT_FILE声明"
            ))
    
    def _check_capture_rc(self, lines: List[str], result: LintResult):
        """RULE-021: 检查capture后是否检查_rc"""
        capture_lines = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            # 检测capture命令
            if re.match(r'^\s*capture\s+', line, re.IGNORECASE):
                capture_lines.append(i)
        
        # 检查每个capture后是否有_rc检查
        for cap_line in capture_lines:
            # 检查接下来5行是否有_rc检查
            found_rc_check = False
            for check_line in range(cap_line, min(cap_line + 6, len(lines) + 1)):
                if check_line <= len(lines):
                    line_content = lines[check_line - 1]
                    if '_rc' in line_content or 'if _rc' in line_content.lower():
                        found_rc_check = True
                        break
            
            if not found_rc_check:
                result.issues.append(LintIssue(
                    rule_id="RULE-021",
                    severity=Severity.HIGH,
                    file=result.file,
                    line=cap_line,
                    message="capture后未检查_rc（沉默失败）",
                    context=lines[cap_line - 1].strip()[:60] if cap_line <= len(lines) else "",
                    suggestion="capture后必须检查 if _rc 并输出 SS_RC|code=..."
                ))
    
    def _check_global_usage(self, lines: List[str], result: LintResult):
        """WARN-001: 检查全局变量使用"""
        global_pattern = re.compile(r'^\s*global\s+', re.IGNORECASE)
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            if global_pattern.match(line):
                result.issues.append(LintIssue(
                    rule_id="WARN-001",
                    severity=Severity.WARNING,
                    file=result.file,
                    line=i,
                    message="使用global变量",
                    context=line.strip()[:80],
                    suggestion="建议使用local变量避免全局污染"
                ))
    
    def _check_version_declaration(self, content: str, result: LintResult):
        """WARN-002: 检查版本声明"""
        if not re.search(r'^\s*version\s+\d+', content, re.MULTILINE):
            result.issues.append(LintIssue(
                rule_id="WARN-002",
                severity=Severity.WARNING,
                file=result.file,
                line=0,
                message="缺少version声明",
                context="",
                suggestion="添加 'version 18' 确保兼容性"
            ))
    
    def _check_community_deps(self, content: str, lines: List[str], result: LintResult):
        """RULE-020: 检查社区命令依赖与白名单"""
        used_community_cmds = []
        
        for i, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('*') or stripped.startswith('//'):
                continue
            
            for cmd in self.KNOWN_COMMUNITY_COMMANDS:
                # 检查命令是否被使用(作为行首或空格后)
                if re.search(rf'^\s*{cmd}\b|\b{cmd}\s+using', line, re.IGNORECASE):
                    used_community_cmds.append((cmd, i, line.strip()[:60]))
        
        if used_community_cmds:
            # 检查是否有SS_DEP_CHECK锚点
            has_dep_check = 'SS_DEP_CHECK|pkg=' in content
            
            for cmd, line_num, ctx in used_community_cmds:
                # 检查命令是否在白名单内
                if cmd.lower() not in self.WHITELISTED_COMMANDS:
                    result.issues.append(LintIssue(
                        rule_id="RULE-020",
                        severity=Severity.CRITICAL,
                        file=result.file,
                        line=line_num,
                        message=f"社区命令'{cmd}'不在白名单内",
                        context=ctx,
                        suggestion=f"将{cmd}添加到stata_dependencies.txt或使用白名单内的替代命令"
                    ))
                elif not has_dep_check:
                    result.issues.append(LintIssue(
                        rule_id="RULE-020",
                        severity=Severity.HIGH,
                        file=result.file,
                        line=line_num,
                        message=f"社区命令'{cmd}'未经SS_DEP_CHECK检测",
                        context=ctx,
                        suggestion=f'添加 display "SS_DEP_CHECK|pkg={cmd}|source=ssc|status=ok"'
                    ))
    
    def _check_error_dual_write(self, content: str, result: LintResult):
        """RULE-008: 检查错误锚点双写(兼容旧解析)"""
        has_ss_error = 'SS_ERROR:' in content
        has_ss_err = 'SS_ERR:' in content
        
        if has_ss_error and not has_ss_err:
            result.issues.append(LintIssue(
                rule_id="RULE-008",
                severity=Severity.WARNING,
                file=result.file,
                line=0,
                message="SS_ERROR存在但缺SS_ERR双写(兼容旧解析)",
                context="",
                suggestion="每个SS_ERROR后添加对应的SS_ERR行"
            ))
        
        if has_ss_err and not has_ss_error:
            result.issues.append(LintIssue(
                rule_id="RULE-008",
                severity=Severity.WARNING,
                file=result.file,
                line=0,
                message="SS_ERR存在但缺SS_ERROR(应同时存在)",
                context="",
                suggestion="每个SS_ERR前添加对应的SS_ERROR行"
            ))
    
    def lint_directory(self, dirpath: Path) -> List[LintResult]:
        """检查目录下所有do文件"""
        results = []
        for do_file in sorted(dirpath.glob("*.do")):
            result = self.lint_file(do_file)
            results.append(result)
            self.results.append(result)
        return results
    
    def get_summary(self) -> Dict:
        """获取汇总报告"""
        total_files = len(self.results)
        passed_files = sum(1 for r in self.results if r.passed)
        failed_files = total_files - passed_files
        total_critical = sum(r.critical_count for r in self.results)
        total_high = sum(r.high_count for r in self.results)
        total_warnings = sum(r.warning_count for r in self.results)
        
        return {
            "total_files": total_files,
            "passed_files": passed_files,
            "failed_files": failed_files,
            "total_critical": total_critical,
            "total_high": total_high,
            "total_warnings": total_warnings,
            "pass_rate": f"{passed_files/total_files*100:.1f}%" if total_files > 0 else "N/A"
        }
    
    def print_report(self, verbose: bool = False):
        """打印检查报告"""
        summary = self.get_summary()
        
        print("\n" + "="*70)
        print("DO LIBRARY LINT REPORT (v1.1)")
        print("="*70)
        print(f"总文件数:     {summary['total_files']}")
        print(f"通过文件数:   {summary['passed_files']}")
        print(f"失败文件数:   {summary['failed_files']}")
        print(f"CRITICAL数:   {summary['total_critical']}")
        print(f"HIGH数:       {summary['total_high']}")
        print(f"WARNING数:    {summary['total_warnings']}")
        print(f"通过率:       {summary['pass_rate']}")
        print("="*70)
        
        if summary['total_critical'] > 0:
            print("\n[X] CRITICAL ISSUES (CI MUST FAIL):")
            print("-"*70)
            for result in self.results:
                for issue in result.issues:
                    if issue.severity == Severity.CRITICAL:
                        print(f"\n[{issue.rule_id}] {Path(issue.file).name}:{issue.line}")
                        print(f"  Message: {issue.message}")
                        if issue.context:
                            print(f"  Context: {issue.context}")
                        print(f"  Fix: {issue.suggestion}")
        
        if summary['total_high'] > 0:
            print("\n[!] HIGH PRIORITY ISSUES (Should Fix):")
            print("-"*70)
            for result in self.results:
                for issue in result.issues:
                    if issue.severity == Severity.HIGH:
                        print(f"\n[{issue.rule_id}] {Path(issue.file).name}:{issue.line}")
                        print(f"  Message: {issue.message}")
                        if issue.context:
                            print(f"  Context: {issue.context}")
                        print(f"  Fix: {issue.suggestion}")
        
        if verbose and summary['total_warnings'] > 0:
            print("\n[i] WARNINGS:")
            print("-"*70)
            for result in self.results:
                for issue in result.issues:
                    if issue.severity == Severity.WARNING:
                        print(f"[{issue.rule_id}] {Path(issue.file).name}:{issue.line} - {issue.message}")
        
        print("\n" + "="*70)
        if summary['total_critical'] > 0 or summary['total_high'] > 0:
            print("RESULT: [X] FAILED - CI should block merge")
        elif summary['total_warnings'] > 0:
            print("RESULT: [!] PASSED WITH WARNINGS")
        else:
            print("RESULT: [OK] PASSED")
        print("="*70 + "\n")
    
    def to_json(self) -> str:
        """导出JSON报告"""
        report = {
            "summary": self.get_summary(),
            "results": [
                {
                    "file": r.file,
                    "passed": r.passed,
                    "critical_count": r.critical_count,
                    "warning_count": r.warning_count,
                    "issues": [
                        {
                            "rule_id": i.rule_id,
                            "severity": i.severity.value,
                            "line": i.line,
                            "message": i.message,
                            "context": i.context,
                            "suggestion": i.suggestion
                        }
                        for i in r.issues
                    ]
                }
                for r in self.results
            ]
        }
        return json.dumps(report, indent=2, ensure_ascii=False)


def main():
    parser = argparse.ArgumentParser(
        description="Do Library 自动门禁检查器",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )
    parser.add_argument("--path", type=str, help="要检查的目录路径")
    parser.add_argument("--file", type=str, help="要检查的单个文件")
    parser.add_argument("--output", type=str, help="输出JSON报告路径")
    parser.add_argument("--verbose", "-v", action="store_true", help="显示详细信息")
    parser.add_argument("--strict", action="store_true", default=True, help="严格模式")
    
    args = parser.parse_args()
    
    if not args.path and not args.file:
        parser.print_help()
        sys.exit(1)
    
    linter = DoLinter(strict=args.strict)
    
    if args.file:
        filepath = Path(args.file)
        if not filepath.exists():
            print(f"Error: File not found: {args.file}")
            sys.exit(1)
        linter.lint_file(filepath)
        linter.results.append(linter.lint_file(filepath))
    
    if args.path:
        dirpath = Path(args.path)
        if not dirpath.exists():
            print(f"Error: Directory not found: {args.path}")
            sys.exit(1)
        linter.lint_directory(dirpath)
    
    linter.print_report(verbose=args.verbose)
    
    if args.output:
        Path(args.output).write_text(linter.to_json(), encoding='utf-8')
        print(f"JSON report saved to: {args.output}")
    
    # 退出码
    summary = linter.get_summary()
    if summary['total_critical'] > 0:
        sys.exit(1)  # CI应失败
    elif summary['total_warnings'] > 0:
        sys.exit(0)  # 有警告但可通过
    else:
        sys.exit(0)  # 完全通过


if __name__ == "__main__":
    main()
