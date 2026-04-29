/**
 * ScheduleRepository - Repository wrapper for schedules
 * 对标 Android: ScheduleRepository.kt
 */
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleDao } from './ScheduleDao'
import emitter from '@ohos.events.emitter'

const CHANGE_EVENT_ID = 998

export class ScheduleRepository {
  private dao: ScheduleDao
  private userId: string

  constructor(dao: ScheduleDao, userId: string) {
    this.dao = dao
    this.userId = userId
  }

  async insert(item: Partial<ScheduleItem>): Promise<number> {
    const now = Date.now()
    const full: ScheduleItem = new ScheduleItem({
      id: item.id,
      userId: this.userId,
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
      createdAt: now,
      updatedAt: now,
      previewContentPriority: item.previewContentPriority
    })
    const id = await this.dao.insert(full as Partial<ScheduleItem>)
    this.notifyChange()
    return id
  }

  async update(item: Partial<ScheduleItem>): Promise<void> {
    const updated: ScheduleItem = new ScheduleItem({
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
      updatedAt: Date.now(),
      previewContentPriority: item.previewContentPriority
    })
    await this.dao.update(updated as Partial<ScheduleItem>)
    this.notifyChange()
  }

  async deleteById(id: number): Promise<void> {
    await this.dao.deleteById(id)
    this.notifyChange()
  }

  async getAll(): Promise<ScheduleItem[]> {
    return this.dao.getAll(this.userId)
  }

  async getById(id: number): Promise<ScheduleItem | null> {
    return this.dao.getById(id)
  }

  observeAll(callback: (items: ScheduleItem[]) => void): void {
    const handler = () => {
      this.getAll().then(callback)
    }
    emitter.on({ eventId: CHANGE_EVENT_ID }, handler)
  }

  notifyChange(): void {
    emitter.emit({ eventId: CHANGE_EVENT_ID })
  }
}
