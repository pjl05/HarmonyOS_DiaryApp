/**
 * CalendarSharedViewModel - 跨 Tab 日历状态协调
 * 替换 Android: CalendarSharedViewModel (SimpleStorage 广播)
 */
import { storageGet, storageSet } from '../utils/SimpleStorage'

export enum HighlightType {
  DIARY = 'diary',
  SCHEDULE = 'schedule',
  DAY = 'day'
}

export interface HighlightRequest {
  type: HighlightType
  value: number
}

const KEY_VISIBLE_YEAR_MONTH = 'calendar_visible_year_month'
const KEY_JUMP_TO_DATE = 'calendar_jump_to_date'
const KEY_HIGHLIGHT_REQUEST = 'calendar_highlight_request'

export class CalendarSharedViewModel {
  static setVisibleYearMonth(text: string): void {
    storageSet(KEY_VISIBLE_YEAR_MONTH, text)
  }

  static getVisibleYearMonth(): string {
    const val = storageGet(KEY_VISIBLE_YEAR_MONTH)
    return typeof val === 'string' ? val : ''
  }

  static observeVisibleYearMonth(callback: (v: string) => void): void {
    callback(CalendarSharedViewModel.getVisibleYearMonth())
  }

  static requestJumpTo(dateMillis: number): void {
    storageSet(KEY_JUMP_TO_DATE, dateMillis)
    setTimeout(() => {
      storageSet(KEY_JUMP_TO_DATE, 0)
    }, 100)
  }

  static getJumpToDate(): number {
    const val = storageGet(KEY_JUMP_TO_DATE)
    return typeof val === 'number' ? val : 0
  }

  static observeJumpToDate(callback: (v: number) => void): void {
    callback(CalendarSharedViewModel.getJumpToDate())
  }

  static requestHighlight(type: HighlightType, value: number): void {
    const req: HighlightRequest = { type, value }
    storageSet(KEY_HIGHLIGHT_REQUEST, req)
    setTimeout(() => {
      storageSet(KEY_HIGHLIGHT_REQUEST, undefined)
    }, 100)
  }

  static getHighlightRequest(): HighlightRequest | null {
    const val = storageGet(KEY_HIGHLIGHT_REQUEST)
    return val as HighlightRequest | null
  }

  static observeHighlightRequest(callback: (v: HighlightRequest | null) => void): void {
    callback(CalendarSharedViewModel.getHighlightRequest())
  }
}