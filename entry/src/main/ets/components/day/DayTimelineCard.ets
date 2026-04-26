/**
 * DayTimelineCard - 时间轴视图单项
 * 对标 Android: DayTimelineAdapter.kt Card ViewHolder
 * 支持 PanGesture 左滑删除
 */
import { DayItem } from '../../model/DayItem'
import { formatDaysDiff } from '../../util/DayTimeUtils'
import router from '@ohos.router'

@Component
export struct DayTimelineCard {
  @ObjectLink item: DayItem
  onDelete: (id: number) => void = () => {}

  @State private offsetX: number = 0
  private readonly DELETE_THRESHOLD: number = -80

  build() {
    Stack() {
      Row() {
        Blank()
        Text('删除')
          .fontColor(Color.White)
          .fontSize(14)
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F44336')
      .justifyContent(FlexAlign.End)
      .padding({ right: 20 })
      .borderRadius(12)
      .visibility(this.offsetX < -20 ? Visibility.Visible : Visibility.Hidden)

      Row() {
        Column() {
          Text(formatDaysDiff(this.item.startAt))
            .fontSize(12)
            .fontColor('#9E9E9E')
            .textAlign(TextAlign.Center)
        }
        .width(60)

        Divider()
          .vertical(true)
          .height('80%')
          .color('#E0E0E0')
          .margin({ left: 4, right: 12 })

        Column() {
          Text(this.item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(new Date(this.item.startAt).toLocaleDateString('zh-CN'))
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
      .translate({ x: this.offsetX })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionUpdate((event: GestureEvent) => {
            const dx = event.offsetX
            if (dx < 0) this.offsetX = Math.max(dx, -120)
          })
          .onActionEnd(() => {
            if (this.offsetX < this.DELETE_THRESHOLD) {
              this.onDelete(this.item.id)
            }
            animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
              this.offsetX = 0
            })
          })
      )
      .onClick(() => {
        router.pushUrl({
          url: 'pages/DayPage',
          params: { dayId: this.item.id }
        })
      })
    }
    .width('100%')
    .height(80)
    .margin({ bottom: 8 })
  }
}
