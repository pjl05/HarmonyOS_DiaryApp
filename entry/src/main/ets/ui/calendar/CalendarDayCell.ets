/**
 * CalendarDayCell - 日历日期单元格
 * 替换 Android: CalendarDayCell (RecyclerView item)
 */
import { CalendarDayState } from '../../model/CalendarCellModel';

@Component
export struct CalendarDayCell {
  @ObjectLink state: CalendarDayStateWrapper;
  @Prop zoomScale: number = 1.0;
  onDayClick: (dayKey: number) => void = () => {};
  onLongPress: (dayKey: number) => void = () => {};

  build() {
    Column() {
      Text(this.state.dayState.cell.day.toString())
        .fontSize(14)
        .fontColor(this.getDayTextColor())
        .fontWeight(this.state.dayState.isToday ? FontWeight.Bold : FontWeight.Normal)
        .backgroundColor(this.state.dayState.isToday ? '#FF4A90D9' : 'transparent')
        .borderRadius(14)
        .width(28)
        .height(28)
        .textAlign(TextAlign.Center)

      if (this.state.dayState.holidayName) {
        Text(this.state.dayState.holidayName)
          .fontSize(8)
          .fontColor('#FFE53935')
          .maxLines(1)
          .textAlign(TextAlign.Center)
          .width('100%')
      }

      Row({ space: 2 }) {
        if (this.state.dayState.diaryInfo) {
          Circle().width(4).height(4).fill('#FF4A90D9')
        }
        if (this.state.dayState.scheduleInfo) {
          Circle().width(4).height(4).fill('#FF66BB6A')
        }
      }
      .height(4)
      .margin({ top: 1 })
    }
    .width('100%')
    .height('100%')
    .padding(2)
    .scale({ x: this.zoomScale, y: this.zoomScale })
    .opacity(this.state.dayState.cell.isPlaceholder ? 0.3 : 1.0)
    .onClick(() => {
      if (!this.state.dayState.cell.isPlaceholder) {
        this.onDayClick(this.state.dayState.cell.dayKey);
      }
    })
    .onLongPress(() => {
      if (!this.state.dayState.cell.isPlaceholder) {
        this.onLongPress(this.state.dayState.cell.dayKey);
      }
    })
  }

  private getDayTextColor(): string {
    if (this.state.dayState.cell.isPlaceholder) return '#FFCCCCCC';
    const dow = new Date(this.state.dayState.cell.date).getDay();
    if (dow === 0) return '#FFE53935';
    if (dow === 6) return '#FF4A90D9';
    return '#FF333333';
  }
}

@Observed
export class CalendarDayStateWrapper {
  dayState: CalendarDayState;

  constructor(state: CalendarDayState) {
    this.dayState = state;
  }
}