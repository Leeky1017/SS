#!/usr/bin/env python3
"""批量生成meta.json"""
import json
from pathlib import Path

with open('tasks/tasks_index.json', 'r', encoding='utf-8') as f:
    tasks = json.load(f)

FAMILY_CONFIG = {
    'data_management': {'level': 'basic', 'metrics': ['n_input', 'n_output', 'n_dropped']},
    'descriptive': {'level': 'basic', 'metrics': ['n_obs', 'n_vars']},
    'hypothesis_testing': {'level': 'basic', 'metrics': ['test_stat', 'p_value', 'effect_size']},
    'linear_regression': {'level': 'intermediate', 'metrics': ['n_obs', 'r_squared', 'f_stat', 'f_pvalue']},
    'limited_dependent': {'level': 'intermediate', 'metrics': ['n_obs', 'pseudo_r2', 'chi2', 'p_value']},
    'panel_policy': {'level': 'advanced', 'metrics': ['n_groups', 'n_obs', 'r2_within', 'r2_overall']},
    'time_series': {'level': 'advanced', 'metrics': ['n_obs', 'aic', 'bic']},
    'survival': {'level': 'advanced', 'metrics': ['n_obs', 'n_events', 'chi2', 'p_value']},
    'multivariate': {'level': 'advanced', 'metrics': ['n_obs', 'n_components', 'variance_explained']},
    'utility': {'level': 'basic', 'metrics': ['n_files', 'n_outputs']},
}

PH_TYPES = {
    '__NUMERIC_VARS__': ('varlist', True),
    '__ID_VAR__': ('varname', False),
    '__TIME_VAR__': ('varname', False),
    '__GROUP_VAR__': ('varname', True),
    '__DEP_VAR__': ('varname', True),
    '__INDEP_VAR__': ('varname', True),
    '__INDEP_VARS__': ('varlist', True),
    '__FILTER_CONDITION__': ('expression', False),
    '__SAMPLE_FRACTION__': ('number', False),
    '__RANDOM_SEED__': ('integer', False),
    '__MERGE_KEYS__': ('varlist', True),
    '__MERGE_TYPE__': ('string', True),
    '__KEEP_OPTION__': ('string', False),
    '__KEY_VARS__': ('varlist', False),
    '__RESHAPE_DIRECTION__': ('string', True),
    '__STUB_VARS__': ('varlist', True),
    '__CLUSTER_VAR__': ('varname', False),
    '__TEST_VALUE__': ('number', True),
    '__VAR1__': ('varname', True),
    '__VAR2__': ('varname', True),
    '__TREATMENT_VAR__': ('varname', True),
    '__POST_VAR__': ('varname', True),
    '__CONTROL_VARS__': ('varlist', False),
    '__EVENT_VAR__': ('varname', True),
    '__TIME_TO_EVENT__': ('varname', True),
    '__ANALYSIS_VARS__': ('varlist', True),
    '__N_COMPONENTS__': ('integer', False),
    '__N_CLUSTERS__': ('integer', True),
    '__LAGS__': ('integer', False),
    '__HORIZON__': ('integer', False),
}

meta_dir = Path('tasks/do/meta')
meta_dir.mkdir(exist_ok=True)

count = 0
for task in tasks:
    family = task.get('family', 'unknown')
    config = FAMILY_CONFIG.get(family, {'level': 'intermediate', 'metrics': ['n_obs']})
    
    placeholders = {}
    for ph in task.get('placeholders', []):
        ph_type, required = PH_TYPES.get(ph, ('string', False))
        placeholders[ph] = {
            'type': ph_type,
            'required': required,
            'default': '',
            'description': ph.replace('__', '').lower()
        }
    
    outputs = {'tables': [], 'figures': [], 'data': [], 'reports': []}
    for out in task.get('outputs', []):
        if out == 'result.log':
            continue
        if out.endswith('.csv') or out.endswith('.xlsx'):
            outputs['tables'].append(out)
        elif out.endswith('.png') or out.endswith('.pdf'):
            outputs['figures'].append(out)
        elif out.endswith('.dta'):
            outputs['data'].append(out)
    
    inputs = {'required': [], 'optional': []}
    for req in task.get('requires', []):
        role = 'main_dataset'
        if 'using' in req:
            role = 'merge_table'
        elif 'append' in req:
            role = 'appendix'
        inputs['required'].append({'file': req, 'role': role})
    
    test_params = {}
    for ph in task.get('placeholders', [])[:2]:
        test_params[ph] = 'test_value'
    
    meta = {
        'task_id': task['id'],
        'version': '2.0.0',
        'family': family,
        'title': task['name'],
        'level': config['level'],
        'capabilities': [task['slug']],
        'inputs': inputs,
        'dependencies': {'official': [], 'community': []},
        'outputs': outputs,
        'placeholders': placeholders,
        'expected_anchors': {
            'SS_TASK_START': 1,
            'SS_TASK_END': 1,
            'SS_OUTPUT_FILE': '>=1',
            'SS_METRIC': '>=1'
        },
        'required_metrics': config['metrics'],
        'test_cases': [
            {
                'name': 'basic',
                'fixture': f"fixtures/{task['id']}/sample_data.csv",
                'params': test_params,
                'expected_success': True
            }
        ]
    }
    
    meta_path = meta_dir / f"{task['id']}_meta.json"
    with open(meta_path, 'w', encoding='utf-8') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
    count += 1

print(f'Generated {count} meta.json files in tasks/do/meta/')
