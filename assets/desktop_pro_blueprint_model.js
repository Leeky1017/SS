(function () {
    const SS = window.SSDesktopPro;
    if (!SS) return;

    const model = SS.blueprintModel || (SS.blueprintModel = {});

    model.normalizeDraftPreview = function (raw) {
        const obj = raw && typeof raw === 'object' ? raw : {};
        return {
            draft_id: typeof obj.draft_id === 'string' ? obj.draft_id : null,
            decision: typeof obj.decision === 'string' ? obj.decision : 'require_confirm',
            risk_score: typeof obj.risk_score === 'number' ? obj.risk_score : null,
            status: typeof obj.status === 'string' ? obj.status : null,
            outcome_var: typeof obj.outcome_var === 'string' ? obj.outcome_var : null,
            treatment_var: typeof obj.treatment_var === 'string' ? obj.treatment_var : null,
            controls: SS.toStringArray(obj.controls),
            column_candidates: SS.toStringArray(obj.column_candidates),
            variable_types: Array.isArray(obj.variable_types) ? obj.variable_types : [],
            data_quality_warnings: Array.isArray(obj.data_quality_warnings) ? obj.data_quality_warnings : [],
            stage1_questions: Array.isArray(obj.stage1_questions) ? obj.stage1_questions : [],
            open_unknowns: Array.isArray(obj.open_unknowns) ? obj.open_unknowns : [],
        };
    };

    model.getCandidateColumns = function (preview) {
        if (!preview) return [];
        if (Array.isArray(preview.column_candidates) && preview.column_candidates.length > 0) {
            return SS.uniqueStrings(preview.column_candidates);
        }
        const fromTypes = (Array.isArray(preview.variable_types) ? preview.variable_types : [])
            .map((v) => (v && typeof v.name === 'string' ? v.name : ''))
            .filter((x) => x !== '');
        if (fromTypes.length > 0) return SS.uniqueStrings(fromTypes);
        return SS.uniqueStrings([preview.outcome_var, preview.treatment_var, ...preview.controls].filter((x) => typeof x === 'string'));
    };

    model.getCorrectedVar = function (name) {
        if (!SS.isNonEmptyString(name)) return null;
        const corrected = SS.state.blueprint.variableCorrections[name];
        if (SS.isNonEmptyString(corrected) && corrected !== name) return corrected;
        return name;
    };

    model.isBlockingUnknown = function (unknown) {
        if (unknown && typeof unknown.blocking === 'boolean') return unknown.blocking;
        const impact = typeof unknown?.impact === 'string' ? unknown.impact.toLowerCase() : '';
        return impact === 'high' || impact === 'critical';
    };

    model.unansweredStage1 = function (preview) {
        const missing = [];
        for (const q of preview.stage1_questions || []) {
            const qid = typeof q?.question_id === 'string' ? q.question_id : '';
            if (!qid) continue;
            const selected = SS.state.blueprint.stage1Answers[qid];
            if (!Array.isArray(selected) || selected.length === 0) missing.push(qid);
        }
        return missing;
    };

    model.missingBlockingUnknownValues = function (preview) {
        const missing = [];
        for (const u of preview.open_unknowns || []) {
            if (!model.isBlockingUnknown(u)) continue;
            const field = typeof u?.field === 'string' ? u.field : '';
            if (!field) continue;
            const v = SS.state.blueprint.openUnknownValues[field];
            if (!SS.isNonEmptyString(v)) missing.push(field);
        }
        return missing;
    };
})();
