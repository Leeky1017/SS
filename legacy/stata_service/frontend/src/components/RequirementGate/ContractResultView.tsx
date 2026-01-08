/**
 * Contract Result View Component (P6)
 * 
 * 冻结契约与执行结果展示：
 * - 契约详情
 * - 执行计划
 * - 结果下载
 */

import React from 'react';

interface RequirementContract {
  contract_id: string;
  contract_hash: string;
  task_id: string;
  version: number;
  status: string;
  goal_type: string;
  outcome: { var_name: string; definition?: string } | null;
  treatment: { var_name: string; definition?: string } | null;
  gate_decision: string;
  risk_score: number;
  frozen_at: string;
}

interface ExecutionStep {
  step_id: string;
  phase: string;
  kind: string;
  label: string;
  enabled: boolean;
}

interface ExecutionPlan {
  plan_id: string;
  plan_hash: string;
  contract_id: string;
  steps: ExecutionStep[];
}

interface Props {
  contract: RequirementContract;
  plan: ExecutionPlan;
  onDownloadDo?: () => void;
  onDownloadLog?: () => void;
  onDownloadResults?: () => void;
}

const STATUS_BADGES: Record<string, { bg: string; text: string; label: string }> = {
  frozen: { bg: 'bg-green-100', text: 'text-green-800', label: '已冻结' },
  superseded: { bg: 'bg-gray-100', text: 'text-gray-800', label: '已取代' },
  cancelled: { bg: 'bg-red-100', text: 'text-red-800', label: '已取消' },
};

const PHASE_COLORS: Record<string, string> = {
  profile: 'bg-blue-100 text-blue-700',
  preprocess: 'bg-purple-100 text-purple-700',
  main_model: 'bg-green-100 text-green-700',
  robustness: 'bg-yellow-100 text-yellow-700',
  diagnostics: 'bg-orange-100 text-orange-700',
  export: 'bg-gray-100 text-gray-700',
};

const GOAL_TYPE_LABELS: Record<string, string> = {
  descriptive: '描述性分析',
  predictive: '预测建模',
  causal: '因果推断',
};

export const ContractResultView: React.FC<Props> = ({
  contract,
  plan,
  onDownloadDo,
  onDownloadLog,
  onDownloadResults,
}) => {
  const statusBadge = STATUS_BADGES[contract.status] || STATUS_BADGES.frozen;

  return (
    <div className="space-y-6">
      {/* Contract Card */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 bg-gradient-to-r from-green-50 to-emerald-50 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
                <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h2 className="text-lg font-semibold text-gray-900">需求契约</h2>
                <p className="text-sm text-gray-500">版本 {contract.version}</p>
              </div>
            </div>
            <span className={`px-3 py-1 rounded-full text-sm font-medium ${statusBadge.bg} ${statusBadge.text}`}>
              {statusBadge.label}
            </span>
          </div>
        </div>

        {/* Contract Details */}
        <div className="p-6">
          {/* Hash & IDs */}
          <div className="grid grid-cols-2 gap-4 mb-6">
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-xs text-gray-500 uppercase tracking-wide mb-1">契约 ID</div>
              <code className="text-sm font-mono text-gray-700 break-all">{contract.contract_id}</code>
            </div>
            <div className="bg-gray-50 rounded-lg p-3">
              <div className="text-xs text-gray-500 uppercase tracking-wide mb-1">契约 Hash</div>
              <code className="text-sm font-mono text-gray-700 break-all">{contract.contract_hash.slice(0, 16)}...</code>
            </div>
          </div>

          {/* Key Info */}
          <div className="space-y-4">
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-500">研究目标</span>
              <span className="text-sm font-medium text-gray-900">
                {GOAL_TYPE_LABELS[contract.goal_type] || contract.goal_type}
              </span>
            </div>
            
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-500">因变量</span>
              <code className="text-sm bg-gray-100 px-2 py-0.5 rounded">
                {contract.outcome?.var_name || '未指定'}
              </code>
            </div>
            
            {contract.treatment && (
              <div className="flex items-center justify-between py-2 border-b border-gray-100">
                <span className="text-sm text-gray-500">自变量</span>
                <code className="text-sm bg-gray-100 px-2 py-0.5 rounded">
                  {contract.treatment.var_name}
                </code>
              </div>
            )}
            
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-500">门禁决策</span>
              <span className="text-sm font-medium text-gray-900">{contract.gate_decision}</span>
            </div>
            
            <div className="flex items-center justify-between py-2 border-b border-gray-100">
              <span className="text-sm text-gray-500">风险评分</span>
              <span className={`text-sm font-bold ${
                contract.risk_score <= 25 ? 'text-green-600' :
                contract.risk_score <= 60 ? 'text-yellow-600' : 'text-red-600'
              }`}>
                {contract.risk_score}
              </span>
            </div>
            
            <div className="flex items-center justify-between py-2">
              <span className="text-sm text-gray-500">冻结时间</span>
              <span className="text-sm text-gray-900">
                {new Date(contract.frozen_at).toLocaleString('zh-CN')}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Execution Plan Card */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">执行计划</h3>
          <p className="text-sm text-gray-500 mt-1">共 {plan.steps.length} 个步骤</p>
        </div>

        <div className="p-6">
          <div className="space-y-3">
            {plan.steps.map((step, index) => (
              <div
                key={step.step_id}
                className="flex items-center gap-4 p-3 bg-gray-50 rounded-lg"
              >
                <div className="w-8 h-8 rounded-full bg-white border border-gray-200 flex items-center justify-center text-sm font-medium text-gray-600">
                  {index + 1}
                </div>
                <div className="flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`px-2 py-0.5 rounded text-xs font-medium ${PHASE_COLORS[step.phase] || 'bg-gray-100 text-gray-700'}`}>
                      {step.phase}
                    </span>
                    <span className="text-sm font-medium text-gray-900">{step.label}</span>
                  </div>
                  <div className="text-xs text-gray-500 mt-1">
                    {step.kind} • {step.step_id}
                  </div>
                </div>
                {step.enabled ? (
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                  </svg>
                ) : (
                  <svg className="w-5 h-5 text-gray-300" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
                  </svg>
                )}
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Download Section */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h3 className="text-lg font-semibold text-gray-900">结果下载</h3>
        </div>

        <div className="p-6">
          <div className="grid grid-cols-3 gap-4">
            <button
              onClick={onDownloadDo}
              className="flex flex-col items-center gap-2 p-4 border border-gray-200 rounded-lg hover:border-blue-300 hover:bg-blue-50 transition-colors"
            >
              <svg className="w-8 h-8 text-blue-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
              </svg>
              <span className="text-sm font-medium text-gray-700">Do 文件</span>
              <span className="text-xs text-gray-400">.do</span>
            </button>

            <button
              onClick={onDownloadLog}
              className="flex flex-col items-center gap-2 p-4 border border-gray-200 rounded-lg hover:border-green-300 hover:bg-green-50 transition-colors"
            >
              <svg className="w-8 h-8 text-green-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
              <span className="text-sm font-medium text-gray-700">运行日志</span>
              <span className="text-xs text-gray-400">.log</span>
            </button>

            <button
              onClick={onDownloadResults}
              className="flex flex-col items-center gap-2 p-4 border border-gray-200 rounded-lg hover:border-purple-300 hover:bg-purple-50 transition-colors"
            >
              <svg className="w-8 h-8 text-purple-500" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
              </svg>
              <span className="text-sm font-medium text-gray-700">完整结果包</span>
              <span className="text-xs text-gray-400">.zip</span>
            </button>
          </div>
        </div>
      </div>

      {/* Traceability Info */}
      <div className="bg-gray-50 rounded-lg p-4 text-center">
        <p className="text-xs text-gray-500">
          此契约已冻结，所有结果均可通过契约 Hash 追溯验证
        </p>
        <code className="text-xs font-mono text-gray-600 mt-1 block">
          {contract.contract_hash}
        </code>
      </div>
    </div>
  );
};

export default ContractResultView;
