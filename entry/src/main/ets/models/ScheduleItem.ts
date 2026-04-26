/**
 * ScheduleItem - 日程数据模型
 * 对标 Android: ScheduleItem.kt
 */
export interface ScheduleItemInterface {
  id: number
  userId: string
  scheduledAt: number
  repeatYearly: boolean
  repeatByLunar: boolean
  repeatType: 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | 'CUSTOM'
  repeatRangeStart: number | null
  repeatRangeEnd: number | null
  repeatMonth: number
  repeatDayOfMonth: number
  repeatWeekday: number
  repeatHour: number
  repeatMinute: number
  lunarMonth: number
  lunarDay: number
  lunarLeap: boolean
  title: string
  content: string
  author: string | null
  mood: string | null
  weather: string | null
  location: string | null
  createdAt: number
  updatedAt: number
  previewContentPriority: string
}

export class ScheduleItem implements ScheduleItemInterface {
  id: number = 0
  userId: string = ''
  scheduledAt: number = 0
  repeatYearly: boolean = false
  repeatByLunar: boolean = false
  repeatType: 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | 'CUSTOM' = 'NONE'
  repeatRangeStart: number | null = null
  repeatRangeEnd: number | null = null
  repeatMonth: number = 0
  repeatDayOfMonth: number = 0
  repeatWeekday: number = 0
  repeatHour: number = -1
  repeatMinute: number = 0
  lunarMonth: number = 0
  lunarDay: number = 0
  lunarLeap: boolean = false
  title: string = ''
  content: string = ''
  author: string | null = null
  mood: string | null = null
  weather: string | null = null
  location: string | null = null
  createdAt: number = 0
  updatedAt: number = 0
  previewContentPriority: string = 'text'

  constructor(data: Partial<ScheduleItemInterface> = {}) {
    Object.assign(this, data)
  }
}
