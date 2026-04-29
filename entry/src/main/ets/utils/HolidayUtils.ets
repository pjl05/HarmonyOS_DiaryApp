/**
 * HolidayUtils - 节日名称计算工具
 * 替换 Android: HolidayUtils (公历/农历节日)
 */
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
  if (![1, 2, 5, 6, 9, 10].includes(month)) return null;

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