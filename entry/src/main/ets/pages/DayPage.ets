/**
 * DayPage - 日子详情页
 * 对标 Android: DayViewActivity.kt
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DayViewModel } from '../viewmodel/DayViewModel'
import { DayRepository } from '../data/repository/DayRepository'
import { DayDao } from '../data/dao/DayDao'
import { formatDaysDiff } from '../util/DayTimeUtils'
import { DayItem } from '../model/DayItem'
import relationalStore from '@ohos.data.relationalStore'

@Entry
@Component
struct DayPage {
  @State private vm: DayViewModel = new DayViewModel(
    new DayRepository(new DayDao(AppStorage.get('dayRdb') as relationalStore.RdbStore))
  )
  @State private dayId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>
    this.dayId = params?.dayId ?? 0
    this.vm.loadDay(this.dayId)
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back'))
          .width(24).height(24)
          .onClick(() => router.back())

        Text('日子详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Image($r('app.media.ic_delete'))
          .width(24).height(24)
          .onClick(() => this.confirmDelete())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.vm.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 60 })
      } else if (this.vm.dayItem !== null) {
        this.buildContent(this.vm.dayItem!)
      } else {
        Text('日子不存在').margin({ top: 60 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildContent(item: DayItem) {
    Scroll() {
      Column() {
        Text(formatDaysDiff(item.startAt))
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C3E50')
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 32, bottom: 8 })

        Text(new Date(item.startAt).toLocaleDateString('zh-CN', {
          year: 'numeric', month: 'long', day: 'numeric'
        }))
          .fontSize(14)
          .fontColor('#9E9E9E')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 24 })

        Column() {
          Text(item.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          if (item.author !== '') {
            Text(`作者：${item.author}`)
              .fontSize(13)
              .fontColor('#757575')
              .margin({ top: 8 })
          }

          if (item.location !== '') {
            Row() {
              Image($r('app.media.ic_location'))
                .width(14).height(14).fillColor('#9E9E9E')
              Text(item.location)
                .fontSize(13)
                .fontColor('#9E9E9E')
                .margin({ left: 4 })
            }
            .margin({ top: 6 })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 12 })
        .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })

        if (item.content !== '') {
          Column() {
            RichText(item.content)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 24 })
          .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
  }

  private async confirmDelete() {
    promptAction.showDialog({
      title: '删除日子',
      message: `确定删除"${this.vm.dayItem?.title ?? ''}"？`,
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '删除', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.vm.deleteDay(this.dayId).then(() => {
          router.back()
        })
      }
    })
  }
}
