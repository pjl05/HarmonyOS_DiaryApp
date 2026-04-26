/**
 * DayTimelineModels - 时间轴分组数据结构
 * 对标 Android: DayTimelineAdapter.kt 分组逻辑
 */
import { DayItem } from '../../model/DayItem'

export interface TimelineSection {
  yearMonth: string   // e.g. "2022年 3月"
  items: DayItem[]
}

/**
 * 将 DayItem[] 按年月分组，返回 TimelineSection[]。
 * 传入的 items 应已按 startAt 降序排列。
 */
export function buildTimelineGroups(items: DayItem[]): TimelineSection[] {
  const map = new Map<string, DayItem[]>()
  for (const item of items) {
    const d = new Date(item.startAt)
    const key = `${d.getFullYear()}年 ${d.getMonth() + 1}月`
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(item)
  }
  const sections: TimelineSection[] = []
  map.forEach((dayItems, yearMonth) => {
    sections.push({ yearMonth, items: dayItems })
  })
  return sections
}
