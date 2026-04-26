/**
 * DayTimeUtils - 已过/剩余天数计算
 * 对标 Android: DayViewActivity.kt 天数显示逻辑
 */

/**
 * 计算 startAt 距今天数差值。正数=已过去，负数=未来。
 */
export function calcDaysDiff(startAt: string): number {
  const start = new Date(startAt).setHours(0, 0, 0, 0)
  const today = new Date().setHours(0, 0, 0, 0)
  const msPerDay = 24 * 60 * 60 * 1000
  return Math.round((today - start) / msPerDay)
}

/**
 * 格式化为"已过 X 天"或"还有 X 天"或"就是今天"。
 */
export function formatDaysDiff(startAt: string): string {
  const diff = calcDaysDiff(startAt)
  if (diff === 0) return '就是今天'
  if (diff > 0) return `已过 ${diff} 天`
  return `还有 ${Math.abs(diff)} 天`
}
