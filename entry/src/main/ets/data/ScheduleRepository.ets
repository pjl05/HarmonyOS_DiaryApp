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
    const full: Partial<ScheduleItem> = {
      ...item,
      userId: this.userId,
      createdAt: now,
      updatedAt: now
    }
    const id = await this.dao.insert(full)
    this.notifyChange()
    return id
  }

  async update(item: Partial<ScheduleItem>): Promise<number> {
    const updated = { ...item, updatedAt: Date.now() }
    const result = await this.dao.update(updated)
    this.notifyChange()
    return result
  }

  async deleteById(id: number): Promise<number> {
    const result = await this.dao.deleteById(id)
    this.notifyChange()
    return result
  }

  async getAll(): Promise<ScheduleItem[]> {
    return this.dao.getAll(this.userId)
  }

  async getById(id: number): Promise<ScheduleItem | null> {
    return this.dao.getById(id)
  }

  observeAll(callback: (items: ScheduleItem[]) => void): emitter.EventId {
    const handler = () => {
      this.getAll().then(callback)
    }
    return emitter.on({ eventId: CHANGE_EVENT_ID }, handler)
  }

  notifyChange(): void {
    emitter.emit({ eventId: CHANGE_EVENT_ID })
  }
}
