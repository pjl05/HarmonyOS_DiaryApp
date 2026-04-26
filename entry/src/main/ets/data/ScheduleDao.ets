/**
 * ScheduleDao - Relational DB CRUD for schedules
 * 对标 Android: ScheduleDao.kt
 */
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

  constructor(context: Context) {
    this.init(context)
  }

  private async init(context: Context): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'diary_schedule.db',
      securityLevel: relationalStore.SecurityLevel.S1
    }
    this.store = await relationalStore.getRdbStore(context, config)
    await this.store.executeSql(CREATE_TABLE_SQL)
    await this.store.executeSql(INDEX_SQL)
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
    predicates.orderByDesc('scheduledAt')
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
