/**
 * ScheduleDetailPage - 日程详情页
 * 对标 Android: ScheduleViewActivity
 */
import router from '@ohos.router'
import { ScheduleDetailViewModel } from '../viewmodel/ScheduleDetailViewModel'
import { RepeatRulePicker } from '../components/RepeatRulePicker'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'

@Entry
@Component
struct ScheduleDetailPage {
  @State viewModel: ScheduleDetailViewModel = new ScheduleDetailViewModel()
  private repository: ScheduleRepository | null = null
  @State showRepeatPicker: boolean = false

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>
    const scheduleId = params?.scheduleId || 0
    this.initRepository(scheduleId)
  }

  async initRepository(scheduleId: number) {
    const context = AppStorage.get<Context>('appContext')!
    const dao = new ScheduleDao(context)
    const userId = AppStorage.get<string>('userId') || 'default'
    this.repository = new ScheduleRepository(dao, userId)
    await this.viewModel.init(this.repository, scheduleId)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          TextInput({ placeholder: '日程标题', text: this.viewModel.title })
            .width('100%')
            .height(48)
            .fontSize(16)
            .onChange((value: string) => { this.viewModel.title = value })

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          Row() {
            Text('日期时间')
              .fontSize(14)
              .fontColor('#666')
            Blank()
            Text(this.formatDateTime(this.viewModel.scheduledAt))
              .fontSize(14)
              .fontColor('#333')
              .onClick(() => this.showDatePicker())
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          Row() {
            Text('重复')
              .fontSize(14)
              .fontColor('#666')
            Blank()
            Text(this.getRepeatLabel())
              .fontSize(14)
              .fontColor('#333')
              .onClick(() => { this.showRepeatPicker = !this.showRepeatPicker })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })

          if (this.showRepeatPicker) {
            RepeatRulePicker({
              selectedType: this.viewModel.repeatType as any,
              selectedWeekday: this.viewModel.repeatWeekday,
              selectedDayOfMonth: this.viewModel.repeatDayOfMonth,
              repeatRangeStart: this.viewModel.repeatRangeStart as any,
              repeatRangeEnd: this.viewModel.repeatRangeEnd as any
            })
          }

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          TextArea({ placeholder: '日程内容...', text: this.viewModel.content })
            .width('100%')
            .height(120)
            .fontSize(15)
            .onChange((value: string) => { this.viewModel.content = value })

          Button('保存')
            .width('100%')
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#1890FF')
            .margin({ top: 24 })
            .onClick(() => this.viewModel.save())
        }
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .title('日程详情')
    .onBackPressed(() => {
      router.back()
    })
  }

  private formatDateTime(millis: number): string {
    const date = new Date(millis)
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  private getRepeatLabel(): string {
    switch (this.viewModel.repeatType) {
      case 'NONE': return '不重复'
      case 'DAILY': return '每天'
      case 'WEEKLY': return '每周'
      case 'MONTHLY': return '每月'
      case 'YEARLY': return '每年'
      default: return '不重复'
    }
  }

  private showDatePicker() {
    DatePickerDialog.show({
      start: new Date(),
      selected: new Date(this.viewModel.scheduledAt),
      onAccept: (result) => {
        this.viewModel.setDate(result.time)
      }
    })
  }
}
