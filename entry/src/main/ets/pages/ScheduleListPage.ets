/**
 * ScheduleListPage - 日程列表页
 * 对标 Android: ScheduleActivity
 */
import router from '@ohos.router'
import { SimpleStorage } from '../utils/SimpleStorage'
import { ScheduleListViewModel } from '../viewmodel/ScheduleListViewModel'
import { ScheduleCard, ScheduleItemWrapper } from '../components/ScheduleCard'
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct ScheduleListPage {
  @State viewModel: ScheduleListViewModel = new ScheduleListViewModel()
  private repository: ScheduleRepository | null = null

  aboutToAppear() {
    this.initRepository()
  }

  async initRepository() {
    const context = SimpleStorage.get<Context>('appContext')!
    const dao = new ScheduleDao(context)
    const userId = SimpleStorage.get<string>('userId') || 'default'
    this.repository = new ScheduleRepository(dao, userId)
    await this.viewModel.init(this.repository)
  }

  build() {
    Stack() {
      if (this.viewModel.isEmpty && !this.viewModel.isLoading) {
        Column() {
          Text('暂无日程')
            .fontSize(16)
            .fontColor('#999')
          Text('点击右下角添加日程')
            .fontSize(13)
            .fontColor('#CCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      if (!this.viewModel.isEmpty) {
        List() {
          ForEach(this.viewModel.schedules, (item: ScheduleItem) => {
            ListItem() {
              ScheduleCard({
                item: ScheduleItemWrapper.from(item),
                onCardClick: (wrapper: ScheduleItemWrapper): void => this.viewModel.openScheduleDetailById(wrapper.id),
                onCardDelete: (wrapper: ScheduleItemWrapper) => this.handleDelete(wrapper)
              })
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }

      Button()
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#1890FF')
        .position({ x: '80%', y: '85%' })
        .onClick(() => this.viewModel.openCreatePage())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  async handleDelete(wrapper: ScheduleItemWrapper) {
    const action = await promptAction.showActionMenu({
      title: '删除日程',
      buttons: [
        { text: '确认删除', color: '#E53935' },
        { text: '取消', color: '#999999' }
      ]
    })
    if (action.index === 0) {
      await this.viewModel.deleteScheduleById(wrapper.id)
    }
  }
}
