/**
 * CalendarPage - 日历页面 NavDestination
 * 替换 Android: CalendarActivity
 */
import { CalendarGrid } from './CalendarGrid'

@Component
export struct CalendarPage {
  build() {
    NavDestination() {
      CalendarGrid()
    }
    .title('日历')
  }
}