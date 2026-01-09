(function () {
    const SS = window.SSDesktopPro || (window.SSDesktopPro = {});

    SS.state = {
        currentView: 'submit',
        jobId: null,
        mainDataSourceId: null,
        files: [],
        apiMode: window.location.protocol === 'file:' ? 'mock' : 'auto',
        apiLastError: null,
        blueprint: {
            status: 'idle',
            preview: null,
            pendingTimerId: null,
            pendingRetryAfterSeconds: null,
            errorMessage: null,
            variableCorrections: {},
            stage1Answers: {},
            openUnknownValues: {},
            locked: false,
            lockedStatus: null,
            isPatching: false,
            isConfirming: false,
        },
        modal: {
            onConfirm: null,
        },
    };

    SS.byId = function (id) {
        return document.getElementById(id);
    };

    SS.escapeHtml = function (value) {
        return String(value)
            .replaceAll('&', '&amp;')
            .replaceAll('<', '&lt;')
            .replaceAll('>', '&gt;')
            .replaceAll('"', '&quot;')
            .replaceAll("'", '&#39;');
    };

    SS.isNonEmptyString = function (value) {
        return typeof value === 'string' && value.trim() !== '';
    };

    SS.uniqueStrings = function (values) {
        const seen = new Set();
        const out = [];
        for (const item of values) {
            if (!SS.isNonEmptyString(item)) continue;
            const key = item.trim();
            if (seen.has(key)) continue;
            seen.add(key);
            out.push(key);
        }
        return out;
    };

    SS.toStringArray = function (value) {
        if (!Array.isArray(value)) return [];
        return value
            .filter((x) => typeof x === 'string')
            .map((x) => x.trim())
            .filter((x) => x !== '');
    };

    function setActiveTab(tabId) {
        document.querySelectorAll('.tab').forEach((t) => {
            t.classList.toggle('active', t.dataset.tab === tabId);
        });
    }

    SS.stopDraftPreviewPolling = function () {
        const id = SS.state.blueprint.pendingTimerId;
        if (id === null) return;
        window.clearTimeout(id);
        SS.state.blueprint.pendingTimerId = null;
    };

    function hydrateQueryInput() {
        const el = SS.byId('queryId');
        if (!el || !SS.state.jobId) return;
        if (SS.isNonEmptyString(el.value)) return;
        el.value = SS.state.jobId;
    }

    SS.showView = function (id) {
        const leavingBlueprint = SS.state.currentView === 'blueprint' && id !== 'blueprint';
        const enteringBlueprint = SS.state.currentView !== 'blueprint' && id === 'blueprint';
        if (leavingBlueprint) SS.stopDraftPreviewPolling();

        document.querySelectorAll('.view-fade').forEach((v) => v.classList.add('hidden'));
        SS.byId('view-' + id).classList.remove('hidden');
        SS.state.currentView = id;
        if (id === 'submit' || id === 'query') setActiveTab(id);
        window.scrollTo(0, 0);

        if (enteringBlueprint && SS.blueprint?.enter) void SS.blueprint.enter();
        if (id === 'query') hydrateQueryInput();
    };
    window.showView = SS.showView;

    function renderSheetOptions() {
        const panel = SS.byId('sheet-options');
        if (!panel) return;
        const filenames = SS.state.files.map((f) => f.name);
        const title = filenames.length > 0 ? SS.escapeHtml(filenames[0]) : 'Uploaded Dataset';
        panel.innerHTML =
            `<div style="padding: 16px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center;">` +
            `<div><b>${title}</b><div style="font-size: 10px; color: var(--text-muted);">Job: ${SS.escapeHtml(SS.state.jobId || '')}</div></div>` +
            `<div style="width:12px; height:12px; background:var(--text); border-radius:50%;"></div>` +
            `</div>`;
    }

    function renderFileList() {
        const list = SS.byId('fileList');
        if (!list) return;
        list.innerHTML = '';
        SS.state.files.forEach((file, idx) => {
            const item = document.createElement('div');
            item.style =
                'padding: 8px 12px; border: 1px solid var(--border); border-radius: 6px; display: flex; justify-content: space-between; align-items: center; font-size: 11px;';
            item.innerHTML = `<span class="mono">${SS.escapeHtml(file.name)}</span>`;

            const remove = document.createElement('button');
            remove.className = 'btn btn-secondary';
            remove.style = 'height: 24px; padding: 0 8px; font-size: 10px;';
            remove.textContent = '移除';
            remove.onclick = () => {
                SS.state.files.splice(idx, 1);
                renderFileList();
            };
            item.appendChild(remove);
            list.appendChild(item);
        });
    }

    function resetBlueprintState() {
        SS.stopDraftPreviewPolling();
        SS.state.blueprint.status = 'idle';
        SS.state.blueprint.preview = null;
        SS.state.blueprint.pendingRetryAfterSeconds = null;
        SS.state.blueprint.errorMessage = null;
        SS.state.blueprint.variableCorrections = {};
        SS.state.blueprint.stage1Answers = {};
        SS.state.blueprint.openUnknownValues = {};
        SS.state.blueprint.locked = false;
        SS.state.blueprint.lockedStatus = null;
        SS.state.blueprint.isPatching = false;
        SS.state.blueprint.isConfirming = false;
        SS.state.blueprint.clarificationErrorMessage = null;
    }

    async function handleNext() {
        const btn = SS.byId('btn-next');
        if (!btn) return;
        if (SS.state.files.length === 0) {
            window.alert('请先上传至少 1 个数据文件。');
            return;
        }

        btn.disabled = true;
        btn.textContent = '正在解析…';

        const requirement = SS.byId('description')?.value ?? '';
        const job = await SS.api?.createJob?.(requirement);
        if (!job || typeof job.job_id !== 'string') {
            SS.state.apiMode = 'mock';
            SS.state.jobId = 'jb_demo';
            resetBlueprintState();
            renderSheetOptions();
            SS.showView('sheets');
            btn.disabled = false;
            btn.innerHTML = '继续 <span class="shortcut">⌘ ↵</span>';
            return;
        }

        SS.state.jobId = job.job_id;
        resetBlueprintState();
        const upload = await SS.api?.uploadInputs?.(job.job_id, SS.state.files);
        if (!upload && SS.state.apiMode !== 'mock') {
            window.alert('上传失败，请确认后端服务可用后重试。');
            btn.disabled = false;
            btn.innerHTML = '继续 <span class="shortcut">⌘ ↵</span>';
            return;
        }

        renderSheetOptions();
        SS.showView('sheets');
        btn.disabled = false;
        btn.innerHTML = '继续 <span class="shortcut">⌘ ↵</span>';
    }

    function applyTpl(t) {
        const tpls = {
            ols: '分析 ESG 表现对企业价值的影响，需要控制个体与时间效应。',
            diff: '使用多时点 DID 模型分析碳交易试点政策的影响。',
        };
        SS.byId('description').value = tpls[t] ?? '';
    }
    window.applyTpl = applyTpl;

    function handleQuery() {
        const id = SS.byId('queryId')?.value ?? '';
        if (!SS.isNonEmptyString(id)) return;
        SS.byId('query-result')?.classList.remove('hidden');
        SS.byId('artifact-list').innerHTML =
            `<div style="padding: 12px; border: 1px solid var(--border); border-radius: 6px; display: flex; justify-content: space-between; align-items: center; background: var(--surface-raised);">` +
            `<span>Final_Report.pdf</span><button class="btn btn-secondary" style="height:24px; font-size:10px;">Download</button></div>`;
    }
    window.handleQuery = handleQuery;

    function copyId() {
        if (!SS.state.jobId) return;
        void navigator.clipboard.writeText(SS.state.jobId);
        const btn = event?.target;
        if (!(btn instanceof HTMLElement)) return;
        btn.innerText = 'Copied';
        setTimeout(() => (btn.innerText = 'Copy'), 2000);
    }
    window.copyId = copyId;

    function initTabs() {
        document.querySelectorAll('.tab').forEach((t) => {
            t.onclick = () => SS.showView(t.dataset.tab);
        });
    }

    function initThemeToggle() {
        const themeBtn = SS.byId('theme-toggle');
        themeBtn.onclick = () => {
            const next = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
            document.documentElement.setAttribute('data-theme', next);
            themeBtn.innerHTML =
                next === 'light'
                    ? '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"/></svg>'
                    : '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="5"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="12" y1="21" x2="12" y2="23"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/><line x1="18.36" y1="4.22" x2="19.78" y2="5.64"/></svg>';
        };
    }

    function initFiles() {
        const dropzone = SS.byId('dropzone');
        const fileInput = SS.byId('fileInput');
        dropzone.onclick = () => fileInput.click();
        fileInput.onchange = (e) => {
            const list = e.target?.files ? Array.from(e.target.files) : [];
            SS.state.files.push(...list);
            renderFileList();
        };
    }

    function initSubmitFlow() {
        SS.byId('btn-next').onclick = () => void handleNext();
    }

    function init() {
        initTabs();
        initThemeToggle();
        initFiles();
        initSubmitFlow();
        renderFileList();
    }

    init();
})();
