/**
 * CalendarViewModel - 日历状态管理
 * 替换 Android: CalendarViewModel (StateFlow 管理)
 */
import { CalendarCell, CalendarDayState, DiaryInfo, ScheduleInfo, createDayCell, createPlaceholderCell, getDayKey } from '../model/CalendarCellModel';
import { CalendarSharedViewModel } from './CalendarSharedViewModel';
import { getHolidayNameCached } from '../utils/HolidayUtils';

const START_YEAR = 2000;
const END_YEAR = 2099;

@Observed
export class CalendarViewModel {
  @State cells: CalendarCell[] = [];
  @State dayStates: Map<number, CalendarDayState> = new Map();
  @State visibleYearMonth: string = '';
  @State zoomScale: number = 1.0;
  @State selectedDateMillis: number = 0;

  private monthStartIndexMap: Map<number, number> = new Map();
  private dayIndexMap: Map<number, number> = new Map();

  aboutToAppear(): void {
    this.generateCalendarCells();
    this.setupObservers();
  }

  private generateCalendarCells(): void {
    const cells: CalendarCell[] = [];
    const monthStartMap = new Map<number, number>();
    const dayMap = new Map<number, number>();
    const startCal = new Date(START_YEAR, 0, 1);
    const endCal = new Date(END_YEAR, 11, 1);
    const monthCal = new Date(startCal);

    while (monthCal <= endCal) {
      const year = monthCal.getFullYear();
      const month = monthCal.getMonth() + 1;
      const monthKey = year * 100 + month;
      monthStartMap.set(monthKey, cells.length);

      const firstDow = monthCal.getDay();
      for (let i = 0; i < firstDow; i++) {
        cells.push(createPlaceholderCell());
      }

      const daysInMonth = new Date(year, month, 0).getDate();
      for (let day = 1; day <= daysInMonth; day++) {
        const cellDate = new Date(year, month - 1, day);
        const ts = cellDate.getTime();
        const dayKey = getDayKey(year, month, day);
        dayMap.set(dayKey, cells.length);
        cells.push(createDayCell(ts, day, dayKey));
      }

      const remainder = cells.length % 7;
      if (remainder !== 0) {
        for (let i = 0; i < 7 - remainder; i++) {
          cells.push(createPlaceholderCell());
        }
      }

      monthCal.setDate(1);
      monthCal.setMonth(monthCal.getMonth() + 1);
    }

    this.cells = cells;
    this.monthStartIndexMap = monthStartMap;
    this.dayIndexMap = dayMap;
  }

  private setupObservers(): void {
    CalendarSharedViewModel.observeVisibleYearMonth((text) => {
      this.visibleYearMonth = text;
    });

    CalendarSharedViewModel.observeJumpToDate((dateMillis) => {
      if (dateMillis > 0) {
        this.jumpToDateCentered(dateMillis);
      }
    });
  }

  updateVisibleRange(startIndex: number, endIndex: number): void {
    if (this.cells.length === 0) return;
    const first = Math.max(0, startIndex);
    const last = Math.min(this.cells.length - 1, endIndex);

    let monthStart = -1;
    let monthEnd = -1;
    for (let i = first; i <= last; i++) {
      const cell = this.cells[i];
      if (!cell.isPlaceholder && cell.date > 0) {
        if (monthStart < 0) monthStart = cell.date;
        monthEnd = cell.date;
      }
    }

    if (monthStart > 0 && monthEnd > 0) {
      const startCal = new Date(monthStart);
      this.visibleYearMonth = `${startCal.getFullYear()}年${startCal.getMonth() + 1}月`;
      CalendarSharedViewModel.setVisibleYearMonth(this.visibleYearMonth);
    }
  }

  jumpToDateCentered(dateMillis: number): void {
    const cal = new Date(dateMillis);
    const year = cal.getFullYear();
    const month = cal.getMonth() + 1;
    const day = cal.getDate();
    const dayKey = getDayKey(year, month, day);
    const monthKey = year * 100 + month;
    const monthIdx = this.monthStartIndexMap.get(monthKey) ?? 0;
    const dayIdx = this.dayIndexMap.get(dayKey) ?? monthIdx;
    this.selectedDateMillis = dateMillis;
    this.updateVisibleRange(dayIdx - 7, dayIdx + 7);
  }

  setZoomScale(scale: number): void {
    this.zoomScale = scale.coerceIn(1.0, 2.5);
  }

  updateDayState(dayKey: number, updates: Partial<CalendarDayState>): void {
    const existing = this.dayStates.get(dayKey);
    if (existing) {
      this.dayStates.set(dayKey, { ...existing, ...updates });
    } else {
      const cell = this.cells.find(c => c.dayKey === dayKey);
      if (!cell) return;
      const today = new Date();
      const cellDate = new Date(cell.date);
      const isToday = today.getFullYear() === cellDate.getFullYear() &&
        today.getMonth() === cellDate.getMonth() &&
        today.getDate() === cellDate.getDate();
      this.dayStates.set(dayKey, {
        cell,
        diaryInfo: null,
        scheduleInfo: null,
        holidayName: null,
        isToday,
        isSelected: false,
        ...updates
      });
    }
  }

  setDiaryInfo(dayKey: number, info: DiaryInfo): void {
    this.updateDayState(dayKey, { diaryInfo: info });
  }

  setScheduleInfo(dayKey: number, info: ScheduleInfo): void {
    this.updateDayState(dayKey, { scheduleInfo: info });
  }

  setHolidayName(dayKey: number, name: string | null): void {
    this.updateDayState(dayKey, { holidayName: name });
  }
}