/**
 * DayCard - 卡片视图单项（Swiper item）
 * 对标 Android: DayCardAdapter.kt
 */
import { DayItem, PreviewContentPriority } from '../../model/DayItem'
import { formatDaysDiff } from '../../util/DayTimeUtils'
import router from '@ohos.router'

@Component
export struct DayCard {
  @ObjectLink item: DayItem

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.item.previewContentPriority === PreviewContentPriority.IMAGE
        && this.extractFirstImage(this.item.content) !== '') {
        Image(this.extractFirstImage(this.item.content))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(16)
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#2C3E50')
          .borderRadius(16)
      }

      Column() {
        Text(this.item.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(formatDaysDiff(this.item.startAt))
          .fontSize(14)
          .fontColor('#E0E0E0')
          .margin({ top: 4 })

        if (this.item.previewContentPriority === PreviewContentPriority.TEXT) {
          Text(this.stripHtml(this.item.content))
            .fontSize(13)
            .fontColor('#BDBDBD')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding(16)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [['#00000000', 0.0], ['#CC000000', 1.0]]
      })
      .borderRadius({ bottomLeft: 16, bottomRight: 16 })
    }
    .width('100%')
    .height(360)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/DayPage',
        params: { dayId: this.item.id }
      })
    })
  }

  private extractFirstImage(html: string): string {
    const match = html.match(/<img[^>]+src="([^"]+)"/)
    return match ? match[1] : ''
  }

  private stripHtml(html: string): string {
    return html.replace(/<[^>]*>/g, '').trim()
  }
}
