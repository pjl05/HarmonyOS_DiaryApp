/**
 * ChatMessageDao - 消息 CRUD 数据访问层
 * 替换 Android: ChatMessageDao (Room @Dao)
 * 使用 HarmonyOS Relational DB
 */
import { relational } from '@kit.ArkData'
import { ChatMessage } from '../../model/ChatMessageModel'

const STORE_NAME = 'diary_chat.db'
const TABLE_NAME = 'chat_messages'

class ChatMessageDao {
  private db: relational.RdbStore | null = null
  private initPromise: Promise<void> | null = null

  async init(): Promise<void> {
    if (this.db) return
    if (this.initPromise) return this.initPromise

    this.initPromise = this.doInit()
    return this.initPromise
  }

  private async doInit(): Promise<void> {
    const ctx = getContext(this) as Context
    const config: relational.StoreConfig = {
      name: STORE_NAME,
      securityLevel: relational.SecurityLevel.S1
    }
    this.db = await relational.getRdbStore(ctx, config)

    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        sessionId TEXT NOT NULL
      )
    `)

    await this.db.executeSql(`
      CREATE INDEX IF NOT EXISTS idx_session_timestamp ON ${TABLE_NAME}(sessionId, timestamp)
    `)
  }

  private async ensureDb(): Promise<relational.RdbStore> {
    await this.init()
    return this.db!
  }

  async getAllMessages(sessionId: string): Promise<ChatMessage[]> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME)
      .equalTo('sessionId', sessionId)
      .orderByAsc('timestamp')
    const result = await db.query(predicates)
    return this.rowsToMessages(result)
  }

  async getRecentMessages(sessionId: string, limit: number): Promise<ChatMessage[]> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME)
      .equalTo('sessionId', sessionId)
      .orderByDesc('timestamp')
      .limitAs(limit)
    const result = await db.query(predicates)
    const msgs = this.rowsToMessages(result)
    return msgs.reverse()
  }

  async insert(message: ChatMessage): Promise<number> {
    const db = await this.ensureDb()
    const values: relational.ValuesBucket = {
      message: message.message,
      role: message.role,
      timestamp: message.timestamp,
      sessionId: message.sessionId
    }
    return await db.insert(TABLE_NAME, values)
  }

  async updateMessageContent(id: number, content: string): Promise<void> {
    const db = await this.ensureDb()
    const values: relational.ValuesBucket = {
      message: content
    }
    const predicates = new relational.RdbPredicates(TABLE_NAME).equalTo('id', id)
    await db.update(TABLE_NAME, values, predicates)
  }

  async deleteById(id: number): Promise<void> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME).equalTo('id', id)
    await db.delete(TABLE_NAME, predicates)
  }

  async clearAll(sessionId: string): Promise<void> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME).equalTo('sessionId', sessionId)
    await db.delete(TABLE_NAME, predicates)
  }

  async getLastUserTimestamp(sessionId: string): Promise<number | null> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME)
      .equalTo('sessionId', sessionId)
      .equalTo('role', 'user')
      .orderByDesc('timestamp')
      .limitAs(1)
    const result = await db.query(predicates)
    if (result.goToFirstRow()) {
      const ts = result.getLong(result.getColumnIndex('timestamp'))
      result.close()
      return ts > 0 ? ts : null
    }
    result.close()
    return null
  }

  async getLastAssistantTimestamp(sessionId: string): Promise<number | null> {
    const db = await this.ensureDb()
    const predicates = new relational.RdbPredicates(TABLE_NAME)
      .equalTo('sessionId', sessionId)
      .equalTo('role', 'assistant')
      .orderByDesc('timestamp')
      .limitAs(1)
    const result = await db.query(predicates)
    if (result.goToFirstRow()) {
      const ts = result.getLong(result.getColumnIndex('timestamp'))
      result.close()
      return ts > 0 ? ts : null
    }
    result.close()
    return null
  }

  private rowsToMessages(result: relational.ResultSet): ChatMessage[] {
    const messages: ChatMessage[] = []
    while (result.goToNextRow()) {
      messages.push({
        id: result.getLong(result.getColumnIndex('id')),
        message: result.getString(result.getColumnIndex('message')),
        role: result.getString(result.getColumnIndex('role')),
        timestamp: result.getLong(result.getColumnIndex('timestamp')),
        sessionId: result.getString(result.getColumnIndex('sessionId'))
      })
    }
    result.close()
    return messages
  }
}

export const chatMessageDao = new ChatMessageDao()
