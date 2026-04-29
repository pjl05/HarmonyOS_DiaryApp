/**
 * DayPagerPage - 日子三视图切换页面
 * 对标 Android: DayPagerFragment.kt
 * 支持 CARD（轮播卡片）/ TIMELINE（时间轴）/ ALBUM（相册）三种视图
 */
import router from '@ohos.router'
import { DayPagerViewModel, ViewMode } from '../../viewmodel/DayPagerViewModel'
import { DayRepository } from '../../data/repository/DayRepository'
import { DayDao } from '../../data/dao/DayDao'
import { DayItem } from '../../model/DayItem'
import { DayCard } from '../../components/day/DayCard'
import { DayTimelineCard } from '../../components/day/DayTimelineCard'
import { DayAlbumSection } from '../../components/day/DayAlbumSection'
import { TimelineSection } from '../../components/day/DayTimelineModels'
import relationalStore from '@ohos.data.relationalStore'
import { SimpleStorage } from '../../utils/SimpleStorage'

const USER_ID = 'default_user'

@Entry
@Component
export struct DayPagerPage {
  @State private vm: DayPagerViewModel = new DayPagerViewModel(
    new DayRepository(new DayDao(SimpleStorage.get('dayRdb') as relationalStore.RdbStore))
  )
  @State private currentIndex: number = 0

  aboutToAppear() {
    this.vm.loadDays(USER_ID)
  }

  build() {
    Column() {
      this.buildHeader()

      if (this.vm.isLoading) {
        LoadingProgress().width(48).height(48).margin({ top: 60 })
      } else if (this.vm.days.length === 0) {
        this.buildEmpty()
      } else {
        this.buildCurrentView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildHeader() {
    Row() {
      Text('日子记录')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#2C3E50')

      Blank()

      Image(this.getViewModeIcon())
        .width(24)
        .height(24)
        .fillColor('#2C3E50')
        .onClick(() => this.vm.cycleViewMode())

      Image($r('app.media.ic_add'))
        .width(24)
        .height(24)
        .fillColor('#2C3E50')
        .margin({ left: 16 })
        .onClick(() => router.pushUrl({ url: 'pages/DayPage' }))
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
  }

  @Builder
  buildEmpty() {
    Column() {
      Text('还没有日子记录')
        .fontSize(16)
        .fontColor('#9E9E9E')
        .margin({ top: 60 })

      Button('添加第一个日子')
        .margin({ top: 16 })
        .onClick(() => router.pushUrl({ url: 'pages/DayPage' }))
    }
    .width('100%')
  }

  @Builder
  buildCurrentView() {
    if (this.vm.viewMode === ViewMode.CARD) {
      this.buildCardView()
    } else if (this.vm.viewMode === ViewMode.TIMELINE) {
      this.buildTimelineView()
    } else {
      this.buildAlbumView()
    }
  }

  @Builder
  buildCardView() {
    Column() {
      Swiper() {
        ForEach(this.vm.days, (item: DayItem) => {
          DayCard({ item: item })
        }, (item: DayItem) => item.id.toString())
      }
      .index(this.currentIndex)
      .indicator(true)
      .loop(false)
      .onChange((index: number) => {
        this.currentIndex = index
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildTimelineView() {
    List() {
      ForEach(this.vm.timelineSections, (section: TimelineSection) => {
        ListItemGroup({ header: this.sectionHeader(section.yearMonth) }) {
          ForEach(section.items, (item: DayItem) => {
            ListItem() {
              DayTimelineCard({
                item: item,
                onDelete: (id: number): void => { this.vm.deleteDay(id) }
              })
            }
          }, (item: DayItem) => item.id.toString())
        }
      }, (section: TimelineSection) => section.yearMonth)
    }
    .width('100%')
    .layoutWeight(1)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildAlbumView() {
    Scroll() {
      DayAlbumSection({ items: this.vm.days })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  sectionHeader(yearMonth: string) {
    Text(yearMonth)
      .fontSize(14)
      .fontColor('#9E9E9E')
      .fontWeight(FontWeight.Medium)
      .padding({ top: 16, bottom: 8 })
  }

  private getViewModeIcon(): Resource {
    if (this.vm.viewMode === ViewMode.CARD) {
      return $r('app.media.ic_view_card')
    } else if (this.vm.viewMode === ViewMode.TIMELINE) {
      return $r('app.media.ic_view_timeline')
    }
    return $r('app.media.ic_view_album')
  }
}
