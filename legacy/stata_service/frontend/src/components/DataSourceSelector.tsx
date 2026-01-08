/**
 * DataSourceSelector - Sheet 选择器组件 (P4: Sheet 选择透明化)
 * 
 * 当 Excel 文件包含多个 Sheet 时，显示可选择的数据源列表，
 * 允许用户查看各 Sheet 的信息并手动选择主数据源。
 */

import { useState } from "react";
import { ChevronDown, Check, AlertTriangle, FileSpreadsheet } from "lucide-react";
import { Button } from "./ui/button";
import {
    DropdownMenu,
    DropdownMenuContent,
    DropdownMenuItem,
    DropdownMenuTrigger,
    DropdownMenuSeparator,
} from "./ui/dropdown-menu";
import { Badge } from "./ui/badge";
import type { DataSourceProfilePublic } from "@/api/stataService";

interface DataSourceSelectorProps {
    dataSources: DataSourceProfilePublic[];
    selectedSourceId: string | null;
    isAutoSelected?: boolean;
    onSelectSource: (sourceId: string) => void;
    isLoading?: boolean;
}

// 警告类型映射
const WARNING_LABELS: Record<string, { label: string; severity: "warning" | "error" }> = {
    WIDE_YEAR_FORMAT: { label: "宽表格式", severity: "warning" },
    WIDE_TABLE_NEEDS_RESHAPE: { label: "需要转换", severity: "warning" },
    MULTI_DATA_BLOCK_SUSPECTED: { label: "多数据块", severity: "error" },
    STACKED_WIDE_YEAR_LIKELY: { label: "堆叠宽表", severity: "warning" },
};

export function DataSourceSelector({
    dataSources,
    selectedSourceId,
    isAutoSelected = true,
    onSelectSource,
    isLoading = false,
}: DataSourceSelectorProps) {
    const [open, setOpen] = useState(false);

    // 只有多个数据源时才显示选择器
    if (!dataSources || dataSources.length <= 1) {
        return null;
    }

    const selectedSource = dataSources.find((s) => s.source_id === selectedSourceId);

    // 按评分排序（推荐的在前）
    const sortedSources = [...dataSources].sort((a, b) => b.score - a.score);
    const recommendedSource = sortedSources[0];

    const getSourceLabel = (source: DataSourceProfilePublic) => {
        if (source.sheet_name) {
            return `${source.file_name} / ${source.sheet_name}`;
        }
        return source.file_name;
    };

    const hasWarnings = (source: DataSourceProfilePublic) => {
        return source.warnings && source.warnings.length > 0;
    };

    const getWarningBadges = (source: DataSourceProfilePublic) => {
        if (!source.warnings) return [];
        return source.warnings
            .map((w) => WARNING_LABELS[w])
            .filter(Boolean)
            .slice(0, 2);
    };

    return (
        <div className="flex items-center gap-2 p-3 bg-muted/50 rounded-lg border">
            <FileSpreadsheet className="h-4 w-4 text-muted-foreground" />
            <span className="text-sm text-muted-foreground">数据源：</span>

            <DropdownMenu open={open} onOpenChange={setOpen}>
                <DropdownMenuTrigger asChild>
                    <Button
                        variant="outline"
                        size="sm"
                        className="flex items-center gap-2 min-w-[200px] justify-between"
                        disabled={isLoading}
                    >
                        <span className="truncate max-w-[180px]">
                            {selectedSource ? getSourceLabel(selectedSource) : "选择数据源"}
                        </span>
                        <ChevronDown className="h-4 w-4 opacity-50" />
                    </Button>
                </DropdownMenuTrigger>

                <DropdownMenuContent align="start" className="w-[320px]">
                    {sortedSources.map((source) => {
                        const isSelected = source.source_id === selectedSourceId;
                        const isRecommended = source.source_id === recommendedSource.source_id;
                        const warnings = getWarningBadges(source);

                        return (
                            <DropdownMenuItem
                                key={source.source_id}
                                onClick={() => {
                                    onSelectSource(source.source_id);
                                    setOpen(false);
                                }}
                                className="flex flex-col items-start gap-1 py-2 cursor-pointer"
                            >
                                <div className="flex items-center gap-2 w-full">
                                    {isSelected && <Check className="h-4 w-4 text-primary" />}
                                    {!isSelected && <div className="w-4" />}

                                    <span className="font-medium truncate flex-1">
                                        {getSourceLabel(source)}
                                    </span>

                                    {isRecommended && (
                                        <Badge variant="secondary" className="text-xs">
                                            推荐
                                        </Badge>
                                    )}
                                </div>

                                <div className="flex items-center gap-2 ml-6 text-xs text-muted-foreground">
                                    <span>{source.shape?.n_rows_sample || 0} 行</span>
                                    <span>·</span>
                                    <span>{source.shape?.n_cols || source.cols_preview?.length || 0} 列</span>

                                    {source.shape?.is_long_panel_like && (
                                        <>
                                            <span>·</span>
                                            <span className="text-green-600">面板数据</span>
                                        </>
                                    )}

                                    {warnings.map((w, i) => (
                                        <Badge
                                            key={i}
                                            variant={w.severity === "error" ? "destructive" : "outline"}
                                            className="text-xs h-5"
                                        >
                                            {w.label}
                                        </Badge>
                                    ))}
                                </div>
                            </DropdownMenuItem>
                        );
                    })}

                    {isAutoSelected && (
                        <>
                            <DropdownMenuSeparator />
                            <div className="px-2 py-1.5 text-xs text-muted-foreground">
                                <AlertTriangle className="h-3 w-3 inline mr-1" />
                                当前为系统自动选择，您可手动切换
                            </div>
                        </>
                    )}
                </DropdownMenuContent>
            </DropdownMenu>

            {isAutoSelected && (
                <Badge variant="outline" className="text-xs">
                    自动选择
                </Badge>
            )}

            {hasWarnings(selectedSource!) && (
                <AlertTriangle className="h-4 w-4 text-yellow-500" />
            )}
        </div>
    );
}

export default DataSourceSelector;
