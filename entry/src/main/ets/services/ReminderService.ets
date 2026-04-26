/**
 * ReminderService - 闹钟提醒服务
 * 对标 Android: ScheduleAlarmScheduler
 * 使用 HarmonyOS ReminderAgentManager 替代 Android AlarmManager
 */
import reminderAgentManager from '@ohos.reminderAgentManager'
import wantAgent from '@ohos.wantAgent'
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleOccurrenceUtils } from '../utils/ScheduleOccurrenceUtils'

export class ReminderService {
  private static activeReminders: Set<number> = new Set()

  static async schedule(item: ScheduleItem, leadMinutes: number = 5): Promise<boolean> {
    try {
      const now = AppStorage.get<number>('currentTimeMillis') ?? Date.now()
      const nextAt = ScheduleOccurrenceUtils.nextOccurrenceMillis(item, now)
      if (nextAt === null) return false

      const triggerAt = nextAt - leadMinutes * 60_000
      if (triggerAt <= now) return false

      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: new Date(triggerAt).getFullYear(),
          month: new Date(triggerAt).getMonth() + 1,
          day: new Date(triggerAt).getDate(),
          hour: new Date(triggerAt).getHours(),
          minute: new Date(triggerAt).getMinutes()
        },
        repeatMonths: [],
        repeatDays: [],
        title: item.title,
        content: item.content || '日程提醒',
        wantAgent: {
          wants: [
            {
              bundleName: 'com.vhenge.diaryapp',
              abilityName: 'EntryAbility'
            }
          ],
          operationType: wantAgent.OperationType.START_ABILITY,
          requestCode: 0,
          wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
        }
      }

      const reminderId = await reminderAgentManager.addReminder(reminderRequest)
      this.activeReminders.add(item.id)
      return reminderId > 0
    } catch (e) {
      console.error('Failed to schedule reminder:', JSON.stringify(e))
      return false
    }
  }

  static async cancel(scheduleId: number): Promise<boolean> {
    try {
      if (!this.activeReminders.has(scheduleId)) return true
      const reminderId = this.getReminderId(scheduleId)
      if (reminderId !== null) {
        await reminderAgentManager.cancelReminder(reminderId)
      }
      this.activeReminders.delete(scheduleId)
      return true
    } catch (e) {
      console.error('Failed to cancel reminder:', JSON.stringify(e))
      return false
    }
  }

  static async rescheduleAll(items: ScheduleItem[], leadMinutes: number = 5): Promise<void> {
    for (const id of this.activeReminders) {
      await this.cancel(id)
    }
    for (const item of items) {
      await this.schedule(item, leadMinutes)
    }
  }

  static async cancelAll(): Promise<void> {
    for (const id of this.activeReminders) {
      await this.cancel(id)
    }
  }

  private static getReminderId(scheduleId: number): number | null {
    return scheduleId > 0 ? scheduleId : null
  }
}
