# 日子模块 (Day Module) HarmonyOS 迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Android DiaryApp 的"日子"模块（DayViewActivity、DayPagerFragment、DayCardAdapter、DayTimelineAdapter）完整迁移至 HarmonyOS ArkTS，实现卡片/时间轴/相册三视图切换、日子详情展示、滑动删除、图片预览等全部功能。

**Architecture:** MVVM + Repository 分层架构，ViewModel 持有 @State 驱动 UI；DayPagerPage 负责三视图切换（Swiper 卡片、List 时间轴、Grid 相册），DayPage 负责日子详情；使用 HarmonyOS Relational DB（createRdbStore）持久化，PanGesture 实现滑动删除。

**Tech Stack:** ArkTS / ArkUI、HarmonyOS Relational DB、@State/@ObjectLink/@Observed、Swiper、List、Grid、PanGesture、router、promptAction

---

## 文件结构

```
entry/src/main/ets/
├── model/
│   └── DayItem.ts                         # Day 数据模型（对标 DayItem.kt Room entity）
├── data/
│   ├── dao/
│   │   └── DayDao.ets                     # Relational DB CRUD（对标 DayDao.kt）
│   └── repository/
│       └── DayRepository.ets              # 数据仓库（对标 DiaryRepository.kt 模式）
├── util/
│   └── DayTimeUtils.ets                   # 已过/剩余天数计算
├── viewmodel/
│   ├── DayViewModel.ets                   # 单条日子 ViewModel
│   └── DayPagerViewModel.ets              # 三视图切换 ViewModel
├── components/day/
│   ├── DayTimelineModels.ets              # 时间轴分组数据结构
│   ├── DayCard.ets                        # 卡片视图单项（Swiper item）
│   ├── DayTimelineCard.ets                # 时间轴视图单项（ListItem）
│   └── DayAlbumSection.ets               # 相册视图（Grid section）
└── pages/
    ├── DayPage.ets                        # 日子详情页（对标 DayViewActivity.kt）
    └── DayPagerPage.ets                   # 三视图主页（对标 DayPagerFragment.kt）
```

---

## Task 1: DayItem.ts — 数据模型

**Files:**
- Create: `entry/src/main/ets/model/DayItem.ts`

对标 Android `DayItem.kt`（Room entity），字段完全对应。

- [ ] **Step 1: 编写模型文件**

```typescript
// entry/src/main/ets/model/DayItem.ts

export enum Priority {
  LOW = 0,
  NORMAL = 1,
  HIGH = 2
}

export enum Mood {
  UNKNOWN = 0,
  HAPPY = 1,
  NEUTRAL = 2,
  SAD = 3,
  ANGRY = 4,
  EXCITED = 5
}

export enum PreviewContentPriority {
  TEXT = 0,
  IMAGE = 1
}

export interface DayItem {
  id: number
  userId: string
  startAt: string           // ISO-8601，"从这一天起"
  title: string
  content: string           // HTML 富文本
  author: string
  mood: Mood
  priority: Priority
  location: string
  createdAt: string
  updatedAt: string
  previewContentPriority: PreviewContentPriority
}

export const DEFAULT_DAY_ITEM: DayItem = {
  id: 0,
  userId: '',
  startAt: '',
  title: '',
  content: '',
  author: '',
  mood: Mood.UNKNOWN,
  priority: Priority.NORMAL,
  location: '',
  createdAt: '',
  updatedAt: '',
  previewContentPriority: PreviewContentPriority.TEXT
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/model/DayItem.ts
git commit -m "feat(day): add DayItem model"
```

---

## Task 2: DayDao.ets — 数据库 CRUD

**Files:**
- Create: `entry/src/main/ets/data/dao/DayDao.ets`

使用 HarmonyOS `@ohos.data.relationalStore`，对标 Android Room `DayDao.kt`。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayDaoTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { DayDao } from '../../main/ets/data/dao/DayDao'
import relationalStore from '@ohos.data.relationalStore'
import { Mood, Priority, PreviewContentPriority } from '../../main/ets/model/DayItem'

const TEST_CONFIG: relationalStore.StoreConfig = {
  name: 'DayTest.db',
  securityLevel: relationalStore.SecurityLevel.S1
}

describe('DayDaoTest', () => {
  let dao: DayDao

  beforeAll(async (done) => {
    const rdb = await relationalStore.getRdbStore(globalThis.context, TEST_CONFIG)
    dao = new DayDao(rdb)
    await dao.createTable()
    done()
  })

  it('should_insert_and_query_day', async (done) => {
    const now = new Date().toISOString()
    await dao.insert({
      id: 0, userId: 'u1', startAt: '2020-01-01T00:00:00Z',
      title: '结婚纪念日', content: '<p>第一天</p>', author: '我',
      mood: Mood.HAPPY, priority: Priority.HIGH, location: '北京',
      createdAt: now, updatedAt: now,
      previewContentPriority: PreviewContentPriority.TEXT
    })
    const items = await dao.queryAll('u1')
    expect(items.length).assertLarger(0)
    expect(items[0].title).assertEqual('结婚纪念日')
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: DayDao not found
```

- [ ] **Step 3: 实现 DayDao**

```typescript
// entry/src/main/ets/data/dao/DayDao.ets
import relationalStore from '@ohos.data.relationalStore'
import { DayItem, Mood, Priority, PreviewContentPriority } from '../../model/DayItem'

const TABLE = 'day_items'

const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS ${TABLE} (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    userId      TEXT    NOT NULL,
    startAt     TEXT    NOT NULL,
    title       TEXT    NOT NULL,
    content     TEXT    NOT NULL DEFAULT '',
    author      TEXT    NOT NULL DEFAULT '',
    mood        INTEGER NOT NULL DEFAULT 0,
    priority    INTEGER NOT NULL DEFAULT 1,
    location    TEXT    NOT NULL DEFAULT '',
    createdAt   TEXT    NOT NULL,
    updatedAt   TEXT    NOT NULL,
    previewContentPriority INTEGER NOT NULL DEFAULT 0
  )
`

export class DayDao {
  private rdb: relationalStore.RdbStore

  constructor(rdb: relationalStore.RdbStore) {
    this.rdb = rdb
  }

  async createTable(): Promise<void> {
    await this.rdb.executeSql(CREATE_TABLE_SQL)
  }

  async insert(item: DayItem): Promise<number> {
    const bucket: relationalStore.ValuesBucket = {
      userId: item.userId,
      startAt: item.startAt,
      title: item.title,
      content: item.content,
      author: item.author,
      mood: item.mood as number,
      priority: item.priority as number,
      location: item.location,
      createdAt: item.createdAt,
      updatedAt: item.updatedAt,
      previewContentPriority: item.previewContentPriority as number
    }
    return await this.rdb.insert(TABLE, bucket)
  }

  async queryAll(userId: string): Promise<DayItem[]> {
    const predicates = new relationalStore.RdbPredicates(TABLE)
    predicates.equalTo('userId', userId).orderByDesc('startAt')
    const cursor = await this.rdb.query(predicates)
    const items: DayItem[] = []
    while (cursor.goToNextRow()) {
      items.push(this.cursorToItem(cursor))
    }
    cursor.close()
    return items
  }

  async queryById(id: number): Promise<DayItem | null> {
    const predicates = new relationalStore.RdbPredicates(TABLE)
    predicates.equalTo('id', id)
    const cursor = await this.rdb.query(predicates)
    if (cursor.goToNextRow()) {
      const item = this.cursorToItem(cursor)
      cursor.close()
      return item
    }
    cursor.close()
    return null
  }

  async update(item: DayItem): Promise<void> {
    const bucket: relationalStore.ValuesBucket = {
      startAt: item.startAt,
      title: item.title,
      content: item.content,
      author: item.author,
      mood: item.mood as number,
      priority: item.priority as number,
      location: item.location,
      updatedAt: new Date().toISOString(),
      previewContentPriority: item.previewContentPriority as number
    }
    const predicates = new relationalStore.RdbPredicates(TABLE)
    predicates.equalTo('id', item.id)
    await this.rdb.update(bucket, predicates)
  }

  async delete(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TABLE)
    predicates.equalTo('id', id)
    await this.rdb.delete(predicates)
  }

  private cursorToItem(cursor: relationalStore.ResultSet): DayItem {
    return {
      id: cursor.getLong(cursor.getColumnIndex('id')),
      userId: cursor.getString(cursor.getColumnIndex('userId')),
      startAt: cursor.getString(cursor.getColumnIndex('startAt')),
      title: cursor.getString(cursor.getColumnIndex('title')),
      content: cursor.getString(cursor.getColumnIndex('content')),
      author: cursor.getString(cursor.getColumnIndex('author')),
      mood: cursor.getLong(cursor.getColumnIndex('mood')) as Mood,
      priority: cursor.getLong(cursor.getColumnIndex('priority')) as Priority,
      location: cursor.getString(cursor.getColumnIndex('location')),
      createdAt: cursor.getString(cursor.getColumnIndex('createdAt')),
      updatedAt: cursor.getString(cursor.getColumnIndex('updatedAt')),
      previewContentPriority: cursor.getLong(
        cursor.getColumnIndex('previewContentPriority')
      ) as PreviewContentPriority
    }
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayDaoTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/data/dao/DayDao.ets entry/src/test/DayDaoTest.ets
git commit -m "feat(day): add DayDao with Relational DB CRUD"
```

---

## Task 3: DayRepository.ets — 数据仓库

**Files:**
- Create: `entry/src/main/ets/data/repository/DayRepository.ets`

对标 Android `DiaryRepository.kt` 模式，封装 DAO，向上暴露业务方法。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayRepositoryTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { DayRepository } from '../../main/ets/data/repository/DayRepository'
import { Mood, Priority, PreviewContentPriority } from '../../main/ets/model/DayItem'
import relationalStore from '@ohos.data.relationalStore'
import { DayDao } from '../../main/ets/data/dao/DayDao'

describe('DayRepositoryTest', () => {
  let repo: DayRepository

  beforeAll(async (done) => {
    const rdb = await relationalStore.getRdbStore(globalThis.context, {
      name: 'DayRepoTest.db', securityLevel: relationalStore.SecurityLevel.S1
    })
    const dao = new DayDao(rdb)
    await dao.createTable()
    repo = new DayRepository(dao)
    done()
  })

  it('should_add_and_list_days', async (done) => {
    const now = new Date().toISOString()
    await repo.addDay({
      id: 0, userId: 'u1', startAt: '2018-06-01T00:00:00Z',
      title: '相识纪念日', content: '', author: '你我',
      mood: Mood.HAPPY, priority: Priority.NORMAL, location: '上海',
      createdAt: now, updatedAt: now,
      previewContentPriority: PreviewContentPriority.TEXT
    })
    const days = await repo.getDays('u1')
    expect(days.length).assertLarger(0)
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: DayRepository not found
```

- [ ] **Step 3: 实现 DayRepository**

```typescript
// entry/src/main/ets/data/repository/DayRepository.ets
import { DayItem } from '../../model/DayItem'
import { DayDao } from '../dao/DayDao'

export class DayRepository {
  private dao: DayDao

  constructor(dao: DayDao) {
    this.dao = dao
  }

  async getDays(userId: string): Promise<DayItem[]> {
    return this.dao.queryAll(userId)
  }

  async getDayById(id: number): Promise<DayItem | null> {
    return this.dao.queryById(id)
  }

  async addDay(item: DayItem): Promise<number> {
    return this.dao.insert(item)
  }

  async updateDay(item: DayItem): Promise<void> {
    return this.dao.update(item)
  }

  async deleteDay(id: number): Promise<void> {
    return this.dao.delete(id)
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayRepositoryTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/data/repository/DayRepository.ets entry/src/test/DayRepositoryTest.ets
git commit -m "feat(day): add DayRepository"
```

---

## Task 4: DayTimeUtils.ets — 天数计算工具

**Files:**
- Create: `entry/src/main/ets/util/DayTimeUtils.ets`

对标 Android `DayViewActivity.kt` 中的天数显示逻辑（"已过 X 天" / "还有 X 天"）。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayTimeUtilsTest.ets
import { describe, it, expect } from '@ohos/hypium'
import { calcDaysDiff, formatDaysDiff } from '../../main/ets/util/DayTimeUtils'

describe('DayTimeUtilsTest', () => {
  it('should_return_positive_for_past_date', (done) => {
    // 2020-01-01 距今（2026-04-20）已过 > 0 天
    const diff = calcDaysDiff('2020-01-01T00:00:00Z')
    expect(diff).assertLarger(0)
    done()
  })

  it('should_return_negative_for_future_date', (done) => {
    const diff = calcDaysDiff('2030-01-01T00:00:00Z')
    expect(diff).assertSmaller(0)
    done()
  })

  it('should_format_past_correctly', (done) => {
    // 用已知过去日期生成正文本
    const text = formatDaysDiff('2020-01-01T00:00:00Z')
    expect(text.includes('已过')).assertTrue()
    done()
  })

  it('should_format_future_correctly', (done) => {
    const text = formatDaysDiff('2030-01-01T00:00:00Z')
    expect(text.includes('还有')).assertTrue()
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: calcDaysDiff not found
```

- [ ] **Step 3: 实现 DayTimeUtils**

```typescript
// entry/src/main/ets/util/DayTimeUtils.ets

/**
 * 计算 startAt 距今的天数差值。
 * 正数 = 已过去，负数 = 未来。
 */
export function calcDaysDiff(startAt: string): number {
  const start = new Date(startAt).setHours(0, 0, 0, 0)
  const today = new Date().setHours(0, 0, 0, 0)
  const msPerDay = 24 * 60 * 60 * 1000
  return Math.round((today - start) / msPerDay)
}

/**
 * 格式化为"已过 X 天"或"还有 X 天"或"就是今天"。
 */
export function formatDaysDiff(startAt: string): string {
  const diff = calcDaysDiff(startAt)
  if (diff === 0) return '就是今天'
  if (diff > 0) return `已过 ${diff} 天`
  return `还有 ${Math.abs(diff)} 天`
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayTimeUtilsTest PASS (4 cases)
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/util/DayTimeUtils.ets entry/src/test/DayTimeUtilsTest.ets
git commit -m "feat(day): add DayTimeUtils for elapsed/remaining days"
```

---

## Task 5: DayViewModel.ets — 单条日子 ViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/DayViewModel.ets`

对标 Android `DiaryViewModel.kt` 模式，持有单条日子详情及删除逻辑。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayViewModelTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { DayViewModel } from '../../main/ets/viewmodel/DayViewModel'
import { DayRepository } from '../../main/ets/data/repository/DayRepository'
import { DayDao } from '../../main/ets/data/dao/DayDao'
import { Mood, Priority, PreviewContentPriority } from '../../main/ets/model/DayItem'
import relationalStore from '@ohos.data.relationalStore'

describe('DayViewModelTest', () => {
  let vm: DayViewModel

  beforeAll(async (done) => {
    const rdb = await relationalStore.getRdbStore(globalThis.context, {
      name: 'DayVMTest.db', securityLevel: relationalStore.SecurityLevel.S1
    })
    const dao = new DayDao(rdb)
    await dao.createTable()
    const repo = new DayRepository(dao)
    vm = new DayViewModel(repo)
    done()
  })

  it('should_load_day_by_id', async (done) => {
    const now = new Date().toISOString()
    const repo = (vm as any).repository as DayRepository
    await repo.addDay({
      id: 0, userId: 'u1', startAt: '2021-05-20T00:00:00Z',
      title: '520', content: '', author: '我',
      mood: Mood.HAPPY, priority: Priority.HIGH, location: '',
      createdAt: now, updatedAt: now,
      previewContentPriority: PreviewContentPriority.TEXT
    })
    const days = await repo.getDays('u1')
    await vm.loadDay(days[0].id)
    expect(vm.dayItem).assertNotNull()
    expect(vm.dayItem?.title).assertEqual('520')
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: DayViewModel not found
```

- [ ] **Step 3: 实现 DayViewModel**

```typescript
// entry/src/main/ets/viewmodel/DayViewModel.ets
import { DayItem, DEFAULT_DAY_ITEM } from '../model/DayItem'
import { DayRepository } from '../data/repository/DayRepository'

export class DayViewModel {
  private repository: DayRepository
  dayItem: DayItem | null = null
  isLoading: boolean = false
  error: string = ''

  constructor(repository: DayRepository) {
    this.repository = repository
  }

  async loadDay(id: number): Promise<void> {
    this.isLoading = true
    try {
      this.dayItem = await this.repository.getDayById(id)
    } catch (e) {
      this.error = e?.message ?? '加载失败'
    } finally {
      this.isLoading = false
    }
  }

  async deleteDay(id: number): Promise<void> {
    await this.repository.deleteDay(id)
    this.dayItem = null
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayViewModelTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/DayViewModel.ets entry/src/test/DayViewModelTest.ets
git commit -m "feat(day): add DayViewModel"
```

---

## Task 6: DayTimelineModels.ets — 时间轴分组数据结构

**Files:**
- Create: `entry/src/main/ets/components/day/DayTimelineModels.ets`

对标 Android `DayTimelineAdapter.kt` 中的 `Header`/`Card` item 分组逻辑。时间轴按年→月→日 分组展示。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayTimelineModelsTest.ets
import { describe, it, expect } from '@ohos/hypium'
import { buildTimelineGroups, TimelineSection } from '../../main/ets/components/day/DayTimelineModels'
import { Mood, Priority, PreviewContentPriority } from '../../main/ets/model/DayItem'

describe('DayTimelineModelsTest', () => {
  it('should_group_days_by_year_month', (done) => {
    const now = new Date().toISOString()
    const items = [
      { id: 1, userId: 'u', startAt: '2022-03-15T00:00:00Z', title: 'A',
        content: '', author: '', mood: Mood.NEUTRAL, priority: Priority.NORMAL,
        location: '', createdAt: now, updatedAt: now, previewContentPriority: PreviewContentPriority.TEXT },
      { id: 2, userId: 'u', startAt: '2021-11-01T00:00:00Z', title: 'B',
        content: '', author: '', mood: Mood.NEUTRAL, priority: Priority.NORMAL,
        location: '', createdAt: now, updatedAt: now, previewContentPriority: PreviewContentPriority.TEXT },
    ]
    const sections: TimelineSection[] = buildTimelineGroups(items)
    expect(sections.length).assertLarger(0)
    // 不同年份 → 至少 2 个 section
    expect(sections.length).assertEqual(2)
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: buildTimelineGroups not found
```

- [ ] **Step 3: 实现 DayTimelineModels**

```typescript
// entry/src/main/ets/components/day/DayTimelineModels.ets
import { DayItem } from '../../model/DayItem'

export interface TimelineSection {
  yearMonth: string   // e.g. "2022年 3月"
  items: DayItem[]
}

/**
 * 将 DayItem[] 按年月分组，返回 TimelineSection[]。
 * 传入的 items 应已按 startAt 降序排列。
 */
export function buildTimelineGroups(items: DayItem[]): TimelineSection[] {
  const map = new Map<string, DayItem[]>()
  for (const item of items) {
    const d = new Date(item.startAt)
    const key = `${d.getFullYear()}年 ${d.getMonth() + 1}月`
    if (!map.has(key)) map.set(key, [])
    map.get(key)!.push(item)
  }
  const sections: TimelineSection[] = []
  map.forEach((dayItems, yearMonth) => {
    sections.push({ yearMonth, items: dayItems })
  })
  return sections
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayTimelineModelsTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/components/day/DayTimelineModels.ets entry/src/test/DayTimelineModelsTest.ets
git commit -m "feat(day): add DayTimelineModels grouping logic"
```

---

## Task 7: DayCard.ets — 卡片视图单项（Swiper item）

**Files:**
- Create: `entry/src/main/ets/components/day/DayCard.ets`

对标 Android `DayCardAdapter.kt`。展示日子标题、已过天数、图片或文本预览；支持点击进入详情。

- [ ] **Step 1: 创建组件文件**

```typescript
// entry/src/main/ets/components/day/DayCard.ets
import { DayItem, PreviewContentPriority } from '../../model/DayItem'
import { formatDaysDiff } from '../../util/DayTimeUtils'
import router from '@ohos.router'

@Component
export struct DayCard {
  @ObjectLink item: DayItem

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 背景：图片或渐变色
      if (this.item.previewContentPriority === PreviewContentPriority.IMAGE
        && this.extractFirstImage(this.item.content) !== '') {
        Image(this.extractFirstImage(this.item.content))
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius(16)
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#2C3E50')
          .borderRadius(16)
      }

      // 底部文字遮罩
      Column() {
        Text(this.item.title)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(formatDaysDiff(this.item.startAt))
          .fontSize(14)
          .fontColor('#E0E0E0')
          .margin({ top: 4 })

        if (this.item.previewContentPriority === PreviewContentPriority.TEXT) {
          Text(this.stripHtml(this.item.content))
            .fontSize(13)
            .fontColor('#BDBDBD')
            .maxLines(3)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 8 })
        }
      }
      .width('100%')
      .padding(16)
      .linearGradient({
        direction: GradientDirection.Top,
        colors: [['#00000000', 0.0], ['#CC000000', 1.0]]
      })
      .borderRadius({ bottomLeft: 16, bottomRight: 16 })
    }
    .width('100%')
    .height(360)
    .borderRadius(16)
    .onClick(() => {
      router.pushUrl({
        url: 'pages/DayPage',
        params: { dayId: this.item.id }
      })
    })
  }

  private extractFirstImage(html: string): string {
    const match = html.match(/<img[^>]+src="([^"]+)"/)
    return match ? match[1] : ''
  }

  private stripHtml(html: string): string {
    return html.replace(/<[^>]*>/g, '').trim()
  }
}
```

- [ ] **Step 2: 验证组件可编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/components/day/DayCard.ets
git commit -m "feat(day): add DayCard swiper item component"
```

---

## Task 8: DayTimelineCard.ets — 时间轴视图单项

**Files:**
- Create: `entry/src/main/ets/components/day/DayTimelineCard.ets`

对标 Android `DayTimelineAdapter.kt` Card ViewHolder；支持 PanGesture 左滑删除（对标 Android ItemTouchHelper/TouchEvent 滑动删除）。

- [ ] **Step 1: 创建组件文件**

```typescript
// entry/src/main/ets/components/day/DayTimelineCard.ets
import { DayItem } from '../../model/DayItem'
import { formatDaysDiff } from '../../util/DayTimeUtils'
import router from '@ohos.router'

@Component
export struct DayTimelineCard {
  @ObjectLink item: DayItem
  onDelete: (id: number) => void = () => {}

  @State private offsetX: number = 0
  private readonly DELETE_THRESHOLD: number = -80

  build() {
    Stack() {
      // 删除背景（左滑后显示）
      Row() {
        Blank()
        Image($r('app.media.ic_delete'))
          .width(24)
          .height(24)
          .fillColor(Color.White)
        Text('删除')
          .fontColor(Color.White)
          .fontSize(14)
          .margin({ left: 4 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F44336')
      .justifyContent(FlexAlign.End)
      .padding({ right: 20 })
      .borderRadius(12)
      .visibility(this.offsetX < -20 ? Visibility.Visible : Visibility.Hidden)

      // 卡片主体
      Row() {
        // 左侧天数竖线
        Column() {
          Text(formatDaysDiff(this.item.startAt))
            .fontSize(12)
            .fontColor('#9E9E9E')
            .textAlign(TextAlign.Center)
        }
        .width(60)
        .alignItems(HorizontalAlign.Center)

        // 分隔线
        Divider()
          .vertical(true)
          .height('80%')
          .color('#E0E0E0')
          .margin({ left: 4, right: 12 })

        // 右侧内容
        Column() {
          Text(this.item.title)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(new Date(this.item.startAt).toLocaleDateString('zh-CN'))
            .fontSize(12)
            .fontColor('#9E9E9E')
            .margin({ top: 4 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
      }
      .width('100%')
      .padding(12)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
      .translate({ x: this.offsetX })
      .gesture(
        PanGesture({ direction: PanDirection.Horizontal })
          .onActionUpdate((event: GestureEvent) => {
            const dx = event.offsetX
            if (dx < 0) this.offsetX = Math.max(dx, -120)
          })
          .onActionEnd(() => {
            if (this.offsetX < this.DELETE_THRESHOLD) {
              this.onDelete(this.item.id)
            }
            animateTo({ duration: 200, curve: Curve.EaseOut }, () => {
              this.offsetX = 0
            })
          })
      )
      .onClick(() => {
        router.pushUrl({
          url: 'pages/DayPage',
          params: { dayId: this.item.id }
        })
      })
    }
    .width('100%')
    .height(80)
    .margin({ bottom: 8 })
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/components/day/DayTimelineCard.ets
git commit -m "feat(day): add DayTimelineCard with swipe-to-delete"
```

---

## Task 9: DayAlbumSection.ets — 相册视图组件

**Files:**
- Create: `entry/src/main/ets/components/day/DayAlbumSection.ets`

对标 Android `DayPagerFragment.kt` 相册模式（RecyclerView Grid + Header）；展示图片缩略图或文本预览，点击进入详情。

- [ ] **Step 1: 创建组件文件**

```typescript
// entry/src/main/ets/components/day/DayAlbumSection.ets
import { DayItem, PreviewContentPriority } from '../../model/DayItem'
import router from '@ohos.router'

@Component
export struct DayAlbumSection {
  items: DayItem[] = []

  build() {
    Grid() {
      ForEach(this.items, (item: DayItem) => {
        GridItem() {
          Stack({ alignContent: Alignment.Bottom }) {
            if (item.previewContentPriority === PreviewContentPriority.IMAGE
              && this.extractFirstImage(item.content) !== '') {
              Image(this.extractFirstImage(item.content))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Cover)
                .borderRadius(8)
            } else {
              Column() {
                Text(item.title)
                  .fontSize(13)
                  .fontColor(Color.White)
                  .maxLines(3)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .padding(8)
              }
              .width('100%')
              .height('100%')
              .backgroundColor('#37474F')
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
            }

            // 底部标题遮罩
            Text(item.title)
              .width('100%')
              .padding({ left: 6, right: 6, bottom: 6 })
              .fontSize(12)
              .fontColor(Color.White)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .linearGradient({
                direction: GradientDirection.Top,
                colors: [['#00000000', 0.0], ['#AA000000', 1.0]]
              })
              .borderRadius({ bottomLeft: 8, bottomRight: 8 })
          }
          .width('100%')
          .height(120)
          .onClick(() => {
            router.pushUrl({ url: 'pages/DayPage', params: { dayId: item.id } })
          })
        }
      }, (item: DayItem) => item.id.toString())
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsGap(8)
    .columnsGap(8)
    .padding(8)
  }

  private extractFirstImage(html: string): string {
    const match = html.match(/<img[^>]+src="([^"]+)"/)
    return match ? match[1] : ''
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/components/day/DayAlbumSection.ets
git commit -m "feat(day): add DayAlbumSection album grid component"
```

---

## Task 10: DayPagerViewModel.ets — 三视图切换 ViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/DayPagerViewModel.ets`

对标 Android `DayPagerFragment.kt` 的 viewMode 枚举 + 视图切换逻辑。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/DayPagerViewModelTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { DayPagerViewModel, ViewMode } from '../../main/ets/viewmodel/DayPagerViewModel'
import { DayRepository } from '../../main/ets/data/repository/DayRepository'
import { DayDao } from '../../main/ets/data/dao/DayDao'
import relationalStore from '@ohos.data.relationalStore'

describe('DayPagerViewModelTest', () => {
  let vm: DayPagerViewModel

  beforeAll(async (done) => {
    const rdb = await relationalStore.getRdbStore(globalThis.context, {
      name: 'DayPagerVMTest.db', securityLevel: relationalStore.SecurityLevel.S1
    })
    const dao = new DayDao(rdb)
    await dao.createTable()
    vm = new DayPagerViewModel(new DayRepository(dao))
    done()
  })

  it('should_cycle_view_modes', (done) => {
    expect(vm.viewMode).assertEqual(ViewMode.CARD)
    vm.cycleViewMode()
    expect(vm.viewMode).assertEqual(ViewMode.TIMELINE)
    vm.cycleViewMode()
    expect(vm.viewMode).assertEqual(ViewMode.ALBUM)
    vm.cycleViewMode()
    expect(vm.viewMode).assertEqual(ViewMode.CARD)
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: DayPagerViewModel not found
```

- [ ] **Step 3: 实现 DayPagerViewModel**

```typescript
// entry/src/main/ets/viewmodel/DayPagerViewModel.ets
import { DayItem } from '../model/DayItem'
import { DayRepository } from '../data/repository/DayRepository'
import { TimelineSection, buildTimelineGroups } from '../components/day/DayTimelineModels'

export enum ViewMode {
  CARD = 0,
  TIMELINE = 1,
  ALBUM = 2
}

export class DayPagerViewModel {
  private repository: DayRepository
  days: DayItem[] = []
  timelineSections: TimelineSection[] = []
  viewMode: ViewMode = ViewMode.CARD
  isLoading: boolean = false
  error: string = ''

  constructor(repository: DayRepository) {
    this.repository = repository
  }

  async loadDays(userId: string): Promise<void> {
    this.isLoading = true
    try {
      this.days = await this.repository.getDays(userId)
      this.timelineSections = buildTimelineGroups(this.days)
    } catch (e) {
      this.error = e?.message ?? '加载失败'
    } finally {
      this.isLoading = false
    }
  }

  cycleViewMode(): void {
    const modes = [ViewMode.CARD, ViewMode.TIMELINE, ViewMode.ALBUM]
    const next = (this.viewMode + 1) % modes.length
    this.viewMode = modes[next]
  }

  async deleteDay(id: number): Promise<void> {
    await this.repository.deleteDay(id)
    this.days = this.days.filter(d => d.id !== id)
    this.timelineSections = buildTimelineGroups(this.days)
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: DayPagerViewModelTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/DayPagerViewModel.ets entry/src/test/DayPagerViewModelTest.ets
git commit -m "feat(day): add DayPagerViewModel with 3-view-mode cycling"
```

---

## Task 11: DayPage.ets — 日子详情页

**Files:**
- Create: `entry/src/main/ets/pages/DayPage.ets`

对标 Android `DayViewActivity.kt`（412行）；展示日子标题、已过天数、作者、地点、富文本内容；提供删除功能。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/DayPage.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DayViewModel } from '../viewmodel/DayViewModel'
import { DayRepository } from '../data/repository/DayRepository'
import { DayDao } from '../data/dao/DayDao'
import { formatDaysDiff } from '../util/DayTimeUtils'
import relationalStore from '@ohos.data.relationalStore'
import { DayItem } from '../model/DayItem'

@Entry
@Component
struct DayPage {
  @State private vm: DayViewModel = new DayViewModel(
    new DayRepository(new DayDao(AppStorage.get('dayRdb') as relationalStore.RdbStore))
  )
  @State private dayId: number = 0

  aboutToAppear() {
    const params = router.getParams() as Record<string, number>
    this.dayId = params.dayId ?? 0
    this.vm.loadDay(this.dayId)
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Image($r('app.media.ic_back'))
          .width(24).height(24)
          .onClick(() => router.back())

        Text('日子详情')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Image($r('app.media.ic_delete'))
          .width(24).height(24)
          .onClick(() => this.confirmDelete())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.vm.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 60 })
      } else if (this.vm.dayItem !== null) {
        this.buildContent(this.vm.dayItem!)
      } else {
        Text('日子不存在').margin({ top: 60 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildContent(item: DayItem) {
    Scroll() {
      Column() {
        // 已过天数大字
        Text(formatDaysDiff(item.startAt))
          .fontSize(48)
          .fontWeight(FontWeight.Bold)
          .fontColor('#2C3E50')
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding({ top: 32, bottom: 8 })

        Text(new Date(item.startAt).toLocaleDateString('zh-CN', {
          year: 'numeric', month: 'long', day: 'numeric'
        }))
          .fontSize(14)
          .fontColor('#9E9E9E')
          .textAlign(TextAlign.Center)
          .width('100%')
          .margin({ bottom: 24 })

        // 标题卡片
        Column() {
          Text(item.title)
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .width('100%')

          if (item.author !== '') {
            Text(`作者：${item.author}`)
              .fontSize(13)
              .fontColor('#757575')
              .margin({ top: 8 })
          }

          if (item.location !== '') {
            Row() {
              Image($r('app.media.ic_location'))
                .width(14).height(14).fillColor('#9E9E9E')
              Text(item.location)
                .fontSize(13)
                .fontColor('#9E9E9E')
                .margin({ left: 4 })
            }
            .margin({ top: 6 })
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ left: 16, right: 16, bottom: 12 })
        .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })

        // 内容（富文本 HTML — 使用 RichText 组件）
        if (item.content !== '') {
          Column() {
            RichText(item.content)
              .width('100%')
          }
          .width('100%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .margin({ left: 16, right: 16, bottom: 24 })
          .shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
        }
      }
      .width('100%')
    }
    .layoutWeight(1)
  }

  private async confirmDelete() {
    promptAction.showDialog({
      title: '删除日子',
      message: `确定删除"${this.vm.dayItem?.title ?? ''}"？`,
      buttons: [
        { text: '取消', color: '#757575' },
        { text: '删除', color: '#F44336' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.vm.deleteDay(this.dayId).then(() => {
          router.back()
        })
      }
    })
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/pages/DayPage.ets
git commit -m "feat(day): add DayPage detail view"
```

---

## Task 12: DayPagerPage.ets — 三视图主页

**Files:**
- Create: `entry/src/main/ets/pages/DayPagerPage.ets`

对标 Android `DayPagerFragment.kt`（685行）；Swiper（卡片）、List（时间轴）、Grid（相册）三模式切换，右上角按钮循环切换视图。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/DayPagerPage.ets
import router from '@ohos.router'
import { DayPagerViewModel, ViewMode } from '../viewmodel/DayPagerViewModel'
import { DayRepository } from '../data/repository/DayRepository'
import { DayDao } from '../data/dao/DayDao'
import { DayCard } from '../components/day/DayCard'
import { DayTimelineCard } from '../components/day/DayTimelineCard'
import { DayAlbumSection } from '../components/day/DayAlbumSection'
import { DayItem } from '../model/DayItem'
import { TimelineSection } from '../components/day/DayTimelineModels'
import relationalStore from '@ohos.data.relationalStore'

@Entry
@Component
struct DayPagerPage {
  @State private vm: DayPagerViewModel = new DayPagerViewModel(
    new DayRepository(new DayDao(AppStorage.get('dayRdb') as relationalStore.RdbStore))
  )

  aboutToAppear() {
    const userId: string = AppStorage.get('userId') ?? ''
    this.vm.loadDays(userId)
  }

  build() {
    Column() {
      // 顶部导航
      Row() {
        Text('日子')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)

        // 视图切换按钮
        Button() {
          Image(this.viewModeIcon())
            .width(24).height(24).fillColor(Color.White)
        }
        .width(40).height(40)
        .borderRadius(20)
        .backgroundColor('#2C3E50')
        .margin({ right: 8 })
        .onClick(() => {
          this.vm.cycleViewMode()
        })

        // 新增按钮
        Button('+')
          .fontSize(22)
          .width(40).height(40)
          .borderRadius(20)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            router.pushUrl({ url: 'pages/DayEditPage' })
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.vm.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 60 })
      } else if (this.vm.days.length === 0) {
        Column() {
          Text('暂无日子记录')
            .fontSize(16)
            .fontColor('#9E9E9E')
          Text('点击 + 号开始记录')
            .fontSize(13)
            .fontColor('#BDBDBD')
            .margin({ top: 8 })
        }
        .margin({ top: 80 })
        .width('100%')
      } else {
        this.buildCurrentView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildCurrentView() {
    if (this.vm.viewMode === ViewMode.CARD) {
      // 卡片视图 — Swiper
      Swiper() {
        ForEach(this.vm.days, (item: DayItem) => {
          DayCard({ item: item })
            .padding({ left: 16, right: 16 })
        }, (item: DayItem) => item.id.toString())
      }
      .displayCount(1)
      .indicator(true)
      .loop(false)
      .layoutWeight(1)
      .padding({ top: 8, bottom: 16 })
    } else if (this.vm.viewMode === ViewMode.TIMELINE) {
      // 时间轴视图 — List 按年月分组
      List() {
        ForEach(this.vm.timelineSections, (section: TimelineSection) => {
          ListItemGroup({ header: this.sectionHeader(section.yearMonth) }) {
            ForEach(section.items, (item: DayItem) => {
              ListItem() {
                DayTimelineCard({
                  item: item,
                  onDelete: (id: number) => { this.vm.deleteDay(id) }
                })
                .padding({ left: 16, right: 16 })
              }
            }, (item: DayItem) => item.id.toString())
          }
        }, (s: TimelineSection) => s.yearMonth)
      }
      .layoutWeight(1)
      .padding({ top: 8, bottom: 16 })
    } else {
      // 相册视图 — Grid
      Scroll() {
        DayAlbumSection({ items: this.vm.days })
      }
      .layoutWeight(1)
    }
  }

  @Builder
  sectionHeader(yearMonth: string) {
    Text(yearMonth)
      .fontSize(13)
      .fontColor('#757575')
      .fontWeight(FontWeight.Medium)
      .padding({ left: 16, top: 8, bottom: 4 })
      .width('100%')
      .backgroundColor('#F5F5F5')
  }

  private viewModeIcon(): Resource {
    switch (this.vm.viewMode) {
      case ViewMode.CARD:     return $r('app.media.ic_view_card')
      case ViewMode.TIMELINE: return $r('app.media.ic_view_timeline')
      case ViewMode.ALBUM:    return $r('app.media.ic_view_album')
      default:                return $r('app.media.ic_view_card')
    }
  }
}
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/pages/DayPagerPage.ets
git commit -m "feat(day): add DayPagerPage with card/timeline/album 3-view switching"
```

---

## Task 13: 路由注册

**Files:**
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`（注册 AppStorage 中的 dayRdb 实例）
- Modify: `entry/src/main/module.json5`（注册 DayPage、DayPagerPage 路由）

- [ ] **Step 1: 在 module.json5 注册页面路由**

在 `pages` 数组中添加（若已有 `MainPage`，在其后追加）：

```json5
// entry/src/main/module.json5
// 在 "pages" 数组中添加：
"pages/DayPage",
"pages/DayPagerPage"
```

完整示例（仅展示 pages 数组部分）：

```json5
{
  "module": {
    "pages": "$profile:main_pages"
  }
}
```

在 `entry/src/main/resources/base/profile/main_pages.json` 中：

```json
{
  "src": [
    "pages/Index",
    "pages/MainPage",
    "pages/DayPage",
    "pages/DayPagerPage"
  ]
}
```

- [ ] **Step 2: 在 EntryAbility.ets 中初始化 dayRdb**

在 `onCreate` 中创建 RDB 并存入 AppStorage（与 scheduleRdb 同级）：

```typescript
// entry/src/main/ets/entryability/EntryAbility.ets
// 在现有 rdb 初始化代码块后追加：
import { DayDao } from '../data/dao/DayDao'
import relationalStore from '@ohos.data.relationalStore'

// 在 onCreate 或 onWindowStageCreate 中：
const DAY_DB_CONFIG: relationalStore.StoreConfig = {
  name: 'DiaryApp.db',   // 与其他模块共享同一个 DB 文件
  securityLevel: relationalStore.SecurityLevel.S1
}

relationalStore.getRdbStore(this.context, DAY_DB_CONFIG).then(async (rdb) => {
  const dayDao = new DayDao(rdb)
  await dayDao.createTable()
  AppStorage.setOrCreate('dayRdb', rdb)
})
```

- [ ] **Step 3: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 4: 安装到真机/模拟器，手动验证**

```
验证清单：
□ DayPagerPage 可访问，显示空状态或已有日子列表
□ 点击 + 跳转新建页（DayEditPage — 下阶段实现，此处可暂时 404）
□ 已有数据时：卡片视图正常展示 DayCard
□ 点击右上角视图切换按钮，依次切换 卡片 → 时间轴 → 相册 → 卡片
□ 时间轴视图左滑 DayTimelineCard，超过阈值触发删除
□ 点击任意 DayCard 或 DayTimelineCard 跳转 DayPage
□ DayPage 正确显示日子标题、已过天数、作者、位置、富文本内容
□ DayPage 点击删除图标，弹出确认对话框，确认后返回列表
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/resources/base/profile/main_pages.json \
        entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "feat(day): register DayPage and DayPagerPage routes, init dayRdb"
```

---

## 自审检查

### Spec 覆盖
| Android 功能 | HarmonyOS 对应 | 任务 |
|---|---|---|
| DayItem.kt Room entity | DayItem.ts | Task 1 |
| DayDao.kt Room DAO | DayDao.ets Relational DB | Task 2 |
| DiaryRepository.kt 模式 | DayRepository.ets | Task 3 |
| DayViewActivity 天数计算 | DayTimeUtils.ets | Task 4 |
| DiaryViewModel.kt 模式 | DayViewModel.ets | Task 5 |
| DayTimelineAdapter Header/Card 分组 | DayTimelineModels.ets | Task 6 |
| DayCardAdapter 卡片视图 | DayCard.ets | Task 7 |
| DayTimelineAdapter 时间轴 + 滑动删除 | DayTimelineCard.ets + PanGesture | Task 8 |
| DayPagerFragment 相册模式 | DayAlbumSection.ets | Task 9 |
| DayPagerFragment viewMode 枚举 | DayPagerViewModel.ets ViewMode | Task 10 |
| DayViewActivity.kt 详情页 | DayPage.ets | Task 11 |
| DayPagerFragment 三视图主页 | DayPagerPage.ets | Task 12 |
| AndroidManifest Activity 注册 | module.json5 + main_pages.json | Task 13 |

### 类型一致性
- `DayItem.id: number` — Task 1 定义，Task 2/3/5/10 全部使用 ✓
- `DayRepository.getDays(userId)` — Task 3 定义，Task 5/10 调用 ✓
- `DayPagerViewModel.cycleViewMode()` — Task 10 定义，Task 12 调用 ✓
- `buildTimelineGroups(items)` — Task 6 定义，Task 10 调用 ✓
- `formatDaysDiff(startAt)` — Task 4 定义，Task 7/8/11 调用 ✓
- `DayCard({ item })` — Task 7 定义，Task 12 使用 `@ObjectLink item` ✓
- `DayTimelineCard({ item, onDelete })` — Task 8 定义，Task 12 传入 `onDelete` ✓
