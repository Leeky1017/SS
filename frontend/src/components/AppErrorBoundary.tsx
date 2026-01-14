import type { ReactNode } from 'react'
import { Component } from 'react'
import type { ApiError } from '../api/errors'
import { requestId } from '../api/utils'
import { toUserErrorMessage } from '../utils/errorCodes'
import { ErrorPanel } from './ErrorPanel'

type AppErrorBoundaryProps = { children: ReactNode }

type AppErrorBoundaryState = { error: ApiError | null }

export class AppErrorBoundary extends Component<AppErrorBoundaryProps, AppErrorBoundaryState> {
  state: AppErrorBoundaryState = { error: null }

  componentDidCatch(_error: Error) {
    const internalCode = 'CLIENT_RENDER_ERROR'
    const kind = 'http'
    const status = null
    const rid = requestId()
    this.setState({
      error: {
        kind,
        status,
        message: toUserErrorMessage({ internalCode, kind, status }),
        requestId: rid,
        details: null,
        internalCode,
        action: 'retry',
      },
    })
  }

  render() {
    if (this.state.error === null) return this.props.children
    return <ErrorPanel error={this.state.error} onRetry={() => window.location.reload()} retryLabel="刷新页面" />
  }
}
