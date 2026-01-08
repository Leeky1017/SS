import { ShieldCheck } from "lucide-react";

export function Hero() {
  return (
    <div className="relative pt-16 pb-8">
      <div className="container mx-auto px-6 text-center relative z-10">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-100 text-blue-600 text-xs font-bold uppercase tracking-wider mb-6 shadow-sm">
          <ShieldCheck className="w-3 h-3" />
          企业级统计分析托管服务
        </div>

        <h1 className="text-4xl md:text-5xl font-extrabold text-slate-900 mb-6 leading-[1.2] tracking-tight">
          面向金融与医学研究的<br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-600">自动化 Stata 分析系统</span>
        </h1>

        <p className="text-lg text-slate-500 max-w-2xl mx-auto leading-relaxed font-light">
          上传数据，描述需求，系统自动完成回归分析与稳健性检验。
        </p>
      </div>
    </div>
  );
}
