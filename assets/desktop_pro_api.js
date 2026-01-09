(function () {
    const SS = window.SSDesktopPro;
    if (!SS) return;

    async function readJsonSafe(resp) {
        try {
            return await resp.json();
        } catch {
            return null;
        }
    }

    async function fetchJson(url, options) {
        try {
            const resp = await fetch(url, options);
            const data = await readJsonSafe(resp);
            return { resp, data };
        } catch (err) {
            SS.state.apiLastError = err instanceof Error ? err.message : String(err);
            return { resp: null, data: null };
        }
    }

    function mockDraftPreview() {
        return {
            draft_id: 'drf_72k9s1',
            decision: 'require_confirm_with_downgrade',
            risk_score: 42,
            status: 'generated',
            outcome_var: 'roe',
            treatment_var: 'esg_score',
            controls: ['size', 'lev', 'age'],
            column_candidates: ['profitability', 'esg_score', 'size', 'lev', 'age', 'year', 'firm_id'],
            data_quality_warnings: [
                { type: 'missing_rate', severity: 'warning', message: '缺失值比例较高', suggestion: '考虑删除缺失严重变量' },
            ],
            stage1_questions: [
                {
                    question_id: 'q_panel',
                    question_text: '数据是否为面板数据？',
                    question_type: 'single_choice',
                    priority: 1,
                    options: [
                        { option_id: 'yes', label: '是', value: true },
                        { option_id: 'no', label: '否', value: false },
                    ],
                },
            ],
            open_unknowns: [
                { field: 'panel_id', description: '请选择个体ID列', impact: 'high', blocking: true, candidates: ['firm_id'] },
            ],
        };
    }

    async function createJob(requirement) {
        if (SS.state.apiMode === 'mock') return { job_id: 'jb_demo' };
        const { resp, data } = await fetchJson('/v1/jobs', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ requirement: SS.isNonEmptyString(requirement) ? requirement : null }),
        });
        if (!resp || !resp.ok || !data || typeof data.job_id !== 'string') return null;
        return data;
    }

    async function uploadInputs(jobId, files) {
        if (SS.state.apiMode === 'mock') return { job_id: jobId, status: 'mock' };
        const form = new FormData();
        for (const f of files) form.append('file', f, f.name);
        const { resp, data } = await fetchJson(`/v1/jobs/${encodeURIComponent(jobId)}/inputs/upload`, {
            method: 'POST',
            body: form,
        });
        if (!resp || !resp.ok) return null;
        return data;
    }

    async function getDraftPreview(jobId, mainDataSourceId) {
        if (SS.state.apiMode === 'mock') return { status: 200, data: mockDraftPreview() };
        if (!SS.isNonEmptyString(jobId)) return { status: 0, data: null };

        const params = new URLSearchParams();
        if (SS.isNonEmptyString(mainDataSourceId)) params.set('main_data_source_id', mainDataSourceId.trim());
        const query = params.toString();
        const url = `/v1/jobs/${encodeURIComponent(jobId)}/draft/preview${query ? `?${query}` : ''}`;

        const { resp, data } = await fetchJson(url, { method: 'GET' });
        if (!resp) return { status: 0, data: null };
        return { status: resp.status, data };
    }

    async function patchDraft(jobId, fieldUpdates) {
        if (!SS.isNonEmptyString(jobId)) return null;
        if (SS.state.apiMode === 'mock') {
            const fields = Object.keys(fieldUpdates || {});
            const prevUnknowns = Array.isArray(SS.state.blueprint.preview?.open_unknowns)
                ? SS.state.blueprint.preview.open_unknowns
                : [];
            const remaining = prevUnknowns.filter((u) => !fields.includes(String(u?.field || '')));
            return {
                status: 'patched',
                patched_fields: fields,
                remaining_unknowns_count: remaining.length,
                open_unknowns: remaining,
                draft_preview: {
                    outcome_var: SS.state.blueprint.preview?.outcome_var ?? null,
                    treatment_var: SS.state.blueprint.preview?.treatment_var ?? null,
                    controls: SS.state.blueprint.preview?.controls ?? [],
                },
            };
        }

        const { resp, data } = await fetchJson(`/v1/jobs/${encodeURIComponent(jobId)}/draft/patch`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ field_updates: fieldUpdates }),
        });
        if (!resp || !resp.ok) return null;
        return data;
    }

    async function confirmJob(jobId, payload) {
        if (!SS.isNonEmptyString(jobId)) return null;
        if (SS.state.apiMode === 'mock') return { job_id: jobId, status: 'queued', message: 'confirmed' };

        const { resp, data } = await fetchJson(`/v1/jobs/${encodeURIComponent(jobId)}/confirm`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload),
        });
        if (!resp || !resp.ok) return null;
        return data;
    }

    SS.api = {
        createJob,
        uploadInputs,
        getDraftPreview,
        patchDraft,
        confirmJob,
        mockDraftPreview,
    };
})();
