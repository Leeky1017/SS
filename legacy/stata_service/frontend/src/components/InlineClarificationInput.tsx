/**
 * InlineClarificationInput - 内联澄清输入组件
 * 
 * 每个 open_unknown 下方配一个独立的澄清输入框，
 * 支持下拉选择模式和文本输入模式。
 */

import { useEffect, useState } from "react";
import { Check, ChevronDown } from "lucide-react";
import { Button } from "./ui/button";

interface InlineClarificationInputProps {
    /** unknown.field - 字段路径 */
    field: string;
    /** 候选值列表（如有） */
    candidates?: string[];
    /** 建议默认值 */
    suggestedDefault?: string;
    /** 已选择的值 */
    value?: string;
    /** 值变化回调 */
    onChange: (value: string) => void;
    /** 是否禁用 */
    disabled?: boolean;
}

export function InlineClarificationInput({
    field,
    candidates,
    suggestedDefault,
    value,
    onChange,
    disabled = false,
}: InlineClarificationInputProps) {
    const [inputValue, setInputValue] = useState(value || "");
    const [isOpen, setIsOpen] = useState(false);

    useEffect(() => {
        setInputValue(value || "");
    }, [value]);

    const hasFilledValue = inputValue.trim() !== "";
    const hasCandidates = candidates && candidates.length > 0;

    const handleSelect = (candidate: string) => {
        setInputValue(candidate);
        onChange(candidate);
        setIsOpen(false);
    };

    const handleInputChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        const newValue = e.target.value;
        setInputValue(newValue);
        onChange(newValue);
    };

    const handleUseSuggested = () => {
        if (suggestedDefault) {
            setInputValue(suggestedDefault);
            onChange(suggestedDefault);
        }
    };

    const handleClear = () => {
        setInputValue("");
        onChange("");
        setIsOpen(false);
    };

    return (
        <div className="mt-3 space-y-2">
            <div className="flex items-center gap-2 text-xs text-muted-foreground">
                <span>请选择或输入：</span>
                {hasFilledValue && (
                    <span className="inline-flex items-center gap-1 text-green-600">
                        <Check className="h-3 w-3" />
                        已填写
                    </span>
                )}
            </div>

            {hasCandidates ? (
                /* 下拉选择模式 */
                <div className="relative">
                    <button
                        type="button"
                        onClick={() => !disabled && setIsOpen(!isOpen)}
                        disabled={disabled}
                        className="w-full flex items-center justify-between px-3 py-2 border rounded-md bg-white text-sm hover:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                        <span className={hasFilledValue ? "text-foreground" : "text-muted-foreground"}>
                            {hasFilledValue ? inputValue : "请选择..."}
                        </span>
                        <ChevronDown className="h-4 w-4 opacity-50" />
                    </button>

                    {isOpen && (
                        <div className="absolute z-10 w-full mt-1 bg-white border rounded-md shadow-lg max-h-48 overflow-y-auto">
                            {!disabled && (
                                <button
                                    type="button"
                                    onClick={handleClear}
                                    className="w-full px-3 py-2 text-left text-sm hover:bg-gray-50 focus:bg-gray-100 focus:outline-none"
                                >
                                    清空 / 取消选择
                                </button>
                            )}
                            {!disabled && <div className="border-t border-gray-100" />}
                            {candidates.map((candidate, idx) => (
                                <button
                                    key={`${field}-${idx}`}
                                    type="button"
                                    onClick={() => handleSelect(candidate)}
                                    className="w-full px-3 py-2 text-left text-sm hover:bg-blue-50 focus:bg-blue-100 focus:outline-none flex items-center justify-between"
                                >
                                    <span className="truncate">{candidate}</span>
                                    {inputValue === candidate && <Check className="h-4 w-4 text-blue-600" />}
                                </button>
                            ))}
                        </div>
                    )}
                </div>
            ) : (
                /* 文本输入模式 */
                <input
                    type="text"
                    value={inputValue}
                    onChange={handleInputChange}
                    disabled={disabled}
                    placeholder="请输入..."
                    className="w-full px-3 py-2 border rounded-md text-sm focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                />
            )}

            {/* 快捷操作：使用建议值 / 清空 */}
            {(!disabled && (suggestedDefault || hasFilledValue)) && (
                <div className="flex flex-wrap items-center gap-2">
                    {suggestedDefault && suggestedDefault !== inputValue && (
                        <Button
                            type="button"
                            variant="outline"
                            size="sm"
                            onClick={handleUseSuggested}
                            disabled={disabled}
                            className="text-xs"
                        >
                            使用建议值：{suggestedDefault}
                        </Button>
                    )}
                    {hasFilledValue && (
                        <Button
                            type="button"
                            variant="ghost"
                            size="sm"
                            onClick={handleClear}
                            disabled={disabled}
                            className="text-xs"
                        >
                            清空
                        </Button>
                    )}
                </div>
            )}
        </div>
    );
}

export default InlineClarificationInput;
