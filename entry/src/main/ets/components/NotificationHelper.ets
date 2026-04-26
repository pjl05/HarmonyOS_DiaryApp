/**
 * NotificationHelper - 通知帮助类
 * 对标 Android: NotificationManager
 */
import notificationManager from '@ohos.notificationManager'
import wantAgent from '@ohos.wantAgent'
import { ScheduleItem } from '../model/ScheduleItem'

export class NotificationHelper {
  static async init(): Promise<void> {
    const isEnabled = await notificationManager.isNotificationEnabled()
    if (!isEnabled) {
      console.warn('Notifications are disabled')
      return
    }
    await notificationManager.addSlot('schedule_reminder')
  }

  static async publishScheduleReminder(item: ScheduleItem, triggerAt: number): Promise<boolean> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.vhenge.diaryapp',
            abilityName: 'EntryAbility'
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0
      }

      const agent = await wantAgent.getWantAgent(wantAgentInfo)

      const request: notificationManager.NotificationRequest = {
        id: item.id,
        slotType: notificationManager.SlotType.CONTENT_INFORMATION,
        wantAgent: agent,
        title: item.title,
        content: item.content || '日程提醒',
        deliveryTime: triggerAt
      }

      await notificationManager.publish(request)
      return true
    } catch (e) {
      console.error('Failed to publish notification:', JSON.stringify(e))
      return false
    }
  }

  static async cancelNotification(id: number): Promise<boolean> {
    try {
      await notificationManager.cancel(id)
      return true
    } catch (e) {
      console.error('Failed to cancel notification:', JSON.stringify(e))
      return false
    }
  }

  static async cancelAll(): Promise<void> {
    try {
      await notificationManager.cancelAll()
    } catch (e) {
      console.error('Failed to cancel all:', JSON.stringify(e))
    }
  }
}
