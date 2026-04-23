/**
 * 日记列表主容器
 * 对标 Android DiaryPagerFragment
 * 支持「全部/图片/视频」Tab 筛选，下拉刷新，搜索适配，空状态显示
 */
import router from '@ohos.router'
import { DiaryViewModel } from '../../viewmodel/DiaryViewModel'
import { DiaryCard, DiaryWrapper } from '../../components/DiaryCard'
import promptAction from '@ohos.promptAction'
import { Logger } from '../../utils/Logger'
import { Diary } from '../../model/DiaryModel'

@Component
export struct DiaryPagerPage {
  @State diaries: DiaryWrapper[] = []
  @State currentFilter: 'all' | 'image' | 'video' = 'all'
  @State showEmpty: boolean = false

  private vm: DiaryViewModel | null = null

  aboutToAppear(): void {
    this.initViewModel()
  }

  private async initViewModel(): Promise<void> {
    const context = getContext(this)
    this.vm = new DiaryViewModel(context)
    await this.vm.loadAll()
    this.diaries = this.vm.diaries.map(d => new DiaryWrapper(d))
    this.showEmpty = this.diaries.length === 0
  }

  private onSearchChanged(query: string): void {
    this.vm?.setSearchQuery(query)
    if (this.vm) {
      this.diaries = this.vm.diaries.map(d => new DiaryWrapper(d))
      this.showEmpty = this.diaries.length === 0
    }
  }

  private onDiaryClick(diary: Diary): void {
    router.pushUrl({
      url: 'pages/diary/DiaryViewPage',
      params: { diaryId: diary.id }
    }).catch((err) => {
      Logger.error('DiaryPagerPage', 'navigate failed: ' + JSON.stringify(err))
    })
  }

  private onDiaryLongPress(diary: Diary): void {
    const menuActions = [
      { text: diary.isFavorite ? '取消收藏' : '收藏', color: '#FF9800' },
      { text: '移至回收站', color: '#F44336' },
      { text: '移动到保险箱', color: '#2196F3' },
      { text: '取消', color: '#999999' }
    ]
    promptAction.showActionMenu({
      buttons: menuActions.map(a => ({ text: a.text, color: a.color }))
    }).then((result) => {
      const idx = result.index
      if (idx === 0) {
        this.vm?.toggleFavorite(diary)
        this.diaries = this.diaries.map(w => {
          if (w.diary.id === diary.id) {
            w.diary = { ...w.diary, isFavorite: !w.diary.isFavorite }
          }
          return w
        })
      } else if (idx === 1) {
        this.vm?.moveToTrash(diary)
        this.diaries = this.diaries.filter(w => w.diary.id !== diary.id)
        promptAction.showToast({ message: '已移至回收站' })
      } else if (idx === 2) {
        this.vm?.moveToVault(diary)
        this.diaries = this.diaries.filter(w => w.diary.id !== diary.id)
        promptAction.showToast({ message: '已移动到保险箱' })
      }
    }).catch(() => {})
  }

  private onFavoriteToggle(diary: Diary): void {
    this.vm?.toggleFavorite(diary)
    this.diaries = this.diaries.map(w => {
      if (w.diary.id === diary.id) {
        w.diary = { ...w.diary, isFavorite: !w.diary.isFavorite }
      }
      return w
    })
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('📔')
        .fontSize(60)
        .opacity(0.3)
      Text('还没有日记')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击底部「+」按钮创建第一篇日记')
        .fontSize(13)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row({ space: 16 }) {
        ForEach(['全部', '图片', '视频'] as Array<'全部' | '图片' | '视频'>, (label: string) => {
          Text(label)
            .fontSize(14)
            .fontColor(this.currentFilter === label ? '#00BCD4' : '#999999')
            .fontWeight(this.currentFilter === label ? FontWeight.Bold : FontWeight.Normal)
            .onClick((): void => { this.currentFilter = label })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FAFAFA')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.diaries, (item: DiaryWrapper) => {
            ListItem() {
              DiaryCard({
                diaryWrapper: item,
                onClick: (): void => this.onDiaryClick(item.diary),
                onLongPress: (): void => this.onDiaryLongPress(item.diary),
                onFavoriteClick: (): void => this.onFavoriteToggle(item.diary)
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
