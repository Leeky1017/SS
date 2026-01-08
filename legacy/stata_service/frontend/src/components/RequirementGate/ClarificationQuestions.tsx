/**
 * Clarification Questions Component (P6)
 * 
 * 澄清问题展示与回答组件：
 * - 最多 3 个选择题
 * - 单选/多选支持
 * - 确认后冻结
 */

import React, { useState } from 'react';

interface QuestionOption {
  option_id: string;
  label: string;
  value: any;
  target_field: string;
}

interface ClarificationQuestion {
  question_id: string;
  question_text: string;
  question_type: 'single_choice' | 'multi_choice';
  options: QuestionOption[];
  priority: number;
  answered: boolean;
  selected_options: string[];
}

interface Props {
  questions: ClarificationQuestion[];
  onSubmit: (answers: Record<string, string[]>) => void;
  isSubmitting?: boolean;
}

const PRIORITY_LABELS: Record<number, string> = {
  1: '高优先级',
  2: '中优先级',
  3: '低优先级',
};

const PRIORITY_COLORS: Record<number, string> = {
  1: 'bg-red-100 text-red-700',
  2: 'bg-yellow-100 text-yellow-700',
  3: 'bg-blue-100 text-blue-700',
};

export const ClarificationQuestions: React.FC<Props> = ({
  questions,
  onSubmit,
  isSubmitting = false,
}) => {
  const [answers, setAnswers] = useState<Record<string, string[]>>(() => {
    const initial: Record<string, string[]> = {};
    questions.forEach(q => {
      initial[q.question_id] = q.selected_options || [];
    });
    return initial;
  });

  const handleOptionChange = (questionId: string, optionId: string, isMulti: boolean) => {
    setAnswers(prev => {
      const current = prev[questionId] || [];
      if (isMulti) {
        // Multi-choice: toggle selection
        if (current.includes(optionId)) {
          return { ...prev, [questionId]: current.filter(id => id !== optionId) };
        } else {
          return { ...prev, [questionId]: [...current, optionId] };
        }
      } else {
        // Single-choice: replace selection
        return { ...prev, [questionId]: [optionId] };
      }
    });
  };

  const allQuestionsAnswered = questions.every(
    q => (answers[q.question_id] || []).length > 0
  );

  const handleSubmit = () => {
    if (allQuestionsAnswered) {
      onSubmit(answers);
    }
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      {/* Header */}
      <div className="px-6 py-4 bg-gradient-to-r from-amber-50 to-orange-50 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-amber-100 flex items-center justify-center">
            <svg className="w-5 h-5 text-amber-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h2 className="text-lg font-semibold text-gray-900">需要确认以下问题</h2>
            <p className="text-sm text-gray-500">请回答下列问题以完成需求确认（共 {questions.length} 题）</p>
          </div>
        </div>
      </div>

      {/* Questions */}
      <div className="p-6 space-y-6">
        {questions.map((question, index) => (
          <div
            key={question.question_id}
            className="border border-gray-200 rounded-lg overflow-hidden"
          >
            {/* Question Header */}
            <div className="px-4 py-3 bg-gray-50 border-b border-gray-200 flex items-center justify-between">
              <div className="flex items-center gap-3">
                <span className="w-7 h-7 rounded-full bg-blue-600 text-white text-sm font-medium flex items-center justify-center">
                  {index + 1}
                </span>
                <span className={`px-2 py-0.5 rounded text-xs font-medium ${PRIORITY_COLORS[question.priority] || PRIORITY_COLORS[3]}`}>
                  {PRIORITY_LABELS[question.priority] || ''}
                </span>
              </div>
              <span className="text-xs text-gray-400">
                {question.question_type === 'multi_choice' ? '可多选' : '单选'}
              </span>
            </div>

            {/* Question Text */}
            <div className="px-4 py-3">
              <p className="text-gray-900 font-medium">{question.question_text}</p>
            </div>

            {/* Options */}
            <div className="px-4 pb-4 space-y-2">
              {question.options.map(option => {
                const isSelected = (answers[question.question_id] || []).includes(option.option_id);
                const isMulti = question.question_type === 'multi_choice';

                return (
                  <label
                    key={option.option_id}
                    className={`
                      flex items-center gap-3 p-3 rounded-lg border cursor-pointer transition-all
                      ${isSelected
                        ? 'border-blue-500 bg-blue-50 ring-1 ring-blue-500'
                        : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50'
                      }
                    `}
                  >
                    <input
                      type={isMulti ? 'checkbox' : 'radio'}
                      name={question.question_id}
                      checked={isSelected}
                      onChange={() => handleOptionChange(question.question_id, option.option_id, isMulti)}
                      className={`
                        ${isMulti ? 'rounded' : 'rounded-full'}
                        w-4 h-4 text-blue-600 border-gray-300 focus:ring-blue-500
                      `}
                    />
                    <span className={`text-sm ${isSelected ? 'text-blue-900 font-medium' : 'text-gray-700'}`}>
                      {option.label}
                    </span>
                  </label>
                );
              })}
            </div>
          </div>
        ))}
      </div>

      {/* Footer */}
      <div className="px-6 py-4 bg-gray-50 border-t border-gray-200">
        <div className="flex items-center justify-between">
          <div className="text-sm text-gray-500">
            {allQuestionsAnswered ? (
              <span className="text-green-600 flex items-center gap-1">
                <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                  <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                </svg>
                所有问题已回答
              </span>
            ) : (
              <span>请回答所有问题后继续</span>
            )}
          </div>
          <button
            onClick={handleSubmit}
            disabled={!allQuestionsAnswered || isSubmitting}
            className={`
              px-6 py-2 rounded-lg font-medium transition-all
              ${allQuestionsAnswered && !isSubmitting
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-200 text-gray-400 cursor-not-allowed'
              }
            `}
          >
            {isSubmitting ? (
              <span className="flex items-center gap-2">
                <svg className="animate-spin w-4 h-4" fill="none" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                处理中...
              </span>
            ) : (
              '确认并开始执行'
            )}
          </button>
        </div>
      </div>
    </div>
  );
};

export default ClarificationQuestions;
