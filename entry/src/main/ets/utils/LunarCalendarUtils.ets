/**
 * LunarCalendarUtils - 农历日期转换工具
 * 替换 Android: LunarCalendarUtils (农历算法)
 */
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