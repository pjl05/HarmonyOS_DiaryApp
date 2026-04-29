/**
 * DayDao - Relational DB CRUD for days
 * 对标 Android: DayDao.kt
 */
import relationalStore from '@ohos.data.relationalStore'
import { DayItem, Mood, Priority, PreviewContentPriority } from '../../model/DayItem'

const TABLE = 'day_items'

const CREATE_TABLE_SQL = `
CREATE TABLE IF NOT EXISTS ${TABLE} (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  userId TEXT NOT NULL,
  startAt TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  content TEXT NOT NULL DEFAULT '',
  author TEXT NOT NULL DEFAULT '',
  mood INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 1,
  location TEXT NOT NULL DEFAULT '',
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
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
    predicates.equalTo('userId', userId)
    predicates.orderByDesc('startAt')
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
