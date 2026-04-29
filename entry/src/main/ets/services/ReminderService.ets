/**
 * ReminderService - 闹钟提醒服务
 * 对标 Android: ScheduleAlarmScheduler
 * 使用 HarmonyOS ReminderAgentManager 替代 Android AlarmManager
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit'
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleOccurrenceUtils } from '../utils/ScheduleOccurrenceUtils'

export class ReminderService {
  private static activeReminders: Set<number> = new Set()

  static async schedule(item: ScheduleItem, leadMinutes: number = 5): Promise<boolean> {
    try {
      const now = Date.now()
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
          pkgName: 'com.vhenge.diaryapp',
          abilityName: 'EntryAbility'
        }
      }

      const reminderId: number = await reminderAgentManager.publishReminder(reminderRequest)
      ReminderService.activeReminders.add(item.id)
      return reminderId > 0
    } catch (e) {
      console.error('Failed to schedule reminder:', JSON.stringify(e))
      return false
    }
  }

  static async cancel(scheduleId: number): Promise<boolean> {
    try {
      if (!ReminderService.activeReminders.has(scheduleId)) return true
      ReminderService.activeReminders.delete(scheduleId)
      return true
    } catch (e) {
      console.error('Failed to cancel reminder:', JSON.stringify(e))
      return false
    }
  }

  static async rescheduleAll(items: ScheduleItem[], leadMinutes: number = 5): Promise<void> {
    for (const id of ReminderService.activeReminders) {
      await ReminderService.cancel(id)
    }
    for (const item of items) {
      await ReminderService.schedule(item, leadMinutes)
    }
  }

  static async cancelAll(): Promise<void> {
    for (const id of ReminderService.activeReminders) {
      await ReminderService.cancel(id)
    }
  }
}