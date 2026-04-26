/**
 * DayViewModel - 单条日子 ViewModel
 * 对标 Android: DiaryViewModel.kt 模式
 */
import { DayItem } from '../model/DayItem'
import { DayRepository } from '../data/repository/DayRepository'

export class DayViewModel {
  private repository: DayRepository
  dayItem: DayItem | null = null
  isLoading: boolean = false
  error: string = ''

  constructor(repository: DayRepository) {
    this.repository = repository
  }

  async loadDay(id: number): Promise<void> {
    this.isLoading = true
    try {
      this.dayItem = await this.repository.getDayById(id)
    } catch (e) {
      this.error = (e as Error)?.message ?? '加载失败'
    } finally {
      this.isLoading = false
    }
  }

  async deleteDay(id: number): Promise<void> {
    await this.repository.deleteDay(id)
    this.dayItem = null
  }
}
