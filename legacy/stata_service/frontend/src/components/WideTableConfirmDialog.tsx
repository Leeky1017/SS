/**
 * WideTableConfirmDialog - 宽表确认弹窗 (P5/P6: 数据格式检测增强)
 * 
 * 当用户选择的数据源包含宽表警告时，显示确认对话框，
 * 提醒用户可能需要进行数据转换。
 */

import { AlertTriangle, Table2, ArrowRight, Info } from "lucide-react";
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
} from "./ui/alert-dialog";
import { Badge } from "./ui/badge";
import type { DataSourceProfilePublic } from "@/api/stataService";

interface WideTableConfirmDialogProps {
    source: DataSourceProfilePublic | null;
    open: boolean;
    onConfirm: () => void;
    onCancel: () => void;
}

// 检查是否需要显示宽表警告
export function shouldShowWideTableWarning(source: DataSourceProfilePublic | null): boolean {
    if (!source || !source.warnings) return false;

    const wideWarnings = [
        "WIDE_YEAR_FORMAT",
        "WIDE_TABLE_NEEDS_RESHAPE",
        "STACKED_WIDE_YEAR_LIKELY",
    ];

    return source.warnings.some((w) => wideWarnings.includes(w));
}

// 检查是否有多数据块警告
export function hasMultiDataBlockWarning(source: DataSourceProfilePublic | null): boolean {
    if (!source || !source.warnings) return false;
    return source.warnings.includes("MULTI_DATA_BLOCK_SUSPECTED");
}

export function WideTableConfirmDialog({
    source,
    open,
    onConfirm,
    onCancel,
}: WideTableConfirmDialogProps) {
    if (!source) return null;

    const isWideTable = shouldShowWideTableWarning(source);
    const hasMultiBlock = hasMultiDataBlockWarning(source);

    // 提取年份列数量
    const wideYearColsCount = source.shape?.wide_year_columns?.length || 0;

    return (
        <AlertDialog open={open} onOpenChange={(o) => !o && onCancel()}>
            <AlertDialogContent className="max-w-lg">
                <AlertDialogHeader>
                    <AlertDialogTitle className="flex items-center gap-2">
                        <AlertTriangle className="h-5 w-5 text-yellow-500" />
                        数据格式提醒
                    </AlertDialogTitle>
                    <AlertDialogDescription asChild>
                        <div className="space-y-4">
                            {/* 基本信息 */}
                            <div className="flex items-center gap-4 p-3 bg-muted rounded-lg">
                                <Table2 className="h-8 w-8 text-muted-foreground" />
                                <div>
                                    <div className="font-medium">
                                        {source.sheet_name
                                            ? `${source.file_name} / ${source.sheet_name}`
                                            : source.file_name}
                                    </div>
                                    <div className="text-sm text-muted-foreground">
                                        {source.shape?.n_rows_sample || 0} 行 × {source.shape?.n_cols || 0} 列
                                    </div>
                                </div>
                            </div>

                            {/* 宽表警告 */}
                            {isWideTable && (
                                <div className="p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg border border-yellow-200 dark:border-yellow-800">
                                    <div className="flex items-start gap-2">
                                        <AlertTriangle className="h-4 w-4 text-yellow-600 mt-0.5" />
                                        <div className="text-sm">
                                            <p className="font-medium text-yellow-800 dark:text-yellow-200">
                                                检测到宽表格式
                                            </p>
                                            <p className="text-yellow-700 dark:text-yellow-300 mt-1">
                                                该数据源包含 <strong>{wideYearColsCount}</strong> 个年份列
                                                （如 2010、2011、2012...），属于宽表格式。
                                            </p>
                                            <p className="text-yellow-700 dark:text-yellow-300 mt-1">
                                                如需进行面板数据分析，系统会尝试自动将其转换为长表格式。
                                            </p>
                                        </div>
                                    </div>

                                    {/* 格式示意 */}
                                    <div className="flex items-center gap-2 mt-3 text-xs">
                                        <Badge variant="outline" className="bg-white dark:bg-gray-800">
                                            宽表: ID | 2010 | 2011 | 2012
                                        </Badge>
                                        <ArrowRight className="h-3 w-3" />
                                        <Badge variant="outline" className="bg-white dark:bg-gray-800">
                                            长表: ID | Year | Value
                                        </Badge>
                                    </div>
                                </div>
                            )}

                            {/* 多数据块警告 */}
                            {hasMultiBlock && (
                                <div className="p-3 bg-orange-50 dark:bg-orange-900/20 rounded-lg border border-orange-200 dark:border-orange-800">
                                    <div className="flex items-start gap-2">
                                        <Info className="h-4 w-4 text-orange-600 mt-0.5" />
                                        <div className="text-sm">
                                            <p className="font-medium text-orange-800 dark:text-orange-200">
                                                可能包含多个数据区域
                                            </p>
                                            <p className="text-orange-700 dark:text-orange-300 mt-1">
                                                该 Sheet 的前几行包含较多空值，可能存在标题区域或多个不连续的数据块。
                                                建议检查数据格式是否符合预期。
                                            </p>
                                        </div>
                                    </div>
                                </div>
                            )}

                            {/* 确认提示 */}
                            <p className="text-sm text-muted-foreground">
                                确认选择此数据源继续分析？如分析效果不佳，建议先在 Excel 中整理数据格式。
                            </p>
                        </div>
                    </AlertDialogDescription>
                </AlertDialogHeader>

                <AlertDialogFooter>
                    <AlertDialogCancel onClick={onCancel}>
                        选择其他数据源
                    </AlertDialogCancel>
                    <AlertDialogAction onClick={onConfirm}>
                        仍然使用此数据源
                    </AlertDialogAction>
                </AlertDialogFooter>
            </AlertDialogContent>
        </AlertDialog>
    );
}

export default WideTableConfirmDialog;
