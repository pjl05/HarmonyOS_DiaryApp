/**
 * ScheduleCard - 日程卡片组件
 * 对标 Android: ScheduleCardAdapter
 */
import { ScheduleItem } from '../models/ScheduleItem'

@Component
export struct ScheduleCard {
  @ObjectLink item: ScheduleItemWrapper
  onClick?: (item: ScheduleItem) => void
  onDelete?: (item: ScheduleItem) => void

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
            if (this.onDelete) {
              this.onDelete(this.item)
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
      if (this.onClick) {
        this.onClick(this.item)
      }
    })
  }

  private formatDateTime(millis: number): string {
    const date = new Date(millis)
    const fmt = new Intl.DateTimeFormat('zh-CN', {
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
    return fmt.format(date)
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
      Object.assign(this, item)
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
