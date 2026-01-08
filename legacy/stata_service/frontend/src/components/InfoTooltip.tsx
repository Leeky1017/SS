import { Info } from "lucide-react";
import { useState, useRef, useEffect } from "react";

interface InfoTooltipProps {
    content: React.ReactNode;
    className?: string;
}

/**
 * G3 Info Tooltip: Shows ⓘ icon that reveals content on hover
 * Compact UI that doesn't take up space until user hovers
 */
export function InfoTooltip({ content, className = "" }: InfoTooltipProps) {
    const [isVisible, setIsVisible] = useState(false);
    const [position, setPosition] = useState<"top" | "bottom">("bottom");
    const triggerRef = useRef<HTMLDivElement>(null);

    useEffect(() => {
        if (isVisible && triggerRef.current) {
            const rect = triggerRef.current.getBoundingClientRect();
            const spaceBelow = window.innerHeight - rect.bottom;
            const spaceAbove = rect.top;

            if (spaceBelow < 250 && spaceAbove > spaceBelow) {
                setPosition("top");
            } else {
                setPosition("bottom");
            }
        }
    }, [isVisible]);

    return (
        <div
            ref={triggerRef}
            className={`relative inline-flex items-center ${className}`}
            onMouseEnter={() => setIsVisible(true)}
            onMouseLeave={() => setIsVisible(false)}
        >
            <button
                type="button"
                onClick={(e) => {
                    e.preventDefault();
                    e.stopPropagation();
                    setIsVisible(!isVisible);
                }}
                className="flex items-center justify-center w-5 h-5 rounded-full bg-blue-100 hover:bg-blue-200 text-blue-600 transition-colors cursor-help border border-blue-200"
                aria-label="更多信息"
            >
                <Info className="w-3 h-3" />
            </button>

            {/* Tooltip content - show on hover or click */}
            <div
                className={`
                    absolute z-[100] w-72 p-3
                    bg-white rounded-lg shadow-2xl border border-slate-200
                    text-sm text-slate-700
                    transition-all duration-200 ease-out
                    ${isVisible
                        ? "opacity-100 visible translate-y-0"
                        : "opacity-0 invisible translate-y-1"
                    }
                    ${position === "top"
                        ? "bottom-full mb-2 left-1/2 -translate-x-1/2"
                        : "top-full mt-2 left-1/2 -translate-x-1/2"
                    }
                `}
                role="tooltip"
                style={{ pointerEvents: isVisible ? "auto" : "none" }}
            >
                {/* Arrow */}
                <div
                    className={`
                        absolute w-2 h-2 bg-white border-slate-200 rotate-45
                        left-1/2 -translate-x-1/2
                        ${position === "top"
                            ? "bottom-[-4px] border-r border-b"
                            : "top-[-4px] border-l border-t"
                        }
                    `}
                />
                <div className="relative z-10">
                    {content}
                </div>
            </div>
        </div>
    );
}
