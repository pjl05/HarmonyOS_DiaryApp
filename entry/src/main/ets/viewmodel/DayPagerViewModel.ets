/**
 * DayPagerViewModel - 三视图切换 ViewModel
 * 对标 Android: DayPagerFragment.kt viewMode 逻辑
 */
import { DayItem } from '../model/DayItem'
import { DayRepository } from '../data/repository/DayRepository'
import { TimelineSection, buildTimelineGroups } from '../components/day/DayTimelineModels'

export enum ViewMode {
  CARD = 0,
  TIMELINE = 1,
  ALBUM = 2
}

export class DayPagerViewModel {
  private repository: DayRepository
  days: DayItem[] = []
  timelineSections: TimelineSection[] = []
  viewMode: ViewMode = ViewMode.CARD
  isLoading: boolean = false
  error: string = ''

  constructor(repository: DayRepository) {
    this.repository = repository
  }

  async loadDays(userId: string): Promise<void> {
    this.isLoading = true
    try {
      this.days = await this.repository.getDays(userId)
      this.timelineSections = buildTimelineGroups(this.days)
    } catch (e) {
      this.error = (e as Error)?.message ?? '加载失败'
    } finally {
      this.isLoading = false
    }
  }

  cycleViewMode(): void {
    const modes = [ViewMode.CARD, ViewMode.TIMELINE, ViewMode.ALBUM]
    const next = (this.viewMode + 1) % modes.length
    this.viewMode = modes[next]
  }

  async deleteDay(id: number): Promise<void> {
    await this.repository.deleteDay(id)
    this.days = this.days.filter(d => d.id !== id)
    this.timelineSections = buildTimelineGroups(this.days)
  }
}
