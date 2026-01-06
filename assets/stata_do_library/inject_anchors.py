#!/usr/bin/env python3
"""
inject_anchors.py - 批量注入SS_*锚点到Do文件

功能：
1. 在log using后注入 SS_TASK_START
2. 在log close前注入 SS_TASK_END
3. 在每个export/save后注入 SS_OUTPUT_FILE
4. 生成注入报告

用法:
    python inject_anchors.py --path tasks/do/ --dry-run   # 预览不修改
    python inject_anchors.py --path tasks/do/             # 实际执行
"""

import argparse
import json
import re
import shutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Tuple


class AnchorInjector:
    """SS_*锚点注入器"""
    
    def __init__(self, tasks_index_path: Path):
        self.tasks_index = self._load_tasks_index(tasks_index_path)
        self.injection_log: List[Dict] = []
    
    def _load_tasks_index(self, path: Path) -> Dict:
        """加载任务索引"""
        if not path.exists():
            return {}
        with open(path, 'r', encoding='utf-8') as f:
            tasks = json.load(f)
        return {t["id"]: t for t in tasks}
    
    def inject_file(self, filepath: Path, dry_run: bool = True) -> Tuple[bool, str, int]:
        """
        对单个do文件注入锚点
        
        Returns:
            (success, message, injection_count)
        """
        try:
            content = filepath.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            content = filepath.read_text(encoding='gbk')
        
        original_content = content
        injection_count = 0
        
        # 提取task_id
        task_id = self._extract_task_id(filepath, content)
        if not task_id:
            return False, "无法提取task_id", 0
        
        # 获取任务元数据
        task_meta = self.tasks_index.get(task_id, {})
        outputs = task_meta.get("outputs", [])
        
        # 1. 注入 SS_TASK_START (在 log using 后)
        content, count1 = self._inject_task_start(content, task_id)
        injection_count += count1
        
        # 2. 注入 SS_TASK_END (在 log close 前)
        content, count2 = self._inject_task_end(content)
        injection_count += count2
        
        # 3. 注入 SS_OUTPUT_FILE (在每个输出操作后)
        content, count3 = self._inject_output_files(content, task_id, outputs)
        injection_count += count3
        
        # 4. 注入 SS_ERROR (在每个 exit 前)
        content, count4 = self._inject_error_anchors(content)
        injection_count += count4
        
        if content == original_content:
            return True, "无需修改（已有锚点或无匹配位置）", 0
        
        if not dry_run:
            # 备份原文件
            backup_path = filepath.with_suffix('.do.bak')
            shutil.copy2(filepath, backup_path)
            # 写入新内容
            filepath.write_text(content, encoding='utf-8')
        
        self.injection_log.append({
            "file": filepath.name,
            "task_id": task_id,
            "injections": injection_count,
            "dry_run": dry_run
        })
        
        return True, f"注入 {injection_count} 处锚点", injection_count
    
    def _extract_task_id(self, filepath: Path, content: str) -> str:
        """从文件名或内容提取task_id"""
        # 优先从文件名提取
        filename = filepath.stem
        match = re.match(r'(T\d+)', filename)
        if match:
            return match.group(1)
        
        # 从内容提取
        match = re.search(r'Task ID:\s*(T\d+)', content)
        if match:
            return match.group(1)
        
        return ""
    
    def _inject_task_start(self, content: str, task_id: str) -> Tuple[str, int]:
        """注入SS_TASK_START"""
        if "SS_TASK_START" in content:
            return content, 0
        
        # 在 log using 行后插入
        pattern = r'(log using\s+"result\.log"[^\n]*\n)'
        anchor_block = f'''
* ============ SS_* 锚点: 任务开始 ============
display "SS_TASK_START:{task_id}"
display "SS_TASK_VERSION:2.0.0"

'''
        new_content, count = re.subn(pattern, r'\1' + anchor_block, content, count=1)
        return new_content, count
    
    def _inject_task_end(self, content: str) -> Tuple[str, int]:
        """注入SS_TASK_END"""
        if "SS_TASK_END" in content:
            return content, 0
        
        # 在 log close 行前插入
        pattern = r'(\n)(log close\s*\n?)'
        anchor_block = '''
* ============ SS_* 锚点: 任务结束 ============
display "SS_TASK_END:SUCCESS"

'''
        new_content, count = re.subn(pattern, anchor_block + r'\2', content, count=1)
        return new_content, count
    
    def _inject_output_files(self, content: str, task_id: str, outputs: List[str]) -> Tuple[str, int]:
        """注入SS_OUTPUT_FILE"""
        if "SS_OUTPUT_FILE" in content:
            return content, 0
        
        total_count = 0
        
        # 处理 export delimited
        pattern = r'(export delimited using\s+"([^"]+)"[^\n]*\n)'
        def replace_export(match):
            nonlocal total_count
            total_count += 1
            filename = match.group(2)
            return match.group(0) + f'display "SS_OUTPUT_FILE:{filename}"\n'
        content = re.sub(pattern, replace_export, content)
        
        # 处理 save
        pattern = r'(save\s+"([^"]+)"[^\n]*\n)'
        def replace_save(match):
            nonlocal total_count
            total_count += 1
            filename = match.group(2)
            return match.group(0) + f'display "SS_OUTPUT_FILE:{filename}"\n'
        content = re.sub(pattern, replace_save, content)
        
        # 处理 graph export
        pattern = r'(graph export\s+"([^"]+)"[^\n]*\n)'
        def replace_graph(match):
            nonlocal total_count
            total_count += 1
            filename = match.group(2)
            return match.group(0) + f'display "SS_OUTPUT_FILE:{filename}"\n'
        content = re.sub(pattern, replace_graph, content)
        
        return content, total_count
    
    def _inject_error_anchors(self, content: str) -> Tuple[str, int]:
        """注入SS_ERROR（在exit前）"""
        if "SS_ERROR" in content:
            return content, 0
        
        total_count = 0
        
        # 查找 exit 200 等模式，在其前面注入SS_ERROR
        pattern = r'(\n\s*)(exit\s+(\d+)\s*\n)'
        def replace_exit(match):
            nonlocal total_count
            total_count += 1
            indent = match.group(1)
            exit_code = match.group(3)
            error_anchor = f'{indent}display "SS_ERROR:{exit_code}:Task failed with error code {exit_code}"\n'
            error_anchor += f'{indent}display "SS_TASK_END:FAILED"\n'
            return error_anchor + match.group(0)
        
        content = re.sub(pattern, replace_exit, content)
        return content, total_count
    
    def inject_directory(self, dirpath: Path, dry_run: bool = True) -> Dict:
        """批量注入目录下所有do文件"""
        results = {
            "total": 0,
            "success": 0,
            "failed": 0,
            "skipped": 0,
            "total_injections": 0,
            "files": []
        }
        
        for do_file in sorted(dirpath.glob("*.do")):
            # 跳过备份文件和samples目录
            if do_file.suffix == '.bak' or 'samples' in str(do_file):
                continue
            
            results["total"] += 1
            success, message, count = self.inject_file(do_file, dry_run)
            
            results["files"].append({
                "file": do_file.name,
                "success": success,
                "message": message,
                "injections": count
            })
            
            if success:
                if count > 0:
                    results["success"] += 1
                    results["total_injections"] += count
                else:
                    results["skipped"] += 1
            else:
                results["failed"] += 1
        
        return results
    
    def print_report(self, results: Dict, dry_run: bool):
        """打印注入报告"""
        mode = "[预览模式]" if dry_run else "[实际执行]"
        
        print("\n" + "="*70)
        print(f"SS_* 锚点注入报告 {mode}")
        print("="*70)
        print(f"扫描文件数:   {results['total']}")
        print(f"成功注入:     {results['success']}")
        print(f"跳过(已有):   {results['skipped']}")
        print(f"失败:         {results['failed']}")
        print(f"总注入数:     {results['total_injections']}")
        print("="*70)
        
        if results['success'] > 0:
            print("\n已注入文件:")
            print("-"*70)
            for f in results['files']:
                if f['injections'] > 0:
                    print(f"  {f['file']}: {f['injections']} 处锚点")
        
        if results['failed'] > 0:
            print("\n失败文件:")
            print("-"*70)
            for f in results['files']:
                if not f['success']:
                    print(f"  {f['file']}: {f['message']}")
        
        print("\n" + "="*70)
        if dry_run:
            print("这是预览模式，未实际修改文件。")
            print("确认无误后，运行: python inject_anchors.py --path tasks/do/")
        else:
            print("注入完成！原文件已备份为 *.do.bak")
        print("="*70 + "\n")


def main():
    parser = argparse.ArgumentParser(description="批量注入SS_*锚点到Do文件")
    parser.add_argument("--path", type=str, required=True, help="Do文件目录")
    parser.add_argument("--dry-run", action="store_true", help="预览模式，不实际修改")
    parser.add_argument("--output", type=str, help="输出JSON报告路径")
    
    args = parser.parse_args()
    
    do_path = Path(args.path)
    if not do_path.exists():
        print(f"错误: 目录不存在 {args.path}")
        return 1
    
    # 查找tasks_index.json
    tasks_index_path = do_path.parent / "tasks_index.json"
    
    injector = AnchorInjector(tasks_index_path)
    
    # 执行注入
    results = injector.inject_directory(do_path, dry_run=args.dry_run)
    
    # 打印报告
    injector.print_report(results, args.dry_run)
    
    # 输出JSON报告
    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
        print(f"JSON报告已保存: {args.output}")
    
    return 0 if results['failed'] == 0 else 1


if __name__ == "__main__":
    exit(main())
