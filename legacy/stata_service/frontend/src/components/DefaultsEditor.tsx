import { Settings } from "lucide-react";
import { Button } from "./ui/button";
import type { DefaultValueItem } from "@/api/stataService";

interface DefaultsEditorProps {
    defaults: DefaultValueItem[];
    overrides: Record<string, unknown>;
    onChange: (overrides: Record<string, unknown>) => void;
}

function toJsonKey(value: unknown): string {
    try {
        return JSON.stringify(value);
    } catch {
        return "null";
    }
}

function fromJsonKey(value: string): unknown {
    try {
        return JSON.parse(value);
    } catch {
        return value;
    }
}

function isStringArray(value: unknown): value is string[] {
    return Array.isArray(value) && value.every((v) => typeof v === "string");
}

function parseStringList(input: string): string[] {
    const raw = String(input || "").replace(/，/g, ",");
    const parts = raw
        .split(/[,\n\t ]+/)
        .map((x) => x.trim())
        .filter((x) => x.length > 0);
    return Array.from(new Set(parts));
}

export function DefaultsEditor({ defaults, overrides, onChange }: DefaultsEditorProps) {
    if (!defaults || defaults.length === 0) return null;

    const updateField = (field: string, value: unknown) => {
        onChange({
            ...overrides,
            [field]: value,
        });
    };

    const resetField = (field: string) => {
        const next = { ...overrides };
        delete next[field];
        onChange(next);
    };

    return (
        <div className="bg-muted/50 rounded-xl p-5 border border-border">
            <div className="flex items-center justify-between mb-4">
                <h4 className="text-sm font-bold text-foreground flex items-center gap-2">
                    <Settings className="w-4 h-4 text-muted-foreground" />
                    分析参数预设 (Analysis Assumptions)
                </h4>
                <span className="text-xs text-muted-foreground">点击卡片可调整</span>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                {defaults.map((item) => {
                    const currentValue = overrides[item.field] ?? item.default_value;
                    const hasOverride = Object.prototype.hasOwnProperty.call(overrides, item.field);
                    const options = item.options || [];
                    const isArray = isStringArray(currentValue);
                    const hasOptions = options.length > 0;

                    return (
                        <div
                            key={item.field}
                            className="p-3 bg-card rounded-lg border border-border shadow-sm hover:border-primary/50 transition-colors group"
                        >
                            <div className="text-[10px] uppercase text-muted-foreground font-bold mb-1 tracking-wide">
                                {item.display_name}
                            </div>
                            <div className="text-sm font-bold text-foreground">
                                {item.default_label}
                            </div>
                            <div
                                className="mt-1 text-xs text-muted-foreground leading-snug whitespace-pre-wrap"
                                title={item.reason}
                            >
                                {item.reason}
                            </div>

                            {/* Show override badge and reset */}
                            {hasOverride && (
                                <div className="mt-2 flex items-center gap-2">
                                    <span className="text-xs px-2 py-0.5 rounded-full bg-primary/10 text-primary border border-primary/20">
                                        已修改
                                    </span>
                                    <Button
                                        type="button"
                                        variant="ghost"
                                        size="sm"
                                        className="h-6 text-xs"
                                        onClick={() => resetField(item.field)}
                                    >
                                        还原
                                    </Button>
                                </div>
                            )}

                            {/* Editable dropdown (hidden by default, shown on hover/click) */}
                            {item.editable && hasOptions && !isArray && (
                                <div className="mt-2 hidden group-hover:block">
                                    <select
                                        className="w-full border border-input rounded-md px-2 py-1 text-xs bg-card"
                                        value={toJsonKey(currentValue)}
                                        onChange={(e) => updateField(item.field, fromJsonKey(e.target.value))}
                                    >
                                        {options.map((opt) => (
                                            <option key={toJsonKey(opt.value)} value={toJsonKey(opt.value)}>
                                                {opt.label}
                                            </option>
                                        ))}
                                    </select>
                                </div>
                            )}

                            {/* Multi-select buttons for array values */}
                            {item.editable && hasOptions && isArray && (
                                <div className="mt-2 flex flex-wrap gap-1">
                                    {options.map((opt) => {
                                        const val = String(opt.value);
                                        const isNoneOpt = val === "none";
                                        const selected = isNoneOpt
                                            ? (currentValue as string[]).length === 0
                                            : (currentValue as string[]).includes(val);

                                        return (
                                            <Button
                                                key={toJsonKey(opt.value)}
                                                type="button"
                                                variant={selected ? "default" : "outline"}
                                                size="sm"
                                                className="h-6 text-xs px-2"
                                                onClick={() => {
                                                    if (isNoneOpt) {
                                                        updateField(item.field, []);
                                                        return;
                                                    }
                                                    const arr = currentValue as string[];
                                                    const next = arr.length === 0 ? [val] : [...arr];
                                                    const idx = next.indexOf(val);
                                                    if (idx >= 0) {
                                                        next.splice(idx, 1);
                                                    } else {
                                                        next.push(val);
                                                    }
                                                    updateField(item.field, next);
                                                }}
                                            >
                                                {opt.label}
                                            </Button>
                                        );
                                    })}
                                </div>
                            )}

                            {/* Free-text editor when no options are provided */}
                            {item.editable && !hasOptions && (
                                <div className="mt-2">
                                    {isArray ? (
                                        <input
                                            className="w-full border border-input rounded-md px-2 py-1 text-xs bg-card"
                                            value={(currentValue as string[]).join(", ")}
                                            placeholder="用逗号/空格分隔多个值；留空表示不选择"
                                            onChange={(e) => updateField(item.field, parseStringList(e.target.value))}
                                        />
                                    ) : (
                                        <input
                                            className="w-full border border-input rounded-md px-2 py-1 text-xs bg-card"
                                            value={
                                                currentValue === null || currentValue === undefined ? "" : String(currentValue)
                                            }
                                            placeholder="请输入（留空表示不设置）"
                                            onChange={(e) => updateField(item.field, e.target.value)}
                                        />
                                    )}
                                    {hasOverride && (
                                        <div className="mt-1">
                                            <Button
                                                type="button"
                                                variant="ghost"
                                                size="sm"
                                                className="h-6 text-xs"
                                                onClick={() => updateField(item.field, isArray ? [] : "")}
                                            >
                                                清空
                                            </Button>
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>
        </div>
    );
}
