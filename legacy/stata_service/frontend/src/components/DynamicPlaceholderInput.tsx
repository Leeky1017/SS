import React, { useState, useEffect } from 'react';

/**
 * 动态占位符输入组件 (R15)
 *
 * 用于列表类型的占位符输入，支持动态增删输入框。
 * 例如：合并变量 __MERGE_KEYS__ 可以输入多个变量名。
 */

interface DynamicPlaceholderInputProps {
  /** 占位符名称，如 "__MERGE_KEYS__" */
  placeholder: string;
  /** 显示标签，如 "合并变量" */
  label: string;
  /** 初始值列表 */
  initialValues: string[];
  /** 候选列表（用于自动补全） */
  candidates?: string[];
  /** 最少项数，默认 1 */
  minItems?: number;
  /** 值变化回调 */
  onChange: (values: string[]) => void;
  /** 是否禁用 */
  disabled?: boolean;
}

export function DynamicPlaceholderInput({
  placeholder,
  label,
  initialValues,
  candidates = [],
  minItems = 1,
  onChange,
  disabled = false,
}: DynamicPlaceholderInputProps) {
  const [values, setValues] = useState<string[]>(
    initialValues.length > 0 ? initialValues : ['']
  );
  const [_focusedIndex, setFocusedIndex] = useState<number | null>(null);

  // 当 initialValues 变化时更新
  useEffect(() => {
    if (initialValues.length > 0) {
      setValues(initialValues);
    }
  }, [initialValues.join(',')]);

  const handleAdd = () => {
    const newValues = [...values, ''];
    setValues(newValues);
    // 不触发 onChange，因为新增的是空值
  };

  const handleRemove = (index: number) => {
    if (values.length <= minItems) return;

    const newValues = values.filter((_, i) => i !== index);
    setValues(newValues);
    onChange(newValues.filter(v => v.trim()));
  };

  const handleChange = (index: number, value: string) => {
    const newValues = [...values];
    newValues[index] = value;
    setValues(newValues);
    onChange(newValues.filter(v => v.trim()));
  };

  const handleKeyDown = (e: React.KeyboardEvent, index: number) => {
    if (e.key === 'Enter') {
      e.preventDefault();
      if (index === values.length - 1) {
        handleAdd();
      }
    }
  };

  // 过滤候选项：排除已选择的值
  const getFilteredCandidates = (currentValue: string) => {
    const selected = new Set(values.filter(v => v.trim()));
    return candidates.filter(
      c => !selected.has(c) && c.toLowerCase().includes(currentValue.toLowerCase())
    );
  };

  return (
    <div className="dynamic-placeholder-input" style={styles.container}>
      <label style={styles.label}>{label}</label>

      {initialValues.length > 0 && (
        <div style={styles.hint}>
          系统推测需要 {initialValues.length} 个变量，您可以增减。
        </div>
      )}

      <div style={styles.inputList}>
        {values.map((value, index) => (
          <div key={index} style={styles.inputRow}>
            <span style={styles.indexLabel}>变量 {index + 1}:</span>

            <div style={styles.inputWrapper}>
              <input
                type="text"
                value={value}
                onChange={(e) => handleChange(index, e.target.value)}
                onFocus={() => setFocusedIndex(index)}
                onBlur={() => setTimeout(() => setFocusedIndex(null), 200)}
                onKeyDown={(e) => handleKeyDown(e, index)}
                placeholder={`输入${label.replace('设置', '')}...`}
                disabled={disabled}
                style={styles.input}
                list={`candidates-${placeholder}-${index}`}
              />

              {/* 自动补全候选列表 */}
              {candidates.length > 0 && (
                <datalist id={`candidates-${placeholder}-${index}`}>
                  {getFilteredCandidates(value).slice(0, 10).map((candidate) => (
                    <option key={candidate} value={candidate} />
                  ))}
                </datalist>
              )}
            </div>

            {values.length > minItems && (
              <button
                type="button"
                onClick={() => handleRemove(index)}
                disabled={disabled}
                style={styles.removeButton}
                title="删除此变量"
              >
                ✕
              </button>
            )}
          </div>
        ))}
      </div>

      <button
        type="button"
        onClick={handleAdd}
        disabled={disabled}
        style={styles.addButton}
      >
        + 添加变量
      </button>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    marginBottom: '1rem',
  },
  label: {
    display: 'block',
    fontWeight: 600,
    marginBottom: '0.5rem',
    color: '#333',
  },
  hint: {
    fontSize: '0.85rem',
    color: '#666',
    marginBottom: '0.75rem',
  },
  inputList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '0.5rem',
  },
  inputRow: {
    display: 'flex',
    alignItems: 'center',
    gap: '0.5rem',
  },
  indexLabel: {
    minWidth: '60px',
    fontSize: '0.9rem',
    color: '#555',
  },
  inputWrapper: {
    flex: 1,
    position: 'relative',
  },
  input: {
    width: '100%',
    padding: '0.5rem 0.75rem',
    border: '1px solid #ddd',
    borderRadius: '4px',
    fontSize: '0.95rem',
    transition: 'border-color 0.2s',
  },
  removeButton: {
    padding: '0.4rem 0.6rem',
    border: '1px solid #e0e0e0',
    borderRadius: '4px',
    background: '#fff',
    color: '#999',
    cursor: 'pointer',
    fontSize: '0.9rem',
    transition: 'all 0.2s',
  },
  addButton: {
    marginTop: '0.5rem',
    padding: '0.5rem 1rem',
    border: '1px dashed #bbb',
    borderRadius: '4px',
    background: 'transparent',
    color: '#666',
    cursor: 'pointer',
    fontSize: '0.9rem',
    transition: 'all 0.2s',
  },
};

export default DynamicPlaceholderInput;
