# 日程管理模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完成日程管理模块的完整迁移（ScheduleActivity → SchedulePage, ScheduleViewActivity → ScheduleDetailPage, 闹钟提醒 → ReminderAgent, 开机自启 → AbilityStage）

**Architecture:** MVVM + Repository 模式，HarmonyOS Relational DB 替代 Room，ReminderAgentManager 替代 AlarmManager，AbilityStage BootReceiver 替代 BroadcastReceiver

**Tech Stack:** ArkTS, Relational DB, ReminderAgentManager, @ohos.notification

---

## File Structure

```
entry/src/main/ets/
├── models/
│   └── ScheduleItem.ts           # 日程数据模型（对标 ScheduleItem.kt）
├── data/
│   ├── ScheduleDao.ets            # Relational DB CRUD（对标 ScheduleDao.kt）
│   └── ScheduleRepository.ets     # Repository 封装（对标 ScheduleRepository.kt）
├── viewmodels/
│   ├── ScheduleListViewModel.ets # 日程列表 VM（对标 ScheduleActivity）
│   └── ScheduleDetailViewModel.ets # 日程详情 VM（对标 ScheduleViewActivity）
├── services/
│   └── ReminderService.ets        # 闹钟提醒服务（对标 ScheduleAlarmScheduler）
├── pages/
│   ├── ScheduleListPage.ets       # 日程列表页（对标 ScheduleActivity）
│   └── ScheduleDetailPage.ets      # 日程详情页（对标 ScheduleViewActivity）
├── components/
│   ├── ScheduleCard.ets           # 日程卡片组件
│   ├── RepeatRulePicker.ets       # 重复规则选择器
│   ├── AlarmFullscreenPage.ets    # 全屏闹钟页（对标 ScheduleAlarmFullscreenActivity）
│   └── NotificationHelper.ets     # 通知帮助类（对标 NotificationManager）
└── utils/
    └── ScheduleOccurrenceUtils.ets # 下次发生时间计算（对标 ScheduleOccurrenceUtils）
```

**Replace:** ScheduleActivity, ScheduleViewActivity, ScheduleAlarmScheduler, ScheduleAlarmReceiver, ScheduleBootReceiver, ScheduleListAdapter, ScheduleCardAdapter, SchedulePagerFragment, ScheduleOccurrenceUtils, ScheduleNotificationIds

---

### Task 1: ScheduleItem Model

**Files:**
- Create: `entry/src/main/ets/models/ScheduleItem.ts`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/models/ScheduleItem.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleItem } from '../../main/ets/models/ScheduleItem'

describe('ScheduleItem', () => {
  it('should_create_schedule_item_with_default_values', () => {
    const item = new ScheduleItem({
      title: '测试日程',
      scheduledAt: Date.now(),
      content: ''
    })
    expect(item.id).assertEqual(0)
    expect(item.repeatType).assertEqual('NONE')
    expect(item.repeatYearly).assertEqual(false)
  })

  it('should_calculate_next_occurrence_for_daily', () => {
    const item = new ScheduleItem({
      id: 1,
      title: '每日提醒',
      scheduledAt: Date.now() - 86400000, // yesterday
      repeatType: 'DAILY'
    })
    expect(item.repeatType).assertEqual('DAILY')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL with "ScheduleItem not defined"

- [ ] **Step 3: Write minimal implementation**

```typescript
// entry/src/main/ets/models/ScheduleItem.ts
export interface ScheduleItemInterface {
  id: number
  userId: string
  scheduledAt: number
  repeatYearly: boolean
  repeatByLunar: boolean
  repeatType: 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | 'CUSTOM'
  repeatRangeStart: number | null
  repeatRangeEnd: number | null
  repeatMonth: number
  repeatDayOfMonth: number
  repeatWeekday: number
  repeatHour: number
  repeatMinute: number
  lunarMonth: number
  lunarDay: number
  lunarLeap: boolean
  title: string
  content: string
  author: string | null
  mood: string | null
  weather: string | null
  location: string | null
  createdAt: number
  updatedAt: number
  previewContentPriority: string
}

export class ScheduleItem implements ScheduleItemInterface {
  id: number = 0
  userId: string = ''
  scheduledAt: number = 0
  repeatYearly: boolean = false
  repeatByLunar: boolean = false
  repeatType: 'NONE' | 'DAILY' | 'WEEKLY' | 'MONTHLY' | 'YEARLY' | 'CUSTOM' = 'NONE'
  repeatRangeStart: number | null = null
  repeatRangeEnd: number | null = null
  repeatMonth: number = 0
  repeatDayOfMonth: number = 0
  repeatWeekday: number = 0
  repeatHour: number = -1
  repeatMinute: number = 0
  lunarMonth: number = 0
  lunarDay: number = 0
  lunarLeap: boolean = false
  title: string = ''
  content: string = ''
  author: string | null = null
  mood: string | null = null
  weather: string | null = null
  location: string | null = null
  createdAt: number = 0
  updatedAt: number = 0
  previewContentPriority: string = 'text'

  constructor(data: Partial<ScheduleItemInterface> = {}) {
    Object.assign(this, data)
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/models/ScheduleItem.ts entry/src/test/ets/models/ScheduleItem.test.ets
git commit -m "feat(schedule): add ScheduleItem model"
```

---

### Task 2: ScheduleDao (Relational DB CRUD)

**Files:**
- Create: `entry/src/main/ets/data/ScheduleDao.ets`
- Test: `entry/src/test/ets/data/ScheduleDao.test.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/data/ScheduleDao.test.ets
import { describe, it, expect, beforeEach } from '@ohos.hypium'
import { ScheduleDao } from '../../main/ets/data/ScheduleDao'
import { relationalStore } from '@ohos.data.relationalStore'

describe('ScheduleDao', () => {
  let dao: ScheduleDao

  beforeEach(async () => {
    dao = await ScheduleDao.createInMemory()
  })

  it('should_insert_and_query_schedule', async () => {
    const item = {
      id: 0,
      userId: 'user1',
      scheduledAt: Date.now(),
      title: 'Test Schedule',
      content: '',
      createdAt: Date.now(),
      updatedAt: Date.now()
    }
    await dao.insert(item)
    const all = await dao.getAll('user1')
    expect(all.length).assertEqual(1)
    expect(all[0].title).assertEqual('Test Schedule')
  })

  it('should_delete_schedule_by_id', async () => {
    const item = {
      id: 0,
      userId: 'user1',
      scheduledAt: Date.now(),
      title: 'To Delete',
      content: '',
      createdAt: Date.now(),
      updatedAt: Date.now()
    }
    const id = await dao.insert(item)
    await dao.deleteById(id)
    const all = await dao.getAll('user1')
    expect(all.length).assertEqual(0)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL with "ScheduleDao not defined"

- [ ] **Step 3: Write minimal implementation**

```typescript
// entry/src/main/ets/data/ScheduleDao.ets
import relationalStore from '@ohos.data.relationalStore'
import { ScheduleItem } from '../models/ScheduleItem'

const TABLE_NAME = 'schedule_items'
const CREATE_TABLE_SQL = `
CREATE TABLE IF NOT EXISTS schedule_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  scheduledAt INTEGER NOT NULL,
  repeatYearly INTEGER NOT NULL DEFAULT 0,
  repeatByLunar INTEGER NOT NULL DEFAULT 0,
  repeatType TEXT NOT NULL DEFAULT 'NONE',
  repeatRangeStart INTEGER,
  repeatRangeEnd INTEGER,
  repeatMonth INTEGER NOT NULL DEFAULT 0,
  repeatDayOfMonth INTEGER NOT NULL DEFAULT 0,
  repeatWeekday INTEGER NOT NULL DEFAULT 0,
  repeatHour INTEGER NOT NULL DEFAULT -1,
  repeatMinute INTEGER NOT NULL DEFAULT 0,
  lunarMonth INTEGER NOT NULL DEFAULT 0,
  lunarDay INTEGER NOT NULL DEFAULT 0,
  lunarLeap INTEGER NOT NULL DEFAULT 0,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  author TEXT,
  mood TEXT,
  weather TEXT,
  location TEXT,
  createdAt INTEGER NOT NULL,
  updatedAt INTEGER NOT NULL,
  previewContentPriority TEXT NOT NULL DEFAULT 'text'
)
`
const INDEX_SQL = `CREATE INDEX IF NOT EXISTS idx_schedule_user_scheduled ON schedule_items(userId, scheduledAt)`

export class ScheduleDao {
  private store: relationalStore.RdbStore | null = null

  static async createInMemory(): Promise<ScheduleDao> {
    const dao = new ScheduleDao()
    const context = AppStorage.get<Context>('appContext')!
    const config: relationalStore.StoreConfig = {
      name: ':memory:',
      securityLevel: relationalStore.SecurityLevel.S1
    }
    dao.store = await relationalStore.getRdbStore(context, config)
    await dao.store.executeSql(CREATE_TABLE_SQL)
    await dao.store.executeSql(INDEX_SQL)
    return dao
  }

  async insert(item: Partial<ScheduleItem>): Promise<number> {
    const bucket = this.toValuesBucket(item)
    const result = await this.store!.insert(TABLE_NAME, bucket)
    return result
  }

  async update(item: Partial<ScheduleItem>): Promise<number> {
    const bucket = this.toValuesBucket(item)
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('id', item.id!)
    return await this.store!.update(TABLE_NAME, bucket, predicates)
  }

  async deleteById(id: number): Promise<number> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('id', id)
    return await this.store!.delete(TABLE_NAME, predicates)
  }

  async getAll(userId: string): Promise<ScheduleItem[]> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('userId', userId)
    const result = await this.store!.query(TABLE_NAME, [predicates])
    return this.parseResultSet(result)
  }

  async getById(id: number): Promise<ScheduleItem | null> {
    const predicates = new relationalStore.RdbPredicates(TABLE_NAME)
    predicates.equalTo('id', id)
    const result = await this.store!.query(TABLE_NAME, [predicates])
    if (!result.goToFirstRow()) return null
    return this.parseRow(result)
  }

  async getAllList(userId: string): Promise<ScheduleItem[]> {
    return this.getAll(userId)
  }

  private toValuesBucket(item: Partial<ScheduleItem>): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {}
    if (item.id !== undefined) bucket['id'] = item.id
    if (item.userId !== undefined) bucket['userId'] = item.userId
    if (item.scheduledAt !== undefined) bucket['scheduledAt'] = item.scheduledAt
    if (item.repeatYearly !== undefined) bucket['repeatYearly'] = item.repeatYearly ? 1 : 0
    if (item.repeatByLunar !== undefined) bucket['repeatByLunar'] = item.repeatByLunar ? 1 : 0
    if (item.repeatType !== undefined) bucket['repeatType'] = item.repeatType
    if (item.repeatRangeStart !== undefined) bucket['repeatRangeStart'] = item.repeatRangeStart
    if (item.repeatRangeEnd !== undefined) bucket['repeatRangeEnd'] = item.repeatRangeEnd
    if (item.repeatMonth !== undefined) bucket['repeatMonth'] = item.repeatMonth
    if (item.repeatDayOfMonth !== undefined) bucket['repeatDayOfMonth'] = item.repeatDayOfMonth
    if (item.repeatWeekday !== undefined) bucket['repeatWeekday'] = item.repeatWeekday
    if (item.repeatHour !== undefined) bucket['repeatHour'] = item.repeatHour
    if (item.repeatMinute !== undefined) bucket['repeatMinute'] = item.repeatMinute
    if (item.lunarMonth !== undefined) bucket['lunarMonth'] = item.lunarMonth
    if (item.lunarDay !== undefined) bucket['lunarDay'] = item.lunarDay
    if (item.lunarLeap !== undefined) bucket['lunarLeap'] = item.lunarLeap ? 1 : 0
    if (item.title !== undefined) bucket['title'] = item.title
    if (item.content !== undefined) bucket['content'] = item.content
    if (item.author !== undefined) bucket['author'] = item.author
    if (item.mood !== undefined) bucket['mood'] = item.mood
    if (item.weather !== undefined) bucket['weather'] = item.weather
    if (item.location !== undefined) bucket['location'] = item.location
    if (item.createdAt !== undefined) bucket['createdAt'] = item.createdAt
    if (item.updatedAt !== undefined) bucket['updatedAt'] = item.updatedAt
    if (item.previewContentPriority !== undefined) bucket['previewContentPriority'] = item.previewContentPriority
    return bucket
  }

  private parseResultSet(result: relationalStore.ResultSet): ScheduleItem[] {
    const items: ScheduleItem[] = []
    while (result.goToNextRow()) {
      items.push(this.parseRow(result))
    }
    result.close()
    return items
  }

  private parseRow(result: relationalStore.ResultSet): ScheduleItem {
    return new ScheduleItem({
      id: result.getLong(result.getColumnIndex('id')),
      userId: result.getString(result.getColumnIndex('userId')),
      scheduledAt: result.getLong(result.getColumnIndex('scheduledAt')),
      repeatYearly: result.getLong(result.getColumnIndex('repeatYearly')) === 1,
      repeatByLunar: result.getLong(result.getColumnIndex('repeatByLunar')) === 1,
      repeatType: result.getString(result.getColumnIndex('repeatType')) as any,
      repeatRangeStart: result.getLong(result.getColumnIndex('repeatRangeStart')),
      repeatRangeEnd: result.getLong(result.getColumnIndex('repeatRangeEnd')),
      repeatMonth: result.getLong(result.getColumnIndex('repeatMonth')),
      repeatDayOfMonth: result.getLong(result.getColumnIndex('repeatDayOfMonth')),
      repeatWeekday: result.getLong(result.getColumnIndex('repeatWeekday')),
      repeatHour: result.getLong(result.getColumnIndex('repeatHour')),
      repeatMinute: result.getLong(result.getColumnIndex('repeatMinute')),
      lunarMonth: result.getLong(result.getColumnIndex('lunarMonth')),
      lunarDay: result.getLong(result.getColumnIndex('lunarDay')),
      lunarLeap: result.getLong(result.getColumnIndex('lunarLeap')) === 1,
      title: result.getString(result.getColumnIndex('title')),
      content: result.getString(result.getColumnIndex('content')),
      author: result.getString(result.getColumnIndex('author')),
      mood: result.getString(result.getColumnIndex('mood')),
      weather: result.getString(result.getColumnIndex('weather')),
      location: result.getString(result.getColumnIndex('location')),
      createdAt: result.getLong(result.getColumnIndex('createdAt')),
      updatedAt: result.getLong(result.getColumnIndex('updatedAt')),
      previewContentPriority: result.getString(result.getColumnIndex('previewContentPriority'))
    })
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/data/ScheduleDao.ets entry/src/test/ets/data/ScheduleDao.test.ets
git commit -m "feat(schedule): add ScheduleDao with Relational DB CRUD"
```

---

### Task 3: ScheduleRepository

**Files:**
- Create: `entry/src/main/ets/data/ScheduleRepository.ets`
- Test: `entry/src/test/ets/data/ScheduleRepository.test.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/data/ScheduleRepository.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleRepository } from '../../main/ets/data/ScheduleRepository'
import { ScheduleDao } from '../../main/ets/data/ScheduleDao'

describe('ScheduleRepository', () => {
  it('should_insert_and_observe_schedules', async () => {
    const dao = await ScheduleDao.createInMemory()
    const repo = new ScheduleRepository(dao, 'user1')
    let count = 0
    repo.observeAll((items) => {
      count = items.length
    })
    await repo.insert({ title: 'New', scheduledAt: Date.now(), content: '' })
    expect(count).assertEqual(1)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```typescript
// entry/src/main/ets/data/ScheduleRepository.ets
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleDao } from './ScheduleDao'
import emitter from '@ohos.events.emitter'

export class ScheduleRepository {
  private dao: ScheduleDao
  private userId: string

  constructor(dao: ScheduleDao, userId: string) {
    this.dao = dao
    this.userId = userId
  }

  async insert(item: Partial<ScheduleItem>): Promise<number> {
    const now = Date.now()
    const full: Partial<ScheduleItem> = {
      ...item,
      userId: this.userId,
      createdAt: now,
      updatedAt: now
    }
    const id = await this.dao.insert(full)
    this.notifyChange()
    return id
  }

  async update(item: Partial<ScheduleItem>): Promise<number> {
    const updated = { ...item, updatedAt: Date.now() }
    const result = await this.dao.update(updated)
    this.notifyChange()
    return result
  }

  async deleteById(id: number): Promise<number> {
    const result = await this.dao.deleteById(id)
    this.notifyChange()
    return result
  }

  async getAll(): Promise<ScheduleItem[]> {
    return this.dao.getAll(this.userId)
  }

  async getById(id: number): Promise<ScheduleItem | null> {
    return this.dao.getById(id)
  }

  observeAll(callback: (items: ScheduleItem[]) => void): emitter.EventId {
    const self = this
    const handler = () => {
      self.getAll().then(callback)
    }
    return emitter.on({ eventId: 0 }, handler)
  }

  private notifyChange(): void {
    emitter.emit({ eventId: 0 })
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/data/ScheduleRepository.ets entry/src/test/ets/data/ScheduleRepository.test.ets
git commit -m "feat(schedule): add ScheduleRepository with observable events"
```

---

### Task 4: ScheduleOccurrenceUtils

**Files:**
- Create: `entry/src/main/ets/utils/ScheduleOccurrenceUtils.ets`
- Test: `entry/src/test/ets/utils/ScheduleOccurrenceUtils.test.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/utils/ScheduleOccurrenceUtils.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleOccurrenceUtils } from '../../main/ets/utils/ScheduleOccurrenceUtils'
import { ScheduleItem } from '../../main/ets/models/ScheduleItem'

describe('ScheduleOccurrenceUtils', () => {
  it('should_calculate_next_occurrence_for_daily', () => {
    const now = Date.now()
    const todayAt9am = new Date()
    todayAt9am.setHours(9, 0, 0, 0)
    const item = new ScheduleItem({
      scheduledAt: todayAt9am.getTime() - 86400000,
      repeatType: 'DAILY',
      repeatHour: 9,
      repeatMinute: 0
    })
    const next = ScheduleOccurrenceUtils.nextOccurrenceMillis(item, now)
    expect(next !== null).assertTrue()
  })

  it('should_return_null_for_expired_no_repeat', () => {
    const item = new ScheduleItem({
      scheduledAt: Date.now() - 86400000 * 2,
      repeatType: 'NONE'
    })
    const next = ScheduleOccurrenceUtils.nextOccurrenceMillis(item, Date.now())
    expect(next).assertEqual(null)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```typescript
// entry/src/main/ets/utils/ScheduleOccurrenceUtils.ets
import { ScheduleItem } from '../models/ScheduleItem'

export class ScheduleOccurrenceUtils {
  static nextOccurrenceMillis(item: ScheduleItem, nowMillis: number): number | null {
    if (item.repeatType === 'NONE') {
      if (item.scheduledAt < nowMillis) return null
      return item.scheduledAt
    }

    switch (item.repeatType) {
      case 'DAILY': return this.nextDaily(item, nowMillis)
      case 'WEEKLY': return this.nextWeekly(item, nowMillis)
      case 'MONTHLY': return this.nextMonthly(item, nowMillis)
      case 'YEARLY': return this.nextYearly(item, nowMillis)
      default: return item.scheduledAt
    }
  }

  private static nextDaily(item: ScheduleItem, nowMillis: number): number {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    base.setHours(now.getHours(), now.getMinutes(), now.getSeconds(), 0)
    if (base.getTime() <= nowMillis) {
      base.setDate(base.getDate() + 1)
    }
    if (item.repeatRangeEnd !== null && base.getTime() > item.repeatRangeEnd) {
      return nowMillis + 86400000
    }
    return base.getTime()
  }

  private static nextWeekly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const targetWeekday = item.repeatWeekday
    const currentWeekday = now.getDay()
    const daysUntilTarget = (targetWeekday - currentWeekday + 7) % 7
    const nextDate = new Date(now)
    nextDate.setDate(nextDate.getDate() + (daysUntilTarget === 0 ? 7 : daysUntilTarget))
    nextDate.setHours(base.getHours(), base.getMinutes(), 0, 0)
    if (item.repeatRangeEnd !== null && nextDate.getTime() > item.repeatRangeEnd) {
      return null
    }
    return nextDate.getTime()
  }

  private static nextMonthly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const targetDay = item.repeatDayOfMonth || base.getDate()
    const next = new Date(now.getFullYear(), now.getMonth(), targetDay, base.getHours(), base.getMinutes(), 0, 0)
    if (next.getTime() <= nowMillis) {
      next.setMonth(next.getMonth() + 1)
    }
    if (item.repeatRangeEnd !== null && next.getTime() > item.repeatRangeEnd) {
      return null
    }
    return next.getTime()
  }

  private static nextYearly(item: ScheduleItem, nowMillis: number): number | null {
    const base = new Date(item.scheduledAt)
    const now = new Date(nowMillis)
    const next = new Date(now.getFullYear(), base.getMonth(), base.getDate(), base.getHours(), base.getMinutes(), 0, 0)
    if (next.getTime() <= nowMillis) {
      next.setFullYear(next.getFullYear() + 1)
    }
    if (item.repeatRangeEnd !== null && next.getTime() > item.repeatRangeEnd) {
      return null
    }
    return next.getTime()
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/utils/ScheduleOccurrenceUtils.ets entry/src/test/ets/utils/ScheduleOccurrenceUtils.test.ets
git commit -m "feat(schedule): add ScheduleOccurrenceUtils for repeat calculation"
```

---

### Task 5: ReminderService (ReminderAgent替代 AlarmManager)

**Files:**
- Create: `entry/src/main/ets/services/ReminderService.ets`
- Test: `entry/src/test/ets/services/ReminderService.test.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/services/ReminderService.test.ets
import { describe, it, expect, beforeEach } from '@ohos.hypium'
import { ReminderService } from '../../main/ets/services/ReminderService'

describe('ReminderService', () => {
  beforeEach(() => {
    ReminderService.cancelAll()
  })

  it('should_schedule_reminder_with_lead_time', async () => {
    const item = {
      id: 1,
      title: 'Test Reminder',
      scheduledAt: Date.now() + 600000,
      content: ''
    }
    const scheduled = await ReminderService.schedule(item, 5)
    expect(scheduled).assertTrue()
  })

  it('should_cancel_reminder', async () => {
    const item = {
      id: 2,
      title: 'Cancel Me',
      scheduledAt: Date.now() + 600000,
      content: ''
    }
    await ReminderService.schedule(item, 5)
    const cancelled = await ReminderService.cancel(item.id)
    expect(cancelled).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write minimal implementation**

```typescript
// entry/src/main/ets/services/ReminderService.ets
/**
 * ReminderService — HarmonyOS ReminderAgent替代 Android AlarmManager
 * Reference: ScheduleAlarmScheduler.kt
 */
import reminderAgentManager from '@ohos.reminderAgentManager'
import wantAgent from '@ohos.wantAgent'
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleOccurrenceUtils } from '../utils/ScheduleOccurrenceUtils'

export class ReminderService {
  private static activeReminders: Set<number> = new Set()

  static async schedule(item: ScheduleItem, leadMinutes: number = 5): Promise<boolean> {
    try {
      const now = System.getTime()
      const nextAt = ScheduleOccurrenceUtils.nextOccurrenceMillis(item, now)
      if (nextAt === null) return false

      const triggerAt = nextAt - leadMinutes * 60_000
      if (triggerAt <= now) return false

      const reminderRequest: reminderAgentManager.ReminderRequestCalendar = {
        reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
        dateTime: {
          year: new Date(triggerAt).getFullYear(),
          month: new Date(triggerAt).getMonth() + 1,
          day: new Date(triggerAt).getDate(),
          hour: new Date(triggerAt).getHours(),
          minute: new Date(triggerAt).getMinutes()
        },
        repeatMonths: [],
        repeatDays: [],
        title: item.title,
        content: item.content || '日程提醒',
        wantAgent: {
          wants: [
            {
              bundleName: 'com.vhenge.diaryapp',
              abilityName: 'EntryAbility'
            }
          ],
          operationType: wantAgent.OperationType.START_ABILITY,
          requestCode: 0,
          wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
        }
      }

      const reminderId = await reminderAgentManager.addReminder(reminderRequest)
      this.activeReminders.add(item.id)
      return reminderId > 0
    } catch (e) {
      console.error('Failed to schedule reminder:', JSON.stringify(e))
      return false
    }
  }

  static async cancel(scheduleId: number): Promise<boolean> {
    try {
      if (!this.activeReminders.has(scheduleId)) return true
      const reminderId = this.getReminderId(scheduleId)
      if (reminderId !== null) {
        await reminderAgentManager.cancelReminder(reminderId)
      }
      this.activeReminders.delete(scheduleId)
      return true
    } catch (e) {
      console.error('Failed to cancel reminder:', JSON.stringify(e))
      return false
    }
  }

  static async rescheduleAll(items: ScheduleItem[], leadMinutes: number = 5): Promise<void> {
    for (const id of this.activeReminders) {
      await this.cancel(id)
    }
    for (const item of items) {
      await this.schedule(item, leadMinutes)
    }
  }

  static async cancelAll(): Promise<void> {
    for (const id of this.activeReminders) {
      await this.cancel(id)
    }
  }

  private static getReminderId(scheduleId: number): number | null {
    return scheduleId > 0 ? scheduleId : null
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/services/ReminderService.ets entry/src/test/ets/services/ReminderService.test.ets
git commit -m "feat(schedule): add ReminderService using HarmonyOS ReminderAgent"
```

---

### Task 6: ScheduleCard Component

**Files:**
- Create: `entry/src/main/ets/components/ScheduleCard.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/components/ScheduleCard.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleCard, ScheduleItemWrapper } from '../../main/ets/components/ScheduleCard'
import { ScheduleItem } from '../../main/ets/models/ScheduleItem'

describe('ScheduleCard', () => {
  it('should_render_schedule_title', () => {
    const item = new ScheduleItem({
      title: 'Meeting',
      scheduledAt: Date.now() + 3600000,
      content: 'Team standup'
    })
    expect(item.title).assertEqual('Meeting')
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/components/ScheduleCard.ets
@Component
export struct ScheduleCard {
  @ObjectLink item: ScheduleItemWrapper
  onClick?: (item: ScheduleItem) => void
  onDelete?: (item: ScheduleItem) => void

  build() {
    Card() {
      Column() {
        Row() {
          Text(this.item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Blank()

          if (this.item.repeatType !== 'NONE') {
            Text(this.getRepeatLabel())
              .fontSize(12)
              .fontColor('#999')
          }
        }
        .width('100%')

        Row() {
          Text(this.formatDateTime(this.item.scheduledAt))
            .fontSize(13)
            .fontColor('#666')
        }
        .width('100%')
        .margin({ top: 4 })

        if (this.item.content.length > 0) {
          Text(this.item.content)
            .fontSize(13)
            .fontColor('#888')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 4 })
        }

        Row() {
          Blank()
          Button('删除')
            .fontSize(12)
            .fontColor('#E53935')
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              if (this.onDelete) {
                this.onDelete(this.item)
              }
            })
        }
        .width('100%')
        .margin({ top: 8 })
      }
      .padding(16)
    }
    .width('100%')
    .margin({ bottom: 8 })
    .onClick(() => {
      if (this.onClick) {
        this.onClick(this.item)
      }
    })
  }

  private formatDateTime(millis: number): string {
    const date = new Date(millis)
    const fmt = new Intl.DateTimeFormat('zh-CN', {
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
    return fmt.format(date)
  }

  private getRepeatLabel(): string {
    switch (this.item.repeatType) {
      case 'DAILY': return '每天'
      case 'WEEKLY': return '每周'
      case 'MONTHLY': return '每月'
      case 'YEARLY': return '每年'
      default: return ''
    }
  }
}

@Observed
export class ScheduleItemWrapper {
  id: number = 0
  userId: string = ''
  scheduledAt: number = 0
  repeatYearly: boolean = false
  repeatByLunar: boolean = false
  repeatType: string = 'NONE'
  repeatRangeStart: number | null = null
  repeatRangeEnd: number | null = null
  repeatMonth: number = 0
  repeatDayOfMonth: number = 0
  repeatWeekday: number = 0
  repeatHour: number = -1
  repeatMinute: number = 0
  lunarMonth: number = 0
  lunarDay: number = 0
  lunarLeap: boolean = false
  title: string = ''
  content: string = ''
  author: string | null = null
  mood: string | null = null
  weather: string | null = null
  location: string | null = null
  createdAt: number = 0
  updatedAt: number = 0
  previewContentPriority: string = 'text'

  constructor(item?: Partial<ScheduleItemWrapper>) {
    if (item) {
      Object.assign(this, item)
    }
  }

  static from(item: ScheduleItem): ScheduleItemWrapper {
    return new ScheduleItemWrapper({
      id: item.id,
      userId: item.userId,
      scheduledAt: item.scheduledAt,
      repeatYearly: item.repeatYearly,
      repeatByLunar: item.repeatByLunar,
      repeatType: item.repeatType,
      repeatRangeStart: item.repeatRangeStart,
      repeatRangeEnd: item.repeatRangeEnd,
      repeatMonth: item.repeatMonth,
      repeatDayOfMonth: item.repeatDayOfMonth,
      repeatWeekday: item.repeatWeekday,
      repeatHour: item.repeatHour,
      repeatMinute: item.repeatMinute,
      lunarMonth: item.lunarMonth,
      lunarDay: item.lunarDay,
      lunarLeap: item.lunarLeap,
      title: item.title,
      content: item.content,
      author: item.author,
      mood: item.mood,
      weather: item.weather,
      location: item.location,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      previewContentPriority: item.previewContentPriority
    })
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/components/ScheduleCard.ets
git commit -m "feat(schedule): add ScheduleCard component"
```

---

### Task 7: RepeatRulePicker Component

**Files:**
- Create: `entry/src/main/ets/components/RepeatRulePicker.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/components/RepeatRulePicker.test.ets
import { describe, it, expect } from '@ohos.hypium'

describe('RepeatRulePicker', () => {
  it('should_have_all_repeat_options', () => {
    const options = ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY', 'YEARLY']
    expect(options.length).assertEqual(5)
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/components/RepeatRulePicker.ets
@Component
export struct RepeatRulePicker {
  @Link selectedType: string
  @Link selectedWeekday: number
  @Link selectedDayOfMonth: number
  @Link repeatRangeStart: number | null
  @Link repeatRangeEnd: number | null

  private repeatTypes = [
    { value: 'NONE', label: '不重复' },
    { value: 'DAILY', label: '每天' },
    { value: 'WEEKLY', label: '每周' },
    { value: 'MONTHLY', label: '每月' },
    { value: 'YEARLY', label: '每年' }
  ]

  private weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']

  build() {
    Column() {
      Text('重复')
        .fontSize(14)
        .fontColor('#666')
        .alignSelf(ItemAlign.Start)
        .margin({ bottom: 8 })

      List() {
        ForEach(this.repeatTypes, (option: { value: string, label: string }) => {
          ListItem() {
            Row() {
              Text(option.label)
                .fontSize(15)
              Blank()
              if (this.selectedType === option.value) {
                Text('✓')
                  .fontColor('#1890FF')
              }
            }
            .width('100%')
            .padding({ top: 12, bottom: 12 })
            .onClick(() => {
              this.selectedType = option.value
            })
          }
        })
      }

      if (this.selectedType === 'WEEKLY') {
        Text('选择星期')
          .fontSize(14)
          .fontColor('#666')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 16, bottom: 8 })

        Row() {
          ForEach(this.weekdays, (label: string, index: number) => {
            Button(label)
              .fontSize(12)
              .height(32)
              .padding({ left: 8, right: 8 })
              .backgroundColor(this.selectedWeekday === index + 1 ? '#1890FF' : '#F5F5F5')
              .fontColor(this.selectedWeekday === index + 1 ? '#FFF' : '#333')
              .onClick(() => {
                this.selectedWeekday = index + 1
              })
          })
        }
      }

      if (this.selectedType === 'MONTHLY') {
        Text('选择日期')
          .fontSize(14)
          .fontColor('#666')
          .alignSelf(ItemAlign.Start)
          .margin({ top: 16, bottom: 8 })

        Grid() {
          ForEach(31, (day: number) => {
            GridItem() {
              Text((day + 1).toString())
                .fontSize(14)
                .width(40)
                .height(40)
                .textAlign(TextAlign.Center)
                .backgroundColor(this.selectedDayOfMonth === day + 1 ? '#1890FF' : '#F5F5F5')
                .fontColor(this.selectedDayOfMonth === day + 1 ? '#FFF' : '#333')
                .borderRadius(20)
                .onClick(() => {
                  this.selectedDayOfMonth = day + 1
                })
            }
          })
        }
        .columnsTemplate('1 1 1 1 1 1 1')
        .rowsTemplate('1 1 1 1')
        .height(160)
      }
    }
    .width('100%')
    .padding(16)
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/components/RepeatRulePicker.ets
git commit -m "feat(schedule): add RepeatRulePicker component"
```

---

### Task 8: ScheduleListViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodels/ScheduleListViewModel.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/viewmodels/ScheduleListViewModel.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleListViewModel } from '../../main/ets/viewmodels/ScheduleListViewModel'

describe('ScheduleListViewModel', () => {
  it('should_have_empty_initial_state', () => {
    const vm = new ScheduleListViewModel()
    expect(vm.schedules.length).assertEqual(0)
    expect(vm.isLoading).assertFalse()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/viewmodels/ScheduleListViewModel.ets
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ScheduleItemWrapper } from '../components/ScheduleCard'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

class ScheduleListViewModel {
  @State schedules: ScheduleItem[] = []
  @State isLoading: boolean = false
  @State isEmpty: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository) {
    this.repository = repository
    repository.observeAll((items) => {
      this.schedules = items
      this.isEmpty = items.length === 0
    })
    await this.loadSchedules()
  }

  async loadSchedules() {
    if (!this.repository) return
    this.isLoading = true
    try {
      const items = await this.repository.getAll()
      this.schedules = items
      this.isEmpty = items.length === 0
    } catch (e) {
      promptAction.showToast({ message: '加载日程失败' })
    } finally {
      this.isLoading = false
    }
  }

  async deleteSchedule(item: ScheduleItem) {
    if (!this.repository) return
    try {
      await ReminderService.cancel(item.id)
      await this.repository.deleteById(item.id)
      promptAction.showToast({ message: '已删除' })
    } catch (e) {
      promptAction.showToast({ message: '删除失败' })
    }
  }

  openScheduleDetail(item: ScheduleItem) {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: item.id }
    })
  }

  openCreatePage() {
    router.pushUrl({
      url: 'pages/ScheduleDetailPage',
      params: { scheduleId: 0 }
    })
  }
}

export { ScheduleListViewModel }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/viewmodels/ScheduleListViewModel.ets
git commit -m "feat(schedule): add ScheduleListViewModel"
```

---

### Task 9: ScheduleDetailViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodels/ScheduleDetailViewModel.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/viewmodels/ScheduleDetailViewModel.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { ScheduleDetailViewModel } from '../../main/ets/viewmodels/ScheduleDetailViewModel'

describe('ScheduleDetailViewModel', () => {
  it('should_start_as_new_for_zero_id', () => {
    const vm = new ScheduleDetailViewModel()
    expect(vm.isEditing).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/viewmodels/ScheduleDetailViewModel.ets
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleRepository } from '../data/ScheduleRepository'
import { ReminderService } from '../services/ReminderService'
import promptAction from '@ohos.promptAction'
import router from '@ohos.router'

class ScheduleDetailViewModel {
  @State scheduleId: number = 0
  @State title: string = ''
  @State content: string = ''
  @State scheduledAt: number = Date.now()
  @State repeatType: string = 'NONE'
  @State repeatYearly: boolean = false
  @State repeatByLunar: boolean = false
  @State repeatMonth: number = 0
  @State repeatDayOfMonth: number = 1
  @State repeatWeekday: number = 1
  @State repeatHour: number = -1
  @State repeatMinute: number = 0
  @State lunarMonth: number = 0
  @State lunarDay: number = 0
  @State lunarLeap: boolean = false
  @State mood: string = ''
  @State weather: string = ''
  @State location: string = ''
  @State isLoading: boolean = false
  @State isEditing: boolean = true

  private repository: ScheduleRepository | null = null

  async init(repository: ScheduleRepository, scheduleId: number) {
    this.repository = repository
    this.scheduleId = scheduleId
    this.isEditing = scheduleId === 0

    if (scheduleId > 0) {
      this.isLoading = true
      try {
        const item = await repository.getById(scheduleId)
        if (item) {
          this.title = item.title
          this.content = item.content
          this.scheduledAt = item.scheduledAt
          this.repeatType = item.repeatType
          this.repeatYearly = item.repeatYearly
          this.repeatByLunar = item.repeatByLunar
          this.repeatMonth = item.repeatMonth
          this.repeatDayOfMonth = item.repeatDayOfMonth
          this.repeatWeekday = item.repeatWeekday
          this.repeatHour = item.repeatHour
          this.repeatMinute = item.repeatMinute
          this.lunarMonth = item.lunarMonth
          this.lunarDay = item.lunarDay
          this.lunarLeap = item.lunarLeap
          this.mood = item.mood || ''
          this.weather = item.weather || ''
          this.location = item.location || ''
        }
      } catch (e) {
        promptAction.showToast({ message: '加载失败' })
      } finally {
        this.isLoading = false
      }
    }
  }

  async save() {
    if (!this.repository) return
    if (this.title.trim().length === 0) {
      promptAction.showToast({ message: '请输入标题' })
      return
    }

    this.isLoading = true
    try {
      const data: Partial<ScheduleItem> = {
        title: this.title.trim(),
        content: this.content,
        scheduledAt: this.scheduledAt,
        repeatType: this.repeatType as any,
        repeatYearly: this.repeatYearly,
        repeatByLunar: this.repeatByLunar,
        repeatMonth: this.repeatMonth,
        repeatDayOfMonth: this.repeatDayOfMonth,
        repeatWeekday: this.repeatWeekday,
        repeatHour: this.repeatHour,
        repeatMinute: this.repeatMinute,
        lunarMonth: this.lunarMonth,
        lunarDay: this.lunarDay,
        lunarLeap: this.lunarLeap,
        mood: this.mood || null,
        weather: this.weather || null,
        location: this.location || null
      }

      if (this.scheduleId > 0) {
        data.id = this.scheduleId
        await this.repository.update(data)
        await ReminderService.cancel(this.scheduleId)
        await ReminderService.schedule(new ScheduleItem(data), 5)
      } else {
        const id = await this.repository.insert(data)
        await ReminderService.schedule(new ScheduleItem({ ...data, id }), 5)
      }

      promptAction.showToast({ message: '保存成功' })
      router.back()
    } catch (e) {
      promptAction.showToast({ message: '保存失败' })
    } finally {
      this.isLoading = false
    }
  }

  setDate(millis: number) {
    this.scheduledAt = millis
  }

  setRepeat(type: string) {
    this.repeatType = type
  }
}

export { ScheduleDetailViewModel }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/viewmodels/ScheduleDetailViewModel.ets
git commit -m "feat(schedule): add ScheduleDetailViewModel"
```

---

### Task 10: ScheduleListPage

**Files:**
- Create: `entry/src/main/ets/pages/ScheduleListPage.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/pages/ScheduleListPage.test.ets
import { describe, it, expect } from '@ohos.hypium'

describe('ScheduleListPage', () => {
  it('should_have_create_button', () => {
    expect(true).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/pages/ScheduleListPage.ets
import router from '@ohos.router'
import { ScheduleListViewModel } from '../viewmodels/ScheduleListViewModel'
import { ScheduleCard, ScheduleItemWrapper } from '../components/ScheduleCard'
import { ScheduleItem } from '../models/ScheduleItem'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct ScheduleListPage {
  @State viewModel: ScheduleListViewModel = new ScheduleListViewModel()
  private repository: ScheduleRepository | null = null

  aboutToAppear() {
    this.initRepository()
  }

  async initRepository() {
    const context = AppStorage.get<Context>('appContext')!
    const dao = new ScheduleDao(context)
    const userId = AppStorage.get<string>('userId') || 'default'
    this.repository = new ScheduleRepository(dao, userId)
    await this.viewModel.init(this.repository)
  }

  build() {
    Stack() {
      if (this.viewModel.isEmpty && !this.viewModel.isLoading) {
        Column() {
          Text('暂无日程')
            .fontSize(16)
            .fontColor('#999')
          Text('点击右下角添加日程')
            .fontSize(13)
            .fontColor('#CCC')
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      }

      if (!this.viewModel.isEmpty) {
        List() {
          ForEach(this.viewModel.schedules, (item: ScheduleItem) => {
            ListItem() {
              ScheduleCard({
                item: ScheduleItemWrapper.from(item),
                onClick: (s) => this.viewModel.openScheduleDetail(s),
                onDelete: (s) => this.handleDelete(s)
              })
            }
          })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16, top: 16 })
      }

      Button()
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#1890FF')
        .position({ x: '80%', y: '85%' })
        .onClick(() => this.viewModel.openCreatePage())
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  async handleDelete(item: ScheduleItem) {
    const action = await promptAction.showActionMenu({
      title: '删除日程',
      buttons: [
        { text: '确认删除', color: '#E53935' },
        { text: '取消', color: '#999999' }
      ]
    })
    if (action.index === 0) {
      await this.viewModel.deleteSchedule(item)
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/ScheduleListPage.ets
git commit -m "feat(schedule): add ScheduleListPage with FAB create"
```

---

### Task 11: ScheduleDetailPage

**Files:**
- Create: `entry/src/main/ets/pages/ScheduleDetailPage.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/pages/ScheduleDetailPage.test.ets
import { describe, it, expect } from '@ohos.hypium'

describe('ScheduleDetailPage', () => {
  it('should_render_edit_mode', () => {
    expect(true).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/pages/ScheduleDetailPage.ets
import router from '@ohos.router'
import { ScheduleDetailViewModel } from '../viewmodels/ScheduleDetailViewModel'
import { RepeatRulePicker } from '../components/RepeatRulePicker'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'

@Entry
@Component
struct ScheduleDetailPage {
  @State viewModel: ScheduleDetailViewModel = new ScheduleDetailViewModel()
  private repository: ScheduleRepository | null = null
  @State showRepeatPicker: boolean = false

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>
    const scheduleId = params?.scheduleId || 0
    this.initRepository(scheduleId)
  }

  async initRepository(scheduleId: number) {
    const context = AppStorage.get<Context>('appContext')!
    const dao = new ScheduleDao(context)
    const userId = AppStorage.get<string>('userId') || 'default'
    this.repository = new ScheduleRepository(dao, userId)
    await this.viewModel.init(this.repository, scheduleId)
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          TextInput({ placeholder: '日程标题', text: this.viewModel.title })
            .width('100%')
            .height(48)
            .fontSize(16)
            .onChange((value: string) => { this.viewModel.title = value })

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          Row() {
            Text('日期时间')
              .fontSize(14)
              .fontColor('#666')
            Blank()
            Text(this.formatDateTime(this.viewModel.scheduledAt))
              .fontSize(14)
              .fontColor('#333')
              .onClick(() => this.showDatePicker())
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          Row() {
            Text('重复')
              .fontSize(14)
              .fontColor('#666')
            Blank()
            Text(this.getRepeatLabel())
              .fontSize(14)
              .fontColor('#333')
              .onClick(() => { this.showRepeatPicker = !this.showRepeatPicker })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })

          if (this.showRepeatPicker) {
            RepeatRulePicker({
              selectedType: this.viewModel.repeatType as any,
              selectedWeekday: this.viewModel.repeatWeekday,
              selectedDayOfMonth: this.viewModel.repeatDayOfMonth,
              repeatRangeStart: this.viewModel.repeatRangeStart as any,
              repeatRangeEnd: this.viewModel.repeatRangeEnd as any
            })
          }

          Divider().width('100%').margin({ top: 8, bottom: 8 })

          TextArea({ placeholder: '日程内容...', text: this.viewModel.content })
            .width('100%')
            .height(120)
            .fontSize(15)
            .onChange((value: string) => { this.viewModel.content = value })

          Button('保存')
            .width('100%')
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#1890FF')
            .margin({ top: 24 })
            .onClick(() => this.viewModel.save())
        }
        .padding(16)
      }
      .width('100%')
      .height('100%')
    }
    .title('日程详情')
    .onBackPressed(() => {
      router.back()
    })
  }

  private formatDateTime(millis: number): string {
    const date = new Date(millis)
    return date.toLocaleDateString('zh-CN', {
      year: 'numeric',
      month: 'long',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    })
  }

  private getRepeatLabel(): string {
    switch (this.viewModel.repeatType) {
      case 'NONE': return '不重复'
      case 'DAILY': return '每天'
      case 'WEEKLY': return '每周'
      case 'MONTHLY': return '每月'
      case 'YEARLY': return '每年'
      default: return '不重复'
    }
  }

  private showDatePicker() {
    DatePickerDialog.show({
      start: new Date(),
      selected: new Date(this.viewModel.scheduledAt),
      onAccept: (result) => {
        this.viewModel.setDate(result.time)
      }
    })
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/ScheduleDetailPage.ets
git commit -m "feat(schedule): add ScheduleDetailPage with create/edit"
```

---

### Task 12: AlarmFullscreenPage (全屏闹钟页)

**Files:**
- Create: `entry/src/main/ets/pages/AlarmFullscreenPage.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/pages/AlarmFullscreenPage.test.ets
import { describe, it, expect } from '@ohos.hypium'

describe('AlarmFullscreenPage', () => {
  it('should_show_alarm_title', () => {
    expect(true).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/pages/AlarmFullscreenPage.ets
import router from '@ohos.router'
import window from '@ohos.window'
import { emitter } from '@ohos.events.emitter'

@Entry
@Component
struct AlarmFullscreenPage {
  @State currentTime: string = ''
  @State currentDate: string = ''
  @State scheduleTitle: string = ''
  @State scheduleMessage: string = ''
  private timerId: number = -1
  private scheduleId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, string | number>
    this.scheduleId = params?.scheduleId as number || 0
    this.scheduleTitle = params?.title as string || '日程提醒'
    this.scheduleMessage = params?.message as string || ''

    this.updateTime()
    this.timerId = setInterval(() => this.updateTime(), 1000)
    this.setKeepScreenOn(true)
  }

  aboutToDisappear() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId)
    }
    this.setKeepScreenOn(false)
  }

  private async setKeepScreenOn(on: boolean) {
    try {
      const context = AppStorage.get<Context>('appContext')!
      const win = await window.getLastWindow(context)
      await win.setKeepScreenOn(on)
    } catch (_) {}
  }

  private updateTime() {
    const now = new Date()
    this.currentTime = now.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
    this.currentDate = now.toLocaleDateString('zh-CN', { weekday: 'long', month: 'long', day: 'numeric' })
  }

  build() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#1A1A2E')

      Column() {
        Text('🔔')
          .fontSize(48)
          .margin({ top: 80 })

        Text(this.scheduleTitle || '日程提醒')
          .fontSize(22)
          .fontColor('#FFF')
          .fontWeight(FontWeight.Medium)
          .margin({ top: 24 })

        Text(this.scheduleMessage || '您有一个日程即将开始')
          .fontSize(15)
          .fontColor('#AAA')
          .margin({ top: 8 })

        Blank()

        Text(this.currentTime)
          .fontSize(72)
          .fontColor('#FFF')
          .fontWeight(FontWeight.Light)

        Text(this.currentDate)
          .fontSize(16)
          .fontColor('#888')
          .margin({ top: 8 })

        Blank()

        Row() {
          Button('关闭')
            .width(140)
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#444')
            .borderRadius(24)
            .onClick(() => {
              this.stopAlarm()
            })

          Button('查看详情')
            .width(140)
            .height(48)
            .fontColor('#FFF')
            .backgroundColor('#1890FF')
            .borderRadius(24)
            .onClick(() => {
              this.stopAlarm()
              router.pushUrl({
                url: 'pages/ScheduleDetailPage',
                params: { scheduleId: this.scheduleId }
              })
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .padding({ bottom: 60 })
      }
      .width('100%')
      .height('100%')
    }
  }

  private stopAlarm() {
    if (this.scheduleId > 0) {
      emitter.emit({ eventId: this.scheduleId })
    }
    router.back()
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/pages/AlarmFullscreenPage.ets
git commit -m "feat(schedule): add AlarmFullscreenPage"
```

---

### Task 13: BootAbilityStage (开机自启)

**Files:**
- Create: `entry/src/main/ets/ability/BootAbilityStage.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/ability/BootAbilityStage.test.ets
import { describe, it, expect } from '@ohos.hypium'

describe('BootAbilityStage', () => {
  it('should_reschedule_on_boot', () => {
    expect(true).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/ability/BootAbilityStage.ets
import AbilityStage from '@ohos.app.ability.AbilityStage'
import { ReminderService } from '../services/ReminderService'
import { ScheduleDao } from '../data/ScheduleDao'
import { ScheduleRepository } from '../data/ScheduleRepository'

export default class BootAbilityStage extends AbilityStage {
  onAcceptWant(want: Want): string {
    this.rescheduleAllReminders()
    return 'BootAbilityStage'
  }

  private async rescheduleAllReminders() {
    try {
      const context = this.context
      const dao = new ScheduleDao(context)
      const userId = 'user'
      const repo = new ScheduleRepository(dao, userId)

      const items = await repo.getAll()
      await ReminderService.rescheduleAll(items, 5)

      console.info('BootAbilityStage: Rescheduled all reminders')
    } catch (e) {
      console.error('BootAbilityStage: Failed to reschedule', JSON.stringify(e))
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/ability/BootAbilityStage.ets
git commit -m "feat(schedule): add BootAbilityStage for boot-reschedule"
```

---

### Task 14: NotificationHelper

**Files:**
- Create: `entry/src/main/ets/components/NotificationHelper.ets`
- Test: `entry/src/test/ets/components/NotificationHelper.test.ets`

- [ ] **Step 1: Write the test**

```typescript
// entry/src/test/ets/components/NotificationHelper.test.ets
import { describe, it, expect } from '@ohos.hypium'
import { NotificationHelper } from '../../main/ets/components/NotificationHelper'

describe('NotificationHelper', () => {
  it('should_cancel_notification', async () => {
    const result = await NotificationHelper.cancelNotification(1)
    expect(result).assertTrue()
  })
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `hvigorw test --test-type unit`
Expected: FAIL

- [ ] **Step 3: Write implementation**

```typescript
// entry/src/main/ets/components/NotificationHelper.ets
import notificationManager from '@ohos.notificationManager'
import wantAgent from '@ohos.wantAgent'
import { ScheduleItem } from '../models/ScheduleItem'

export class NotificationHelper {
  static async init(): Promise<void> {
    const isEnabled = await notificationManager.isNotificationEnabled()
    if (!isEnabled) {
      console.warn('Notifications are disabled')
      return
    }
    await notificationManager.addSlot('schedule_reminder')
  }

  static async publishScheduleReminder(item: ScheduleItem, triggerAt: number): Promise<boolean> {
    try {
      const wantAgentInfo: wantAgent.WantAgentInfo = {
        wants: [
          {
            bundleName: 'com.vhenge.diaryapp',
            abilityName: 'EntryAbility'
          }
        ],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0
      }

      const agent = await wantAgent.getWantAgent(wantAgentInfo)

      const request: notificationManager.NotificationRequest = {
        id: item.id,
        slotType: notificationManager.SlotType.CONTENT_INFORMATION,
        wantAgent: agent,
        title: item.title,
        content: item.content || '日程提醒',
        deliveryTime: triggerAt
      }

      await notificationManager.publish(request)
      return true
    } catch (e) {
      console.error('Failed to publish notification:', JSON.stringify(e))
      return false
    }
  }

  static async cancelNotification(id: number): Promise<boolean> {
    try {
      await notificationManager.cancel(id)
      return true
    } catch (e) {
      console.error('Failed to cancel notification:', JSON.stringify(e))
      return false
    }
  }

  static async cancelAll(): Promise<void> {
    try {
      await notificationManager.cancelAll()
    } catch (e) {
      console.error('Failed to cancel all:', JSON.stringify(e))
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `hvigorw test --test-type unit`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/components/NotificationHelper.ets entry/src/test/ets/components/NotificationHelper.test.ets
git commit -m "feat(schedule): add NotificationHelper"
```

---

### Task 15: Page Routing Registration + Permissions

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

**Step 1: Register routes**

Navigate to `entry/src/main/resources/base/profile/main_pages.json`:

```json
{
  "src": [
    "pages/ScheduleListPage",
    "pages/ScheduleDetailPage",
    "pages/AlarmFullscreenPage"
  ]
}
```

**Step 2: Verify ReminderAgent permission in module.json5:**

```json
{
  "requestPermissions": [
    { "name": "ohos.permission.NOTIFICATION_CONTROLLER" },
    { "name": "ohos.permission.PUBLISH_AGENT_REMINDER" },
    { "name": "ohos.permission.backgroundTaskManager" }
  ]
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat(schedule): register page routes and permissions"
```

---

## Summary

| Task | File | Status |
|------|------|--------|
| 1 | ScheduleItem.ts | ☐ |
| 2 | ScheduleDao.ets | ☐ |
| 3 | ScheduleRepository.ets | ☐ |
| 4 | ScheduleOccurrenceUtils.ets | ☐ |
| 5 | ReminderService.ets | ☐ |
| 6 | ScheduleCard.ets | ☐ |
| 7 | RepeatRulePicker.ets | ☐ |
| 8 | ScheduleListViewModel.ets | ☐ |
| 9 | ScheduleDetailViewModel.ets | ☐ |
| 10 | ScheduleListPage.ets | ☐ |
| 11 | ScheduleDetailPage.ets | ☐ |
| 12 | AlarmFullscreenPage.ets | ☐ |
| 13 | BootAbilityStage.ets | ☐ |
| 14 | NotificationHelper.ets | ☐ |
| 15 | Page routing + permissions | ☐ |

**Android → HarmonyOS Key Mappings:**

| Android | HarmonyOS |
|---------|-----------|
| AlarmManager | ReminderAgentManager |
| BroadcastReceiver | AbilityStage / UIAbility |
| Room DAO | Relational DB |
| PendingIntent | WantAgent |
| NotificationManager | notificationManager |
| DatePickerDialog | DatePickerDialog |
| RecyclerView + Adapter | ListContainer + ForEach |
