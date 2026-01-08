import { BarChart3 } from "lucide-react";

interface HeaderProps {
  onShowTips?: () => void;
}

export function Header({ onShowTips }: HeaderProps) {
  return (
    <header className="sticky top-0 z-50 transition-all duration-300 bg-white/60 backdrop-blur-xl border-b border-black/5">
      <div className="container mx-auto px-6 h-16 flex items-center justify-between">
        <div className="flex items-center gap-3">
          {/* G3 Premium Icon */}
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-blue-600 text-white shadow-md shadow-blue-600/20">
            <BarChart3 className="h-5 w-5" strokeWidth={3} />
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-xl font-bold tracking-tight text-slate-900 leading-none">Stata Service</span>
            <span className="px-1.5 py-0.5 rounded-[4px] bg-slate-100 border border-slate-200 text-[10px] font-extrabold text-slate-600 leading-none tracking-widest">PRO</span>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <button
            onClick={onShowTips}
            className="hidden md:block text-sm font-medium text-slate-500 hover:text-slate-900 transition-colors"
          >
            使用指南
          </button>
          <a href="#" className="hidden md:block text-sm font-medium text-slate-500 hover:text-slate-900 transition-colors">常见问题</a>
          <div className="h-4 w-px bg-slate-200 hidden md:block"></div>
          <div className="flex items-center gap-2">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span className="text-xs font-bold text-slate-600 tracking-wide">SYSTEM ONLINE</span>
          </div>
        </div>
      </div>
    </header>
  );
}
