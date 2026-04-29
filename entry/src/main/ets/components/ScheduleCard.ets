/**
 * ScheduleCard - 日程卡片组件
 * 对标 Android: ScheduleCardAdapter
 */
import { ScheduleItem } from '../models/ScheduleItem'

@Component
export struct ScheduleCard {
  @ObjectLink item: ScheduleItemWrapper
  onCardClick?: (item: ScheduleItemWrapper) => void
  onCardDelete?: (item: ScheduleItemWrapper) => void

  build() {
    Column() {
      Row() {
        Text(this.item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Blank()

        if (this.item.repeatType !== 'NONE') {
          Text(this.getRepeatLabel())
            .fontSize(12)
            .fontColor('#999')
        }
      }
      .width('100%')

      Row() {
        Text(this.formatDateTime(this.item.scheduledAt))
          .fontSize(13)
          .fontColor('#666')
      }
      .width('100%')
      .margin({ top: 4 })

      if (this.item.content.length > 0) {
        Text(this.item.content)
          .fontSize(13)
          .fontColor('#888')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }

      Row() {
        Blank()
        Button('删除')
          .fontSize(12)
          .fontColor('#E53935')
          .backgroundColor(Color.Transparent)
          .onClick(() => {
          if (this.onCardDelete) {
            this.onCardDelete(this.item)
          }
        })
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .padding(16)
    .width('100%')
    .backgroundColor('#FFFFFFFF')
    .borderRadius(12)
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      if (this.onCardClick) {
        this.onCardClick(this.item)
      }
    })
  }

  private formatDateTime(millis: number): string {
    const date = new Date(millis)
    const month = date.getMonth() + 1
    const day = date.getDate()
    const hour = date.getHours().toString().padStart(2, '0')
    const minute = date.getMinutes().toString().padStart(2, '0')
    const months = ['1月', '2月', '3月', '4月', '5月', '6月', '7月', '8月', '9月', '10月', '11月', '12月']
    return `${months[date.getMonth()]}${day}日 ${hour}:${minute}`
  }

  private getRepeatLabel(): string {
    switch (this.item.repeatType) {
      case 'DAILY': return '每天'
      case 'WEEKLY': return '每周'
      case 'MONTHLY': return '每月'
      case 'YEARLY': return '每年'
      default: return ''
    }
  }
}

@Observed
export class ScheduleItemWrapper {
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

  constructor(item?: Partial<ScheduleItemWrapper>) {
    if (item) {
      if (item.id !== undefined) this.id = item.id
      if (item.userId !== undefined) this.userId = item.userId
      if (item.scheduledAt !== undefined) this.scheduledAt = item.scheduledAt
      if (item.repeatYearly !== undefined) this.repeatYearly = item.repeatYearly
      if (item.repeatByLunar !== undefined) this.repeatByLunar = item.repeatByLunar
      if (item.repeatType !== undefined) this.repeatType = item.repeatType
      if (item.repeatRangeStart !== undefined) this.repeatRangeStart = item.repeatRangeStart
      if (item.repeatRangeEnd !== undefined) this.repeatRangeEnd = item.repeatRangeEnd
      if (item.repeatMonth !== undefined) this.repeatMonth = item.repeatMonth
      if (item.repeatDayOfMonth !== undefined) this.repeatDayOfMonth = item.repeatDayOfMonth
      if (item.repeatWeekday !== undefined) this.repeatWeekday = item.repeatWeekday
      if (item.repeatHour !== undefined) this.repeatHour = item.repeatHour
      if (item.repeatMinute !== undefined) this.repeatMinute = item.repeatMinute
      if (item.lunarMonth !== undefined) this.lunarMonth = item.lunarMonth
      if (item.lunarDay !== undefined) this.lunarDay = item.lunarDay
      if (item.lunarLeap !== undefined) this.lunarLeap = item.lunarLeap
      if (item.title !== undefined) this.title = item.title
      if (item.content !== undefined) this.content = item.content
      if (item.author !== undefined) this.author = item.author
      if (item.mood !== undefined) this.mood = item.mood
      if (item.weather !== undefined) this.weather = item.weather
      if (item.location !== undefined) this.location = item.location
      if (item.createdAt !== undefined) this.createdAt = item.createdAt
      if (item.updatedAt !== undefined) this.updatedAt = item.updatedAt
      if (item.previewContentPriority !== undefined) this.previewContentPriority = item.previewContentPriority
    }
  }

  static from(item: ScheduleItem): ScheduleItemWrapper {
    return new ScheduleItemWrapper({
      id: item.id,
      userId: item.userId,
      scheduledAt: item.scheduledAt,
      repeatYearly: item.repeatYearly,
      repeatByLunar: item.repeatByLunar,
      repeatType: item.repeatType,
      repeatRangeStart: item.repeatRangeStart,
      repeatRangeEnd: item.repeatRangeEnd,
      repeatMonth: item.repeatMonth,
      repeatDayOfMonth: item.repeatDayOfMonth,
      repeatWeekday: item.repeatWeekday,
      repeatHour: item.repeatHour,
      repeatMinute: item.repeatMinute,
      lunarMonth: item.lunarMonth,
      lunarDay: item.lunarDay,
      lunarLeap: item.lunarLeap,
      title: item.title,
      content: item.content,
      author: item.author,
      mood: item.mood,
      weather: item.weather,
      location: item.location,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      previewContentPriority: item.previewContentPriority
    })
  }
}
