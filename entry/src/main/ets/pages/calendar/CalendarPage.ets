/**
 * CalendarPage - 日历页面 NavDestination
 * 替换 Android: CalendarActivity
 */
import { CalendarGrid } from '../../ui/calendar/CalendarGrid'

@Entry
@Component
export struct CalendarPage {
  build() {
    NavDestination() {
      CalendarGrid()
    }
    .title('日历')
  }
}