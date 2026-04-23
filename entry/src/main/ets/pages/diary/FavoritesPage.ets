/**
 * 收藏列表页
 * 对标 Android FavoritesActivity
 */
import router from '@ohos.router'
import { DiaryViewModel } from '../../viewmodel/DiaryViewModel'
import { DiaryCard, DiaryWrapper } from '../../components/DiaryCard'
import promptAction from '@ohos.promptAction'

@Component
export struct FavoritesPage {
  @State diaries: DiaryWrapper[] = []
  @State showEmpty: boolean = false

  private vm: DiaryViewModel | null = null

  aboutToAppear(): void {
    this.vm = new DiaryViewModel(getContext(this))
    this.loadFavorites()
  }

  private async loadFavorites(): Promise<void> {
    await this.vm?.loadFavorites()
    this.diaries = (this.vm?.favoriteDiaries ?? []).map(d => new DiaryWrapper(d))
    this.showEmpty = this.diaries.length === 0
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('♡')
        .fontSize(60)
        .fontColor('#DDDDDD')
      Text('还没有收藏')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick((): void => { router.pop() })
        Text('收藏')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.diaries, (item: DiaryWrapper) => {
            ListItem() {
              DiaryCard({
                diaryWrapper: item,
                onClick: (): void => {
                  router.pushUrl({
                    url: 'pages/diary/DiaryViewPage',
                    params: { diaryId: item.diary.id }
                  }).catch((): void => {})
                },
                onFavoriteClick: (): void => {
                  this.vm?.toggleFavorite(item.diary)
                  this.loadFavorites()
                  promptAction.showToast({ message: '已取消收藏' })
                }
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
