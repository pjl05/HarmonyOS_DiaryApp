/**
 * CalendarCellModel - 日历单元格数据模型
 * 替换 Android: CalendarCell (RecyclerView item)
 */
export interface CalendarCell {
  date: number          // 时间戳（毫秒），0 = 占位格子
  day: number           // 日期（1-31），0 = 占位格子
  isPlaceholder: boolean
  dayKey: number        // YYYYMMDD 格式唯一键，0 = 占位格
}

export interface DiaryInfo {
  title: string
  previewText: string
  mood: string
  weather: string
}

export interface ScheduleInfo {
  id: number
  title: string
  previewText: string
  mood: string
  weather: string
}

export interface CalendarDayState {
  cell: CalendarCell
  diaryInfo: DiaryInfo | null
  scheduleInfo: ScheduleInfo | null
  holidayName: string | null
  isToday: boolean
  isSelected: boolean
}

export function createPlaceholderCell(): CalendarCell {
  return { date: 0, day: 0, isPlaceholder: true, dayKey: 0 }
}

export function createDayCell(date: number, day: number, dayKey: number): CalendarCell {
  return { date, day, isPlaceholder: false, dayKey }
}

export function getDayKey(year: number, month: number, day: number): number {
  return year * 10000 + month * 100 + day
}