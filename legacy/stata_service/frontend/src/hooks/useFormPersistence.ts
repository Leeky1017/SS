import { useCallback } from 'react';

const STORAGE_KEY = 'ss_task_draft';
const EXPIRY_HOURS = 24;

export interface FileMeta {
  name: string;
  size: number;
  type: string;
}

export interface FormDraft {
  taskCode: string;
  description: string;
  filesMeta: FileMeta[];
  pendingJobId: string | null;
  currentStep: 'form' | 'confirming' | 'completed';
  savedAt: number;
}

export function useFormPersistence() {
  const loadDraft = useCallback((): FormDraft | null => {
    try {
      const stored = localStorage.getItem(STORAGE_KEY);
      if (!stored) return null;

      const draft: FormDraft = JSON.parse(stored);

      const hoursSinceSave = (Date.now() - draft.savedAt) / (1000 * 60 * 60);
      if (hoursSinceSave > EXPIRY_HOURS) {
        localStorage.removeItem(STORAGE_KEY);
        return null;
      }

      return draft;
    } catch {
      return null;
    }
  }, []);

  const saveDraft = useCallback((draft: Omit<FormDraft, 'savedAt'>) => {
    try {
      localStorage.setItem(
        STORAGE_KEY,
        JSON.stringify({
          ...draft,
          savedAt: Date.now(),
        })
      );
    } catch (e) {
      console.error('Failed to save draft:', e);
    }
  }, []);

  const clearDraft = useCallback(() => {
    localStorage.removeItem(STORAGE_KEY);
  }, []);

  const hasDraft = useCallback((): boolean => {
    return loadDraft() !== null;
  }, [loadDraft]);

  return { loadDraft, saveDraft, clearDraft, hasDraft };
}
