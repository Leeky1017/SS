export function formatTaskReference(jobId: string | null): string {
  if (jobId === null) return ''
  const trimmed = jobId.trim()
  if (trimmed === '') return ''

  const withoutPrefix = trimmed.replace(/^job[_-]?/i, '')
  const compact = withoutPrefix.replace(/[^a-zA-Z0-9]/g, '')
  if (compact === '') return '任务'
  if (compact.length <= 8) return `任务-${compact}`
  return `任务-${compact.slice(0, 4)}…${compact.slice(-4)}`
}
