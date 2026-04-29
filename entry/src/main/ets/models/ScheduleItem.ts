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
  repeatType: string
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
  repeatType: string = 'NONE'
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
    if (data.id !== undefined) this.id = data.id
    if (data.userId !== undefined) this.userId = data.userId
    if (data.scheduledAt !== undefined) this.scheduledAt = data.scheduledAt
    if (data.repeatYearly !== undefined) this.repeatYearly = data.repeatYearly
    if (data.repeatByLunar !== undefined) this.repeatByLunar = data.repeatByLunar
    if (data.repeatType !== undefined) this.repeatType = data.repeatType
    if (data.repeatRangeStart !== undefined) this.repeatRangeStart = data.repeatRangeStart
    if (data.repeatRangeEnd !== undefined) this.repeatRangeEnd = data.repeatRangeEnd
    if (data.repeatMonth !== undefined) this.repeatMonth = data.repeatMonth
    if (data.repeatDayOfMonth !== undefined) this.repeatDayOfMonth = data.repeatDayOfMonth
    if (data.repeatWeekday !== undefined) this.repeatWeekday = data.repeatWeekday
    if (data.repeatHour !== undefined) this.repeatHour = data.repeatHour
    if (data.repeatMinute !== undefined) this.repeatMinute = data.repeatMinute
    if (data.lunarMonth !== undefined) this.lunarMonth = data.lunarMonth
    if (data.lunarDay !== undefined) this.lunarDay = data.lunarDay
    if (data.lunarLeap !== undefined) this.lunarLeap = data.lunarLeap
    if (data.title !== undefined) this.title = data.title
    if (data.content !== undefined) this.content = data.content
    if (data.author !== undefined) this.author = data.author
    if (data.mood !== undefined) this.mood = data.mood
    if (data.weather !== undefined) this.weather = data.weather
    if (data.location !== undefined) this.location = data.location
    if (data.createdAt !== undefined) this.createdAt = data.createdAt
    if (data.updatedAt !== undefined) this.updatedAt = data.updatedAt
    if (data.previewContentPriority !== undefined) this.previewContentPriority = data.previewContentPriority
  }
}
