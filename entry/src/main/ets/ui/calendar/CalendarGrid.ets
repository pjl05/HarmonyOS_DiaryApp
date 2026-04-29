/**
 * CalendarGrid - 日历网格主视图
 * 替换 Android: CalendarGrid (LazyColumn + Grid)
 */
import { CalendarViewModel } from '../../viewmodel/CalendarViewModel';
import { CalendarCell, CalendarDayState } from '../../model/CalendarCellModel';
import { CalendarDayStateWrapper } from './CalendarDayCell';
import { CalendarWeekdayHeader } from './CalendarWeekdayHeader';
import { CalendarDayCell } from './CalendarDayCell';
import { promptAction, router } from '@kit.ArkUI';

@Component
export struct CalendarGrid {
  @State viewModel: CalendarViewModel = new CalendarViewModel();
  @State zoomScale: number = 1.0;
  @State cellWrappers: CalendarDayStateWrapper[] = [];

  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.viewModel.aboutToAppear();
    this.buildCellWrappers();
  }

  private buildCellWrappers(): void {
    this.cellWrappers = this.viewModel.cells.map(cell => {
      const today = new Date();
      const cellDate = new Date(cell.date);
      const isToday = !cell.isPlaceholder &&
        today.getFullYear() === cellDate.getFullYear() &&
        today.getMonth() === cellDate.getMonth() &&
        today.getDate() === cellDate.getDate();

      const state: CalendarDayState = {
        cell,
        diaryInfo: null,
        scheduleInfo: null,
        holidayName: null,
        isToday,
        isSelected: false
      };
      return new CalendarDayStateWrapper(state);
    });
  }

  build() {
    Column() {
      Row() {
        Text(this.viewModel.visibleYearMonth)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FF333333')
      }
      .width('100%')
      .height(48)
      .padding({ left: 16 })

      CalendarWeekdayHeader({ zoomScale: this.zoomScale })

      List({ scroller: this.scroller, initialIndex: this.getTodayIndex() }) {
        ForEach(this.viewModel.cells, (cell: CalendarCell, index: number) => {
          ListItem() {
            this.buildWeekRow(index)
          }
        }, (cell: CalendarCell) => `${cell.dayKey}`)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .onScrollIndex((start, end) => {
        this.viewModel.updateVisibleRange(start, end);
      })
      .gesture(
        PinchGesture()
          .onActionUpdate((event) => {
            const newScale = Math.min(2.5, Math.max(1.0, this.zoomScale * event.scale));
            this.zoomScale = newScale;
            this.viewModel.setZoomScale(newScale);
          })
      )
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFFFF')
  }

  @Builder
  buildWeekRow(startIndex: number) {
    Row() {
      ForEach(
        this.viewModel.cells.slice(startIndex, startIndex + 7),
        (cell: CalendarCell, offset: number) => {
          CalendarDayCell({
            state: this.cellWrappers[startIndex + offset],
            zoomScale: this.zoomScale,
            onDayClick: (dayKey) => this.onDayClick(dayKey),
            onLongPress: (dayKey) => this.onLongPress(dayKey)
          })
        },
        (cell: CalendarCell) => `${cell.dayKey}`
      )
    }
    .width('100%')
    .height(56)
  }

  private onDayClick(dayKey: number): void {
    const cell = this.viewModel.cells.find(c => c.dayKey === dayKey);
    if (!cell || cell.isPlaceholder) return;

    promptAction.showActionMenu({
      buttons: [
        { text: '写日记', color: '#FF4A90D9' },
        { text: '写日程', color: '#FF66BB6A' },
        { text: '写日子', color: '#FFFF9800' },
        { text: '查看日记', color: '#FF999999' }
      ]
    }).then((response) => {
      const index = response.index
      switch (index) {
        case 0:
          router.pushUrl({ url: 'pages/diary/DiaryEditPage', params: { diary_record_at: cell.date } });
          break;
        case 1:
          router.pushUrl({ url: 'pages/ScheduleEditPage', params: { schedule_date: cell.date } });
          break;
        case 2:
          router.pushUrl({ url: 'pages/DayPage', params: { day_date: cell.date } });
          break;
        case 3:
          router.pushUrl({ url: 'pages/DiaryPage', params: { date: cell.date } });
          break;
      }
    });
  }

  private onLongPress(dayKey: number): void {
    const state = this.viewModel.dayStates.get(dayKey);
    if (!state) return;
    let content = '';
    if (state.diaryInfo) content += `📔 日记: ${state.diaryInfo.title}\n`;
    if (state.scheduleInfo) content += `📅 日程: ${state.scheduleInfo.title}\n`;
    if (state.holidayName) content += `🎉 ${state.holidayName}`;
    if (content) {
      promptAction.showToast({ message: content, duration: 3000 });
    }
  }

  private getTodayIndex(): number {
    const today = new Date();
    const todayKey = today.getFullYear() * 10000 + (today.getMonth() + 1) * 100 + today.getDate();
    return this.viewModel.getDayIndex(todayKey) ?? 1200;
  }
}