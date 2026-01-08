/**
 * Contract Draft View Component (P6)
 * 
 * 需求契约草案展示组件：
 * - 可折叠字段
 * - 展示系统依据（不展示置信度数值）
 * - 风险标记高亮
 */

import React, { useState } from 'react';

interface ConfidenceEvidence {
  confidence: number;
  evidence: string;
  source: string;
}

interface VariableSpec {
  var_name: string | null;
  definition: string | null;
  unit: string | null;
  transform: string | null;
}

interface OpenUnknown {
  field: string;
  display_name?: string;
  description: string;
  impact: string;
  blocking?: boolean;
  suggested_default: any;
}

interface ContractDraft {
  draft_id: string;
  task_id: string;
  goal_type: string;
  goal_type_confidence: ConfidenceEvidence;
  outcome: VariableSpec | null;
  outcome_confidence: ConfidenceEvidence | null;
  treatment: VariableSpec | null;
  treatment_confidence: ConfidenceEvidence | null;
  controls: { var_names: string[]; group_rule: string | null };
  sample_scope: {
    time_range_start: string | null;
    time_range_end: string | null;
    filters: string[];
    exclusions: string[];
  };
  method_constraints: {
    allowed_methods: string[];
    must_causal: boolean;
    cluster_se: string | null;
    fixed_effects: string[];
  };
  open_unknowns: OpenUnknown[];
  assumptions: { assumption: string; testable: boolean }[];
}

interface Props {
  draft: ContractDraft;
  riskScore: number;
  onProceed?: () => void;
}

const GOAL_TYPE_LABELS: Record<string, string> = {
  descriptive: '描述性分析',
  predictive: '预测建模',
  causal: '因果推断',
};

const IMPACT_COLORS: Record<string, string> = {
  high: 'bg-red-100 text-red-800 border-red-200',
  medium: 'bg-yellow-100 text-yellow-800 border-yellow-200',
  low: 'bg-green-100 text-green-800 border-green-200',
};

const StatusBadge: React.FC<{ confidence: number }> = ({ confidence }) => {
  let colorClass = 'bg-green-100 text-green-800';
  let label = '已验证';

  if (confidence < 0.5) {
    colorClass = 'bg-red-100 text-red-800';
    label = '需要确认';
  } else if (confidence < 0.8) {
    colorClass = 'bg-yellow-100 text-yellow-800';
    label = '建议核对';
  }

  return (
    <span className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium ${colorClass}`}>
      {label}
    </span>
  );
};

const CollapsibleSection: React.FC<{
  title: string;
  confidence?: ConfidenceEvidence | null;
  defaultOpen?: boolean;
  children: React.ReactNode;
}> = ({ title, confidence, defaultOpen = false, children }) => {
  const [isOpen, setIsOpen] = useState(defaultOpen);
  
  return (
    <div className="border border-gray-200 rounded-lg mb-3">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="w-full px-4 py-3 flex items-center justify-between bg-gray-50 hover:bg-gray-100 rounded-t-lg"
      >
        <div className="flex items-center gap-3">
          <span className="font-medium text-gray-900">{title}</span>
          {confidence && <StatusBadge confidence={confidence.confidence} />}
        </div>
        <svg
          className={`w-5 h-5 text-gray-500 transform transition-transform ${isOpen ? 'rotate-180' : ''}`}
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
        </svg>
      </button>
      {isOpen && (
        <div className="px-4 py-3 border-t border-gray-200">
          {children}
          {confidence && confidence.evidence && (
            <div className="mt-2 text-xs text-gray-500">
              <span className="font-medium">系统依据：</span> {confidence.evidence}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export const ContractDraftView: React.FC<Props> = ({ draft, riskScore, onProceed }) => {
  const riskColor = riskScore <= 25 ? 'text-green-600' : riskScore <= 60 ? 'text-yellow-600' : 'text-red-600';
  
  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 bg-gradient-to-r from-blue-50 to-indigo-50 border-b border-gray-200">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-lg font-semibold text-gray-900">需求契约草案</h2>
            <p className="text-sm text-gray-500 mt-1">ID: {draft.draft_id}</p>
          </div>
          <div className="text-right">
            <div className="text-sm text-gray-500">风险评分</div>
            <div className={`text-2xl font-bold ${riskColor}`}>{riskScore}</div>
          </div>
        </div>
      </div>
      
      {/* Content */}
      <div className="p-6">
        {/* Goal Type */}
        <CollapsibleSection
          title="研究目标类型"
          confidence={draft.goal_type_confidence}
          defaultOpen={true}
        >
          <div className="flex items-center gap-2">
            <span className="px-3 py-1 bg-blue-100 text-blue-800 rounded-full text-sm font-medium">
              {GOAL_TYPE_LABELS[draft.goal_type] || draft.goal_type}
            </span>
          </div>
        </CollapsibleSection>
        
        {/* Outcome Variable */}
        <CollapsibleSection
          title="因变量（被解释变量）"
          confidence={draft.outcome_confidence}
          defaultOpen={true}
        >
          {draft.outcome ? (
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-gray-500">变量名：</span>
                <code className="px-2 py-0.5 bg-gray-100 rounded text-sm">{draft.outcome.var_name}</code>
              </div>
              {draft.outcome.definition && (
                <div className="text-sm text-gray-600">定义：{draft.outcome.definition}</div>
              )}
              {draft.outcome.transform && (
                <div className="text-sm text-gray-600">变换：{draft.outcome.transform}</div>
              )}
            </div>
          ) : (
            <div className="text-sm text-gray-400 italic">未指定</div>
          )}
        </CollapsibleSection>
        
        {/* Treatment Variable */}
        <CollapsibleSection
          title="自变量（解释变量）"
          confidence={draft.treatment_confidence}
        >
          {draft.treatment ? (
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <span className="text-sm font-medium text-gray-500">变量名：</span>
                <code className="px-2 py-0.5 bg-gray-100 rounded text-sm">{draft.treatment.var_name}</code>
              </div>
              {draft.treatment.definition && (
                <div className="text-sm text-gray-600">定义：{draft.treatment.definition}</div>
              )}
            </div>
          ) : (
            <div className="text-sm text-gray-400 italic">未指定</div>
          )}
        </CollapsibleSection>
        
        {/* Controls */}
        <CollapsibleSection title="控制变量">
          {draft.controls.var_names.length > 0 ? (
            <div className="flex flex-wrap gap-2">
              {draft.controls.var_names.map((v, i) => (
                <code key={i} className="px-2 py-0.5 bg-gray-100 rounded text-sm">{v}</code>
              ))}
            </div>
          ) : (
            <div className="text-sm text-gray-400 italic">未指定控制变量</div>
          )}
        </CollapsibleSection>
        
        {/* Sample Scope */}
        <CollapsibleSection title="样本范围">
          <div className="space-y-2 text-sm">
            {draft.sample_scope.time_range_start || draft.sample_scope.time_range_end ? (
              <div>
                时间范围：{draft.sample_scope.time_range_start || '?'} - {draft.sample_scope.time_range_end || '?'}
              </div>
            ) : (
              <div className="text-gray-400 italic">未指定时间范围</div>
            )}
            {draft.sample_scope.filters.length > 0 && (
              <div>筛选条件：{draft.sample_scope.filters.join(', ')}</div>
            )}
          </div>
        </CollapsibleSection>
        
        {/* Method Constraints */}
        <CollapsibleSection title="方法约束">
          <div className="space-y-2 text-sm">
            <div className="flex items-center gap-2">
              <span className="text-gray-500">因果要求：</span>
              <span className={draft.method_constraints.must_causal ? 'text-red-600 font-medium' : 'text-gray-600'}>
                {draft.method_constraints.must_causal ? '要求因果推断' : '相关性分析即可'}
              </span>
            </div>
            {draft.method_constraints.fixed_effects.length > 0 && (
              <div>
                固定效应：{draft.method_constraints.fixed_effects.join(', ')}
              </div>
            )}
            {draft.method_constraints.cluster_se && (
              <div>聚类标准误：{draft.method_constraints.cluster_se}</div>
            )}
          </div>
        </CollapsibleSection>
        
        {/* Open Unknowns */}
        {draft.open_unknowns.length > 0 && (
          <div className="mt-6">
            <h3 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <svg className="w-4 h-4 text-yellow-500" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
              </svg>
              待确认项 ({draft.open_unknowns.length})
            </h3>
            <div className="space-y-2">
              {draft.open_unknowns.map((unknown, i) => (
                <div
                  key={i}
                  className={`px-3 py-2 rounded-lg border ${IMPACT_COLORS[unknown.impact] || IMPACT_COLORS.medium}`}
                >
                  <div className="flex items-center justify-between">
                    <span className="font-medium text-sm">{unknown.display_name || unknown.field}</span>
                    <span className="text-xs uppercase">{unknown.impact}</span>
                  </div>
                  <p className="text-sm mt-1 opacity-80 whitespace-pre-line">{unknown.description}</p>
                </div>
              ))}
            </div>
          </div>
        )}
        
        {/* Assumptions */}
        {draft.assumptions.length > 0 && (
          <CollapsibleSection title={`研究假设 (${draft.assumptions.length})`}>
            <ul className="list-disc list-inside space-y-1 text-sm text-gray-600">
              {draft.assumptions.map((a, i) => (
                <li key={i}>
                  {a.assumption}
                  {a.testable && <span className="ml-2 text-xs text-blue-500">[可检验]</span>}
                </li>
              ))}
            </ul>
          </CollapsibleSection>
        )}
      </div>
      
      {/* Footer */}
      {onProceed && (
        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
          <button
            onClick={onProceed}
            className="w-full px-4 py-2 bg-blue-600 text-white rounded-lg font-medium hover:bg-blue-700 transition-colors"
          >
            {riskScore <= 25 ? '确认并开始执行' : '继续回答确认问题'}
          </button>
        </div>
      )}
    </div>
  );
};

export default ContractDraftView;
