*! ss_smart_xtset v2.0.0 - 智能面板设置
*! 功能：
*!   1. 自动将字符串变量转换为数值 ID
*!   2. 自动去除重复的 panel-time 组合
*!   3. 智能处理数字字符串（带逗号等）
*! SS_ADO_PATH: tasks/do/includes/ss_smart_xtset.ado

program define ss_smart_xtset
    version 14.0
    syntax varlist(min=2 max=2), [FORCE NODEDUP]
    
    local panelvar : word 1 of `varlist'
    local timevar  : word 2 of `varlist'
    
    * 保存原始变量名用于后续引用  
    local orig_panelvar "`panelvar'"
    local orig_timevar "`timevar'"
    
    display as text ""
    display as text "═══════════════════════════════════════════════════════════════"
    display as text "SS_SMART_XTSET: 智能面板设置"
    display as text "═══════════════════════════════════════════════════════════════"
    
    * ========== Step 1: 检查并转换 panel 变量 ==========
    capture confirm string variable `panelvar'
    if !_rc {
        display as text "SS_INFO: 检测到字符串面板变量 `panelvar'，自动转换为数值..."
        
        * 先清理字符串（去除前后空格）
        quietly replace `panelvar' = strtrim(`panelvar')
        
        * 删除已存在的临时变量（如果有）
        capture drop _ss_panel_id
        
        * 使用 encode 转换，保留 value labels
        encode `panelvar', generate(_ss_panel_id)
        
        * 更新变量引用
        local panelvar "_ss_panel_id"
        display as text "SS_INFO: 已创建数值变量 _ss_panel_id (共 " _N " 行)"
    }
    
    * ========== Step 2: 检查并转换 time 变量 ==========
    capture confirm string variable `timevar'
    if !_rc {
        * 先清理字符串（去除前后空格和千分位逗号）
        quietly replace `timevar' = strtrim(`timevar')
        quietly replace `timevar' = subinstr(`timevar', ",", "", .)
        
        * 尝试 destring（如果内容实际是数字字符串如 "2000", "2001"）
        tempvar test_destring
        capture destring `timevar', generate(`test_destring') force
        
        if _rc == 0 {
            * destring 成功，检查是否有非缺失值
            quietly count if !missing(`test_destring')
            if r(N) > 0 {
                display as text "SS_INFO: 时间变量 `orig_timevar' 是数字字符串，使用 destring 转换..."
                capture drop _ss_time_id
                destring `timevar', generate(_ss_time_id) force
                local timevar "_ss_time_id"
                display as text "SS_INFO: 已创建数值时间变量 _ss_time_id"
            }
            else {
                * 全部是缺失值，使用 encode
                display as text "SS_INFO: 检测到字符串时间变量 `orig_timevar'，使用 encode 转换..."
                capture drop _ss_time_id
                encode `orig_timevar', generate(_ss_time_id)
                local timevar "_ss_time_id"
                display as text "SS_INFO: 已创建数值时间变量 _ss_time_id"
            }
        }
        else {
            * destring 失败，使用 encode
            display as text "SS_INFO: 检测到字符串时间变量 `orig_timevar'，使用 encode 转换..."
            capture drop _ss_time_id
            encode `orig_timevar', generate(_ss_time_id)
            local timevar "_ss_time_id"
            display as text "SS_INFO: 已创建数值时间变量 _ss_time_id"
        }
        
        * 清理临时变量
        capture drop `test_destring'
    }
    else {
        * 时间变量已经是数值型，但可能需要清理（如果是字符串转来的）
        * 检查是否有缺失值需要处理
    }
    
    * ========== Step 3: 检测并去除重复的 panel-time 组合 ==========
    if "`nodedup'" == "" {
        * 检查是否有重复
        quietly duplicates report `panelvar' `timevar'
        local n_dup = r(N) - r(unique_value)
        
        if `n_dup' > 0 {
            display as text ""
            display as result "SS_WARNING: 发现 `n_dup' 条重复的面板-时间组合"
            display as text "SS_INFO: 自动去除重复行（保留第一条）..."
            
            local n_before = _N
            duplicates drop `panelvar' `timevar', force
            local n_after = _N
            local n_dropped = `n_before' - `n_after'
            
            display as text "SS_INFO: 已去除 `n_dropped' 条重复行 (剩余 `n_after' 行)"
            display "SS_METRIC|name=n_dup_dropped|value=`n_dropped'"
        }
        else {
            display as text "SS_INFO: 未发现重复的面板-时间组合"
        }
    }
    
    * ========== Step 4: 执行 xtset ==========
    display as text ""
    display as text ">>> 正在设置面板结构: xtset `panelvar' `timevar'"
    xtset `panelvar' `timevar'
    
    * 显示面板信息
    quietly xtdescribe
    local n_panels = r(n)
    local n_times = r(max)
    display as text ""
    display as text "SS_INFO: 面板设置完成"
    display as text "    个体数: `n_panels'"
    display as text "    时间跨度: `n_times'"
    display as text "═══════════════════════════════════════════════════════════════"
    
end

