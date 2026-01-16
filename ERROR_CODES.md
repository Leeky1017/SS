# SS 系统错误代号索引
本文档供内部排查使用，不对外公开。

说明：
- `内部错误名`：系统内部 `error_code`（或前端本地错误名），用于定位问题。
- `用户显示文本`：前端对用户展示的文案（统一为“错误代号 + 友好提示”），不得包含实现细节。

## E1XXX - 输入验证错误
| 代号 | 内部错误名 | 用户显示文本 | 可能原因 |
|------|-----------|-------------|---------|
| E1001 | DRAFT_CONFIRM_BLOCKED | 错误代号 E1001：必填项未完成，请补充后继续 | 必填信息/确认未完成 |
| E1001 | MISSING_REQUIRED_FIELD | 错误代号 E1001：必填项未完成，请补充后继续 | 必填信息/确认未完成 |
| E1001 | PLAN_FREEZE_MISSING_REQUIRED | 错误代号 E1001：必填项未完成，请补充后继续 | 必填信息/确认未完成 |
| E1002 | ADMIN_BEARER_TOKEN_INVALID | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | ADMIN_BEARER_TOKEN_MISSING | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | ADMIN_CREDENTIALS_INVALID | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | ADMIN_TOKEN_INVALID | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | ADMIN_TOKEN_NOT_FOUND | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | AUTH_BEARER_TOKEN_INVALID | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | AUTH_BEARER_TOKEN_MISSING | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | AUTH_TOKEN_FORBIDDEN | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | AUTH_TOKEN_INVALID | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1002 | JOB_NOT_FOUND | 错误代号 E1002：验证信息无效，请重新验证后继续 | 验证信息缺失/无效/过期 |
| E1003 | TASK_CODE_INVALID | 错误代号 E1003：验证码无效，请检查后重试 | 验证码无效或不存在 |
| E1003 | TASK_CODE_NOT_FOUND | 错误代号 E1003：验证码无效，请检查后重试 | 验证码无效或不存在 |
| E1004 | TASK_CODE_EXPIRED | 错误代号 E1004：验证码已失效，请重新获取 | 验证码过期/已撤销 |
| E1004 | TASK_CODE_REVOKED | 错误代号 E1004：验证码已失效，请重新获取 | 验证码过期/已撤销 |
| E1005 | TASK_CODE_REDEEM_CONFLICT | 错误代号 E1005：验证码暂不可用，请稍后重试 | 验证码冲突或暂不可用 |
| E1006 | ARTIFACT_PATH_UNSAFE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | CONTRACT_COLUMN_NOT_FOUND | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_DATASET_KEY_CONFLICT | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_EXCEL_SHEET_NOT_FOUND | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_EXCEL_SHEET_SELECTION_UNSUPPORTED | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_FILENAME_COUNT_MISMATCH | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_FILENAME_UNSAFE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_MAIN_DATA_SOURCE_NOT_FOUND | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_PATH_UNSAFE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_PRIMARY_DATASET_MISSING | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_PRIMARY_DATASET_MULTIPLE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_ROLE_COUNT_MISMATCH | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_ROLE_INVALID | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | INPUT_VALIDATION_FAILED | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | JOB_ID_UNSAFE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | TENANT_ID_UNSAFE | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | API_HTTP_ERROR | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | API_METHOD_NOT_ALLOWED | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1006 | API_NOT_FOUND | 错误代号 E1006：选择项无效，请重新选择后继续 | 选择项无效或输入不符合要求 |
| E1007 | UPLOAD_FILE_SIZE_LIMIT_EXCEEDED | 错误代号 E1007：文件过大，请更换文件后重试 | 文件大小超出限制 |
| E1008 | INPUT_UNSUPPORTED_FORMAT | 错误代号 E1008：文件格式不支持，请更换文件后重试 | 文件格式不支持 |
| E1009 | INPUT_EMPTY_FILE | 错误代号 E1009：文件为空，请检查后重试 | 文件为空 |
| E1010 | BUNDLE_NOT_FOUND | 错误代号 E1010：上传未完成，请重新上传后继续 | 上传未完成或上传会话失效 |
| E1010 | FILE_NOT_FOUND | 错误代号 E1010：上传未完成，请重新上传后继续 | 上传未完成或上传会话失效 |
| E1010 | UPLOAD_INCOMPLETE | 错误代号 E1010：上传未完成，请重新上传后继续 | 上传未完成或上传会话失效 |
| E1010 | UPLOAD_SESSION_EXPIRED | 错误代号 E1010：上传未完成，请重新上传后继续 | 上传未完成或上传会话失效 |
| E1010 | UPLOAD_SESSION_NOT_FOUND | 错误代号 E1010：上传未完成，请重新上传后继续 | 上传未完成或上传会话失效 |
| E1011 | CHECKSUM_MISMATCH | 错误代号 E1011：文件校验失败，请重新上传后重试 | 上传校验失败 |
| E1011 | UPLOAD_PARTS_INVALID | 错误代号 E1011：文件校验失败，请重新上传后重试 | 上传校验失败 |
| E1012 | BUNDLE_FILES_LIMIT_EXCEEDED | 错误代号 E1012：上传数量或次数超出限制，请稍后再试 | 上传数量/次数超出限制 |
| E1012 | UPLOAD_MULTIPART_LIMIT_EXCEEDED | 错误代号 E1012：上传数量或次数超出限制，请稍后再试 | 上传数量/次数超出限制 |
| E1012 | UPLOAD_SESSIONS_LIMIT_EXCEEDED | 错误代号 E1012：上传数量或次数超出限制，请稍后再试 | 上传数量/次数超出限制 |

## E2XXX - 数据处理错误
| 代号 | 内部错误名 | 用户显示文本 | 可能原因 |
|------|-----------|-------------|---------|
| E2001 | CLIENT_PARSE_ERROR | 错误代号 E2001：数据格式解析失败，请检查文件格式 | 数据格式无法解析 |
| E2001 | INPUT_PARSE_FAILED | 错误代号 E2001：数据格式解析失败，请检查文件格式 | 数据格式无法解析 |
| E2001 | JSON_PARSE_ERROR | 错误代号 E2001：数据格式解析失败，请检查文件格式 | 数据格式无法解析 |
| E2002 | BUNDLE_CORRUPTED | 错误代号 E2002：数据异常，请重新上传或稍后重试 | 数据损坏/不一致/被污染 |
| E2002 | DO_TEMPLATE_INDEX_CORRUPTED | 错误代号 E2002：数据异常，请重新上传或稍后重试 | 数据损坏/不一致/被污染 |
| E2002 | JOB_DATA_CORRUPTED | 错误代号 E2002：数据异常，请重新上传或稍后重试 | 数据损坏/不一致/被污染 |
| E2002 | QUEUE_DATA_CORRUPTED | 错误代号 E2002：数据异常，请重新上传或稍后重试 | 数据损坏/不一致/被污染 |
| E2002 | UPLOAD_SESSION_CORRUPTED | 错误代号 E2002：数据异常，请重新上传或稍后重试 | 数据损坏/不一致/被污染 |
| E2003 | ARTIFACT_NOT_FOUND | 错误代号 E2003：数据读取失败，请稍后重试 | 数据读取失败（文件缺失/权限/IO） |
| E2003 | INPUTS_MANIFEST_READ_FAILED | 错误代号 E2003：数据读取失败，请稍后重试 | 数据读取失败（文件缺失/权限/IO） |

## E3XXX - 分析执行错误
| 代号 | 内部错误名 | 用户显示文本 | 可能原因 |
|------|-----------|-------------|---------|
| E3001 | DRAFT_PREVIEW_FAILED | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_CALL_CONTEXT_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_EMPTY_STEPS | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_JSON_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_MAX_STEPS_EXCEEDED | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_SCHEMA_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_STEP_ID_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_STEP_ID_UNSAFE | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_STEP_TYPE_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_TEMPLATE_ID_INVALID | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_TEMPLATE_ID_UNSUPPORTED | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3001 | PLAN_GEN_UNSUPPORTED_STEP_TYPE | 错误代号 E3001：分析预览生成失败，请稍后重试 | 预览/方案生成失败 |
| E3002 | DO_TEMPLATE_SELECTION_INVALID_FAMILY_ID | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | DO_TEMPLATE_SELECTION_INVALID_TEMPLATE_ID | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | DO_TEMPLATE_SELECTION_NOT_WIRED | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | DO_TEMPLATE_SELECTION_NO_CANDIDATES | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | DO_TEMPLATE_SELECTION_PARSE_FAILED | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | INPUTS_MANIFEST_INVALID | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | INPUTS_MANIFEST_MISSING | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | INPUTS_MANIFEST_UNSAFE | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_ALREADY_FROZEN_CONFLICT | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_ARTIFACTS_WRITE_FAILED | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_COMPOSITION_INVALID | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_FREEZE_NOT_ALLOWED | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_MISSING | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_TEMPLATE_META_INVALID | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3002 | PLAN_TEMPLATE_META_NOT_FOUND | 错误代号 E3002：分析准备未完成，请稍后重试 | 分析准备条件不足（缺少必要资源） |
| E3003 | DOFILE_INPUTS_MANIFEST_INVALID | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DOFILE_PLAN_INVALID | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DOFILE_TEMPLATE_UNSUPPORTED | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_ARTIFACTS_WRITE_FAILED | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_CONTRACT_INVALID | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_INDEX_NOT_FOUND | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_META_INVALID | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_META_NOT_FOUND | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_NOT_FOUND | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_OUTPUT_ARCHIVE_FAILED | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_PARAM_INVALID | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_PARAM_MISSING | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3003 | DO_TEMPLATE_SOURCE_NOT_FOUND | 错误代号 E3003：分析配置有误，请检查后重试 | 分析配置不合法/不支持 |
| E3004 | STATA_ARTIFACTS_WRITE_FAILED | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_DOFILE_UNSAFE | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_DOFILE_WRITE_FAILED | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_INPUTS_COPY_FAILED | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_INPUTS_UNSAFE | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_NONZERO_EXIT | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3004 | STATA_WORKSPACE_INVALID | 错误代号 E3004：分析执行失败，请稍后重试 | 分析执行失败（运行错误） |
| E3005 | COMPOSITION_PIPELINE_ERROR_WRITE_FAILED | 错误代号 E3005：结果文件生成失败，请稍后重试 | 结果/日志等文件生成或归档失败 |
| E3005 | OUTPUT_FORMATS_INVALID | 错误代号 E3005：结果文件生成失败，请稍后重试 | 结果/日志等文件生成或归档失败 |
| E3005 | OUTPUT_FORMATTER_FAILED | 错误代号 E3005：结果文件生成失败，请稍后重试 | 结果/日志等文件生成或归档失败 |
| E3005 | WORKER_ARTIFACTS_WRITE_FAILED | 错误代号 E3005：结果文件生成失败，请稍后重试 | 结果/日志等文件生成或归档失败 |

## E4XXX - 系统服务错误
| 代号 | 内部错误名 | 用户显示文本 | 可能原因 |
|------|-----------|-------------|---------|
| E4001 | LLM_CALL_FAILED | 错误代号 E4001：分析服务暂时不可用，请稍后重试 | 分析服务调用失败 |
| E4001 | LLM_RESPONSE_INVALID | 错误代号 E4001：分析服务暂时不可用，请稍后重试 | 分析服务返回格式异常（非 JSON/截断/字段缺失等） |
| E4002 | ADMIN_STORE_IO_ERROR | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | INPUT_STORAGE_FAILED | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | JOB_STORE_IO_ERROR | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | LLM_ARTIFACTS_WRITE_FAILED | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | OBJECT_STORE_OPERATION_FAILED | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | QUEUE_IO_ERROR | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | RESOURCE_OOM | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | SERVICE_SHUTTING_DOWN | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | TASK_CODE_DATA_CORRUPTED | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4002 | TASK_CODE_STORE_IO_ERROR | 错误代号 E4002：系统服务暂时不可用，请稍后重试 | 系统依赖异常（IO/队列/存储等） |
| E4003 | JOB_STORE_BACKEND_UNSUPPORTED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | LLM_CONFIG_INVALID | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | OBJECT_STORE_CONFIG_INVALID | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_CMD_INVALID | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_CMD_NOT_CONFIGURED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_CMD_NOT_FOUND | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_DEPENDENCY_MISSING | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_DEPENDENCY_PREFLIGHT_FAILED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_DEPENDENCY_PREFLIGHT_READ_FAILED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_DEPENDENCY_PREFLIGHT_SUBPROCESS_FAILED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | STATA_DEPENDENCY_PREFLIGHT_WRITE_FAILED | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4003 | WSL_INTEROP_UNAVAILABLE | 错误代号 E4003：系统配置异常，请联系支持 | 系统配置缺失/无效 |
| E4004 | ADMIN_NOT_CONFIGURED | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | CLIENT_RENDER_ERROR | 错误代号 E4004：系统异常，请稍后重试 | 页面渲染异常 |
| E4004 | JOB_ALREADY_EXISTS | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | JOB_ILLEGAL_TRANSITION | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | JOB_LOCKED | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | JOB_VERSION_CONFLICT | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SERVICE_INTERNAL_ERROR | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_FIXTURE_COPY_FAILED | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_FIXTURE_NOT_FOUND | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_MANIFEST_INVALID | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_MANIFEST_INVALID_JSON | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_MANIFEST_NOT_FOUND | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |
| E4004 | SMOKE_SUITE_MANIFEST_READ_FAILED | 错误代号 E4004：系统异常，请稍后重试 | 未分类系统异常 |

## E5XXX - 网络/超时错误
| 代号 | 内部错误名 | 用户显示文本 | 可能原因 |
|------|-----------|-------------|---------|
| E5001 | API_TIMEOUT | 错误代号 E5001：连接超时或网络不稳定，请检查网络后重试 | 网络不可达/连接失败 |
| E5001 | CLIENT_NETWORK_ERROR | 错误代号 E5001：连接超时或网络不稳定，请检查网络后重试 | 网络不可达/连接失败 |
| E5002 | CLIENT_TIMEOUT | 错误代号 E5002：操作超时，请稍后重试 | 操作超时 |
| E5002 | STATA_DEPENDENCY_PREFLIGHT_TIMEOUT | 错误代号 E5002：操作超时，请稍后重试 | 操作超时 |
