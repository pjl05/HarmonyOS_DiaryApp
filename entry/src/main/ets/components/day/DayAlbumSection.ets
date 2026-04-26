/**
 * DayAlbumSection - 相册视图
 * 对标 Android: DayPagerFragment.kt 相册模式
 */
import { DayItem, PreviewContentPriority } from '../../model/DayItem'
import router from '@ohos.router'

@Component
export struct DayAlbumSection {
  items: DayItem[] = []

  build() {
    Grid() {
      ForEach(this.items, (item: DayItem) => {
        GridItem() {
          Stack({ alignContent: Alignment.Bottom }) {
            if (item.previewContentPriority === PreviewContentPriority.IMAGE
              && this.extractFirstImage(item.content) !== '') {
              Image(this.extractFirstImage(item.content))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
            } else {
              Column() {
                Text(item.title)
                  .fontSize(13)
                  .fontColor(Color.White)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding(8)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#37474F')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
            }

            Text(item.title)
              .width('100%')
              .padding({ left: 6, right: 6, bottom: 6 })
              .fontSize(12)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [['#00000000', 0.0], ['#AA000000', 1.0]]
              })
              .borderRadius({ bottomLeft: 8, bottomRight: 8 })
          }
          .width('100%')
          .height(120)
          .onClick(() => {
            router.pushUrl({ url: 'pages/DayPage', params: { dayId: item.id } })
          })
        }
      }, (item: DayItem) => item.id.toString())
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .padding(8)
  }

  private extractFirstImage(html: string): string {
    const match = html.match(/<img[^>]+src="([^"]+)"/)
    return match ? match[1] : ''
  }
}
