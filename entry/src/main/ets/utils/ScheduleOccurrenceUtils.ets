/**
 * ScheduleOccurrenceUtils - 下次发生时间计算
 * 对标 Android: ScheduleOccurrenceUtils.kt
 */
import { ScheduleItem } from '../models/ScheduleItem'

export class ScheduleOccurrenceUtils {
  static nextOccurrenceMillis(item: ScheduleItem, nowMillis: number): number | null {
    if (item.repeatType === 'NONE') {
      if (item.scheduledAt < nowMillis) return null
      return item.scheduledAt
    }

    switch (item.repeatType) {
      case 'DAILY': return ScheduleOccurrenceUtils.nextDaily(item, nowMillis)
      case 'WEEKLY': return ScheduleOccurrenceUtils.nextWeekly(item, nowMillis)
      case 'MONTHLY': return ScheduleOccurrenceUtils.nextMonthly(item, nowMillis)
      case 'YEARLY': return ScheduleOccurrenceUtils.nextYearly(item, nowMillis)
      default: return item.scheduledAt
    }
  }

  private static nextDaily(item: ScheduleItem, nowMillis: number): number {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    base.setHours(now.getHours(), now.getMinutes(), now.getSeconds(), 0)
    if (base.getTime() <= nowMillis) {
      base.setDate(base.getDate() + 1)
    }
    if (item.repeatRangeEnd !== null && base.getTime() > item.repeatRangeEnd) {
      return nowMillis + 86400000
    }
    return base.getTime()
  }

  private static nextWeekly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const targetWeekday = item.repeatWeekday
    const currentWeekday = now.getDay()
    const daysUntilTarget = (targetWeekday - currentWeekday + 7) % 7
    const nextDate = new Date(now)
    nextDate.setDate(nextDate.getDate() + (daysUntilTarget === 0 ? 7 : daysUntilTarget))
    nextDate.setHours(base.getHours(), base.getMinutes(), 0, 0)
    if (item.repeatRangeEnd !== null && nextDate.getTime() > item.repeatRangeEnd) {
      return null
    }
    return nextDate.getTime()
  }

  private static nextMonthly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const targetDay = item.repeatDayOfMonth || base.getDate()
    const next = new Date(now.getFullYear(), now.getMonth(), targetDay, base.getHours(), base.getMinutes(), 0, 0)
    if (next.getTime() <= nowMillis) {
      next.setMonth(next.getMonth() + 1)
    }
    if (item.repeatRangeEnd !== null && next.getTime() > item.repeatRangeEnd) {
      return null
    }
    return next.getTime()
  }

  private static nextYearly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const next = new Date(now.getFullYear(), base.getMonth(), base.getDate(), base.getHours(), base.getMinutes(), 0, 0)
    if (next.getTime() <= nowMillis) {
      next.setFullYear(next.getFullYear() + 1)
    }
    if (item.repeatRangeEnd !== null && next.getTime() > item.repeatRangeEnd) {
      return null
    }
    return next.getTime()
  }
}