import type { ApiError } from '../../api/errors'
import { formatUserErrorMessage } from '../../utils/errorCodes'

export function localValidationError(message: string, requestId: string): ApiError {
  const internalCode = 'MISSING_REQUIRED_FIELD'
  return {
    kind: 'http',
    status: 400,
    message: formatUserErrorMessage('E1001', message),
    requestId,
    details: null,
    internalCode,
    action: 'retry',
  }
}
