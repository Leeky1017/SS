(function () {
    const SS = window.SSDesktopPro;
    if (!SS) return;
    const model = SS.blueprintModel;
    if (!model) return;

    function render() {
        SS.blueprintRender?.render?.();
    }

    function setBlueprintError(message) {
        SS.state.blueprint.status = 'error';
        SS.state.blueprint.errorMessage = message;
        render();
    }

    function useMockPreview() {
        SS.state.apiMode = 'mock';
        SS.state.blueprint.preview = model.normalizeDraftPreview(SS.api.mockDraftPreview());
        SS.state.blueprint.status = 'ready';
        SS.state.blueprint.errorMessage = null;
        render();
    }

    async function loadPreview() {
        SS.stopDraftPreviewPolling();
        SS.state.blueprint.status = 'loading';
        SS.state.blueprint.errorMessage = null;
        render();

        const jobId = SS.state.jobId;
        const { status, data } = await SS.api.getDraftPreview(jobId, SS.state.mainDataSourceId);
        if (status === 202) {
            const retryAfter = Number(data?.retry_after_seconds) || 5;
            SS.state.blueprint.status = 'pending';
            SS.state.blueprint.pendingRetryAfterSeconds = retryAfter;
            render();
            SS.state.blueprint.pendingTimerId = window.setTimeout(() => void loadPreview(), retryAfter * 1000);
            return;
        }

        if (status !== 200 || !data) {
            const msg =
                typeof data?.message === 'string'
                    ? data.message
                    : typeof data?.detail === 'string'
                        ? data.detail
                        : status === 0
                            ? '无法连接后端服务'
                            : '无法加载蓝图预览';
            setBlueprintError(`${msg} (HTTP ${status || 'N/A'})`);
            return;
        }

        SS.state.blueprint.preview = model.normalizeDraftPreview(data);
        SS.state.blueprint.status = 'ready';
        render();
    }

    async function enter() {
        if (!SS.state.jobId && SS.state.apiMode !== 'mock') {
            setBlueprintError('尚未创建 Job，请先完成前两步。');
            return;
        }
        void loadPreview();
    }

    function updateCorrection(from, to) {
        const key = SS.isNonEmptyString(from) ? from.trim() : '';
        const value = SS.isNonEmptyString(to) ? to.trim() : '';
        if (!key) return;
        if (!value || value === key) delete SS.state.blueprint.variableCorrections[key];
        else SS.state.blueprint.variableCorrections[key] = value;
        render();
    }

    async function applyClarifications() {
        if (SS.state.blueprint.locked || SS.state.blueprint.isPatching) return;
        SS.state.blueprint.clarificationErrorMessage = null;

        const updates = {};
        for (const [k, v] of Object.entries(SS.state.blueprint.openUnknownValues)) {
            if (SS.isNonEmptyString(v)) updates[k] = v.trim();
        }
        if (Object.keys(updates).length === 0) return;

        SS.state.blueprint.isPatching = true;
        render();
        const resp = await SS.api.patchDraft(SS.state.jobId, updates);
        SS.state.blueprint.isPatching = false;
        if (!resp) {
            SS.state.blueprint.clarificationErrorMessage = '澄清提交失败（patch API 不可用或返回错误）。';
            render();
            return;
        }

        const patchedFields = Array.isArray(resp.patched_fields) ? resp.patched_fields : Object.keys(updates);
        for (const f of patchedFields) delete SS.state.blueprint.openUnknownValues[f];

        if (SS.state.blueprint.preview && Array.isArray(resp.open_unknowns)) {
            SS.state.blueprint.preview.open_unknowns = resp.open_unknowns;
        }
        const dp = resp.draft_preview && typeof resp.draft_preview === 'object' ? resp.draft_preview : null;
        if (SS.state.blueprint.preview && dp) {
            if (typeof dp.outcome_var === 'string' || dp.outcome_var === null) SS.state.blueprint.preview.outcome_var = dp.outcome_var;
            if (typeof dp.treatment_var === 'string' || dp.treatment_var === null) SS.state.blueprint.preview.treatment_var = dp.treatment_var;
            if (Array.isArray(dp.controls)) SS.state.blueprint.preview.controls = SS.toStringArray(dp.controls);
        }
        render();
    }

    function openDowngradeModal(onConfirm) {
        const modal = SS.byId('downgrade-modal');
        if (!modal) return;
        SS.state.modal.onConfirm = onConfirm;
        modal.classList.remove('hidden');
    }

    function closeDowngradeModal() {
        const modal = SS.byId('downgrade-modal');
        if (!modal) return;
        SS.state.modal.onConfirm = null;
        modal.classList.add('hidden');
    }

    async function doConfirm() {
        closeDowngradeModal();
        const preview = SS.state.blueprint.preview;
        if (!preview) return;

        SS.state.blueprint.clarificationErrorMessage = null;
        SS.state.blueprint.isConfirming = true;
        render();

        const updates = {};
        for (const [k, v] of Object.entries(SS.state.blueprint.openUnknownValues)) {
            if (SS.isNonEmptyString(v)) updates[k] = v.trim();
        }
        if (Object.keys(updates).length > 0) {
            const patched = await SS.api.patchDraft(SS.state.jobId, updates);
            if (!patched) {
                SS.state.blueprint.isConfirming = false;
                SS.state.blueprint.clarificationErrorMessage = '澄清提交失败（patch API 不可用或返回错误）。';
                render();
                return;
            }
            const patchedFields = Array.isArray(patched.patched_fields) ? patched.patched_fields : Object.keys(updates);
            for (const f of patchedFields) delete SS.state.blueprint.openUnknownValues[f];
            if (Array.isArray(patched.open_unknowns)) preview.open_unknowns = patched.open_unknowns;
            const dp = patched.draft_preview && typeof patched.draft_preview === 'object' ? patched.draft_preview : null;
            if (dp) {
                if (typeof dp.outcome_var === 'string' || dp.outcome_var === null) preview.outcome_var = dp.outcome_var;
                if (typeof dp.treatment_var === 'string' || dp.treatment_var === null) preview.treatment_var = dp.treatment_var;
                if (Array.isArray(dp.controls)) preview.controls = SS.toStringArray(dp.controls);
            }
            if (model.missingBlockingUnknownValues(preview).length > 0) {
                SS.state.blueprint.isConfirming = false;
                SS.state.blueprint.clarificationErrorMessage = '仍有未澄清的必填项，请先完成后再确认。';
                render();
                return;
            }
        }

        const payload = {
            confirmed: true,
            variable_corrections: SS.state.blueprint.variableCorrections,
            answers: SS.state.blueprint.stage1Answers,
            default_overrides: {},
            expert_suggestions_feedback: {},
        };

        const resp = await SS.api.confirmJob(SS.state.jobId, payload);
        SS.state.blueprint.isConfirming = false;
        if (!resp) {
            window.alert('确认失败，请稍后重试。');
            render();
            return;
        }
        SS.state.blueprint.locked = true;
        SS.state.blueprint.lockedStatus = typeof resp.status === 'string' ? resp.status : 'queued';
        render();
    }

    async function handleConfirm() {
        if (SS.state.blueprint.locked) {
            SS.showView('query');
            return;
        }
        const preview = SS.state.blueprint.preview;
        if (!preview || SS.state.blueprint.status !== 'ready' || SS.state.blueprint.isConfirming) return;
        if (model.unansweredStage1(preview).length > 0 || model.missingBlockingUnknownValues(preview).length > 0) {
            render();
            return;
        }
        if (preview.decision === 'require_confirm_with_downgrade') {
            openDowngradeModal(() => void doConfirm());
            return;
        }
        void doConfirm();
    }

    function initEvents() {
        SS.byId('btn-clear-corrections').onclick = () => {
            SS.state.blueprint.variableCorrections = {};
            render();
        };

        SS.byId('var-mapping-rows').addEventListener('change', (e) => {
            const target = e.target;
            if (!(target instanceof HTMLSelectElement)) return;
            const from = target.dataset.from;
            if (!from) return;
            updateCorrection(from, target.value);
        });

        SS.byId('stage1-questions').addEventListener('click', (e) => {
            if (SS.state.blueprint.locked) return;
            SS.state.blueprint.clarificationErrorMessage = null;
            const btn = e.target instanceof HTMLElement ? e.target.closest('button[data-question-id]') : null;
            if (!(btn instanceof HTMLButtonElement)) return;
            const qid = btn.dataset.questionId || '';
            const qtype = btn.dataset.questionType || 'single_choice';
            const oid = btn.dataset.optionId || '';
            if (!qid || !oid) return;
            const prev = SS.state.blueprint.stage1Answers[qid] || [];
            const next = Array.isArray(prev) ? [...prev] : [];
            if (qtype === 'multi_choice') {
                const idx = next.indexOf(oid);
                if (idx >= 0) next.splice(idx, 1);
                else next.push(oid);
                SS.state.blueprint.stage1Answers[qid] = next;
            } else {
                SS.state.blueprint.stage1Answers[qid] = next.length === 1 && next[0] === oid ? [] : [oid];
            }
            render();
        });

        SS.byId('open-unknowns').addEventListener('input', (e) => {
            if (SS.state.blueprint.locked) return;
            SS.state.blueprint.clarificationErrorMessage = null;
            const input = e.target;
            if (!(input instanceof HTMLInputElement)) return;
            const field = input.dataset.unknownField || '';
            if (!field) return;
            SS.state.blueprint.openUnknownValues[field] = input.value ?? '';
            render();
        });

        SS.byId('open-unknowns').addEventListener('change', (e) => {
            if (SS.state.blueprint.locked) return;
            SS.state.blueprint.clarificationErrorMessage = null;
            const select = e.target;
            if (!(select instanceof HTMLSelectElement)) return;
            const field = select.dataset.unknownField || '';
            if (!field) return;
            SS.state.blueprint.openUnknownValues[field] = select.value ?? '';
            render();
        });

        SS.byId('btn-apply-clarifications').onclick = () => void applyClarifications();
        SS.byId('btn-confirm').onclick = () => void handleConfirm();
        SS.byId('btn-back-to-sheets').onclick = () => SS.showView('sheets');

        SS.byId('btn-modal-cancel').onclick = () => closeDowngradeModal();
        SS.byId('btn-modal-confirm').onclick = () => {
            const fn = SS.state.modal.onConfirm;
            closeDowngradeModal();
            if (typeof fn === 'function') fn();
        };
    }

    SS.blueprint = { enter, loadPreview, useMockPreview };
    initEvents();
    render();
})();
