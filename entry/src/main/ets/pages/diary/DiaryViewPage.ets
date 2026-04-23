/**
 * 日记查看页面
 * 对标 Android DiaryViewActivity
 * 显示日记完整内容，支持编辑/删除/收藏操作菜单
 */
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { Diary } from '../../model/DiaryModel'
import { Logger } from '../../utils/Logger'

@Entry
@Component
struct DiaryViewPage {
  @State diary: Diary | null = null
  @State isLoading: boolean = true

  private diaryId: number = 0
  private repo: DiaryRepository | null = null

  async aboutToAppear(): Promise<void> {
    const params = router.getParams() as Record<string, Object>
    this.diaryId = (params?.diaryId as number) ?? 0

    if (this.diaryId <= 0) {
      promptAction.showToast({ message: '日记不存在' })
      router.pop()
      return
    }

    this.repo = new DiaryRepository(getContext(this))
    this.diary = await this.repo.findById(this.diaryId)
    this.isLoading = false

    if (!this.diary) {
      promptAction.showToast({ message: '日记不存在' })
      router.pop()
    }
  }

  private formatFullDate(millis: number): string {
    const d = new Date(millis)
    const weekday = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][d.getDay()]
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 ${weekday}`
  }

  private showOptionsMenu(): void {
    const diary = this.diary
    if (!diary) return

    promptAction.showActionMenu({
      buttons: [
        { text: '编辑', color: '#2196F3' },
        { text: diary.isFavorite ? '取消收藏' : '收藏', color: '#FF9800' },
        { text: '移至回收站', color: '#F44336' },
        { text: '取消', color: '#999999' }
      ]
    }).then(async (result): Promise<void> => {
      if (!this.repo || !this.diary) return
      switch (result.index) {
        case 0:
          router.pushUrl({
            url: 'pages/diary/DiaryEditPage',
            params: { diaryId: this.diaryId }
          }).catch((): void => {})
          break
        case 1:
          await this.repo.toggleFavorite(this.diary)
          this.diary = await this.repo.findById(this.diaryId)
          break
        case 2:
          await this.repo.moveToTrash(this.diary)
          promptAction.showToast({ message: '已移至回收站' })
          router.pop()
          break
      }
    }).catch((): void => {})
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick((): void => { router.pop() })
        Blank()
        Text('⋮')
          .fontSize(22)
          .fontColor('#333333')
          .onClick((): void => { this.showOptionsMenu() })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.diary) {
        Scroll() {
          Column({ space: 16 }) {
            Column({ space: 8 }) {
              Text(this.formatFullDate(this.diary.date))
                .fontSize(14)
                .fontColor('#888888')

              if (this.diary.title) {
                Text(this.diary.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
              }

              Row({ space: 12 }) {
                Text(`${this.getWeatherEmoji(this.diary.weather)} ${this.getWeatherLabel(this.diary.weather)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                Text(`${this.getMoodEmoji(this.diary.mood)} ${this.getMoodLabel(this.diary.mood)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                if (this.diary.location) {
                  Text(`📍 ${this.diary.location}`)
                    .fontSize(12)
                    .fontColor('#666666')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#F0F0F0')
                    .borderRadius(12)
                }
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ top: 20, left: 16, right: 16 })

            Divider().strokeWidth(0.5).color('#EEEEEE').margin({ left: 16, right: 16 })

            Text(this.diary.content)
              .fontSize(16)
              .fontColor('#333333')
              .lineHeight(26)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 20 })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private getWeatherEmoji(w: string): string {
    const map: Record<string, string> = { sunny: '☀️', cloudy: '⛅', rainy: '🌧️', snowy: '❄️', windy: '💨', foggy: '🌫️' }
    return map[w] ?? '☀️'
  }

  private getWeatherLabel(w: string): string {
    const map: Record<string, string> = { sunny: '晴', cloudy: '多云', rainy: '雨', snowy: '雪', windy: '风', foggy: '雾' }
    return map[w] ?? '晴'
  }

  private getMoodEmoji(m: string): string {
    const map: Record<string, string> = { happy: '😊', neutral: '😐', sad: '😢', angry: '😠', worried: '😰', excited: '🤩' }
    return map[m] ?? '😐'
  }

  private getMoodLabel(m: string): string {
    const map: Record<string, string> = { happy: '开心', neutral: '平静', sad: '难过', angry: '生气', worried: '担心', excited: '兴奋' }
    return map[m] ?? '平静'
  }
}
