# Day 5-7：日记管理模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 完整实现日记管理模块，包括日记列表（DiaryPagerPage）、日记编辑（DiaryEditPage）、日记查看（DiaryViewPage）、收藏（FavoritesPage）、草稿箱（DraftsPage）、回收站（RecycleBinPage），对标 Android `DiaryEditActivity`、`DiaryViewActivity`、`DiaryPagerFragment`、`FavoritesActivity`、`DraftsActivity`、`RecycleBinActivity` 的所有功能。

**Architecture:** MVVM + Repository 模式，`@State` + `@Link` 驱动 UI 状态，`DiaryRepository` 封装本地 Relational DB 操作，日记数据模型使用 ArkTS `PersistentStorage` 持久化（对标 Room）。

**Tech Stack:** ArkTS 4.x, ArkUI Relational DB, @ohos.net.http, @ohos.router, @ohos.promptAction

---

## 文件结构

```
entry/src/main/ets/
├── model/
│   ├── DiaryModel.ets              # 日记数据模型（对标 Diary.kt）
│   └── DraftDiaryModel.ets         # 草稿数据模型（对标 DraftDiary.kt）
│
├── repository/
│   └── DiaryRepository.ets         # 日记数据仓库（CRUD + 搜索）
│
├── viewmodel/
│   ├── DiaryViewModel.ets           # 日记列表 ViewModel
│   └── DiaryEditViewModel.ets       # 日记编辑 ViewModel
│
├── components/
│   ├── DiaryCard.ets                # 日记卡片组件（列表项）
│   ├── WeatherPicker.ets           # 天气选择器
│   └── MoodPicker.ets               # 心情选择器
│
└── pages/
    └── diary/
        ├── DiaryPagerPage.ets       # 日记列表主容器（全部/图片/视频筛选）
        ├── DiaryEditPage.ets         # 日记编辑页面
        ├── DiaryViewPage.ets         # 日记查看页面
        ├── FavoritesPage.ets         # 收藏列表页
        ├── DraftsPage.ets            # 草稿箱页
        └── RecycleBinPage.ets        # 回收站页
```

> **依赖关系：** Task 1-4 先完成（Model + Repository + ViewModel），后续 Task 可并行。

---

## Task 1：日记数据模型

**Files:**
- Create: `entry/src/main/ets/model/DiaryModel.ets`
- Create: `entry/src/main/ets/model/DraftDiaryModel.ets`

对标 Android `Diary.kt`（Room Entity）和 `DraftDiary.kt`。

- [ ] **Step 1: 创建 DiaryModel**

文件路径：`entry/src/main/ets/model/DiaryModel.ets`

```typescript
/**
 * 日记数据模型
 * 对标 Android Diary.kt (Room Entity)
 */
export interface Diary {
  id: number
  userId: string
  author: string | null
  title: string
  content: string       // 支持富文本 HTML
  mood: string          // 心情标签（happy, sad, neutral, angry, worried, excited）
  weather: string       // 天气标签（sunny, cloudy, rainy, snowy, windy, foggy）
  location: string | null
  date: number          // 时间戳（毫秒）
  createdAt: number     // 创建时间戳
  synced: boolean       // 是否已同步到服务端
  isFavorite: boolean   // 是否收藏
  isVaulted: boolean    // 是否移入保险箱
  isTrashed: boolean    // 是否在回收站
  trashedAt: number | null
  previewContentPriority: string  // "text" | "image" | "video"
}

export function createEmptyDiary(dateMillis?: number): Diary {
  const now = Date.now()
  return {
    id: 0,
    userId: '',
    author: null,
    title: '',
    content: '',
    mood: 'neutral',
    weather: 'sunny',
    location: null,
    date: dateMillis ?? now,
    createdAt: now,
    synced: false,
    isFavorite: false,
    isVaulted: false,
    isTrashed: false,
    trashedAt: null,
    previewContentPriority: 'text'
  }
}

/**
 * 系统日记内容判断（不可删除/移动/收藏）
 * 对标 Android SystemDiary.isSystemDiaryContent()
 */
export function isSystemDiaryContent(content: string): boolean {
  if (!content) return false
  return content.startsWith('<!-- SYSTEM_DIARY:welcome -->')
}
```

- [ ] **Step 2: 创建 DraftDiaryModel**

文件路径：`entry/src/main/ets/model/DraftDiaryModel.ets`

```typescript
/**
 * 草稿日记数据模型
 * 对标 Android DraftDiary.kt (Room Entity)
 */
export interface DraftDiary {
  id: number
  userId: string
  title: string
  content: string
  mood: string
  weather: string
  date: number
  createdAt: number
  updatedAt: number
}

export function createEmptyDraft(dateMillis?: number): DraftDiary {
  const now = Date.now()
  return {
    id: 0,
    userId: '',
    title: '',
    content: '',
    mood: 'neutral',
    weather: 'sunny',
    date: dateMillis ?? now,
    createdAt: now,
    updatedAt: now
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/model/DiaryModel.ets \
        entry/src/main/ets/model/DraftDiaryModel.ets
git commit -m "feat: add Diary and DraftDiary data models"
```

---

## Task 2：DiaryRepository（日记数据仓库）

**Files:**
- Create: `entry/src/main/ets/repository/DiaryRepository.ets`

对标 Android `DiaryRepository`，封装本地 Relational DB CRUD + 搜索 + 收藏/草稿/回收站逻辑。

- [ ] **Step 1: 创建 DiaryRepository**

文件路径：`entry/src/main/ets/repository/DiaryRepository.ets`

```typescript
import { Diary } from '../model/DiaryModel'
import { DraftDiary } from '../model/DraftDiaryModel'
import { RelationalStore } from '@ohos.data.relationalStore'
import { Logger } from '../utils/Logger'

const STORE_NAME = 'diary.db'

/**
 * 日记数据仓库
 * 对标 Android DiaryRepository (Room DAO + Repository)
 * 使用 HarmonyOS Relational DB 存储日记数据
 */
export class DiaryRepository {
  private store: RelationalStore | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<RelationalStore> {
    if (this.store) return this.store
    const config = {
      name: STORE_NAME,
      securityLevel: RelationalStore.SecurityLevel.S1
    }
    this.store = await relationalStore.getRdbStore(this.context, config)
    await this.initTables()
    return this.store
  }

  private async initTables(): Promise<void> {
    const store = this.store!
    // 创建 diaries 表（对标 Room @Entity Diary）
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT '',
        author TEXT,
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        mood TEXT NOT NULL DEFAULT 'neutral',
        weather TEXT NOT NULL DEFAULT 'sunny',
        location TEXT,
        date INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0,
        isFavorite INTEGER NOT NULL DEFAULT 0,
        isVaulted INTEGER NOT NULL DEFAULT 0,
        isTrashed INTEGER NOT NULL DEFAULT 0,
        trashedAt INTEGER,
        previewContentPriority TEXT NOT NULL DEFAULT 'text'
      )
    `)
    // 创建 draft_diaries 表（对标 Room @Entity DraftDiary）
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS draft_diaries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL DEFAULT '',
        title TEXT NOT NULL DEFAULT '',
        content TEXT NOT NULL DEFAULT '',
        mood TEXT NOT NULL DEFAULT 'neutral',
        weather TEXT NOT NULL DEFAULT 'sunny',
        date INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    `)
  }

  // ————————————————
  // 日记 CRUD
  // ————————————————

  async insert(diary: Diary): Promise<number> {
    const store = await this.getStore()
    const bucket = {
      userId: diary.userId,
      author: diary.author,
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      createdAt: diary.createdAt,
      synced: diary.synced ? 1 : 0,
      isFavorite: diary.isFavorite ? 1 : 0,
      isVaulted: diary.isVaulted ? 1 : 0,
      isTrashed: diary.isTrashed ? 1 : 0,
      trashedAt: diary.trashedAt,
      previewContentPriority: diary.previewContentPriority
    }
    const result = await store.insert('diaries', bucket)
    Logger.info('DiaryRepository', `inserted diary id=${result}`)
    return result
  }

  async update(diary: Diary): Promise<void> {
    const store = await this.getStore()
    const bucket = {
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      isFavorite: diary.isFavorite ? 1 : 0,
      isVaulted: diary.isVaulted ? 1 : 0,
      isTrashed: diary.isTrashed ? 1 : 0,
      trashedAt: diary.trashedAt,
      previewContentPriority: diary.previewContentPriority
    }
    const predicates = new RelationalStore.RdbPredicates('diaries')
    await store.update('diaries', bucket, predicates.equalTo('id', diary.id))
  }

  async delete(diary: Diary): Promise<void> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
    await store.delete(predicates.equalTo('id', diary.id))
  }

  async findById(id: number): Promise<Diary | null> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
    const result = await store.query(predicates.equalTo('id', id))
    return this.rowToDiary(result)
  }

  async allDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async searchDiaries(query: string): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .beginLike()
      .equalTo('title', `%${query}%`)
      .or()
      .equalTo('content', `%${query}%`)
      .endLike()
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  // ————————————————
  // 收藏相关
  // ————————————————

  async favoriteDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
      .equalTo('isFavorite', 1)
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async toggleFavorite(diary: Diary): Promise<void> {
    await this.update({ ...diary, isFavorite: !diary.isFavorite })
  }

  // ————————————————
  // 回收站相关
  // ————————————————

  async trashedDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 1)
      .orderByDesc('trashedAt')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async moveToTrash(diary: Diary): Promise<void> {
    await this.update({ ...diary, isTrashed: true, trashedAt: Date.now() })
  }

  async restoreFromTrash(diary: Diary): Promise<void> {
    await this.update({ ...diary, isTrashed: false, trashedAt: null })
  }

  // ————————————————
  // 保险箱相关
  // ————————————————

  async moveToVault(diary: Diary): Promise<void> {
    await this.update({ ...diary, isVaulted: true })
  }

  async vaultedDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('diaries')
      .equalTo('isVaulted', 1)
      .equalTo('isTrashed', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  // ————————————————
  // 草稿箱相关
  // ————————————————

  async allDrafts(): Promise<DraftDiary[]> {
    const store = await this.getStore()
    const predicates = new RelationalStore.RdbPredicates('draft_diaries')
      .orderByDesc('updatedAt')
    const result = await store.query(predicates)
    return this.rowsToDrafts(result)
  }

  async saveDraft(draft: DraftDiary): Promise<number> {
    const store = await this.getStore()
    const bucket = {
      userId: draft.userId,
      title: draft.title,
      content: draft.content,
      mood: draft.mood,
      weather: draft.weather,
      date: draft.date,
      createdAt: draft.createdAt,
      updatedAt: Date.now()
    }
    if (draft.id > 0) {
      await store.update('draft_diaries', bucket,
        new RelationalStore.RdbPredicates('draft_diaries').equalTo('id', draft.id))
      return draft.id
    } else {
      return await store.insert('draft_diaries', bucket)
    }
  }

  async deleteDraft(draftId: number): Promise<void> {
    const store = await this.getStore()
    await store.delete(
      new RelationalStore.RdbPredicates('draft_diaries').equalTo('id', draftId)
    )
  }

  // ————————————————
  // 私有辅助方法
  // ————————————————

  private rowToDiary(result: RelationalStore.ResultSet): Diary | null {
    if (!result.goToFirstRow()) return null
    return {
      id: result.getLong(result.getColumnIndex('id')),
      userId: result.getString(result.getColumnIndex('userId')),
      author: result.getString(result.getColumnIndex('author')),
      title: result.getString(result.getColumnIndex('title')),
      content: result.getString(result.getColumnIndex('content')),
      mood: result.getString(result.getColumnIndex('mood')),
      weather: result.getString(result.getColumnIndex('weather')),
      location: result.getString(result.getColumnIndex('location')),
      date: result.getLong(result.getColumnIndex('date')),
      createdAt: result.getLong(result.getColumnIndex('createdAt')),
      synced: result.getLong(result.getColumnIndex('synced')) === 1,
      isFavorite: result.getLong(result.getColumnIndex('isFavorite')) === 1,
      isVaulted: result.getLong(result.getColumnIndex('isVaulted')) === 1,
      isTrashed: result.getLong(result.getColumnIndex('isTrashed')) === 1,
      trashedAt: result.getColumnIndex('trashedAt') >= 0
        ? result.getLong(result.getColumnIndex('trashedAt'))
        : null,
      previewContentPriority: result.getString(result.getColumnIndex('previewContentPriority'))
    }
  }

  private rowsToDiaries(result: RelationalStore.ResultSet): Diary[] {
    const diaries: Diary[] = []
    while (result.goToNextRow()) {
      const d = this.rowToDiary(result)
      if (d) diaries.push(d)
    }
    result.close()
    return diaries
  }

  private rowsToDrafts(result: RelationalStore.ResultSet): DraftDiary[] {
    const drafts: DraftDiary[] = []
    while (result.goToNextRow()) {
      drafts.push({
        id: result.getLong(result.getColumnIndex('id')),
        userId: result.getString(result.getColumnIndex('userId')),
        title: result.getString(result.getColumnIndex('title')),
        content: result.getString(result.getColumnIndex('content')),
        mood: result.getString(result.getColumnIndex('mood')),
        weather: result.getString(result.getColumnIndex('weather')),
        date: result.getLong(result.getColumnIndex('date')),
        createdAt: result.getLong(result.getColumnIndex('createdAt')),
        updatedAt: result.getLong(result.getColumnIndex('updatedAt'))
      })
    }
    result.close()
    return drafts
  }
}
```

- [ ] **Step 2: 写单元测试**

文件路径：`entry/src/test/ets/model/DiaryModelTest.ets`

```typescript
import { describe, it, expect } from '@ohos/hypium'
import { createEmptyDiary, isSystemDiaryContent } from '../../main/ets/model/DiaryModel'
import { createEmptyDraft } from '../../main/ets/model/DraftDiaryModel'

export default function DiaryModelTest() {
  describe('DiaryModelTest', () => {
    it('createEmptyDiary returns diary with default values', 0, () => {
      const diary = createEmptyDiary()
      expect(diary.title).assertEqual('')
      expect(diary.content).assertEqual('')
      expect(diary.mood).assertEqual('neutral')
      expect(diary.weather).assertEqual('sunny')
      expect(diary.isFavorite).assertFalse()
      expect(diary.isTrashed).assertFalse()
      expect(diary.isVaulted).assertFalse()
    })

    it('createEmptyDiary uses provided dateMillis', 0, () => {
      const now = Date.now()
      const diary = createEmptyDiary(now)
      expect(diary.date).assertEqual(now)
    })

    it('isSystemDiaryContent returns true for welcome diary', 0, () => {
      const result = isSystemDiaryContent('<!-- SYSTEM_DIARY:welcome -->Hello')
      expect(result).assertTrue()
    })

    it('isSystemDiaryContent returns false for normal content', 0, () => {
      expect(isSystemDiaryContent('今天天气很好')).assertFalse()
      expect(isSystemDiaryContent('')).assertFalse()
      expect(isSystemDiaryContent(null as unknown as string)).assertFalse()
    })

    it('createEmptyDraft returns draft with correct defaults', 0, () => {
      const draft = createEmptyDraft()
      expect(draft.title).assertEqual('')
      expect(draft.content).assertEqual('')
      expect(draft.mood).assertEqual('neutral')
      expect(draft.weather).assertEqual('sunny')
    })
  })
}
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/repository/DiaryRepository.ets \
        entry/src/test/ets/model/DiaryModelTest.ets
git commit -m "feat: add DiaryRepository with full CRUD and favorites/trash/drafts support"
```

---

## Task 3：DiaryViewModel（日记列表）

**Files:**
- Create: `entry/src/main/ets/viewmodel/DiaryViewModel.ets`
- Create: `entry/src/test/ets/viewmodel/DiaryViewModelTest.ets`

对标 Android `DiaryViewModel`，管理日记列表状态（搜索、收藏筛选）、跳转请求。

- [ ] **Step 1: 创建 DiaryViewModel**

文件路径：`entry/src/main/ets/viewmodel/DiaryViewModel.ets`

```typescript
import { Diary, isSystemDiaryContent } from '../model/DiaryModel'
import { DiaryRepository } from '../repository/DiaryRepository'
import { Logger } from '../utils/Logger'

/**
 * 日记列表 ViewModel
 * 对标 Android DiaryViewModel
 */
export class DiaryViewModel {
  diaries: Diary[] = []
  favoriteDiaries: Diary[] = []
  searchQuery: string = ''
  jumpToDateMillis: number | null = null
  isLoading: boolean = false

  private repository: DiaryRepository
  private context: Context

  constructor(context: Context, repository?: DiaryRepository) {
    this.context = context
    this.repository = repository ?? new DiaryRepository(context)
  }

  async loadAll(): Promise<void> {
    this.isLoading = true
    try {
      this.diaries = await this.repository.allDiaries()
    } catch (err) {
      Logger.error('DiaryViewModel', 'loadAll failed: ' + JSON.stringify(err))
    } finally {
      this.isLoading = false
    }
  }

  async loadFavorites(): Promise<void> {
    try {
      this.favoriteDiaries = await this.repository.favoriteDiaries()
    } catch (err) {
      Logger.error('DiaryViewModel', 'loadFavorites failed: ' + JSON.stringify(err))
    }
  }

  setSearchQuery(query: string): void {
    this.searchQuery = query
    if (query.isEmpty()) {
      this.loadAll()
    } else {
      this.search(query)
    }
  }

  private async search(query: string): Promise<void> {
    try {
      this.diaries = await this.repository.searchDiaries(query)
    } catch (err) {
      Logger.error('DiaryViewModel', 'search failed: ' + JSON.stringify(err))
    }
  }

  requestJumpToDate(millis: number): void {
    this.jumpToDateMillis = millis
  }

  clearJumpToDate(): void {
    this.jumpToDateMillis = null
  }

  async deleteDiary(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.delete(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'deleteDiary failed: ' + JSON.stringify(err))
    }
  }

  async toggleFavorite(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.toggleFavorite(diary)
      const updated = await this.repository.findById(diary.id)
      if (updated) {
        this.diaries = this.diaries.map(d => d.id === diary.id ? updated : d)
      }
    } catch (err) {
      Logger.error('DiaryViewModel', 'toggleFavorite failed: ' + JSON.stringify(err))
    }
  }

  async moveToVault(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.moveToVault(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'moveToVault failed: ' + JSON.stringify(err))
    }
  }

  async moveToTrash(diary: Diary): Promise<void> {
    if (isSystemDiaryContent(diary.content)) return
    try {
      await this.repository.moveToTrash(diary)
      this.diaries = this.diaries.filter(d => d.id !== diary.id)
    } catch (err) {
      Logger.error('DiaryViewModel', 'moveToTrash failed: ' + JSON.stringify(err))
    }
  }
}
```

- [ ] **Step 2: 写 DiaryViewModel 测试**

文件路径：`entry/src/test/ets/viewmodel/DiaryViewModelTest.ets`

```typescript
import { describe, it, expect } from '@ohos/hypium'
import { DiaryViewModel } from '../../main/ets/viewmodel/DiaryViewModel'
import { createEmptyDiary } from '../../main/ets/model/DiaryModel'

export default function DiaryViewModelTest() {
  describe('DiaryViewModelTest', () => {
    it('initial state has empty diaries', 0, () => {
      // Note: requires full device/emulator context, test skeleton shown
    })

    it('requestJumpToDate stores the date', 0, () => {
      const vm = new DiaryViewModel(globalThis.globalContext as Context)
      const now = Date.now()
      vm.requestJumpToDate(now)
      expect(vm.jumpToDateMillis).assertEqual(now)
    })

    it('clearJumpToDate sets to null', 0, () => {
      const vm = new DiaryViewModel(globalThis.globalContext as Context)
      vm.requestJumpToDate(Date.now())
      vm.clearJumpToDate()
      expect(vm.jumpToDateMillis).assertNull()
    })

    it('setSearchQuery updates searchQuery field', 0, () => {
      const vm = new DiaryViewModel(globalThis.globalContext as Context)
      vm.setSearchQuery('test')
      expect(vm.searchQuery).assertEqual('test')
    })
  })
}
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/viewmodel/DiaryViewModel.ets \
        entry/src/test/ets/viewmodel/DiaryViewModelTest.ets
git commit -m "feat: add DiaryViewModel for list management with search and favorites"
```

---

## Task 4：DiaryCard 组件（列表项）

**Files:**
- Create: `entry/src/main/ets/components/DiaryCard.ets`

对标 Android `DiaryTimelineAdapter` / `DiaryGridAdapter` 的列表项，显示标题、摘要、时间、天气、心情、收藏状态。

- [ ] **Step 1: 创建 DiaryCard 组件**

文件路径：`entry/src/main/ets/components/DiaryCard.ets`

```typescript
@Component
export struct DiaryCard {
  @ObjectLink diaryWrapper: DiaryWrapper
  onClick: () => void = () => {}
  onFavoriteClick: () => void = () => {}
  onLongPress: () => void = () => {}

  private formatDate(millis: number): string {
    const d = new Date(millis)
    const month = String(d.getMonth() + 1).padStart(2, '0')
    const day = String(d.getDate()).padStart(2, '0')
    return `${d.getFullYear()}-${month}-${day}`
  }

  private getPreviewText(): string {
    const content = this.diaryWrapper.diary.content
    const plain = content.replace(/<[^>]*>/g, '').trim()
    return plain.length > 80 ? plain.substring(0, 80) + '...' : plain
  }

  build() {
    Column() {
      // 顶部行：日期 + 天气 + 心情
      Row() {
        Text(this.formatDate(this.diaryWrapper.diary.date))
          .fontSize(12)
          .fontColor('#999999')
        Blank()
        Row({ space: 8 }) {
          Text(this.getWeatherLabel(this.diaryWrapper.diary.weather))
            .fontSize(11)
            .fontColor('#888888')
          Text(' ')
          Text(this.getMoodLabel(this.diaryWrapper.diary.mood))
            .fontSize(11)
            .fontColor('#888888')
        }
      }
      .width('100%')

      // 标题
      Text(this.diaryWrapper.diary.title || '(无标题)')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor('#222222')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ top: 8 })

      // 内容摘要
      if (this.getPreviewText()) {
        Text(this.getPreviewText())
          .fontSize(13)
          .fontColor('#666666')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
      }

      // 收藏按钮
      Row() {
        Blank()
        Text(this.diaryWrapper.diary.isFavorite ? '♥' : '♡')
          .fontSize(18)
          .fontColor(this.diaryWrapper.diary.isFavorite ? '#FF5722' : '#BBBBBB')
          .onClick(() => this.onFavoriteClick())
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .shadow({ radius: 6, color: '#15000000', offsetX: 0, offsetY: 2 })
    .onClick(() => this.onClick())
    .onLongPress(() => this.onLongPress())
  }

  private getWeatherLabel(w: string): string {
    const map: Record<string, string> = {
      sunny: '☀️', cloudy: '⛅', rainy: '🌧️', snowy: '❄️', windy: '💨', foggy: '🌫️'
    }
    return map[w] ?? '☀️'
  }

  private getMoodLabel(m: string): string {
    const map: Record<string, string> = {
      happy: '😊', neutral: '😐', sad: '😢', angry: '😠', worried: '😰', excited: '🤩'
    }
    return map[m] ?? '😐'
  }
}

/**
 * DiaryWrapper — 包装 Diary 供 @ObjectLink 使用
 * HarmonyOS @ObjectLink 要求 @Observed class
 */
@Observed
export class DiaryWrapper {
  diary: Diary

  constructor(diary: Diary) {
    this.diary = diary
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/components/DiaryCard.ets
git commit -m "feat: add DiaryCard component with weather/mood/date preview"
```

---

## Task 5：WeatherPicker + MoodPicker 组件

**Files:**
- Create: `entry/src/main/ets/components/WeatherPicker.ets`
- Create: `entry/src/main/ets/components/MoodPicker.ets`

对标 Android `DiaryEditActivity` 中的天气选择和心情选择 UI（圆形图标网格）。

- [ ] **Step 1: 创建 WeatherPicker**

文件路径：`entry/src/main/ets/components/WeatherPicker.ets`

```typescript
@Component
export struct WeatherPicker {
  @Prop selected: string = 'sunny'
  onSelected: (weather: string) => void = () => {}

  private weathers = [
    { id: 'sunny',  label: '晴' },
    { id: 'cloudy', label: '多云' },
    { id: 'rainy',  label: '雨' },
    { id: 'snowy',  label: '雪' },
    { id: 'windy',  label: '风' },
    { id: 'foggy',  label: '雾' },
  ]

  build() {
    Column({ space: 8 }) {
      Text('天气')
        .fontSize(13)
        .fontColor('#888888')

      Row({ space: 12 }) {
        ForEach(this.weathers, (w: { id: string; label: string }) => {
          Column({ space: 4 }) {
            Stack() {
              Circle({ width: 40, height: 40 })
                .fill(this.selected === w.id ? '#E0F7FA' : '#F5F5F5')
              Circle({ width: 40, height: 40 })
                .stroke(this.selected === w.id ? '#00BCD4' : 'transparent')
                .strokeWidth(2)
              Text(this.getWeatherEmoji(w.id))
                .fontSize(20)
            }
            .onClick(() => {
              this.selected = w.id
              this.onSelected(w.id)
            })

            Text(w.label)
              .fontSize(10)
              .fontColor(this.selected === w.id ? '#00BCD4' : '#999999')
          }
        })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private getWeatherEmoji(id: string): string {
    const map: Record<string, string> = {
      sunny: '☀️', cloudy: '⛅', rainy: '🌧️', snowy: '❄️', windy: '💨', foggy: '🌫️'
    }
    return map[id] ?? '☀️'
  }
}
```

- [ ] **Step 2: 创建 MoodPicker**

文件路径：`entry/src/main/ets/components/MoodPicker.ets`

```typescript
@Component
export struct MoodPicker {
  @Prop selected: string = 'neutral'
  onSelected: (mood: string) => void = () => {}

  private moods = [
    { id: 'happy',   label: '开心' },
    { id: 'neutral', label: '平静' },
    { id: 'sad',     label: '难过' },
    { id: 'angry',   label: '生气' },
    { id: 'worried', label: '担心' },
    { id: 'excited', label: '兴奋' },
  ]

  build() {
    Column({ space: 8 }) {
      Text('心情')
        .fontSize(13)
        .fontColor('#888888')

      Row({ space: 12 }) {
        ForEach(this.moods, (m: { id: string; label: string }) => {
          Column({ space: 4 }) {
            Stack() {
              Circle({ width: 40, height: 40 })
                .fill(this.selected === m.id ? '#FFF3E0' : '#F5F5F5')
              Circle({ width: 40, height: 40 })
                .stroke(this.selected === m.id ? '#FF9800' : 'transparent')
                .strokeWidth(2)
              Text(this.getMoodEmoji(m.id))
                .fontSize(20)
            }
            .onClick(() => {
              this.selected = m.id
              this.onSelected(m.id)
            })

            Text(m.label)
              .fontSize(10)
              .fontColor(this.selected === m.id ? '#FF9800' : '#999999')
          }
        })
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
  }

  private getMoodEmoji(id: string): string {
    const map: Record<string, string> = {
      happy: '😊', neutral: '😐', sad: '😢', angry: '😠', worried: '😰', excited: '🤩'
    }
    return map[id] ?? '😐'
  }
}
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/components/WeatherPicker.ets \
        entry/src/main/ets/components/MoodPicker.ets
git commit -m "feat: add WeatherPicker and MoodPicker components"
```

---

## Task 6：DiaryPagerPage（日记列表主容器）

**Files:**
- Modify: `entry/src/main/ets/pages/diary/DiaryPagerPage.ets`

对标 Android `DiaryPagerFragment`，支持「全部/图片/视频」Tab 筛选，下拉刷新，搜索适配，空状态显示。

- [ ] **Step 1: 创建完整 DiaryPagerPage**

文件路径：`entry/src/main/ets/pages/diary/DiaryPagerPage.ets`

```typescript
import router from '@ohos.router'
import { DiaryViewModel } from '../../viewmodel/DiaryViewModel'
import { DiaryCard, DiaryWrapper } from '../../components/DiaryCard'
import promptAction from '@ohos.promptAction'
import { Logger } from '../../utils/Logger'

@Component
export struct DiaryPagerPage {
  @State diaries: DiaryWrapper[] = []
  @State currentFilter: 'all' | 'image' | 'video' = 'all'
  @State showEmpty: boolean = false
  @State searchQuery: string = ''

  private vm: DiaryViewModel | null = null

  aboutToAppear() {
    this.initViewModel()
  }

  private async initViewModel() {
    const context = getContext(this)
    this.vm = new DiaryViewModel(context)
    await this.vm.loadAll()
    this.diaries = this.vm.diaries.map(d => new DiaryWrapper(d))
    this.showEmpty = this.diaries.length === 0
  }

  private onSearchChanged(query: string) {
    this.searchQuery = query
    this.vm?.setSearchQuery(query)
    if (this.vm) {
      this.diaries = this.vm.diaries.map(d => new DiaryWrapper(d))
      this.showEmpty = this.diaries.length === 0
    }
  }

  private onDiaryClick(diary: Diary) {
    router.pushUrl({
      url: 'pages/diary/DiaryViewPage',
      params: { diaryId: diary.id }
    }).catch((err) => {
      Logger.error('DiaryPagerPage', 'navigate failed: ' + JSON.stringify(err))
    })
  }

  private onDiaryLongPress(diary: Diary) {
    const menuActions = [
      { text: diary.isFavorite ? '取消收藏' : '收藏', color: '#FF9800' },
      { text: '移至回收站', color: '#F44336' },
      { text: '移动到保险箱', color: '#2196F3' },
      { text: '取消', color: '#999999' }
    ]
    promptAction.showActionMenu({
      buttons: menuActions.map(a => ({ text: a.text, color: a.color }))
    }).then((result) => {
      const idx = result.index
      if (idx === 0) {
        this.vm?.toggleFavorite(diary)
        this.diaries = this.diaries.map(w => {
          if (w.diary.id === diary.id) {
            w.diary = { ...w.diary, isFavorite: !w.diary.isFavorite }
          }
          return w
        })
      } else if (idx === 1) {
        this.vm?.moveToTrash(diary)
        this.diaries = this.diaries.filter(w => w.diary.id !== diary.id)
        promptAction.showToast({ message: '已移至回收站' })
      } else if (idx === 2) {
        this.vm?.moveToVault(diary)
        this.diaries = this.diaries.filter(w => w.diary.id !== diary.id)
        promptAction.showToast({ message: '已移动到保险箱' })
      }
    }).catch(() => {})
  }

  private onFavoriteToggle(diary: Diary) {
    this.vm?.toggleFavorite(diary)
    this.diaries = this.diaries.map(w => {
      if (w.diary.id === diary.id) {
        w.diary = { ...w.diary, isFavorite: !w.diary.isFavorite }
      }
      return w
    })
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('📔')
        .fontSize(60)
        .opacity(0.3)
      Text('还没有日记')
        .fontSize(16)
        .fontColor('#999999')
      Text('点击底部「+」按钮创建第一篇日记')
        .fontSize(13)
        .fontColor('#BBBBBB')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      // 顶部筛选 Tab
      Row({ space: 16 }) {
        ForEach(['全部', '图片', '视频'] as Array<'全部' | '图片' | '视频'>, (label: string) => {
          Text(label)
            .fontSize(14)
            .fontColor(this.currentFilter === label ? '#00BCD4' : '#999999')
            .fontWeight(this.currentFilter === label ? FontWeight.Bold : FontWeight.Normal)
            .onClick(() => { this.currentFilter = label })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
      .backgroundColor('#FAFAFA')

      // 日记列表
      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.diaries, (item: DiaryWrapper) => {
            ListItem() {
              DiaryCard({
                diaryWrapper: item,
                onClick: () => this.onDiaryClick(item.diary),
                onLongPress: () => this.onDiaryLongPress(item.diary),
                onFavoriteClick: () => this.onFavoriteToggle(item.diary)
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .edgeEffect(EdgeEffect.Spring)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/pages/diary/DiaryPagerPage.ets
git commit -m "feat: implement DiaryPagerPage with filter tabs and empty state"
```

---

## Task 7：DiaryEditViewModel + DiaryEditPage（日记编辑）

**Files:**
- Create: `entry/src/main/ets/viewmodel/DiaryEditViewModel.ets`
- Modify: `entry/src/main/ets/pages/diary/DiaryEditPage.ets`
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

对标 Android `DiaryEditActivity`，包含标题编辑、富文本内容、天气心情选择、日期选择、图片添加、自动草稿保存。

- [ ] **Step 1: 创建 DiaryEditViewModel**

文件路径：`entry/src/main/ets/viewmodel/DiaryEditViewModel.ets`

```typescript
import { Diary, createEmptyDiary } from '../model/DiaryModel'
import { DraftDiary, createEmptyDraft } from '../model/DraftDiaryModel'
import { DiaryRepository } from '../repository/DiaryRepository'
import { Logger } from '../utils/Logger'

/**
 * 日记编辑 ViewModel
 * 对标 Android DiaryEditActivity 的编辑逻辑
 */
export class DiaryEditViewModel {
  diary: Diary
  draft: DraftDiary
  isDirty: boolean = false
  currentDraftId: number = 0
  images: string[] = []

  private repository: DiaryRepository
  private isNew: boolean = true
  private context: Context

  constructor(context: Context, diaryId?: number) {
    this.context = context
    this.repository = new DiaryRepository(context)
    this.diary = createEmptyDiary()
    this.draft = createEmptyDraft()
    if (diaryId && diaryId > 0) {
      this.loadDiary(diaryId)
    }
  }

  async loadDiary(id: number): Promise<void> {
    try {
      const loaded = await this.repository.findById(id)
      if (loaded) {
        this.diary = loaded
        this.isNew = false
        this.isDirty = false
      }
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'loadDiary failed: ' + JSON.stringify(err))
    }
  }

  updateTitle(title: string): void {
    this.diary.title = title
    this.draft.title = title
    this.isDirty = true
  }

  updateContent(content: string): void {
    this.diary.content = content
    this.draft.content = content
    this.isDirty = true
  }

  updateMood(mood: string): void {
    this.diary.mood = mood
    this.draft.mood = mood
    this.isDirty = true
  }

  updateWeather(weather: string): void {
    this.diary.weather = weather
    this.draft.weather = weather
    this.isDirty = true
  }

  updateDate(dateMillis: number): void {
    this.diary.date = dateMillis
    this.draft.date = dateMillis
    this.isDirty = true
  }

  addImage(uri: string): void {
    this.images.push(uri)
    this.isDirty = true
  }

  removeImage(index: number): void {
    this.images.splice(index, 1)
    this.isDirty = true
  }

  /** 自动保存草稿（每 30 秒） */
  async saveDraft(): Promise<void> {
    try {
      this.currentDraftId = await this.repository.saveDraft({
        ...this.draft,
        id: this.currentDraftId,
        updatedAt: Date.now()
      })
      this.isDirty = false
      Logger.info('DiaryEditViewModel', 'draft saved id=' + this.currentDraftId)
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'saveDraft failed: ' + JSON.stringify(err))
    }
  }

  /** 发布日记（保存到数据库） */
  async publish(): Promise<boolean> {
    if (!this.diary.title.trim() && !this.diary.content.trim()) {
      Logger.warn('DiaryEditViewModel', 'cannot publish empty diary')
      return false
    }
    try {
      if (this.isNew) {
        const id = await this.repository.insert(this.diary)
        this.diary.id = id
        this.isNew = false
      } else {
        await this.repository.update(this.diary)
      }
      if (this.currentDraftId > 0) {
        await this.repository.deleteDraft(this.currentDraftId)
        this.currentDraftId = 0
      }
      this.isDirty = false
      return true
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'publish failed: ' + JSON.stringify(err))
      return false
    }
  }

  async loadFromDraft(draftId: number): Promise<void> {
    try {
      const drafts = await this.repository.allDrafts()
      const draft = drafts.find(d => d.id === draftId)
      if (draft) {
        this.draft = draft
        this.currentDraftId = draftId
        this.diary.title = draft.title
        this.diary.content = draft.content
        this.diary.mood = draft.mood
        this.diary.weather = draft.weather
        this.diary.date = draft.date
        this.isNew = true
      }
    } catch (err) {
      Logger.error('DiaryEditViewModel', 'loadFromDraft failed: ' + JSON.stringify(err))
    }
  }
}
```

- [ ] **Step 2: 创建 DiaryEditPage**

文件路径：`entry/src/main/ets/pages/diary/DiaryEditPage.ets`

```typescript
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryEditViewModel } from '../../viewmodel/DiaryEditViewModel'
import { WeatherPicker } from '../../components/WeatherPicker'
import { MoodPicker } from '../../components/MoodPicker'
import { Logger } from '../../utils/Logger'

@Entry
@Component
struct DiaryEditPage {
  @State title: string = ''
  @State content: string = ''
  @State mood: string = 'neutral'
  @State weather: string = 'sunny'
  @State dateText: string = ''
  @State images: string[] = []
  @State isDirty: boolean = false

  private vm: DiaryEditViewModel | null = null
  private autoSaveTimer: number = -1

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    const diaryId = (params?.diaryId as number) ?? 0
    const draftId = (params?.draftId as number) ?? 0

    this.vm = new DiaryEditViewModel(getContext(this), diaryId)

    if (diaryId > 0) {
      this.vm.loadDiary(diaryId).then(() => {
        this.title = this.vm!.diary.title
        this.content = this.vm!.diary.content
        this.mood = this.vm!.diary.mood
        this.weather = this.vm!.diary.weather
        this.dateText = this.formatDate(this.vm!.diary.date)
      })
    } else if (draftId > 0) {
      this.vm.loadFromDraft(draftId).then(() => {
        this.title = this.vm!.diary.title
        this.content = this.vm!.diary.content
        this.mood = this.vm!.diary.mood
        this.weather = this.vm!.diary.weather
        this.dateText = this.formatDate(this.vm!.diary.date)
      })
    } else {
      this.dateText = this.formatDate(Date.now())
    }

    // 自动保存草稿（每 30 秒）
    this.autoSaveTimer = setInterval(() => {
      if (this.isDirty) {
        this.vm?.saveDraft()
      }
    }, 30000) as number
  }

  aboutToDisappear() {
    if (this.autoSaveTimer >= 0) {
      clearInterval(this.autoSaveTimer)
    }
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  private async handlePublish() {
    this.vm?.updateTitle(this.title)
    this.vm?.updateContent(this.content)
    this.vm?.updateMood(this.mood)
    this.vm?.updateWeather(this.weather)

    if (this.vm) {
      const success = await this.vm.publish()
      if (success) {
        promptAction.showToast({ message: '保存成功' })
        router.pop()
      } else {
        promptAction.showToast({ message: '标题或内容不能全为空' })
      }
    }
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('取消')
          .fontSize(16)
          .fontColor('#666666')
          .onClick(() => router.pop())

        Blank()

        Text('发布')
          .fontSize(16)
          .fontColor('#00BCD4')
          .fontWeight(FontWeight.Bold)
          .onClick(() => this.handlePublish())
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      // 滚动内容区
      Scroll() {
        Column({ space: 16 }) {
          // 日期行
          Row({ space: 8 }) {
            Text('📅')
              .fontSize(16)
            Text(this.dateText)
              .fontSize(15)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ top: 12 })

          // 标题输入
          TextInput({ placeholder: '标题（选填）', text: this.title })
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .placeholderColor('#BBBBBB')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .height(44)
            .padding({ left: 12, right: 12 })
            .onChange((val: string) => {
              this.title = val
              this.isDirty = true
            })

          // 内容输入（简化 TextArea，Day 6 替换为 RichTextEditor）
          TextArea({ placeholder: '写下今天的故事...', text: this.content })
            .fontSize(15)
            .placeholderColor('#BBBBBB')
            .backgroundColor('#FFFFFF')
            .borderRadius(8)
            .height(240)
            .padding(12)
            .onChange((val: string) => {
              this.content = val
              this.isDirty = true
            })

          // 图片预览（简化占位）
          if (this.images.length > 0) {
            Grid() {
              ForEach(this.images, (uri: string) => {
                GridItem() {
                  Image(uri)
                    .width('100%')
                    .height(100)
                    .objectFit(ImageFit.Cover)
                    .borderRadius(8)
                }
              })
            }
            .columnsTemplate('1fr 1fr 1fr')
            .columnsGap(8)
            .rowsGap(8)
            .width('100%')
            .height(Math.ceil(this.images.length / 3) * 108)
          }

          // 添加图片按钮
          Row() {
            Text('🖼️')
              .fontSize(16)
            Text('添加图片')
              .fontSize(14)
              .fontColor('#00BCD4')
              .margin({ left: 6 })
          }
          .width('100%')
          .height(44)
          .padding({ left: 12 })
          .backgroundColor('#F5F9FA')
          .borderRadius(8)
          .onClick(() => {
            promptAction.showToast({ message: '图片选择（Day 6 完善）' })
          })

          // 天气选择器
          WeatherPicker({
            selected: this.weather,
            onSelected: (w: string) => {
              this.weather = w
              this.isDirty = true
            }
          })

          // 心情选择器
          MoodPicker({
            selected: this.mood,
            onSelected: (m: string) => {
              this.mood = m
              this.isDirty = true
            }
          })
        }
        .padding({ left: 16, right: 16, bottom: 40 })
      }
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 3: 注册 DiaryEditPage 和 DiaryViewPage 路由**

修改 `entry/src/main/resources/base/profile/main_pages.json`，在 `src` 数组中添加：
```json
"pages/diary/DiaryEditPage",
"pages/diary/DiaryViewPage"
```

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/ets/viewmodel/DiaryEditViewModel.ets \
        entry/src/main/ets/pages/diary/DiaryEditPage.ets
git commit -m "feat: add DiaryEditPage and DiaryEditViewModel with weather/mood picker"
```

---

## Task 8：DiaryViewPage（日记查看页面）

**Files:**
- Modify: `entry/src/main/ets/pages/diary/DiaryViewPage.ets`
- Modify: `main_pages.json`

对标 Android `DiaryViewActivity`，显示日记完整内容，支持编辑/删除/收藏操作菜单。

- [ ] **Step 1: 创建 DiaryViewPage**

文件路径：`entry/src/main/ets/pages/diary/DiaryViewPage.ets`

```typescript
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { Diary } from '../../model/DiaryModel'
import { Logger } from '../../utils/Logger'

@Entry
@Component
struct DiaryViewPage {
  @State diary: Diary | null = null
  @State isLoading: boolean = true

  private diaryId: number = 0
  private repo: DiaryRepository | null = null

  async aboutToAppear() {
    const params = router.getParams() as Record<string, Object>
    this.diaryId = (params?.diaryId as number) ?? 0

    if (this.diaryId <= 0) {
      promptAction.showToast({ message: '日记不存在' })
      router.pop()
      return
    }

    this.repo = new DiaryRepository(getContext(this))
    this.diary = await this.repo.findById(this.diaryId)
    this.isLoading = false

    if (!this.diary) {
      promptAction.showToast({ message: '日记不存在' })
      router.pop()
    }
  }

  private formatFullDate(millis: number): string {
    const d = new Date(millis)
    const weekday = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'][d.getDay()]
    return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日 ${weekday}`
  }

  private showOptionsMenu() {
    const diary = this.diary
    if (!diary) return

    promptAction.showActionMenu({
      buttons: [
        { text: '编辑', color: '#2196F3' },
        { text: diary.isFavorite ? '取消收藏' : '收藏', color: '#FF9800' },
        { text: '移至回收站', color: '#F44336' },
        { text: '取消', color: '#999999' }
      ]
    }).then(async (result) => {
      if (!this.repo || !this.diary) return
      switch (result.index) {
        case 0: // 编辑
          router.pushUrl({
            url: 'pages/diary/DiaryEditPage',
            params: { diaryId: this.diaryId }
          }).catch(() => {})
          break
        case 1: // 收藏切换
          await this.repo.toggleFavorite(this.diary)
          this.diary = await this.repo.findById(this.diaryId)
          break
        case 2: // 移至回收站
          await this.repo.moveToTrash(this.diary)
          promptAction.showToast({ message: '已移至回收站' })
          router.pop()
          break
      }
    }).catch(() => {})
  }

  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => router.pop())
        Blank()
        Text('⋮')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => this.showOptionsMenu())
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.diary) {
        Scroll() {
          Column({ space: 16 }) {
            // 日期标题区
            Column({ space: 8 }) {
              Text(this.formatFullDate(this.diary.date))
                .fontSize(14)
                .fontColor('#888888')

              if (this.diary.title) {
                Text(this.diary.title)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#222222')
              }

              // 天气 + 心情标签
              Row({ space: 12 }) {
                Text(`${this.getWeatherEmoji(this.diary.weather)} ${this.getWeatherLabel(this.diary.weather)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                Text(`${this.getMoodEmoji(this.diary.mood)} ${this.getMoodLabel(this.diary.mood)}`)
                  .fontSize(12)
                  .fontColor('#666666')
                  .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                  .backgroundColor('#F0F0F0')
                  .borderRadius(12)

                if (this.diary.location) {
                  Text(`📍 ${this.diary.location}`)
                    .fontSize(12)
                    .fontColor('#666666')
                    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
                    .backgroundColor('#F0F0F0')
                    .borderRadius(12)
                }
              }
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .padding({ top: 20, left: 16, right: 16 })

            Divider().strokeWidth(0.5).color('#EEEEEE').margin({ left: 16, right: 16 })

            // 内容正文
            Text(this.diary.content)
              .fontSize(16)
              .fontColor('#333333')
              .lineHeight(26)
              .width('100%')
              .padding({ left: 16, right: 16, top: 12, bottom: 20 })
          }
        }
        .layoutWeight(1)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private getWeatherEmoji(w: string): string {
    const map: Record<string, string> = { sunny: '☀️', cloudy: '⛅', rainy: '🌧️', snowy: '❄️', windy: '💨', foggy: '🌫️' }
    return map[w] ?? '☀️'
  }

  private getWeatherLabel(w: string): string {
    const map: Record<string, string> = { sunny: '晴', cloudy: '多云', rainy: '雨', snowy: '雪', windy: '风', foggy: '雾' }
    return map[w] ?? '晴'
  }

  private getMoodEmoji(m: string): string {
    const map: Record<string, string> = { happy: '😊', neutral: '😐', sad: '😢', angry: '😠', worried: '😰', excited: '🤩' }
    return map[m] ?? '😐'
  }

  private getMoodLabel(m: string): string {
    const map: Record<string, string> = { happy: '开心', neutral: '平静', sad: '难过', angry: '生气', worried: '担心', excited: '兴奋' }
    return map[m] ?? '平静'
  }
}
```

- [ ] **Step 2: 提交**

```bash
git add entry/src/main/ets/pages/diary/DiaryViewPage.ets
git commit -m "feat: add DiaryViewPage for viewing diary detail with edit/delete/favorite"
```

---

## Task 9：FavoritesPage / DraftsPage / RecycleBinPage

**Files:**
- Create: `entry/src/main/ets/pages/diary/FavoritesPage.ets`
- Create: `entry/src/main/ets/pages/diary/DraftsPage.ets`
- Create: `entry/src/main/ets/pages/diary/RecycleBinPage.ets`
- Modify: `main_pages.json`

对标 Android `FavoritesActivity`、`DraftsActivity`、`RecycleBinActivity`，复用 `DiaryCard` 组件。

- [ ] **Step 1: 创建 FavoritesPage**

文件路径：`entry/src/main/ets/pages/diary/FavoritesPage.ets`

```typescript
import router from '@ohos.router'
import { DiaryViewModel } from '../../viewmodel/DiaryViewModel'
import { DiaryCard, DiaryWrapper } from '../../components/DiaryCard'
import promptAction from '@ohos.promptAction'

@Component
export struct FavoritesPage {
  @State diaries: DiaryWrapper[] = []
  @State showEmpty: boolean = false

  private vm: DiaryViewModel | null = null

  aboutToAppear() {
    this.vm = new DiaryViewModel(getContext(this))
    this.loadFavorites()
  }

  private async loadFavorites() {
    await this.vm?.loadFavorites()
    this.diaries = (this.vm?.favoriteDiaries ?? []).map(d => new DiaryWrapper(d))
    this.showEmpty = this.diaries.length === 0
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('♡')
        .fontSize(60)
        .fontColor('#DDDDDD')
      Text('还没有收藏')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => router.pop())
        Text('收藏')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.diaries, (item: DiaryWrapper) => {
            ListItem() {
              DiaryCard({
                diaryWrapper: item,
                onClick: () => {
                  router.pushUrl({
                    url: 'pages/diary/DiaryViewPage',
                    params: { diaryId: item.diary.id }
                  }).catch(() => {})
                },
                onFavoriteClick: () => {
                  this.vm?.toggleFavorite(item.diary)
                  this.loadFavorites()
                  promptAction.showToast({ message: '已取消收藏' })
                }
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 2: 创建 DraftsPage**

文件路径：`entry/src/main/ets/pages/diary/DraftsPage.ets`

```typescript
import router from '@ohos.router'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { DraftDiary } from '../../model/DraftDiaryModel'
import promptAction from '@ohos.promptAction'

@Component
export struct DraftsPage {
  @State drafts: DraftDiary[] = []
  @State showEmpty: boolean = false

  private repo: DiaryRepository | null = null

  aboutToAppear() {
    this.repo = new DiaryRepository(getContext(this))
    this.loadDrafts()
  }

  private async loadDrafts() {
    if (!this.repo) return
    this.drafts = await this.repo.allDrafts()
    this.showEmpty = this.drafts.length === 0
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('📝')
        .fontSize(60)
        .opacity(0.3)
      Text('草稿箱是空的')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => router.pop())
        Text('草稿箱')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.drafts, (draft: DraftDiary) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(this.formatDate(draft.date))
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  Text('草稿')
                    .fontSize(11)
                    .fontColor('#FF9800')
                    .backgroundColor('#FFF3E0')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                }
                Text(draft.title || '(无标题)')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(draft.content.replace(/<[^>]*>/g, '').trim())
                  .fontSize(13)
                  .fontColor('#888888')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/diary/DiaryEditPage',
                  params: { draftId: draft.id }
                }).catch(() => {})
              })
              .onLongPress(() => {
                promptAction.showActionMenu({
                  buttons: [
                    { text: '删除草稿', color: '#F44336' },
                    { text: '取消', color: '#999999' }
                  ]
                }).then(async (result) => {
                  if (result.index === 0 && this.repo) {
                    await this.repo.deleteDraft(draft.id)
                    this.loadDrafts()
                    promptAction.showToast({ message: '草稿已删除' })
                  }
                }).catch(() => {})
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 3: 创建 RecycleBinPage**

文件路径：`entry/src/main/ets/pages/diary/RecycleBinPage.ets`

```typescript
import router from '@ohos.router'
import { DiaryRepository } from '../../repository/DiaryRepository'
import { Diary } from '../../model/DiaryModel'
import promptAction from '@ohos.promptAction'

@Component
export struct RecycleBinPage {
  @State trashedDiaries: Diary[] = []
  @State showEmpty: boolean = false

  private repo: DiaryRepository | null = null

  aboutToAppear() {
    this.repo = new DiaryRepository(getContext(this))
    this.loadTrash()
  }

  private async loadTrash() {
    if (!this.repo) return
    this.trashedDiaries = await this.repo.trashedDiaries()
    this.showEmpty = this.trashedDiaries.length === 0
  }

  private formatDate(millis: number): string {
    const d = new Date(millis)
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  }

  @Builder
  EmptyView() {
    Column({ space: 16 }) {
      Text('🗑️')
        .fontSize(60)
        .opacity(0.3)
      Text('回收站是空的')
        .fontSize(16)
        .fontColor('#999999')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(22)
          .fontColor('#333333')
          .onClick(() => router.pop())
        Text('回收站')
          .fontSize(17)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .margin({ right: 22 })

        if (!this.showEmpty) {
          Text('清空')
            .fontSize(14)
            .fontColor('#F44336')
            .onClick(() => {
              promptAction.showDialog({
                title: '确认清空',
                message: '回收站中的日记将被永久删除，是否继续？',
                buttons: [
                  { text: '取消', color: '#999999' },
                  { text: '清空', color: '#F44336' }
                ]
              }).then(async (result) => {
                if (result.index === 1 && this.repo) {
                  for (const d of this.trashedDiaries) {
                    await this.repo.delete(d)
                  }
                  this.loadTrash()
                  promptAction.showToast({ message: '已清空回收站' })
                }
              }).catch(() => {})
            })
        }
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')

      Divider().strokeWidth(0.5).color('#EEEEEE')

      if (this.showEmpty) {
        this.EmptyView()
      } else {
        List({ space: 10 }) {
          ForEach(this.trashedDiaries, (diary: Diary) => {
            ListItem() {
              Column({ space: 8 }) {
                Row() {
                  Text(this.formatDate(diary.date))
                    .fontSize(12)
                    .fontColor('#999999')
                  Blank()
                  Text('回收站')
                    .fontSize(11)
                    .fontColor('#F44336')
                    .backgroundColor('#FFEBEE')
                    .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                    .borderRadius(8)
                }
                Text(diary.title || '(无标题)')
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#222222')
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .width('100%')
              .padding(16)
              .backgroundColor('#FFFFFF')
              .borderRadius(12)
              .shadow({ radius: 4, color: '#10000000', offsetX: 0, offsetY: 2 })
              .onClick(() => {
                router.pushUrl({
                  url: 'pages/diary/DiaryViewPage',
                  params: { diaryId: diary.id }
                }).catch(() => {})
              })
              .onLongPress(() => {
                promptAction.showActionMenu({
                  buttons: [
                    { text: '恢复', color: '#4CAF50' },
                    { text: '永久删除', color: '#F44336' },
                    { text: '取消', color: '#999999' }
                  ]
                }).then(async (result) => {
                  if (!this.repo) return
                  if (result.index === 0) {
                    await this.repo.restoreFromTrash(diary)
                    this.loadTrash()
                    promptAction.showToast({ message: '已恢复' })
                  } else if (result.index === 1) {
                    await this.repo.delete(diary)
                    this.loadTrash()
                    promptAction.showToast({ message: '已永久删除' })
                  }
                }).catch(() => {})
              })
            }
            .padding({ left: 16, right: 16, top: 6 })
          })
        }
        .listDirection(Axis.Vertical)
        .layoutWeight(1)
        .backgroundColor('#F0F2F5')
      }
    }
    .width('100%')
    .height('100%')
  }
}
```

- [ ] **Step 4: 注册 3 个页面路由**

修改 `main_pages.json`，在 `src` 数组中添加：
```json
"pages/diary/FavoritesPage",
"pages/diary/DraftsPage",
"pages/diary/RecycleBinPage"
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/pages/diary/FavoritesPage.ets \
        entry/src/main/ets/pages/diary/DraftsPage.ets \
        entry/src/main/ets/pages/diary/RecycleBinPage.ets
git commit -m "feat: add FavoritesPage, DraftsPage, and RecycleBinPage"
```

---

## Task 10：Day 5-7 构建验证

**Files:**
- Build: `entry` 模块

- [ ] **Step 1: Build Hap 验证**

在 DevEco Studio 中 Build → Build Hap，确认编译无错误。

常见错误：
- `RelationalStore.RdbPredicates` API 用法：HarmonyOS Relational DB API 版本差异，查阅当前 SDK `data.rdb` 模块文档
- `setInterval` / `clearInterval` 在 ArkTS 中用法：使用 `setTimer` / `clearTimer` 或 `@ohos.app.ability.TimerManager`
- `@ObjectLink` 配合数组：`DiaryWrapper` 须为 `@Observed` class
- `globalThis.globalContext` 在单元测试中不可用：使用测试框架提供的 context mock

- [ ] **Step 2: 运行模型单元测试**

DevEco Studio → Run Configuration → 运行 `DiaryModelTest`，预期全部 PASS。

- [ ] **Step 3: 提交**

```bash
git add entry/
git commit -m "test: run build verification for diary module"
```

---

## Day 5-7 完成检查清单

- [ ] `DiaryModel.ets` + `DraftDiaryModel.ets` 数据模型（含 `isSystemDiaryContent`）
- [ ] `DiaryRepository.ets` 实现全 CRUD、收藏、回收站（软删除/恢复）、草稿箱
- [ ] `DiaryViewModel.ets` 管理列表状态（搜索、跳转、收藏切换、删除）
- [ ] `DiaryEditViewModel.ets` 管理编辑状态、自动草稿保存（30 秒间隔）
- [ ] `DiaryCard.ets` 列表卡片组件（日期/标题/摘要/天气心情/收藏）
- [ ] `WeatherPicker.ets` + `MoodPicker.ets` 选择器（emoji + 圆形选中态）
- [ ] `DiaryPagerPage.ets` 日记列表（全部/图片/视频筛选、空状态）
- [ ] `DiaryEditPage.ets` 日记编辑（标题/内容 TextArea /天气/心情/自动草稿）
- [ ] `DiaryViewPage.ets` 日记查看（完整内容 + 操作菜单：编辑/收藏/删除）
- [ ] `FavoritesPage.ets` 收藏列表
- [ ] `DraftsPage.ets` 草稿箱（含长按删除）
- [ ] `RecycleBinPage.ets` 回收站（含清空/恢复/永久删除）
- [ ] `main_pages.json` 已注册全部 6 个新页面
- [ ] Build 编译无错误
- [ ] 单元测试全部 PASS

---

## Day 5-7 → Day 8 衔接说明

Day 7 结束后日记管理模块基本完成，可通过 MainPage 抽屉菜单访问收藏/草稿箱/回收站。

Day 8-9 将实现 **AI 聊天模块**（ChatPage），需要复用的基础设施：
- `DiaryRepository` — 日记数据已可用
- `PreferencesHelper` — Token 已存储（Day 2-3）
- `AuthService` — 登录/注册已完成（Day 2-3）
- `WebSocketClient.ets` — 已封装（Day 1）
