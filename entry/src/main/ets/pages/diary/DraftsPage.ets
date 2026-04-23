/**
 * 草稿箱页
 * 对标 Android DraftsActivity
 */
import router from '@ohos.router'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { DraftDiary } from '../../model/DraftDiaryModel'
import promptAction from '@ohos.promptAction'

@Component
export struct DraftsPage {
  @State drafts: DraftDiary[] = []
  @State showEmpty: boolean = false

  private repo: DiaryRepository | null = null

  aboutToAppear(): void {
    this.repo = new DiaryRepository(getContext(this))
    this.loadDrafts()
  }

  private async loadDrafts(): Promise<void> {
    if (!this.repo) return
    this.drafts = await this.repo.allDrafts()
    this.showEmpty = this.drafts.length === 0
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('📝')
        .fontSize(60)
        .opacity(0.3)
      Text('草稿箱是空的')
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
          .onClick((): void => { router.back() })
        Text('草稿箱')
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
          ForEach(this.drafts, (draft: DraftDiary) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(this.formatDate(draft.date))
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  Text('草稿')
                    .fontSize(11)
                    .fontColor('#FF9800')
                    .backgroundColor('#FFF3E0')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                }
                Text(draft.title || '(无标题)')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(draft.content.replace(/<[^>]*>/g, '').trim())
                  .fontSize(13)
                  .fontColor('#888888')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
              .onClick((): void => {
                router.pushUrl({
                  url: 'pages/diary/DiaryEditPage',
                  params: { draftId: draft.id }
                }).catch((): void => {})
              })
              .onLongPress((): void => {
                promptAction.showActionMenu({
                  buttons: [
                    { text: '删除草稿', color: '#F44336' },
                    { text: '取消', color: '#999999' }
                  ]
                }).then(async (result): Promise<void> => {
                  if (result.index === 0 && this.repo) {
                    await this.repo.deleteDraft(draft.id)
                    this.loadDrafts()
                    promptAction.showToast({ message: '草稿已删除' })
                  }
                }).catch((): void => {})
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