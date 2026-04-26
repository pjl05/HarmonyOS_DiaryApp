/**
 * ScheduleDetailViewModel - 日程详情 VM
 * 对标 Android: ScheduleViewActivity
 */
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

class ScheduleDetailViewModel {
  @State scheduleId: number = 0
  @State title: string = ''
  @State content: string = ''
  @State scheduledAt: number = Date.now()
  @State repeatType: string = 'NONE'
  @State repeatYearly: boolean = false
  @State repeatByLunar: boolean = false
  @State repeatMonth: number = 0
  @State repeatDayOfMonth: number = 1
  @State repeatWeekday: number = 1
  @State repeatHour: number = -1
  @State repeatMinute: number = 0
  @State lunarMonth: number = 0
  @State lunarDay: number = 0
  @State lunarLeap: boolean = false
  @State mood: string = ''
  @State weather: string = ''
  @State location: string = ''
  @State isLoading: boolean = false
  @State isEditing: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository, scheduleId: number) {
    this.repository = repository
    this.scheduleId = scheduleId
    this.isEditing = scheduleId === 0

    if (scheduleId > 0) {
      this.isLoading = true
      try {
        const item = await repository.getById(scheduleId)
        if (item) {
          this.title = item.title
          this.content = item.content
          this.scheduledAt = item.scheduledAt
          this.repeatType = item.repeatType
          this.repeatYearly = item.repeatYearly
          this.repeatByLunar = item.repeatByLunar
          this.repeatMonth = item.repeatMonth
          this.repeatDayOfMonth = item.repeatDayOfMonth
          this.repeatWeekday = item.repeatWeekday
          this.repeatHour = item.repeatHour
          this.repeatMinute = item.repeatMinute
          this.lunarMonth = item.lunarMonth
          this.lunarDay = item.lunarDay
          this.lunarLeap = item.lunarLeap
          this.mood = item.mood || ''
          this.weather = item.weather || ''
          this.location = item.location || ''
        }
      } catch (e) {
        promptAction.showToast({ message: '加载失败' })
      } finally {
        this.isLoading = false
      }
    }
  }

  async save() {
    if (!this.repository) return
    if (this.title.trim().length === 0) {
      promptAction.showToast({ message: '请输入标题' })
      return
    }

    this.isLoading = true
    try {
      const data: Partial<ScheduleItem> = {
        title: this.title.trim(),
        content: this.content,
        scheduledAt: this.scheduledAt,
        repeatType: this.repeatType as any,
        repeatYearly: this.repeatYearly,
        repeatByLunar: this.repeatByLunar,
        repeatMonth: this.repeatMonth,
        repeatDayOfMonth: this.repeatDayOfMonth,
        repeatWeekday: this.repeatWeekday,
        repeatHour: this.repeatHour,
        repeatMinute: this.repeatMinute,
        lunarMonth: this.lunarMonth,
        lunarDay: this.lunarDay,
        lunarLeap: this.lunarLeap,
        mood: this.mood || null,
        weather: this.weather || null,
        location: this.location || null
      }

      if (this.scheduleId > 0) {
        data.id = this.scheduleId
        await this.repository.update(data)
        await ReminderService.cancel(this.scheduleId)
        await ReminderService.schedule(new ScheduleItem(data), 5)
      } else {
        const id = await this.repository.insert(data)
        await ReminderService.schedule(new ScheduleItem({ ...data, id }), 5)
      }

      promptAction.showToast({ message: '保存成功' })
      router.back()
    } catch (e) {
      promptAction.showToast({ message: '保存失败' })
    } finally {
      this.isLoading = false
    }
  }

  setDate(millis: number) {
    this.scheduledAt = millis
  }

  setRepeat(type: string) {
    this.repeatType = type
  }
}

export { ScheduleDetailViewModel }
