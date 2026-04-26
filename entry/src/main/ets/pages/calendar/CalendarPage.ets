/**
 * CalendarPage - 路由页面入口
 * 替换 Android: CalendarActivity
 */
import { CalendarPage as CalendarPageUI } from '../ui/calendar/CalendarPage';

@Entry
@Component
export struct CalendarPage {
  build() {
    CalendarPageUI()
  }
}