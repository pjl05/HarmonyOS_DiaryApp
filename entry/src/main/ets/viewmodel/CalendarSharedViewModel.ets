/**
 * CalendarSharedViewModel - 跨 Tab 日历状态协调
 * 替换 Android: CalendarSharedViewModel (AppStorage 广播)
 */
import { AppStorage } from '@kit.ArkUI';

export enum HighlightType {
  DIARY = 'diary',
  SCHEDULE = 'schedule',
  DAY = 'day'
}

export interface HighlightRequest {
  type: HighlightType
  value: number
}

const KEY_VISIBLE_YEAR_MONTH = 'calendar_visible_year_month';
const KEY_JUMP_TO_DATE = 'calendar_jump_to_date';
const KEY_HIGHLIGHT_REQUEST = 'calendar_highlight_request';

export class CalendarSharedViewModel {
  static setVisibleYearMonth(text: string): void {
    AppStorage.setOrCreate(KEY_VISIBLE_YEAR_MONTH, text);
  }

  static getVisibleYearMonth(): string {
    return AppStorage.get<string>(KEY_VISIBLE_YEAR_MONTH) ?? '';
  }

  static observeVisibleYearMonth(callback: (v: string) => void): void {
    const prop = AppStorage.link(KEY_VISIBLE_YEARMonth);
    prop.addListener(callback);
  }

  static requestJumpTo(dateMillis: number): void {
    AppStorage.setOrCreate(KEY_JUMP_TO_DATE, dateMillis);
    setTimeout(() => {
      AppStorage.setOrCreate(KEY_JUMP_TO_DATE, 0);
    }, 100);
  }

  static getJumpToDate(): number {
    return AppStorage.get<number>(KEY_JUMP_TO_DATE) ?? 0;
  }

  static observeJumpToDate(callback: (v: number) => void): void {
    const prop = AppStorage.link(KEY_JUMP_TO_DATE);
    prop.addListener(callback);
  }

  static requestHighlight(type: HighlightType, value: number): void {
    const req: HighlightRequest = { type, value };
    AppStorage.setOrCreate(KEY_HIGHLIGHT_REQUEST, req);
    setTimeout(() => {
      AppStorage.setOrCreate(KEY_HIGHLIGHT_REQUEST, null);
    }, 100);
  }

  static getHighlightRequest(): HighlightRequest | null {
    return AppStorage.get<HighlightRequest>(KEY_HIGHLIGHT_REQUEST) ?? null;
  }

  static observeHighlightRequest(callback: (v: HighlightRequest | null) => void): void {
    const prop = AppStorage.link(KEY_HIGHLIGHT_REQUEST);
    prop.addListener(callback);
  }
}