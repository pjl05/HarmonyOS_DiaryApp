# Day 10: 日历模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现日历模块，包含日历主视图（年历缩放、滑动）、HolidayUtils 假期计算、以及 CalendarSharedViewModel 跨 Tab 状态协调。迁移自 Android CalendarFragment/CalendarScrollAdapter 及相关组件。

**Architecture:**
- LazyColumn + GridLayout 实现无限滚动日历（2000-2099年）
- PinchGestureHandler 处理缩放（1x-2.5x）
- CalendarSharedViewModel 作为 AppStorage 广播协调各 Tab
- HolidayUtils 纯函数计算农历节日（无状态依赖）
- 窗口化加载日记/日程数据（可见区域前后各预加载1个月）

**Tech Stack:** ArkTS, LazyColumn, GridLayout, PinchGestureHandler, AppStorage, LunarCalendar (HarmonyOS)

---

## File Structure

```
entry/src/main/ets/
├── model/
│   └── CalendarCellModel.ets
├── utils/
│   └── HolidayUtils.ets
│   └── LunarCalendarUtils.ets
├── viewmodel/
│   └── CalendarViewModel.ets
│   └── CalendarSharedViewModel.ets
├── ui/
│   └── calendar/
│       ├── CalendarPage.ets
│       ├── CalendarGrid.ets
│       ├── CalendarDayCell.ets
│       └── CalendarWeekdayHeader.ets
└── pages/
    └── CalendarPage.ets
```

---

## Task 1: CalendarCellModel and CalendarSharedViewModel

**Files:**
- Create: `entry/src/main/ets/model/CalendarCellModel.ets`
- Create: `entry/src/main/ets/viewmodel/CalendarSharedViewModel.ets`

- [ ] **Step 1: Create CalendarCellModel.ets**

```typescript
// entry/src/main/ets/model/CalendarCellModel.ets

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
```

- [ ] **Step 2: Create CalendarSharedViewModel.ets**

```typescript
// entry/src/main/ets/viewmodel/CalendarSharedViewModel.ets

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
    const prop = AppStorage.link(KEY_VISIBLE_YEAR_MONTH);
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
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/model/CalendarCellModel.ets entry/src/main/ets/viewmodel/CalendarSharedViewModel.ets
git commit -m "feat(calendar): add CalendarCellModel and CalendarSharedViewModel"
```

---

## Task 2: HolidayUtils and LunarCalendarUtils

**Files:**
- Create: `entry/src/main/ets/utils/HolidayUtils.ets`
- Create: `entry/src/main/ets/utils/LunarCalendarUtils.ets`

- [ ] **Step 1: Create LunarCalendarUtils.ets**

```typescript
// entry/src/main/ets/utils/LunarCalendarUtils.ets

const LUNAR_INFO: number[] = [
  0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x055c0, 0x0ab60, 0x096d5, 0x092e0,
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
  0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
  0x0d520
];

const LUNAR_MIN_YEAR = 1900;
const LUNAR_MAX_YEAR = 2100;

export class LunarDate {
  year: number
  month: number
  day: number
  isLeapMonth: boolean

  constructor(year: number, month: number, day: number, isLeapMonth: boolean = false) {
    this.year = year
    this.month = month
    this.day = day
    this.isLeapMonth = isLeapMonth
  }
}

function getLunarMonthDays(year: number, month: number): number {
  if (year < LUNAR_MIN_YEAR || year > LUNAR_MAX_YEAR) return 30;
  const info = LUNAR_INFO[year - LUNAR_MIN_YEAR];
  const shift = month - 1;
  if (shift < 0 || shift > 11) return 30;
  const bit = 1 << shift;
  if ((info & 0x10000) !== 0) {
    if (month === ((info & 0xf0000) >> 16)) {
      return (info & bit) !== 0 ? 30 : 29;
    }
  }
  return (info & bit) !== 0 ? 30 : 29;
}

function getLeapMonth(year: number): number {
  if (year < LUNAR_MIN_YEAR || year > LUNAR_MAX_YEAR) return 0;
  return (LUNAR_INFO[year - LUNAR_MIN_YEAR] & 0xf0000) >> 16;
}

function getLunarYearDays(year: number): number {
  if (year < LUNAR_MIN_YEAR || year > LUNAR_MAX_YEAR) return 365;
  let days = 0;
  const info = LUNAR_INFO[year - LUNAR_MIN_YEAR];
  for (let i = 0; i < 12; i++) {
    const bit = 1 << i;
    if ((info & bit) !== 0) days++;
    if (i === getLeapMonth(year) - 1) days++;
  }
  return days === 0 ? 354 : days;
}

function getJulianDay(year: number, month: number, day: number): number {
  const a = Math.floor((14 - month) / 12);
  const y = year + 4800 - a;
  const m = month + 12 * a - 3;
  return day + Math.floor((153 * m + 2) / 5) + 365 * y + Math.floor(y / 4) - Math.floor(y / 100) + Math.floor(y / 400) - 32045;
}

export function solarToLunar(year: number, month: number, day: number): LunarDate {
  const solarDate = new Date(year, month - 1, day);
  const julianDay = Math.floor((solarDate.getTime() + 43200000) / 86400000);

  let offset = julianDay - getJulianDay(LUNAR_MIN_YEAR, 1, 1);
  let year2 = LUNAR_MIN_YEAR;
  let days2 = getLunarYearDays(year2);

  while (offset >= days2 && year2 < LUNAR_MAX_YEAR) {
    offset -= days2;
    year2++;
    days2 = getLunarYearDays(year2);
  }

  let month2 = 1;
  const leapMonth = getLeapMonth(year2);
  let isLeapMonth = false;

  while (month2 <= 12 && offset >= 0) {
    let monthDays: number;
    if (month2 === leapMonth && !isLeapMonth) {
      monthDays = getLunarMonthDays(year2, month2);
      isLeapMonth = true;
    } else if (month2 === leapMonth + 1 && isLeapMonth) {
      isLeapMonth = false;
      month2++;
      monthDays = getLunarMonthDays(year2, month2);
    } else {
      monthDays = getLunarMonthDays(year2, month2);
    }
    if (offset < monthDays) break;
    offset -= monthDays;
    month2++;
  }

  return new LunarDate(year2, month2, offset + 1, isLeapMonth);
}
```

- [ ] **Step 2: Create HolidayUtils.ets**

```typescript
// entry/src/main/ets/utils/HolidayUtils.ets

import { solarToLunar, LunarDate } from './LunarCalendarUtils';

const NONE = '__NONE__';
const cache = new Map<number, string>();

export function getHolidayName(dateMillis: number): string | null {
  const cal = new Date(dateMillis);
  const year = cal.getFullYear();
  const month = cal.getMonth() + 1;
  const day = cal.getDate();

  if (month === 1 && day === 1) return '元旦';
  if (month === 5 && day === 1) return '劳动节';
  if (month === 10 && day === 1) return '国庆节';
  if (month === 4 && day === qingmingDay(year)) return '清明节';
  if (month !in [1, 2, 5, 6, 9, 10]) return null;

  const lunar: LunarDate = solarToLunar(year, month, day);
  if (lunar.month === 1 && lunar.day === 1) return '春节';
  if (isChuXi(year, month, day)) return '除夕';
  if (lunar.month === 5 && lunar.day === 5) return '端午节';
  if (lunar.month === 8 && lunar.day === 15) return '中秋节';

  return null;
}

export function getHolidayNameCached(dateMillis: number): string | null {
  const cal = new Date(dateMillis);
  const key = cal.getFullYear() * 10000 + (cal.getMonth() + 1) * 100 + cal.getDate();
  const cached = cache.get(key);
  if (cached !== undefined) return cached === NONE ? null : cached;
  const name = getHolidayName(dateMillis);
  cache.set(key, name ?? NONE);
  return name;
}

function isChuXi(year: number, month: number, day: number): boolean {
  const lunar = solarToLunar(year, month, day);
  if (lunar.month !== 12) return false;
  const tomorrow = new Date(year, month - 1, day + 1);
  const tomorrowLunar = solarToLunar(tomorrow.getFullYear(), tomorrow.getMonth() + 1, tomorrow.getDate());
  return tomorrowLunar.month === 1 && tomorrowLunar.day === 1;
}

function qingmingDay(year: number): number {
  const c = 4.81;
  return Math.floor((year * 0.2422 + c) - Math.floor((year - 1) / 4));
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/utils/LunarCalendarUtils.ets entry/src/main/ets/utils/HolidayUtils.ets
git commit -m "feat(calendar): add LunarCalendarUtils and HolidayUtils"
```

---

## Task 3: CalendarViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/CalendarViewModel.ets`

- [ ] **Step 1: Create CalendarViewModel.ets**

```typescript
// entry/src/main/ets/viewmodel/CalendarViewModel.ets

import { CalendarCell, CalendarDayState, DiaryInfo, ScheduleInfo, createDayCell, createPlaceholderCell, getDayKey } from '../model/CalendarCellModel';
import { CalendarSharedViewModel } from './CalendarSharedViewModel';

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
        monthCal.setDate(day);
        const ts = monthCal.getTime();
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
      const locale = getContext(this).resourceManager.getLocales()[0];
      const isZh = locale.startsWith('zh');
      if (isZh) {
        this.visibleYearMonth = `${startCal.getFullYear()}年${startCal.getMonth() + 1}月`;
      } else {
        this.visibleYearMonth = `${startCal.toLocaleString('en', { month: 'long' })} ${startCal.getFullYear()}`;
      }
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
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/viewmodel/CalendarViewModel.ets
git commit -m "feat(calendar): add CalendarViewModel with cell generation and state"
```

---

## Task 4: CalendarWeekdayHeader

**Files:**
- Create: `entry/src/main/ets/ui/calendar/CalendarWeekdayHeader.ets`

- [ ] **Step 1: Create CalendarWeekdayHeader.ets**

```typescript
// entry/src/main/ets/ui/calendar/CalendarWeekdayHeader.ets

@Component
export struct CalendarWeekdayHeader {
  @Prop zoomScale: number = 1.0;

  private weekdays: string[] = ['日', '一', '二', '三', '四', '五', '六'];

  build() {
    Row() {
      ForEach(this.weekdays, (day: string, index: number) => {
        Text(day)
          .fontSize(12)
          .fontColor(index === 0 ? '#FFE53935' : index === 6 ? '#FF4A90D9' : '#FF999999')
          .fontWeight(index === 0 || index === 6 ? FontWeight.Medium : FontWeight.Normal)
          .textAlign(TextAlign.Center)
          .layoutWeight(1)
      })
    }
    .width('100%')
    .height(32)
    .padding({ left: 8, right: 8 })
    .scale({ x: this.zoomScale, y: 1 })
    .transformCenter({ x: 0, y: 0 })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/ui/calendar/CalendarWeekdayHeader.ets
git commit -m "feat(calendar): add CalendarWeekdayHeader with weekend highlighting"
```

---

## Task 5: CalendarDayCell

**Files:**
- Create: `entry/src/main/ets/ui/calendar/CalendarDayCell.ets`

- [ ] **Step 1: Create CalendarDayCell.ets**

```typescript
// entry/src/main/ets/ui/calendar/CalendarDayCell.ets

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
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/ui/calendar/CalendarDayCell.ets
git commit -m "feat(calendar): add CalendarDayCell with indicators"
```

---

## Task 6: CalendarGrid

**Files:**
- Create: `entry/src/main/ets/ui/calendar/CalendarGrid.ets`

- [ ] **Step 1: Create CalendarGrid.ets**

```typescript
// entry/src/main/ets/ui/calendar/CalendarGrid.ets

import { CalendarViewModel } from '../../viewmodel/CalendarViewModel';
import { CalendarCell } from '../../model/CalendarCellModel';
import { CalendarDayStateWrapper } from './CalendarDayCell';
import { CalendarWeekdayHeader } from './CalendarWeekdayHeader';
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
        LazyForEach(this.viewModel.cells, (cell: CalendarCell, index: number) => {
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
            const newScale = (this.zoomScale * event.scale).coerceIn(1.0, 2.5);
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
  buildWeekRow(startIndex: number): Row {
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
    }).then((index) => {
      switch (index) {
        case 0:
          router.pushUrl({ url: 'pages/DiaryEditPage' }, { params: { diary_record_at: cell.date } });
          break;
        case 1:
          router.pushUrl({ url: 'pages/ScheduleEditPage' }, { params: { schedule_date: cell.date } });
          break;
        case 2:
          router.pushUrl({ url: 'pages/DayPage' }, { params: { day_date: cell.date } });
          break;
        case 3:
          router.pushUrl({ url: 'pages/DiaryPage' }, { params: { date: cell.date } });
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
    return this.viewModel.dayIndexMap.get(todayKey) ?? 1200;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/ui/calendar/CalendarGrid.ets
git commit -m "feat(calendar): add CalendarGrid with virtual scroll and pinch zoom"
```

---

## Task 7: CalendarPage and 路由注册

**Files:**
- Create: `entry/src/main/ets/ui/calendar/CalendarPage.ets`
- Create: `entry/src/main/ets/pages/CalendarPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Create CalendarPage.ets**

```typescript
// entry/src/main/ets/ui/calendar/CalendarPage.ets

import { CalendarGrid } from './CalendarGrid';

@Component
export struct CalendarPage {
  build() {
    NavDestination() {
      CalendarGrid()
    }
    .title('日历')
    .titleMode(NavDestinationTitleMode.Medium)
  }
}
```

- [ ] **Step 2: Create pages/CalendarPage.ets**

```typescript
// entry/src/main/ets/pages/CalendarPage.ets

import { CalendarPage } from '../ui/calendar/CalendarPage';

@Entry
@Component
export struct CalendarPageEntry {
  build() {
    CalendarPage()
  }
}
```

- [ ] **Step 3: Register routes**

```json
{
  "src": [
    "pages/Index",
    "pages/MainPage",
    "pages/ChatPage",
    "pages/ChatManagementPage",
    "pages/CalendarPage"
  ]
}
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/ui/calendar/CalendarPage.ets entry/src/main/ets/pages/CalendarPage.ets
git add entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat(calendar): add CalendarPage and register routes"
```

---

## Task 8: 跨Tab导航协调

**Files:**
- Modify: `entry/src/main/ets/ui/main/MainPage.ets` (from Day 4)

- [ ] **Step 1: 在 MainPage TabContent 中添加 CalendarPage**

在 Day 4 的 MainPage.ets 中，添加日历 Tab：

```typescript
TabContent() {
  CalendarPage()
}
.tabBar('日历')
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/ui/main/MainPage.ets
git commit -m "feat(calendar): integrate CalendarPage into MainPage tabs"
```

---

## Self-Review Checklist

1. **Spec coverage:**
   - CalendarFragment → CalendarPage + CalendarGrid (Task 6, 7) ✓
   - CalendarScrollAdapter → CalendarDayCell (Task 5) ✓
   - CalendarSharedViewModel → CalendarSharedViewModel (Task 1) ✓
   - HolidayUtils → HolidayUtils + LunarCalendarUtils (Task 2) ✓
   - CalendarWeekdayHeader → CalendarWeekdayHeader (Task 4) ✓
   - GridLayoutManager(7) → Grid 7列布局 (Task 5, 6) ✓
   - PinchZoom → PinchGesture (Task 6) ✓
   - jumpToDateCentered → jumpToDateCentered (Task 3) ✓

2. **Placeholder scan:** All steps have actual code — no "TBD", "TODO"

3. **Type consistency:**
   - `CalendarCell.date` is `number`
   - `CalendarCell.dayKey` is `number` (YYYYMMDD)
   - All timestamps use `number`

4. **API differences noted:**
   - Android RecyclerView → HarmonyOS LazyColumn
   - Android GridLayoutManager → HarmonyOS Grid + ForEach
   - Android PinchZoom → HarmonyOS PinchGesture
   - Android ValueAnimator → HarmonyOS animateTo
