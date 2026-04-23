/**
 * 回收站页
 * 对标 Android RecycleBinActivity
 */
import router from '@ohos.router'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { Diary } from '../../model/DiaryModel'
import promptAction from '@ohos.promptAction'

@Component
export struct RecycleBinPage {
  @State trashedDiaries: Diary[] = []
  @State showEmpty: boolean = false

  private repo: DiaryRepository | null = null

  aboutToAppear(): void {
    this.repo = new DiaryRepository(getContext(this))
    this.loadTrash()
  }

  private async loadTrash(): Promise<void> {
    if (!this.repo) return
    this.trashedDiaries = await this.repo.trashedDiaries()
    this.showEmpty = this.trashedDiaries.length === 0
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('🗑️')
        .fontSize(60)
        .opacity(0.3)
      Text('回收站是空的')
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
        Text('回收站')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })

        if (!this.showEmpty) {
          Text('清空')
            .fontSize(14)
            .fontColor('#F44336')
            .onClick((): void => {
              promptAction.showDialog({
                title: '确认清空',
                message: '回收站中的日记将被永久删除，是否继续？',
                buttons: [
                  { text: '取消', color: '#999999' },
                  { text: '清空', color: '#F44336' }
                ]
              }).then(async (result): Promise<void> => {
                if (result.index === 1 && this.repo) {
                  for (const d of this.trashedDiaries) {
                    await this.repo.delete(d)
                  }
                  this.loadTrash()
                  promptAction.showToast({ message: '已清空回收站' })
                }
              }).catch((): void => {})
            })
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.trashedDiaries, (diary: Diary) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(this.formatDate(diary.date))
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  Text('回收站')
                    .fontSize(11)
                    .fontColor('#F44336')
                    .backgroundColor('#FFEBEE')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                }
                Text(diary.title || '(无标题)')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
              .onClick((): void => {
                router.pushUrl({
                  url: 'pages/diary/DiaryViewPage',
                  params: { diaryId: diary.id }
                }).catch((): void => {})
              })
              .onLongPress((): void => {
                promptAction.showActionMenu({
                  buttons: [
                    { text: '恢复', color: '#4CAF50' },
                    { text: '永久删除', color: '#F44336' },
                    { text: '取消', color: '#999999' }
                  ]
                }).then(async (result): Promise<void> => {
                  if (!this.repo) return
                  if (result.index === 0) {
                    await this.repo.restoreFromTrash(diary)
                    this.loadTrash()
                    promptAction.showToast({ message: '已恢复' })
                  } else if (result.index === 1) {
                    await this.repo.delete(diary)
                    this.loadTrash()
                    promptAction.showToast({ message: '已永久删除' })
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
