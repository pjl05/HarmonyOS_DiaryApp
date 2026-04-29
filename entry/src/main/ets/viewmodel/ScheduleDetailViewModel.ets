/**
 * ScheduleDetailViewModel - 日程详情 VM
 * 对标 Android: ScheduleViewActivity
 */
import { ScheduleItem, ScheduleItemInterface } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

@Observed
export class ScheduleDetailViewModel {
  scheduleId: number = 0
  title: string = ''
  content: string = ''
  scheduledAt: number = Date.now()
  repeatType: string = 'NONE'
  repeatYearly: boolean = false
  repeatByLunar: boolean = false
  repeatMonth: number = 0
  repeatDayOfMonth: number = 1
  repeatWeekday: number = 1
  repeatHour: number = -1
  repeatMinute: number = 0
  lunarMonth: number = 0
  lunarDay: number = 0
  lunarLeap: boolean = false
  mood: string = ''
  weather: string = ''
  location: string = ''
  isLoading: boolean = false
  isEditing: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository, scheduleId: number): Promise<void> {
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

  async save(): Promise<void> {
    if (!this.repository) return
    if (this.title.trim().length === 0) {
      promptAction.showToast({ message: '请输入标题' })
      return
    }

    this.isLoading = true
    try {
      const data: ScheduleItemInterface = {
        id: this.scheduleId > 0 ? this.scheduleId : 0,
        userId: '',
        title: this.title.trim(),
        content: this.content,
        scheduledAt: this.scheduledAt,
        repeatYearly: this.repeatYearly,
        repeatByLunar: this.repeatByLunar,
        repeatType: this.repeatType as 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | 'CUSTOM',
        repeatRangeStart: null,
        repeatRangeEnd: null,
        repeatMonth: this.repeatMonth,
        repeatDayOfMonth: this.repeatDayOfMonth,
        repeatWeekday: this.repeatWeekday,
        repeatHour: this.repeatHour,
        repeatMinute: this.repeatMinute,
        lunarMonth: this.lunarMonth,
        lunarDay: this.lunarDay,
        lunarLeap: this.lunarLeap,
        author: null,
        mood: this.mood || null,
        weather: this.weather || null,
        location: this.location || null,
        createdAt: 0,
        updatedAt: Date.now(),
        previewContentPriority: 'text'
      }

      if (this.scheduleId > 0) {
        data.id = this.scheduleId
        await this.repository.update(data)
        await ReminderService.cancel(this.scheduleId)
        await ReminderService.schedule(new ScheduleItem(data), 5)
      } else {
        const id = await this.repository.insert(data)
        const newItem = new ScheduleItem({
          id: id,
          title: data.title!,
          content: data.content!,
          scheduledAt: data.scheduledAt!,
          repeatType: data.repeatType!,
          repeatYearly: data.repeatYearly!,
          repeatByLunar: data.repeatByLunar!,
          repeatMonth: data.repeatMonth!,
          repeatDayOfMonth: data.repeatDayOfMonth!,
          repeatWeekday: data.repeatWeekday!,
          repeatHour: data.repeatHour!,
          repeatMinute: data.repeatMinute!,
          lunarMonth: data.lunarMonth!,
          lunarDay: data.lunarDay!,
          lunarLeap: data.lunarLeap!,
          mood: data.mood,
          weather: data.weather,
          location: data.location
        })
        await ReminderService.schedule(newItem, 5)
      }

      promptAction.showToast({ message: '保存成功' })
      router.back()
    } catch (e) {
      promptAction.showToast({ message: '保存失败' })
    } finally {
      this.isLoading = false
    }
  }

  setDate(millis: number): void {
    this.scheduledAt = millis
  }

  setRepeat(type: string): void {
    this.repeatType = type
  }
}