/**
 * DayRepository - 数据仓库
 * 对标 Android: DiaryRepository.kt 模式
 */
import { DayItem } from '../../model/DayItem'
import { DayDao } from '../dao/DayDao'

export class DayRepository {
  private dao: DayDao

  constructor(dao: DayDao) {
    this.dao = dao
  }

  async getDays(userId: string): Promise<DayItem[]> {
    return this.dao.queryAll(userId)
  }

  async getDayById(id: number): Promise<DayItem | null> {
    return this.dao.queryById(id)
  }

  async addDay(item: DayItem): Promise<number> {
    return this.dao.insert(item)
  }

  async updateDay(item: DayItem): Promise<void> {
    return this.dao.update(item)
  }

  async deleteDay(id: number): Promise<void> {
    return this.dao.delete(id)
  }
}
