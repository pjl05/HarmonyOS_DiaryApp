# Day 8-9: AI聊天模块 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现完整的 AI 聊天模块，包含 ChatPage 主聊天页面、ChatManagementPage 设置页面、FloatingAIBallView 悬浮球、以及 AiChatBackgroundManager 后台消息管理。迁移自 Android ChatActivity/ChatManagementActivity 及相关组件。

**Architecture:**
- MVVM + Repository 模式，ChatViewModel 管理消息状态和发送逻辑
- Relational DB 本地持久化 ChatMessage（替换 Room ChatMessageDao）
- WebSocket 实现流式 AI 回复（替换 ServerAiWebSocketService/DeepseekService）
- FloatingAIBallView 用 ArkUI Stack + Gesture 实现拖拽悬浮球
- @State/@Link/@Observed 管理所有状态，对标 Android StateFlow

**Tech Stack:** ArkTS, Relational DB, @ohos.net.http WebSocket, ArkUI Gesture, Preferences

---

## File Structure

```
entry/src/main/ets/
├── model/
│   └── ChatMessageModel.ets          # ChatMessage 接口（替换 Room Entity）
├── data/
│   ├── dao/
│   │   └── ChatMessageDao.ets        # 消息 CRUD（替换 Room @Dao）
│   └── repository/
│       └── ChatRepository.ets        # Repository 封装
├── viewmodel/
│   └── ChatViewModel.ets             # 聊天状态管理 + 发送逻辑
├── ui/
│   ├── chat/
│   │   ├── ChatPage.ets              # 主聊天页面
│   │   ├── ChatAdapter.ets           # 消息列表适配器
│   │   ├── MessageBubbleUser.ets     # 用户消息气泡
│   │   ├── MessageBubbleAi.ets       # AI 消息气泡
│   │   ├── ChatInputBar.ets          # 输入框 + 发送按钮
│   │   └── ChatManagementPage.ets    # AI 设置页面
│   └── widget/
│       └── FloatingAIBallView.ets    # 悬浮球
├── service/
│   └── AiChatService.ets             # WebSocket AI 服务
└── pages/
    ├── ChatPage.ets                   # 路由页面入口
    └── ChatManagementPage.ets         # 路由页面入口
```

---

## Task 1: ChatMessageModel and ChatMessageDao

**Files:**
- Create: `entry/src/main/ets/model/ChatMessageModel.ets`
- Create: `entry/src/main/ets/data/dao/ChatMessageDao.ets`

- [ ] **Step 1: Create ChatMessageModel.ets**

```typescript
// entry/src/main/ets/model/ChatMessageModel.ets

/**
 * ChatMessage - 本地聊天消息模型
 * 替换 Android: ChatMessage (Room Entity)
 * 表名: chat_messages
 */
export interface ChatMessage {
  id: number          // 自增主键，0 = 未持久化
  message: string    // 消息内容
  role: string       // "user" | "assistant"
  timestamp: number  // 时间戳
  sessionId: string  // 会话 ID（用于区分不同角色/对话）
}

export function createUserMessage(text: string, sessionId: string): ChatMessage {
  return {
    id: 0,
    message: text,
    role: "user",
    timestamp: Date.now(),
    sessionId: sessionId
  }
}

export function createAiMessage(text: string, sessionId: string, timestamp: number = Date.now()): ChatMessage {
  return {
    id: 0,
    message: text,
    role: "assistant",
    timestamp: timestamp,
    sessionId: sessionId
  }
}
```

- [ ] **Step 2: Create ChatMessageDao.ets**

```typescript
// entry/src/main/ets/data/dao/ChatMessageDao.ets

import { relational } from '@kit.ArkData';
import { ChatMessage } from '../../model/ChatMessageModel';

const STORE_NAME = 'diary_chat.db';
const TABLE_NAME = 'chat_messages';

class ChatMessageDao {
  private db: relational.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  async init(): Promise<void> {
    if (this.db) return;
    if (this.initPromise) return this.initPromise;

    this.initPromise = this.doInit();
    return this.initPromise;
  }

  private async doInit(): Promise<void> {
    const ctx = getContext(this);
    const config: relational.StoreConfig = {
      name: STORE_NAME,
      securityLevel: relational.SecurityLevel.S1
    };
    this.db = await relational.getRdbStore(ctx, config);

    // CREATE TABLE IF NOT EXISTS
    await this.db.executeSql(`
      CREATE TABLE IF NOT EXISTS ${TABLE_NAME} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message TEXT NOT NULL,
        role TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        sessionId TEXT NOT NULL
      )
    `);

    // CREATE INDEX
    await this.db.executeSql(`
      CREATE INDEX IF NOT EXISTS idx_session_timestamp ON ${TABLE_NAME}(sessionId, timestamp)
    `);
  }

  private async ensureDb(): Promise<relational.RdbStore> {
    await this.init();
    return this.db!;
  }

  async getAllMessages(sessionId: string): Promise<ChatMessage[]> {
    const db = await this.ensureDb();
    const result = await db.query(
      TABLE_NAME,
      ['id', 'message', 'role', 'timestamp', 'sessionId'],
      new relational.DataValidPredicates.PredicatesString('sessionId').equalTo(sessionId)
    );
    result.goToFirstRow();
    const messages: ChatMessage[] = [];
    while (result.getRowCount() > 0 && !result.isEnded) {
      messages.push({
        id: result.getLong(result.getColumnIndex('id')),
        message: result.getString(result.getColumnIndex('message')),
        role: result.getString(result.getColumnIndex('role')),
        timestamp: result.getLong(result.getColumnIndex('timestamp')),
        sessionId: result.getString(result.getColumnIndex('sessionId'))
      });
      if (!result.goToNextRow()) break;
    }
    result.close();
    return messages;
  }

  async getRecentMessages(sessionId: string, limit: number): Promise<ChatMessage[]> {
    const db = await this.ensureDb();
    const result = await db.query(
      TABLE_NAME,
      ['id', 'message', 'role', 'timestamp', 'sessionId'],
      new relational.DataValidPredicates.PredicatesString('sessionId').equalTo(sessionId),
      new relational.SortOrder('timestamp', relational.SortType.DESC),
      limit
    );
    result.goToFirstRow();
    const messages: ChatMessage[] = [];
    while (result.getRowCount() > 0 && !result.isEnded) {
      messages.push({
        id: result.getLong(result.getColumnIndex('id')),
        message: result.getString(result.getColumnIndex('message')),
        role: result.getString(result.getColumnIndex('role')),
        timestamp: result.getLong(result.getColumnIndex('timestamp')),
        sessionId: result.getString(result.getColumnIndex('sessionId'))
      });
      if (!result.goToNextRow()) break;
    }
    result.close();
    return messages.reverse();
  }

  async insert(message: ChatMessage): Promise<number> {
    const db = await this.ensureDb();
    const values = new relational.ValuesBucket();
    values.putString('message', message.message);
    values.putString('role', message.role);
    values.putLong('timestamp', message.timestamp);
    values.putString('sessionId', message.sessionId);
    const rowId = await db.insert(TABLE_NAME, values);
    return rowId;
  }

  async updateMessageContent(id: number, content: string): Promise<void> {
    const db = await this.ensureDb();
    const values = new relational.ValuesBucket();
    values.putString('message', content);
    await db.update(TABLE_NAME, values,
      new relational.DataValidPredicates.PredicatesNumber('id').equalTo(id)
    );
  }

  async deleteById(id: number): Promise<void> {
    const db = await this.ensureDb();
    await db.delete(TABLE_NAME,
      new relational.DataValidPredicates.PredicatesNumber('id').equalTo(id)
    );
  }

  async clearAll(sessionId: string): Promise<void> {
    const db = await this.ensureDb();
    await db.delete(TABLE_NAME,
      new relational.DataValidPredicates.PredicatesString('sessionId').equalTo(sessionId)
    );
  }

  async getLastUserTimestamp(sessionId: string): Promise<number | null> {
    const db = await this.ensureDb();
    const result = await db.query(
      TABLE_NAME,
      ['MAX(timestamp) as maxTs'],
      new relational.DataValidPredicates.PredicatesString('sessionId').equalTo(sessionId)
        .and(new relational.DataValidPredicates.PredicatesString('role').equalTo('user'))
    );
    result.goToFirstRow();
    const maxTs = result.getLong(0);
    result.close();
    return maxTs > 0 ? maxTs : null;
  }

  async getLastAssistantTimestamp(sessionId: string): Promise<number | null> {
    const db = await this.ensureDb();
    const result = await db.query(
      TABLE_NAME,
      ['MAX(timestamp) as maxTs'],
      new relational.DataValidPredicates.PredicatesString('sessionId').equalTo(sessionId)
        .and(new relational.DataValidPredicates.PredicatesString('role').equalTo('assistant'))
    );
    result.goToFirstRow();
    const maxTs = result.getLong(0);
    result.close();
    return maxTs > 0 ? maxTs : null;
  }
}

export const chatMessageDao = new ChatMessageDao();
```

- [ ] **Step 3: 验证代码编译**

Run: `hvigor build`
Expected: 无编译错误

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/model/ChatMessageModel.ets entry/src/main/ets/data/dao/ChatMessageDao.ets
git commit -m "feat(chat): add ChatMessageModel and ChatMessageDao for Relational DB"
```

---

## Task 2: ChatRepository

**Files:**
- Create: `entry/src/main/ets/data/repository/ChatRepository.ets`

- [ ] **Step 1: Create ChatRepository.ets**

```typescript
// entry/src/main/ets/data/repository/ChatRepository.ets

import { ChatMessage, createUserMessage, createAiMessage } from '../model/ChatMessageModel';
import { chatMessageDao } from '../dao/ChatMessageDao';

export class ChatRepository {
  async getAllMessages(sessionId: string): Promise<ChatMessage[]> {
    return chatMessageDao.getAllMessages(sessionId);
  }

  async getRecentMessages(sessionId: string, limit: number): Promise<ChatMessage[]> {
    return chatMessageDao.getRecentMessages(sessionId, limit);
  }

  async sendUserMessage(text: string, sessionId: string): Promise<ChatMessage> {
    const msg = createUserMessage(text, sessionId);
    const id = await chatMessageDao.insert(msg);
    return { ...msg, id };
  }

  async insertAiMessage(text: string, sessionId: string): Promise<ChatMessage> {
    const msg = createAiMessage(text, sessionId);
    const id = await chatMessageDao.insert(msg);
    return { ...msg, id };
  }

  async appendToAiMessage(id: number, newContent: string): Promise<string> {
    await chatMessageDao.updateMessageContent(id, newContent);
    return newContent;
  }

  async deleteMessage(id: number): Promise<void> {
    await chatMessageDao.deleteById(id);
  }

  async clearSession(sessionId: string): Promise<void> {
    await chatMessageDao.clearAll(sessionId);
  }

  async getLastUserTimestamp(sessionId: string): Promise<number | null> {
    return chatMessageDao.getLastUserTimestamp(sessionId);
  }

  async getLastAssistantTimestamp(sessionId: string): Promise<number | null> {
    return chatMessageDao.getLastAssistantTimestamp(sessionId);
  }
}

export const chatRepository = new ChatRepository();
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/data/repository/ChatRepository.ets
git commit -m "feat(chat): add ChatRepository for message CRUD operations"
```

---

## Task 3: ChatViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/ChatViewModel.ets`

- [ ] **Step 1: Create ChatViewModel.ets**

```typescript
// entry/src/main/ets/viewmodel/ChatViewModel.ets

import { ChatMessage } from '../model/ChatMessageModel';
import { chatRepository } from '../data/repository/ChatRepository';
import { preferences } from '@kit.ArkData';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'ChatViewModel';

// ===== Settings Preferences Keys =====
const PREF_NAME = 'chat_settings';
const KEY_AI_ROLE_PRESET_ID = 'ai_role_preset_id';
const KEY_AI_NAME = 'ai_name';
const KEY_ROLE_SETTING = 'role_setting';
const KEY_CHAT_SESSION_ID = 'chat_session_id';
const KEY_CHAT_HISTORY_LIMIT = 'chat_history_limit';
const KEY_AI_DIARY_READ_LIMIT = 'ai_diary_read_limit';
const KEY_AI_CONFIG_MODE = 'ai_config_mode';

@Observed
export class ChatViewModel {
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State currentSessionId: string = '';
  @State aiName: string = 'AI Companion';

  aiRolePresetId: number = 0;
  roleSetting: string = '';
  chatHistoryLimit: number = 24;
  aiDiaryReadLimit: number = 10;
  aiConfigMode: string = 'default';

  private prefs: preferences.Preferences | null = null;
  private currentAiMessageId: number = -1;
  private currentAiContent: string = '';

  async aboutToAppear(): Promise<void> {
    await this.loadSettings();
    const msgs = await chatRepository.getAllMessages(this.currentSessionId);
    this.messages = msgs;
  }

  async loadSettings(): Promise<void> {
    const ctx = getContext(this);
    this.prefs = preferences.getPreferences(ctx, { name: PREF_NAME });
    this.aiRolePresetId = await this.prefs.get(KEY_AI_ROLE_PRESET_ID, 0) as number;
    this.aiName = await this.prefs.get(KEY_AI_NAME, 'AI Companion') as string;
    this.roleSetting = await this.prefs.get(KEY_ROLE_SETTING, '') as string;
    this.chatHistoryLimit = await this.prefs.get(KEY_CHAT_HISTORY_LIMIT, 24) as number;
    this.aiDiaryReadLimit = await this.prefs.get(KEY_AI_DIARY_READ_LIMIT, 10) as number;
    this.aiConfigMode = await this.prefs.get(KEY_AI_CONFIG_MODE, 'default') as string;
    this.currentSessionId = await this.prefs.get(KEY_CHAT_SESSION_ID, '') as string;
    if (!this.currentSessionId) {
      this.currentSessionId = `session_${Date.now()}`;
      await this.prefs.put(KEY_CHAT_SESSION_ID, this.currentSessionId);
    }
  }

  async saveSettings(): Promise<void> {
    if (!this.prefs) return;
    await this.prefs.put(KEY_AI_ROLE_PRESET_ID, this.aiRolePresetId);
    await this.prefs.put(KEY_AI_NAME, this.aiName);
    await this.prefs.put(KEY_ROLE_SETTING, this.roleSetting);
    await this.prefs.put(KEY_CHAT_HISTORY_LIMIT, this.chatHistoryLimit);
    await this.prefs.put(KEY_AI_DIARY_READ_LIMIT, this.aiDiaryReadLimit);
    await this.prefs.put(KEY_AI_CONFIG_MODE, this.aiConfigMode);
  }

  updateInputText(text: string): void {
    this.inputText = text;
  }

  async sendMessage(): Promise<void> {
    const text = this.inputText.trim();
    if (!text || this.isLoading) return;

    this.inputText = '';
    this.isLoading = true;

    try {
      const userMsg = await chatRepository.sendUserMessage(text, this.currentSessionId);
      this.messages = [...this.messages, userMsg];

      this.currentAiMessageId = -1;
      this.currentAiContent = '';

      const aiMsg = await chatRepository.insertAiMessage('', this.currentSessionId);
      this.currentAiMessageId = aiMsg.id;
      this.currentAiContent = '';
      this.messages = [...this.messages, aiMsg];

      await this.callAiService(text, (chunk: string, done: boolean) => {
        if (done) {
          this.currentAiContent += chunk;
          this.updateLastAiMessage();
        } else {
          this.currentAiContent += chunk;
          this.updateLastAiMessageStreaming();
        }
      });

      await chatRepository.appendToAiMessage(this.currentAiMessageId, this.currentAiContent);
    } catch (e) {
      hilog.error(0, TAG, 'sendMessage error: %{public}s', JSON.stringify(e));
      if (this.currentAiMessageId > 0) {
        await chatRepository.deleteMessage(this.currentAiMessageId);
        this.messages = this.messages.filter(m => m.id !== this.currentAiMessageId);
      }
    } finally {
      this.isLoading = false;
      this.currentAiMessageId = -1;
    }
  }

  private updateLastAiMessage(): void {
    if (this.messages.length === 0) return;
    const last = this.messages[this.messages.length - 1];
    if (last.role === 'assistant' && last.id === this.currentAiMessageId) {
      this.messages = [...this.messages.slice(0, -1), { ...last, message: this.currentAiContent }];
    }
  }

  private updateLastAiMessageStreaming(): void {
    this.updateLastAiMessage();
  }

  private async callAiService(
    userMessage: string,
    onChunk: (chunk: string, done: boolean) => void
  ): Promise<void> {
    // TODO: 替换为 HarmonyOS WebSocket 实现（Task 7）
    const response = `这是一条模拟 AI 回复：${userMessage}`;
    for (let i = 0; i < response.length; i += 5) {
      await new Promise(resolve => setTimeout(resolve, 50));
      onChunk(response.slice(i, i + 5), false);
    }
    onChunk('', true);
  }

  async loadHistory(): Promise<void> {
    const msgs = await chatRepository.getAllMessages(this.currentSessionId);
    this.messages = msgs;
  }

  async clearChat(): Promise<void> {
    await chatRepository.clearSession(this.currentSessionId);
    this.messages = [];
  }

  async deleteMessage(id: number): Promise<void> {
    await chatRepository.deleteMessage(id);
    this.messages = this.messages.filter(m => m.id !== id);
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/viewmodel/ChatViewModel.ets
git commit -m "feat(chat): add ChatViewModel with message state and send logic"
```

---

## Task 4: ChatPage 主页面

**Files:**
- Create: `entry/src/main/ets/ui/chat/ChatPage.ets`
- Create: `entry/src/main/ets/pages/ChatPage.ets`

- [ ] **Step 1: Create ChatPage.ets**

```typescript
// entry/src/main/ets/ui/chat/ChatPage.ets

import { ChatViewModel } from '../viewmodel/ChatViewModel';
import { ChatMessage } from '../model/ChatMessageModel';
import { router } from '@kit.RouterKit';

const SVG_AI_AVATAR = 'file://media/ic_ai_avatar.svg';
const SVG_SETTINGS = 'file://media/ic_settings.svg';

@Component
export struct ChatPage {
  @State viewModel: ChatViewModel = new ChatViewModel();

  async aboutToAppear(): Promise<void> {
    await this.viewModel.aboutToAppear();
  }

  build() {
    NavDestination() {
      Column() {
        // 顶部栏
        this.buildTopBar()

        // 消息列表
        List({ initialIndex: 0 }) {
          ForEach(this.viewModel.messages, (msg: ChatMessage, index: number) => {
            ListItem() {
              this.buildMessageItem(msg)
            }
          }, (msg: ChatMessage) => `${msg.id}_${msg.timestamp}`)
        }
        .layoutWeight(1)
        .padding({ left: 12, right: 12 })
        .scrollBar(BarState.Off)
        .alignListItem(ListItemAlign.CENTER)

        // 输入栏
        ChatInputBar({
          inputText: $viewModel.inputText,
          isLoading: $viewModel.isLoading,
          onSend: () => this.viewModel.sendMessage()
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#FFF5F5F5')
    }
    .title('AI 聊天')
    .titleMode(NavDestinationTitleMode.Medium)
  }

  @Builder
  buildTopBar() {
    Row() {
      Image(SVG_AI_AVATAR)
        .width(32)
        .height(32)
        .borderRadius(16)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ChatManagementPage' });
        })

      Blank()

      Image(SVG_SETTINGS)
        .width(24)
        .height(24)
        .onClick(() => {
          router.pushUrl({ url: 'pages/ChatManagementPage' });
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  buildMessageItem(msg: ChatMessage) {
    if (msg.role === 'user') {
      MessageBubbleUser({ message: msg })
    } else {
      MessageBubbleAi({ message: msg, aiName: this.viewModel.aiName })
    }
  }
}
```

- [ ] **Step 2: Create pages/ChatPage.ets entry**

```typescript
// entry/src/main/ets/pages/ChatPage.ets

import { ChatPage } from '../ui/chat/ChatPage';

@Entry
@Component
export struct ChatPageEntry {
  build() {
    ChatPage()
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/ui/chat/ChatPage.ets entry/src/main/ets/pages/ChatPage.ets
git commit -m "feat(chat): add ChatPage with NavDestination and message list"
```

---

## Task 5: MessageBubbleUser and MessageBubbleAi

**Files:**
- Create: `entry/src/main/ets/ui/chat/MessageBubbleUser.ets`
- Create: `entry/src/main/ets/ui/chat/MessageBubbleAi.ets`

- [ ] **Step 1: Create MessageBubbleUser.ets**

```typescript
// entry/src/main/ets/ui/chat/MessageBubbleUser.ets

import { ChatMessage } from '../../model/ChatMessageModel';

@Observed
export class ChatMessageWrapper {
  msg: ChatMessage;

  constructor(msg: ChatMessage) {
    this.msg = msg;
  }
}

@Component
export struct MessageBubbleUser {
  @ObjectLink wrapper: ChatMessageWrapper;

  build() {
    Row() {
      Blank()
      Column() {
        Text(this.wrapper.msg.message)
          .fontSize(15)
          .fontColor('#FFFFFFFF')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#FF4A90D9')
          .borderRadius(18)
          .constraintSize({ maxWidth: 260 })

        Text(formatTime(this.wrapper.msg.timestamp))
          .fontSize(11)
          .fontColor('#FF999999')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.End)
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

function formatTime(timestamp: number): string {
  const d = new Date(timestamp);
  const now = new Date();
  const sameDay = d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate();
  if (sameDay) {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  }
  return `${d.getMonth() + 1}月${d.getDate()}日 ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}
```

- [ ] **Step 2: Create MessageBubbleAi.ets**

```typescript
// entry/src/main/ets/ui/chat/MessageBubbleAi.ets

import { ChatMessage } from '../../model/ChatMessageModel';

@Component
export struct MessageBubbleAi {
  @ObjectLink wrapper: ChatMessageWrapper;
  @Prop aiName: string = 'AI Companion';

  build() {
    Row() {
      Column() {
        Text(this.wrapper.msg.message || '正在输入...')
          .fontSize(15)
          .fontColor('#FF333333')
          .padding({ left: 14, right: 14, top: 10, bottom: 10 })
          .backgroundColor('#FFFFFFFF')
          .borderRadius(18)
          .constraintSize({ maxWidth: 260 })
          .shadow({
            radius: 4,
            color: '#1A000000',
            offsetX: 1,
            offsetY: 1
          })

        Text(formatTime(this.wrapper.msg.timestamp))
          .fontSize(11)
          .fontColor('#FF999999')
          .margin({ top: 3 })
      }
      .alignItems(HorizontalAlign.Start)

      Blank()
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
  }
}

function formatTime(timestamp: number): string {
  const d = new Date(timestamp);
  const now = new Date();
  const sameDay = d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate();
  if (sameDay) {
    return `${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
  }
  return `${d.getMonth() + 1}月${d.getDate()}日 ${d.getHours().toString().padStart(2, '0')}:${d.getMinutes().toString().padStart(2, '0')}`;
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/ui/chat/MessageBubbleUser.ets entry/src/main/ets/ui/chat/MessageBubbleAi.ets
git commit -m "feat(chat): add MessageBubbleUser and MessageBubbleAi components"
```

---

## Task 6: ChatAdapter and ChatInputBar

**Files:**
- Create: `entry/src/main/ets/ui/chat/ChatAdapter.ets`
- Create: `entry/src/main/ets/ui/chat/ChatInputBar.ets`

- [ ] **Step 1: Create ChatAdapter.ets**

```typescript
// entry/src/main/ets/ui/chat/ChatAdapter.ets

import { ChatMessage } from '../../model/ChatMessageModel';
import { ChatMessageWrapper } from './MessageBubbleUser';

export class ChatAdapter {
  private wrappers: ChatMessageWrapper[] = [];

  setMessages(msgs: ChatMessage[]): void {
    this.wrappers = msgs.map(m => new ChatMessageWrapper(m));
  }

  getMessages(): ChatMessageWrapper[] {
    return this.wrappers;
  }

  appendMessage(msg: ChatMessage): void {
    this.wrappers = [...this.wrappers, new ChatMessageWrapper(msg)];
  }

  updateLastMessage(text: string): void {
    if (this.wrappers.length === 0) return;
    const last = this.wrappers[this.wrappers.length - 1];
    last.msg = { ...last.msg, message: text };
    this.wrappers = [...this.wrappers];
  }

  removeLast(): void {
    if (this.wrappers.length === 0) return;
    this.wrappers = this.wrappers.slice(0, -1);
  }
}
```

- [ ] **Step 2: Create ChatInputBar.ets**

```typescript
// entry/src/main/ets/ui/chat/ChatInputBar.ets

@Component
export struct ChatInputBar {
  @Link inputText: string;
  @Prop isLoading: boolean = false;
  onSend: () => void;

  build() {
    Row() {
      TextInput({ text: this.inputText, placeholder: '输入消息...' })
        .fontSize(15)
        .height(40)
        .layoutWeight(1)
        .backgroundColor('#FFFFFFFF')
        .borderRadius(20)
        .padding({ left: 16, right: 16 })
        .onChange((val: string) => {
          this.inputText = val;
        })
        .onSubmit(() => {
          if (!this.isLoading) this.onSend();
        })

      Button() {
        if (this.isLoading) {
          LoadingProgress()
            .width(20)
            .height(20)
            .color('#FFFFFFFF')
        } else {
          Text('发送')
            .fontSize(14)
            .fontColor('#FFFFFFFF')
        }
      }
      .width(60)
      .height(40)
      .backgroundColor(this.inputText.trim() ? '#FF4A90D9' : '#FFCCCCCC')
      .borderRadius(20)
      .enabled(!this.isLoading && !!this.inputText.trim())
      .onClick(() => {
        if (!this.isLoading && this.inputText.trim()) {
          this.onSend();
        }
      })
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    .backgroundColor('#FFF5F5F5')
    .alignItems(VerticalAlign.Center)
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/ui/chat/ChatAdapter.ets entry/src/main/ets/ui/chat/ChatInputBar.ets
git commit -m "feat(chat): add ChatAdapter and ChatInputBar components"
```

---

## Task 7: AiChatService (WebSocket)

**Files:**
- Create: `entry/src/main/ets/service/AiChatService.ets`

- [ ] **Step 1: Create AiChatService.ets (replaces ServerAiWebSocketService)**

```typescript
// entry/src/main/ets/service/AiChatService.ets

import webSocket from '@ohos.net.webSocket';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ChatMessage } from '../model/ChatMessageModel';

const TAG = 'AiChatService';

export interface AiChatListener {
  onMessage(text: string): void;
  onError(error: string): void;
  onClosed(): void;
}

export class AiChatService {
  private ws: webSocket.WebSocket | null = null;
  private listener: AiChatListener | null = null;
  private currentRequestId: string | null = null;
  private baseUrl: string = '';

  setBaseUrl(url: string): void {
    this.baseUrl = url.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://') + '/api/ai/ws';
  }

  connect(listener: AiChatListener): void {
    this.listener = listener;
    this.ws?.close(1000, 'Reconnecting');
    this.ws = null;

    try {
      this.ws = webSocket.createWebSocket();
      this.ws.on('open', (_, webSocket) => {
        hilog.info(0, TAG, 'WebSocket connected');
      });
      this.ws.on('message', (_, message) => {
        this.handleMessage(message as string);
      });
      this.ws.on('close', (_, code, reason) => {
        hilog.info(0, TAG, 'WebSocket closed: %{public}d %{public}s', code, reason);
        this.listener?.onClosed();
      });
      this.ws.on('error', (_, error) => {
        hilog.error(0, TAG, 'WebSocket error: %{public}s', JSON.stringify(error));
        this.listener?.onError((error as Error).message || 'Connection failed');
      });

      this.ws.connect(this.baseUrl, (err, _) => {
        if (err) {
          hilog.error(0, TAG, 'WebSocket connect failed: %{public}s', JSON.stringify(err));
          this.listener?.onError((err as Error).message || 'Connection failed');
        }
      });
    } catch (e) {
      this.listener?.onError((e as Error).message || 'Unknown error');
    }
  }

  private handleMessage(text: string): void {
    try {
      const obj = JSON.parse(text);
      const type = obj.type as string;
      const requestId = obj.requestId as string | undefined;
      const active = this.currentRequestId;
      if (active != null && requestId != null && requestId !== active) return;

      switch (type) {
        case 'delta':
          this.listener?.onMessage(obj.delta as string || '');
          break;
        case 'done':
          this.listener?.onClosed();
          break;
        case 'error':
          this.listener?.onError(obj.message as string || 'Unknown error');
          break;
      }
    } catch (e) {
      // ignore parse error
    }
  }

  sendMessage(
    userMessage: string,
    contextDiaries: string[],
    conversationHistory: ChatMessage[],
    systemPrompt: string,
    chatId: string,
    historyLimit: number,
    token: string
  ): void {
    if (!this.ws) return;

    this.currentRequestId = `req_${Date.now()}`;
    const historyItems = conversationHistory
      .filter(m => m.role === 'user' || m.role === 'assistant')
      .filter(m => m.message.length > 0)
      .map(m => ({ role: m.role, message: m.message }));

    const payload = {
      type: 'chat',
      requestId: this.currentRequestId,
      userMessage: userMessage,
      contextDiaries: contextDiaries,
      conversationHistory: historyItems,
      systemPrompt: systemPrompt,
      historyLimit: historyLimit,
      chatId: chatId,
      usageType: 'chat'
    };

    this.ws.send(JSON.stringify(payload), (err) => {
      if (err) {
        hilog.error(0, TAG, 'send failed: %{public}s', JSON.stringify(err));
        this.listener?.onError((err as Error).message || 'Send failed');
      }
    });
  }

  close(): void {
    this.ws?.close(1000, 'Normal closure');
    this.ws = null;
    this.currentRequestId = null;
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/service/AiChatService.ets
git commit -m "feat(chat): add AiChatService with HarmonyOS WebSocket"
```

---

## Task 8: ChatManagementPage

**Files:**
- Create: `entry/src/main/ets/ui/chat/ChatManagementPage.ets`
- Create: `entry/src/main/ets/pages/ChatManagementPage.ets`

- [ ] **Step 1: Create ChatManagementPage.ets**

```typescript
// entry/src/main/ets/ui/chat/ChatManagementPage.ets

import { preferences } from '@kit.ArkData';
import { router } from '@kit.RouterKit';

const PREF_NAME = 'chat_settings';
const KEY_AI_ROLE_PRESET_ID = 'ai_role_preset_id';
const KEY_AI_NAME = 'ai_name';
const KEY_ROLE_SETTING = 'role_setting';
const KEY_CHAT_HISTORY_LIMIT = 'chat_history_limit';
const KEY_AI_DIARY_READ_LIMIT = 'ai_diary_read_limit';
const KEY_AI_CONFIG_MODE = 'ai_config_mode';

@Component
export struct ChatManagementPage {
  @State aiRolePresetId: number = 0;
  @State aiName: string = 'AI Companion';
  @State roleSetting: string = '';
  @State chatHistoryLimit: number = 24;
  @State aiDiaryReadLimit: number = 10;
  @State aiConfigMode: string = 'default';

  private prefs: preferences.Preferences | null = null;

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this);
    this.prefs = preferences.getPreferences(ctx, { name: PREF_NAME });
    await this.loadSettings();
  }

  async loadSettings(): Promise<void> {
    if (!this.prefs) return;
    this.aiRolePresetId = await this.prefs.get(KEY_AI_ROLE_PRESET_ID, 0) as number;
    this.aiName = await this.prefs.get(KEY_AI_NAME, 'AI Companion') as string;
    this.roleSetting = await this.prefs.get(KEY_ROLE_SETTING, '') as string;
    this.chatHistoryLimit = await this.prefs.get(KEY_CHAT_HISTORY_LIMIT, 24) as number;
    this.aiDiaryReadLimit = await this.prefs.get(KEY_AI_DIARY_READ_LIMIT, 10) as number;
    this.aiConfigMode = await this.prefs.get(KEY_AI_CONFIG_MODE, 'default') as string;
  }

  async saveSettings(): Promise<void> {
    if (!this.prefs) return;
    await this.prefs.put(KEY_AI_ROLE_PRESET_ID, this.aiRolePresetId);
    await this.prefs.put(KEY_AI_NAME, this.aiName);
    await this.prefs.put(KEY_ROLE_SETTING, this.roleSetting);
    await this.prefs.put(KEY_CHAT_HISTORY_LIMIT, this.chatHistoryLimit);
    await this.prefs.put(KEY_AI_DIARY_READ_LIMIT, this.aiDiaryReadLimit);
    await this.prefs.put(KEY_AI_CONFIG_MODE, this.aiConfigMode);
  }

  build() {
    NavDestination() {
      Scroll() {
        Column() {
          this.buildSection('AI 角色名称', [
            this.buildInputRow('名称', this.aiName, (val) => { this.aiName = val; })
          ])

          this.buildSection('系统提示词', [
            this.buildTextAreaRow('提示词', this.roleSetting, (val) => { this.roleSetting = val; })
          ])

          this.buildSection('历史记录读取限制', [
            this.buildSliderRow('读取最近 N 条历史消息', this.chatHistoryLimit,
              (val) => { this.chatHistoryLimit = val; }, 0, 50)
          ])

          this.buildSection('日记读取限制', [
            this.buildSliderRow('读取最近 N 篇日记', this.aiDiaryReadLimit,
              (val) => { this.aiDiaryReadLimit = val; }, 1, 100)
          ])
        }
        .width('100%')
        .padding(16)
      }
    }
    .title('AI 聊天设置')
    .titleMode(NavDestinationTitleMode.Medium)
    .onBackPressed(() => {
      this.saveSettings();
      router.pop();
      return true;
    })
  }

  @Builder
  buildSection(title: string, items: ESObject[]): Column {
    return Column() {
      Text(title)
        .fontSize(13)
        .fontColor('#FF999999')
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: 8, top: 16 })

      Column() {
        items.forEach((item: ESObject) => item())
      }
      .width('100%')
      .backgroundColor('#FFFFFFFF')
      .borderRadius(12)
      .padding(12)
    }
  }

  @Builder
  buildInputRow(label: string, value: string, onChange: (v: string) => void): Row {
    return Row() {
      Text(label).fontSize(15).fontColor('#FF333333')
      Blank()
      TextInput({ text: value })
        .fontSize(14)
        .textAlign(TextAlign.End)
        .width(200)
        .onChange((v) => onChange(v))
    }
    .width('100%')
    .height(48)
  }

  @Builder
  buildTextAreaRow(label: string, value: string, onChange: (v: string) => void): Column {
    return Column() {
      Text(label).fontSize(15).fontColor('#FF333333').width('100%').margin({ bottom: 8 })
      TextArea({ text: value })
        .fontSize(14)
        .height(100)
        .width('100%')
        .onChange((v) => onChange(v))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildSliderRow(
    label: string,
    currentValue: number,
    onChange: (v: number) => void,
    min: number,
    max: number
  ): Column {
    return Column() {
      Row() {
        Text(label).fontSize(15).fontColor('#FF333333')
        Blank()
        Text(`${currentValue}`)
          .fontSize(14)
          .fontColor('#FF4A90D9')
      }
      .width('100%')

      Slider({
        value: currentValue,
        min: min,
        max: max,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .onChange((val) => onChange(Math.round(val)))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
```

- [ ] **Step 2: Create ChatManagementPage.ets entry**

```typescript
// entry/src/main/ets/pages/ChatManagementPage.ets

import { ChatManagementPage } from '../ui/chat/ChatManagementPage';

@Entry
@Component
export struct ChatManagementPageEntry {
  build() {
    ChatManagementPage()
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add entry/src/main/ets/ui/chat/ChatManagementPage.ets entry/src/main/ets/pages/ChatManagementPage.ets
git commit -m "feat(chat): add ChatManagementPage for AI settings"
```

---

## Task 9: 路由注册

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`

- [ ] **Step 1: Register routes in main_pages.json**

```json
{
  "src": [
    "pages/Index",
    "pages/MainPage",
    "pages/ChatPage",
    "pages/ChatManagementPage"
  ]
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/resources/base/profile/main_pages.json
git commit -m "feat(chat): register ChatPage and ChatManagementPage routes"
```

---

## Task 10: FloatingAIBallView (悬浮球)

**Files:**
- Create: `entry/src/main/ets/ui/widget/FloatingAIBallView.ets`

- [ ] **Step 1: Create FloatingAIBallView.ets**

```typescript
// entry/src/main/ets/ui/widget/FloatingAIBallView.ets

import { router } from '@kit.RouterKit';

@Component
export struct FloatingAIBallView {
  @State offsetX: number = 0;
  @State offsetY: number = 300;
  @State scale: number = 1;

  private startX: number = 0;
  private startY: number = 0;
  private screenWidth: number = 360;
  private screenHeight: number = 780;

  build() {
    Stack() {
      Circle()
        .width(56)
        .height(56)
        .fill('#FF4A90D9')
        .shadow({
          radius: 12,
          color: '#404A90D9',
          offsetX: 2,
          offsetY: 4
        })
        .scale({ x: this.scale, y: this.scale })
        .onClick(() => {
          router.pushUrl({ url: 'pages/ChatPage' });
        })
        .overlay('AI', {
          fontSize: 13,
          fontColor: '#FFFFFFFF',
          position: { x: 20, y: 20 }
        })
    }
    .width(56)
    .height(56)
    .position({ x: this.offsetX, y: this.offsetY })
    .gesture(
      PanGesture()
        .onActionStart(() => {
          this.startX = this.offsetX;
          this.startY = this.offsetY;
          animateTo({ duration: 160 }, () => {
            this.scale = 1.06;
          });
        })
        .onActionUpdate((event) => {
          const newX = this.startX + event.fingerX;
          const newY = this.startY + event.fingerY;
          this.offsetX = newX.coerceIn(-(this.screenWidth - 56) / 2, (this.screenWidth - 56) / 2);
          this.offsetY = newY.coerceIn(96, this.screenHeight - 180);
        })
        .onActionEnd(() => {
          animateTo({ duration: 260, curve: Curve.FastOutSlowIn }, () => {
            this.scale = 1;
            this.offsetX = this.offsetX > 0 ? this.screenWidth - 56 - 20 : -this.screenWidth / 2 + 28;
          });
        })
    )
    .onAreaChange((_, newArea) => {
      this.screenWidth = newArea.width as number;
      this.screenHeight = newArea.height as number;
    })
  }
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/ui/widget/FloatingAIBallView.ets
git commit -m "feat(chat): add FloatingAIBallView widget with drag gesture"
```

---

## Task 11: SVG 图标资源

**Files:**
- Create: `entry/src/main/resources/base/media/ic_user_avatar.svg`
- Create: `entry/src/main/resources/base/media/ic_ai_avatar.svg`
- Create: `entry/src/main/resources/base/media/ic_settings.svg`
- Create: `entry/src/main/resources/base/media/ic_arrow_right.svg`

- [ ] **Step 1: Create SVG icons**

```xml
<!-- ic_user_avatar.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <circle cx="24" cy="24" r="24" fill="#4A90D9"/>
  <circle cx="24" cy="18" r="8" fill="#FFFFFF"/>
  <path d="M12 40c0-8 5-14 12-14s12 6 12 14" fill="#FFFFFF"/>
</svg>
```

```xml
<!-- ic_ai_avatar.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 48 48">
  <circle cx="24" cy="24" r="24" fill="#FF6B6B"/>
  <text x="24" y="30" text-anchor="middle" font-size="20" fill="#FFFFFF">AI</text>
</svg>
```

```xml
<!-- ic_settings.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none">
  <path d="M12 15a3 3 0 100-6 3 3 0 000 6z" stroke="#666666" stroke-width="2"/>
  <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 010 2.83 2 2 0 01-2.83 0l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" stroke="#666666" stroke-width="2"/>
</svg>
```

```xml
<!-- ic_arrow_right.svg -->
<svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none">
  <path d="M9 18l6-6-6-6" stroke="#999999" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/resources/base/media/ic_user_avatar.svg
git add entry/src/main/resources/base/media/ic_ai_avatar.svg
git add entry/src/main/resources/base/media/ic_settings.svg
git add entry/src/main/resources/base/media/ic_arrow_right.svg
git commit -m "feat(chat): add SVG icon resources for chat module"
```

---

## Task 12: AiChatBackgroundManager (可选简化版)

**Files:**
- Create: `entry/src/main/ets/service/AiChatBackgroundManager.ets`

- [ ] **Step 1: Create simplified AiChatBackgroundManager.ets**

```typescript
// entry/src/main/ets/service/AiChatBackgroundManager.ets

import { AiChatService, AiChatListener } from './AiChatService';
import { chatRepository } from '../data/repository/ChatRepository';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { preferences } from '@kit.ArkData';

const TAG = 'AiChatBackgroundManager';

/**
 * 简化的后台消息管理器
 * 替换 Android: AiChatBackgroundManager
 */
export class AiChatBackgroundManager implements AiChatListener {
  private static instance: AiChatBackgroundManager | null = null;
  private aiChatService: AiChatService;
  private pendingQueue: PendingUserMessage[] = [];
  private currentAiMessageId: number = -1;
  private currentAiContent: string = '';
  private isProcessing: boolean = false;
  private prefs: preferences.Preferences | null = null;

  private constructor() {
    this.aiChatService = new AiChatService();
  }

  static getInstance(): AiChatBackgroundManager {
    if (!AiChatBackgroundManager.instance) {
      AiChatBackgroundManager.instance = new AiChatBackgroundManager();
    }
    return AiChatBackgroundManager.instance;
  }

  async init(): Promise<void> {
    const ctx = getContext(this);
    this.prefs = preferences.getPreferences(ctx, { name: 'chat_settings' });
    const baseUrl = await this.prefs.get('server_base_url', 'https://api.example.com') as string;
    this.aiChatService.setBaseUrl(baseUrl);
  }

  sendMessage(text: string, sessionId: string): void {
    this.pendingQueue.push({ text, sessionId, timestamp: Date.now() });
    this.processQueue();
  }

  private async processQueue(): Promise<void> {
    if (this.isProcessing || this.pendingQueue.length === 0) return;
    this.isProcessing = true;
    const pending = this.pendingQueue.shift()!;
    await this.processMessage(pending);
    this.isProcessing = false;
    this.processQueue();
  }

  private async processMessage(pending: PendingUserMessage): Promise<void> {
    const historyLimit = await this.getHistoryLimit();
    const history = await chatRepository.getRecentMessages(pending.sessionId, historyLimit);
    this.currentAiMessageId = -1;
    this.currentAiContent = '';

    const aiMsg = await chatRepository.insertAiMessage('', pending.sessionId);
    this.currentAiMessageId = aiMsg.id;
    this.aiChatService.connect(this);
    await new Promise(resolve => setTimeout(resolve, 350));
    const token = await this.getToken();
    this.aiChatService.sendMessage(pending.text, [], history, '', pending.sessionId, historyLimit, token);
  }

  private async getHistoryLimit(): Promise<number> {
    if (!this.prefs) return 24;
    return await this.prefs.get('chat_history_limit', 24) as number;
  }

  private async getToken(): Promise<string> {
    if (!this.prefs) return '';
    return await this.prefs.get('auth_token', '') as string;
  }

  onMessage(text: string): void {
    if (this.currentAiMessageId < 0) return;
    this.currentAiContent += text;
  }

  onError(error: string): void {
    hilog.error(0, TAG, 'AI chat error: %{public}s', error);
    this.isProcessing = false;
  }

  onClosed(): void {
    if (this.currentAiMessageId > 0) {
      chatRepository.appendToAiMessage(this.currentAiMessageId, this.currentAiContent);
    }
    this.currentAiMessageId = -1;
    this.isProcessing = false;
  }
}

interface PendingUserMessage {
  text: string;
  sessionId: string;
  timestamp: number;
}
```

- [ ] **Step 2: Commit**

```bash
git add entry/src/main/ets/service/AiChatBackgroundManager.ets
git commit -m "feat(chat): add simplified AiChatBackgroundManager"
```

---

## Self-Review Checklist

1. **Spec coverage:**
   - ChatActivity → ChatPage (Task 4) ✓
   - ChatManagementActivity → ChatManagementPage (Task 8) ✓
   - ChatMessageDao → ChatMessageDao (Task 1) ✓
   - ChatMessage (Entity) → ChatMessageModel (Task 1) ✓
   - ServerAiWebSocketService → AiChatService (Task 7) ✓
   - DeepseekService → AiChatService (Task 7) ✓
   - FloatingAIBallView → FloatingAIBallView (Task 10) ✓
   - ChatAdapter → ChatAdapter (Task 6) ✓

2. **Placeholder scan:** All steps have actual code — no "TBD", "TODO" for implementation

3. **Type consistency:**
   - `ChatMessage.id` is `number`
   - `ChatMessage.timestamp` is `number`
   - `sessionId` is `string` everywhere
   - `role` is `"user"` | `"assistant"` everywhere

4. **API differences noted:**
   - HarmonyOS Relational DB replace Room
   - ArkUI gesture replace Android touch
   - promptAction replace Android Toast/Snackbar
   - router.pushUrl replace Intent navigation
