/**
 * 日记数据仓库
 * 对标 Android DiaryRepository (Room DAO + Repository)
 * 使用 HarmonyOS Relational DB 存储日记数据
 */
import { Diary } from '../model/DiaryModel'
import { DraftDiary } from '../model/DraftDiaryModel'
import { relationalStore } from '@kit.ArkData'
import { getLogger } from '../utils/Logger'

const logger = getLogger('DiaryRepository')
const STORE_NAME = 'diary.db'

export class DiaryRepository {
  private store: relationalStore.RdbStore | null = null
  private context: Context

  constructor(context: Context) {
    this.context = context
  }

  private async getStore(): Promise<relationalStore.RdbStore> {
    if (this.store) return this.store
    const config: relationalStore.StoreConfig = {
      name: STORE_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    }
    this.store = await relationalStore.getRdbStore(this.context, config)
    await this.initTables()
    return this.store
  }

  private async initTables(): Promise<void> {
    const store = this.store!
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

  async insert(diary: Diary): Promise<number> {
    const store = await this.getStore()
    const bucket: relationalStore.ValuesBucket = {
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
    logger.info(`inserted diary id=${result}`)
    return result
  }

  async update(diary: Diary): Promise<void> {
    const store = await this.getStore()
    const bucket: relationalStore.ValuesBucket = {
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
    const predicates = new relationalStore.RdbPredicates('diaries')
    predicates.equalTo('id', diary.id)
    await store.update('diaries', bucket, predicates)
  }

  async delete(diary: Diary): Promise<void> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
    predicates.equalTo('id', diary.id)
    await store.delete(predicates)
  }

  async findById(id: number): Promise<Diary | null> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
    predicates.equalTo('id', id)
    const result = await store.query(predicates)
    return this.rowToDiary(result)
  }

  async allDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async searchDiaries(query: string): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .like('title', `%${query}%`)
      .or()
      .like('content', `%${query}%`)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async favoriteDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
      .equalTo('isFavorite', 1)
      .equalTo('isTrashed', 0)
      .equalTo('isVaulted', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async toggleFavorite(diary: Diary): Promise<void> {
    const updated: Diary = {
      id: diary.id,
      userId: diary.userId,
      author: diary.author,
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      createdAt: diary.createdAt,
      synced: diary.synced,
      isFavorite: !diary.isFavorite,
      isVaulted: diary.isVaulted,
      isTrashed: diary.isTrashed,
      trashedAt: diary.trashedAt,
      previewContentPriority: diary.previewContentPriority
    }
    await this.update(updated)
  }

  async trashedDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
      .equalTo('isTrashed', 1)
      .orderByDesc('trashedAt')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async moveToTrash(diary: Diary): Promise<void> {
    const updated: Diary = {
      id: diary.id,
      userId: diary.userId,
      author: diary.author,
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      createdAt: diary.createdAt,
      synced: diary.synced,
      isFavorite: diary.isFavorite,
      isVaulted: diary.isVaulted,
      isTrashed: true,
      trashedAt: Date.now(),
      previewContentPriority: diary.previewContentPriority
    }
    await this.update(updated)
  }

  async restoreFromTrash(diary: Diary): Promise<void> {
    const updated: Diary = {
      id: diary.id,
      userId: diary.userId,
      author: diary.author,
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      createdAt: diary.createdAt,
      synced: diary.synced,
      isFavorite: diary.isFavorite,
      isVaulted: diary.isVaulted,
      isTrashed: false,
      trashedAt: null,
      previewContentPriority: diary.previewContentPriority
    }
    await this.update(updated)
  }

  async moveToVault(diary: Diary): Promise<void> {
    const updated: Diary = {
      id: diary.id,
      userId: diary.userId,
      author: diary.author,
      title: diary.title,
      content: diary.content,
      mood: diary.mood,
      weather: diary.weather,
      location: diary.location,
      date: diary.date,
      createdAt: diary.createdAt,
      synced: diary.synced,
      isFavorite: diary.isFavorite,
      isVaulted: true,
      isTrashed: diary.isTrashed,
      trashedAt: diary.trashedAt,
      previewContentPriority: diary.previewContentPriority
    }
    await this.update(updated)
  }

  async vaultedDiaries(): Promise<Diary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('diaries')
      .equalTo('isVaulted', 1)
      .equalTo('isTrashed', 0)
      .orderByDesc('date')
    const result = await store.query(predicates)
    return this.rowsToDiaries(result)
  }

  async allDrafts(): Promise<DraftDiary[]> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('draft_diaries')
      .orderByDesc('updatedAt')
    const result = await store.query(predicates)
    return this.rowsToDrafts(result)
  }

  async saveDraft(draft: DraftDiary): Promise<number> {
    const store = await this.getStore()
    const bucket: relationalStore.ValuesBucket = {
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
      const pred = new relationalStore.RdbPredicates('draft_diaries')
      pred.equalTo('id', draft.id)
      await store.update('draft_diaries', bucket, pred)
      return draft.id
    } else {
      return await store.insert('draft_diaries', bucket)
    }
  }

  async deleteDraft(draftId: number): Promise<void> {
    const store = await this.getStore()
    const predicates = new relationalStore.RdbPredicates('draft_diaries')
    predicates.equalTo('id', draftId)
    await store.delete(predicates)
  }

  private rowToDiary(result: relationalStore.ResultSet): Diary | null {
    if (!result.goToFirstRow()) return null
    const getStr = (col: string): string => {
      const idx = result.getColumnIndex(col)
      return idx >= 0 ? (result.getString(idx) ?? '') : ''
    }
    const getLong = (col: string): number => {
      const idx = result.getColumnIndex(col)
      return idx >= 0 ? result.getLong(idx) : 0
    }
    const trashedAtIdx = result.getColumnIndex('trashedAt')
    return {
      id: getLong('id'),
      userId: getStr('userId'),
      author: getStr('author') || null,
      title: getStr('title'),
      content: getStr('content'),
      mood: getStr('mood'),
      weather: getStr('weather'),
      location: getStr('location') || null,
      date: getLong('date'),
      createdAt: getLong('createdAt'),
      synced: getLong('synced') === 1,
      isFavorite: getLong('isFavorite') === 1,
      isVaulted: getLong('isVaulted') === 1,
      isTrashed: getLong('isTrashed') === 1,
      trashedAt: trashedAtIdx >= 0 ? getLong('trashedAt') : null,
      previewContentPriority: getStr('previewContentPriority')
    }
  }

  private rowsToDiaries(result: relationalStore.ResultSet): Diary[] {
    const diaries: Diary[] = []
    while (result.goToNextRow()) {
      const d = this.rowToDiary(result)
      if (d) diaries.push(d)
    }
    result.close()
    return diaries
  }

  private rowsToDrafts(result: relationalStore.ResultSet): DraftDiary[] {
    const drafts: DraftDiary[] = []
    while (result.goToNextRow()) {
      const getLong = (col: string): number => {
        const idx = result.getColumnIndex(col)
        return idx >= 0 ? result.getLong(idx) : 0
      }
      const getStr = (col: string): string => {
        const idx = result.getColumnIndex(col)
        return idx >= 0 ? (result.getString(idx) ?? '') : ''
      }
      drafts.push({
        id: getLong('id'),
        userId: getStr('userId'),
        title: getStr('title'),
        content: getStr('content'),
        mood: getStr('mood'),
        weather: getStr('weather'),
        date: getLong('date'),
        createdAt: getLong('createdAt'),
        updatedAt: getLong('updatedAt')
      })
    }
    result.close()
    return drafts
  }
}