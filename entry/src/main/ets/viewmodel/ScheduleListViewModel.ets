/**
 * ScheduleListViewModel - 日程列表 VM
 * 对标 Android: ScheduleActivity
 */
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ScheduleItemWrapper } from '../components/ScheduleCard'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

class ScheduleListViewModel {
  @State schedules: ScheduleItem[] = []
  @State isLoading: boolean = false
  @State isEmpty: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository) {
    this.repository = repository
    repository.observeAll((items) => {
      this.schedules = items
      this.isEmpty = items.length === 0
    })
    await this.loadSchedules()
  }

  async loadSchedules() {
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

  async deleteSchedule(item: ScheduleItem) {
    if (!this.repository) return
    try {
      await ReminderService.cancel(item.id)
      await this.repository.deleteById(item.id)
      promptAction.showToast({ message: '已删除' })
    } catch (e) {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  openScheduleDetail(item: ScheduleItem) {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: item.id }
    })
  }

  openCreatePage() {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: 0 }
    })
  }
}

export { ScheduleListViewModel }
