/**
 * AlarmFullscreenPage - 全屏闹钟页
 * 对标 Android: ScheduleAlarmFullscreenActivity
 */
import router from '@ohos.router'
import window from '@ohos.window'
import { emitter } from '@ohos.events.emitter'

@Entry
@Component
struct AlarmFullscreenPage {
  @State currentTime: string = ''
  @State currentDate: string = ''
  @State scheduleTitle: string = ''
  @State scheduleMessage: string = ''
  private timerId: number = -1
  private scheduleId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, string | number>
    this.scheduleId = params?.scheduleId as number || 0
    this.scheduleTitle = params?.title as string || '日程提醒'
    this.scheduleMessage = params?.message as string || ''

    this.updateTime()
    this.timerId = setInterval(() => this.updateTime(), 1000)
    this.setKeepScreenOn(true)
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    this.setKeepScreenOn(false)
  }

  private async setKeepScreenOn(on: boolean) {
    try {
      const context = AppStorage.get<Context>('appContext')!
      const win = await window.getLastWindow(context)
      await win.setKeepScreenOn(on)
    } catch (_) {}
  }

  private updateTime() {
    const now = new Date()
    this.currentTime = now.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
    this.currentDate = now.toLocaleDateString('zh-CN', { weekday: 'long', month: 'long', day: 'numeric' })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A2E')

      Column() {
        Text('🔔')
          .fontSize(48)
          .margin({ top: 80 })

        Text(this.scheduleTitle || '日程提醒')
          .fontSize(22)
          .fontColor('#FFF')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 24 })

        Text(this.scheduleMessage || '您有一个日程即将开始')
          .fontSize(15)
          .fontColor('#AAA')
          .margin({ top: 8 })

        Blank()

        Text(this.currentTime)
          .fontSize(72)
          .fontColor('#FFF')
          .fontWeight(FontWeight.Light)

        Text(this.currentDate)
          .fontSize(16)
          .fontColor('#888')
          .margin({ top: 8 })

        Blank()

        Row() {
          Button('关闭')
            .width(140)
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#444')
            .borderRadius(24)
            .onClick(() => {
              this.stopAlarm()
            })

          Button('查看详情')
            .width(140)
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#1890FF')
            .borderRadius(24)
            .onClick(() => {
              this.stopAlarm()
              router.pushUrl({
                url: 'pages/ScheduleDetailPage',
                params: { scheduleId: this.scheduleId }
              })
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ bottom: 60 })
      }
      .width('100%')
      .height('100%')
    }
  }

  private stopAlarm() {
    if (this.scheduleId > 0) {
      emitter.emit({ eventId: this.scheduleId })
    }
    router.back()
  }
}
