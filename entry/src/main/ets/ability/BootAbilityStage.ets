/**
 * BootAbilityStage - 开机自启能力
 * 对标 Android: ScheduleBootReceiver
 * 使用 HarmonyOS AbilityStage 替代 Android BroadcastReceiver
 */
import AbilityStage from '@ohos.app.ability.AbilityStage'
import { ReminderService } from '../services/ReminderService'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'

export default class BootAbilityStage extends AbilityStage {
  onAcceptWant(want: Want): string {
    this.rescheduleAllReminders()
    return 'BootAbilityStage'
  }

  private async rescheduleAllReminders() {
    try {
      const context = this.context
      const dao = new ScheduleDao(context)
      const userId = AppStorage.get<string>('userId') || 'default'
      const repo = new ScheduleRepository(dao, userId)

      const items = await repo.getAll()
      await ReminderService.rescheduleAll(items, 5)

      console.info('BootAbilityStage: Rescheduled all reminders')
    } catch (e) {
      console.error('BootAbilityStage: Failed to reschedule', JSON.stringify(e))
    }
  }
}
