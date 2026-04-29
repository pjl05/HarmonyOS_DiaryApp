/**
 * ScheduleListViewModel - 日程列表 VM
 * 对标 Android: ScheduleActivity
 */
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

@Observed
export class ScheduleListViewModel {
  schedules: ScheduleItem[] = []
  isLoading: boolean = false
  isEmpty: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository): Promise<void> {
    this.repository = repository
    repository.observeAll((items: ScheduleItem[]): void => {
      this.schedules = items
      this.isEmpty = items.length === 0
    })
    await this.loadSchedules()
  }

  async loadSchedules(): Promise<void> {
    if (!this.repository) return
    this.isLoading = true
    try {
      const items = await this.repository.getAll()
      this.schedules = items
      this.isEmpty = items.length === 0
    } catch (e) {
      promptAction.showToast({ message: '加载日程失败' })
    } finally {
      this.isLoading = false
    }
  }

  async deleteSchedule(item: ScheduleItem): Promise<void> {
    if (!this.repository) return
    try {
      await ReminderService.cancel(item.id)
      await this.repository.deleteById(item.id)
      promptAction.showToast({ message: '已删除' })
    } catch (e) {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  async deleteScheduleById(scheduleId: number): Promise<void> {
    if (!this.repository) return
    try {
      await ReminderService.cancel(scheduleId)
      await this.repository.deleteById(scheduleId)
      promptAction.showToast({ message: '已删除' })
    } catch (e) {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  openScheduleDetail(item: ScheduleItem): void {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: item.id }
    })
  }

  openScheduleDetailById(scheduleId: number): void {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId }
    })
  }

  openCreatePage(): void {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: 0 }
    })
  }
}