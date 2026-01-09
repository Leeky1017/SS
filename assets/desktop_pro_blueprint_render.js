(function () {
    const SS = window.SSDesktopPro;
    if (!SS) return;
    const model = SS.blueprintModel;
    if (!model) return;

    function setDecisionBadge(preview) {
        const el = SS.byId('blueprint-decision-badge');
        if (!el) return;
        const decision = preview?.decision ?? 'require_confirm';
        el.classList.remove('success', 'info', 'error');
        if (decision === 'auto_freeze') {
            el.classList.add('success');
            el.textContent = '可自动执行';
        } else if (decision === 'require_confirm_with_downgrade') {
            el.classList.add('error');
            el.textContent = '高风险需确认';
        } else {
            el.classList.add('info');
            el.textContent = '需要确认';
        }
    }

    function renderHeader(preview) {
        const jobLine = SS.byId('blueprint-job-line');
        const statusLine = SS.byId('blueprint-status-line');
        if (!jobLine || !statusLine) return;
        jobLine.textContent = SS.state.jobId
            ? `Job: ${SS.state.jobId}${SS.state.apiMode === 'mock' ? ' · mock' : ''}`
            : `Job: (未创建)${SS.state.apiMode === 'mock' ? ' · mock' : ''}`;
        setDecisionBadge(preview);
        const parts = [];
        if (preview?.draft_id) parts.push(`draft_id=${preview.draft_id}`);
        if (preview?.status) parts.push(`status=${preview.status}`);
        if (typeof preview?.risk_score === 'number') parts.push(`risk=${preview.risk_score}`);
        statusLine.textContent = parts.length > 0 ? parts.join(' · ') : '—';
    }

    function renderLockedBanner() {
        const banner = SS.byId('blueprint-locked-banner');
        const subtitle = SS.byId('blueprint-locked-subtitle');
        if (!banner || !subtitle) return;
        const locked = SS.state.blueprint.locked;
        banner.classList.toggle('hidden', !locked);
        if (!locked) return;
        const status = SS.state.blueprint.lockedStatus || 'queued';
        subtitle.textContent = SS.state.jobId ? `Job: ${SS.state.jobId} · status=${status}` : `status=${status}`;
    }

    function renderPreviewStatePanel() {
        const panel = SS.byId('blueprint-preview-state');
        const text = SS.byId('blueprint-preview-state-text');
        const actions = SS.byId('blueprint-preview-state-actions');
        if (!panel || !text || !actions) return;
        actions.innerHTML = '';
        panel.classList.toggle('hidden', SS.state.blueprint.status === 'ready');
        if (SS.state.blueprint.status === 'ready') return;

        if (SS.state.blueprint.status === 'loading') {
            text.textContent = '正在加载蓝图预览…';
            return;
        }
        if (SS.state.blueprint.status === 'pending') {
            const s = SS.state.blueprint.pendingRetryAfterSeconds ?? 5;
            text.textContent = `预处理中，将在 ${s}s 后自动重试…`;
            return;
        }
        if (SS.state.blueprint.status === 'error') {
            text.textContent = SS.state.blueprint.errorMessage || '加载失败，请重试。';
            const btn = document.createElement('button');
            btn.className = 'btn btn-secondary';
            btn.textContent = '重试';
            btn.onclick = () => void SS.blueprint?.loadPreview?.();
            actions.appendChild(btn);
            if (SS.state.apiMode === 'auto' && typeof SS.blueprint?.useMockPreview === 'function') {
                const mockBtn = document.createElement('button');
                mockBtn.className = 'btn btn-secondary';
                mockBtn.textContent = '使用示例草案';
                mockBtn.onclick = () => SS.blueprint.useMockPreview();
                actions.appendChild(mockBtn);
            }
            return;
        }
        text.textContent = '—';
    }

    function renderVariablePreviewTable(preview) {
        const tbody = SS.byId('blueprint-vars-body');
        if (!tbody) return;
        const dependent = model.getCorrectedVar(preview.outcome_var);
        const independent = model.getCorrectedVar(preview.treatment_var);
        const controls = preview.controls.map((v) => model.getCorrectedVar(v)).filter((v) => v !== null);
        tbody.innerHTML =
            `<tr><td style="color:var(--accent)">DEPENDENT</td><td>${SS.escapeHtml(dependent || '—')}</td><td>因变量</td></tr>` +
            `<tr><td style="color:var(--success)">INDEPENDENT</td><td>${SS.escapeHtml(independent || '—')}</td><td>核心解释变量</td></tr>` +
            `<tr><td style="color:var(--text-muted)">CONTROL</td><td>${SS.escapeHtml(controls.join(', ') || '—')}</td><td>控制变量</td></tr>`;
    }

    function renderWarnings(preview) {
        const panel = SS.byId('panel-warnings');
        const body = SS.byId('warnings-body');
        const count = SS.byId('warnings-count');
        if (!panel || !body || !count) return;
        const items = Array.isArray(preview.data_quality_warnings) ? preview.data_quality_warnings : [];
        panel.classList.toggle('hidden', items.length === 0);
        if (items.length === 0) return;
        panel.open = true;
        count.textContent = `${items.length} 条`;
        body.innerHTML = items
            .map((w) => {
                const sev = typeof w?.severity === 'string' ? w.severity : 'info';
                const sevClass = sev === 'error' ? 'error' : sev === 'info' ? 'info' : '';
                const suggestion = typeof w?.suggestion === 'string' && w.suggestion.trim() !== '' ? w.suggestion : null;
                const msg = typeof w?.message === 'string' ? w.message : '';
                return (
                    `<div class="warning-item"><div class="warning-title">` +
                    `<span class="badge ${sevClass}">${SS.escapeHtml(sev.toUpperCase())}</span>` +
                    `<span class="warning-message">${SS.escapeHtml(msg)}</span></div>` +
                    (suggestion ? `<div class="warning-suggestion">${SS.escapeHtml(suggestion)}</div>` : '') +
                    `</div>`
                );
            })
            .join('');
    }

    function buildSelectHtml(from, currentValue, candidates, disabled) {
        const values = SS.uniqueStrings([from, currentValue, ...candidates]);
        const options = values
            .map((opt) => `<option value="${SS.escapeHtml(opt)}" ${opt === currentValue ? 'selected' : ''}>${SS.escapeHtml(opt)}</option>`)
            .join('');
        return `<select data-from="${SS.escapeHtml(from)}" ${disabled || values.length === 0 ? 'disabled' : ''}>${options}</select>`;
    }

    function renderCorrections(preview) {
        const tbody = SS.byId('var-mapping-rows');
        const clearBtn = SS.byId('btn-clear-corrections');
        const count = SS.byId('corrections-count');
        if (!tbody || !clearBtn || !count) return;
        const correctionsCount = Object.keys(SS.state.blueprint.variableCorrections).length;
        count.textContent = correctionsCount > 0 ? `${correctionsCount} 项已修正` : '未修正';
        clearBtn.classList.toggle('hidden', correctionsCount === 0);
        clearBtn.disabled = SS.state.blueprint.locked;

        const candidates = model.getCandidateColumns(preview);
        const disabled = SS.state.blueprint.locked;
        const rows = [];
        if (SS.isNonEmptyString(preview.outcome_var)) {
            const from = preview.outcome_var;
            const currentValue = model.getCorrectedVar(from) || from;
            rows.push(`<tr><td style="color:var(--accent)">DEPENDENT</td><td>${SS.escapeHtml(from)}</td><td>${buildSelectHtml(from, currentValue, candidates, disabled)}</td></tr>`);
        }
        if (SS.isNonEmptyString(preview.treatment_var)) {
            const from = preview.treatment_var;
            const currentValue = model.getCorrectedVar(from) || from;
            rows.push(`<tr><td style="color:var(--success)">INDEPENDENT</td><td>${SS.escapeHtml(from)}</td><td>${buildSelectHtml(from, currentValue, candidates, disabled)}</td></tr>`);
        }
        for (const c of preview.controls) {
            if (!SS.isNonEmptyString(c)) continue;
            const currentValue = model.getCorrectedVar(c) || c;
            rows.push(`<tr><td style="color:var(--text-muted)">CONTROL</td><td>${SS.escapeHtml(c)}</td><td>${buildSelectHtml(c, currentValue, candidates, disabled)}</td></tr>`);
        }
        tbody.innerHTML = rows.length > 0 ? rows.join('') : `<tr><td colspan="3">未检测到可映射变量</td></tr>`;
    }

    function renderStage1Questions(preview) {
        const root = SS.byId('stage1-questions');
        if (!root) return;
        const unanswered = model.unansweredStage1(preview);
        const questions = [...preview.stage1_questions].sort((a, b) => (a?.priority ?? 0) - (b?.priority ?? 0));
        if (questions.length === 0) {
            root.innerHTML = `<div class="inline-hint">当前无需要确认的选择题。</div>`;
            return;
        }
        root.innerHTML = questions
            .map((q) => {
                const qid = typeof q?.question_id === 'string' ? q.question_id : '';
                const qtext = typeof q?.question_text === 'string' ? q.question_text : '';
                const qtype = q?.question_type === 'multi_choice' ? 'multi_choice' : 'single_choice';
                const selected = SS.state.blueprint.stage1Answers[qid] || [];
                const missing = unanswered.includes(qid);
                const options = Array.isArray(q?.options) ? q.options : [];
                const optionHtml = options
                    .map((opt) => {
                        const oid = typeof opt?.option_id === 'string' ? opt.option_id : '';
                        const label = typeof opt?.label === 'string' ? opt.label : oid;
                        const on = Array.isArray(selected) && selected.includes(oid);
                        return `<button class="tpl-tag ${on ? 'selected' : ''}" data-question-id="${SS.escapeHtml(qid)}" data-question-type="${SS.escapeHtml(qtype)}" data-option-id="${SS.escapeHtml(oid)}" ${SS.state.blueprint.locked ? 'disabled' : ''}>${SS.escapeHtml(label)}</button>`;
                    })
                    .join('');
                const pill = `<span class="mono ${missing ? 'field-error' : ''}" style="font-size: 11px; padding: 2px 8px; border-radius: 999px; border: 1px solid var(--border);">${missing ? '必答' : '已答'}</span>`;
                return `<div style="margin-top: 14px;"><div style="display:flex; justify-content:space-between; gap: 12px;"><div style="font-weight: 600;">${SS.escapeHtml(qtext)}</div>${pill}</div><div style="margin-top: 10px; display:flex; flex-wrap:wrap; gap: 8px;">${optionHtml}</div></div>`;
            })
            .join('');
    }

    function renderOpenUnknowns(preview) {
        const root = SS.byId('open-unknowns');
        if (!root) return;
        const missing = model.missingBlockingUnknownValues(preview);
        if (preview.open_unknowns.length === 0) {
            root.innerHTML = `<div class="inline-hint">当前无需要澄清的待确认项。</div>`;
            return;
        }
        root.innerHTML = preview.open_unknowns
            .map((u) => {
                const field = typeof u?.field === 'string' ? u.field : '';
                const desc = typeof u?.description === 'string' ? u.description : '';
                const impact = typeof u?.impact === 'string' ? u.impact : 'low';
                const required = model.isBlockingUnknown(u);
                const v = SS.state.blueprint.openUnknownValues[field] || '';
                const candidates = Array.isArray(u?.candidates) ? SS.uniqueStrings(u.candidates) : [];
                const cls = required && missing.includes(field) ? 'field-error' : '';
                const disabled = SS.state.blueprint.locked ? 'disabled' : '';
                const badge = required ? `<span class="badge error">BLOCKING</span>` : '';
                const input =
                    candidates.length > 0
                        ? `<select class="${cls}" data-unknown-field="${SS.escapeHtml(field)}" ${disabled}><option value="">请选择…</option>${candidates
                            .map((c) => `<option value="${SS.escapeHtml(c)}" ${v === c ? 'selected' : ''}>${SS.escapeHtml(c)}</option>`)
                            .join('')}</select>`
                        : `<input type="text" class="${cls}" data-unknown-field="${SS.escapeHtml(field)}" value="${SS.escapeHtml(v)}" placeholder="请输入…" ${disabled}>`;
                return `<div style="margin-top: 16px;"><div style="display:flex; justify-content:space-between; align-items:flex-start; gap: 12px;"><div><div style="font-weight: 600;">${SS.escapeHtml(field)}</div><div class="inline-hint" style="margin-top: 4px;">${SS.escapeHtml(desc)} · impact=${SS.escapeHtml(impact)}</div></div>${badge}</div><div style="margin-top: 10px;">${input}</div></div>`;
            })
            .join('');
    }

    function renderClarifications(preview) {
        const summary = SS.byId('clarification-summary');
        const patchBtn = SS.byId('btn-apply-clarifications');
        const err = SS.byId('clarification-error');
        if (!summary || !patchBtn || !err) return;
        renderStage1Questions(preview);
        renderOpenUnknowns(preview);
        const blockers = model.unansweredStage1(preview).length + model.missingBlockingUnknownValues(preview).length;
        summary.textContent = blockers === 0 ? '无阻断项' : `阻断项：${blockers}`;
        const patchReady = Object.values(SS.state.blueprint.openUnknownValues).some((v) => SS.isNonEmptyString(v));
        patchBtn.disabled = SS.state.blueprint.locked || SS.state.blueprint.isPatching || !patchReady;
        patchBtn.textContent = SS.state.blueprint.isPatching ? '应用中…' : '应用澄清并刷新预览';
        const msg = SS.state.blueprint.clarificationErrorMessage;
        err.textContent = SS.isNonEmptyString(msg) ? msg : '';
        err.classList.toggle('hidden', !SS.isNonEmptyString(msg));
    }

    function renderConfirmControls(preview) {
        const backBtn = SS.byId('btn-back-to-sheets');
        const confirmBtn = SS.byId('btn-confirm');
        const hint = SS.byId('confirm-hint');
        if (!backBtn || !confirmBtn || !hint) return;
        backBtn.disabled = SS.state.blueprint.locked;
        if (SS.state.blueprint.locked) {
            confirmBtn.disabled = false;
            confirmBtn.textContent = '查看任务状态';
            hint.textContent = '蓝图已锁定（只读）。';
            return;
        }
        confirmBtn.textContent = SS.state.blueprint.isConfirming ? '提交中…' : '确认并启动';
        if (SS.state.blueprint.status !== 'ready') {
            confirmBtn.disabled = true;
            hint.textContent = '请先等待蓝图预览加载完成。';
            return;
        }
        const missingQ = model.unansweredStage1(preview);
        const missingU = model.missingBlockingUnknownValues(preview);
        if (missingQ.length === 0 && missingU.length === 0) {
            confirmBtn.disabled = SS.state.blueprint.isConfirming;
            hint.textContent = '确认后将锁定需求并加入执行队列。';
            return;
        }
        confirmBtn.disabled = true;
        const parts = [];
        if (missingQ.length > 0) parts.push(`${missingQ.length} 个选择题未回答`);
        if (missingU.length > 0) parts.push(`${missingU.length} 个必填澄清未完成`);
        hint.textContent = `确认被阻断：${parts.join('，')}。`;
    }

    function render() {
        const preview = SS.state.blueprint.preview;
        renderHeader(preview);
        renderLockedBanner();
        renderPreviewStatePanel();
        const content = SS.byId('blueprint-preview-content');
        if (!content) return;
        content.classList.toggle('hidden', SS.state.blueprint.status !== 'ready');
        if (SS.state.blueprint.status !== 'ready' || !preview) return;
        renderVariablePreviewTable(preview);
        renderWarnings(preview);
        renderCorrections(preview);
        renderClarifications(preview);
        renderConfirmControls(preview);
    }

    SS.blueprintRender = { render };
})();
