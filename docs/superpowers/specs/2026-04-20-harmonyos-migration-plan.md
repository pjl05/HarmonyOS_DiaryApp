# DiaryApp 鸿蒙化迁移计划

**项目**：DiaryApp Android → HarmonyOS
**作者**：单人开发
**创建日期**：2026-04-20
**目标完成日期**：2026-05-05
**总工期**：15天

---

## 一、项目概述

### 1.1 源项目分析

| 属性 | Android 原始值 | 鸿蒙目标值 |
|------|---------------|------------|
| **项目名称** | DiaryApp | DiaryApp（保持一致） |
| **包名** | com.vhenge.diaryapp | com.vhenge.diaryapp（保持一致） |
| **版本** | 6.4.4.9 | 6.5.0.0（鸿蒙首发版） |
| **最低 SDK** | API 26 (Android 8.0) | API 4 (HarmonyOS 2.0) |
| **目标 SDK** | API 34 | API 9 (HarmonyOS 3.0) |

### 1.2 技术栈对比

| 层级 | Android | 鸿蒙 | 迁移策略 |
|------|---------|------|----------|
| **语言** | Kotlin 1.9.22 | ArkTS | 完全重写 |
| **UI 框架** | Android Views + ViewBinding | ArkUI | 批量重写 |
| **本地数据库** | Room 2.6.1 | HarmonyOS Relational DB | 逻辑复用，代码重写 |
| **网络请求** | Retrofit 2.9.0 + OkHttp 4.12 | HarmonyOS HTTP API | 逻辑复用，代码重写 |
| **图片加载** | Glide 4.16.0 | HarmonyOS Image | 功能对标实现 |
| **架构** | MVVM + Repository | MVVM + Repository | 模式保留 |
| **状态管理** | LiveData + ViewModel | @State + ViewModel | 功能对标 |
| **后端通信** | REST API + WebSocket | REST API + WebSocket | 保持不变 |

### 1.3 后端对接方案

**保持现有 Node.js Server 不变**

```
┌─────────────────────────────────────────────┐
│          HarmonyOS App (DiaryApp)            │
│                                              │
│  ┌─────────┐  ┌──────────┐  ┌─────────────┐ │
│  │ ArkUI   │  │ HTTP API │  │ WebSocket   │ │
│  └─────────┘  └──────────┘  └─────────────┘ │
└─────────────────────────────────────────────┘
                    │
                    │ HTTP/REST/WebSocket
                    ▼
┌─────────────────────────────────────────────┐
│     现有 Node.js Server (保持不变)            │
│     http://39.97.46.231:3000                │
└─────────────────────────────────────────────┘
```

---

## 二、模块划分与迁移顺序

### 2.1 模块优先级矩阵

| 优先级 | 模块名称 | 文件数 | 依赖关系 | 迁移顺序 |
|--------|----------|--------|----------|----------|
| **P0** | 项目基础框架 | - | 无 | Day 1 |
| **P0** | 登录/注册模块 | ~12 | 基础框架 | Day 2-3 |
| **P1** | 主界面 + 导航 | ~10 | 登录 | Day 4 |
| **P1** | 日记管理模块 | ~20 | 主界面 | Day 5-7 |
| **P2** | AI 聊天模块 | ~15 | 日记 | Day 8-9 |
| **P2** | 日历模块 | ~10 | 日记 | Day 10 |
| **P2** | 日程管理模块 | ~10 | 主界面 | Day 11 |
| **P3** | 日子模块 | ~8 | 日历 | Day 12 |
| **P3** | 设置/个人中心 | ~10 | 登录 | Day 13 |
| **P3** | 会员/关于/隐私等 | ~15 | 设置 | Day 14 |
| **P4** | 收尾 + 测试 | - | 全部 | Day 15 |

### 2.2 详细模块列表

#### P0 - 基础层
```
01. 项目框架搭建
   - DevEco Studio 项目创建
   - ArkTS 项目结构设计
   - 基础页面路由配置
   - HTTP Client 封装
   - WebSocket 封装
   - Token 管理器
   - 主题管理

02. 登录/注册模块
   - LoginActivity → LoginPage
   - ForgotPasswordActivity → ForgotPasswordPage
   - 注册流程（邮箱验证码）
   - 生物识别登录
   - Token 存储
```

#### P1 - 核心功能层
```
03. 主界面框架
   - MainActivity → MainPage
   - 底部导航栏实现
   - Fragment → NavigationDestination
   - ViewPager → Swiper/Tabs

04. 日记管理模块
   - DiaryEditActivity → DiaryEditPage
   - DiaryViewActivity → DiaryViewPage
   - DiaryPagerFragment → DiaryPager
   - DiaryGridAdapter → GridContainer
   - DiaryTimelineAdapter → ListContainer
   - 富文本编辑器实现
   - 图片选择/拍照
   - 天气/心情选择器
   - 收藏/草稿/回收站
```

#### P2 - 增值功能层
```
05. AI 聊天模块
   - ChatActivity → ChatPage
   - ChatAdapter → ChatList
   - ChatManagementActivity → ChatListPage
   - AI 角色选择器
   - WebSocket 实时通信
   - DeepSeek API 对接

06. 日历模块
   - CalendarFragment → CalendarPage
   - MonthPagerAdapter → Swiper
   - CalendarAdapter → CalendarGrid
   - 假期标注显示

07. 日程管理模块
   - ScheduleActivity → SchedulePage
   - ScheduleViewActivity → ScheduleDetailPage
   - ScheduleAlarmReceiver → AlarmAgent
   - 开机自启广播
```

#### P3 - 扩展功能层
```
08. 日子模块
   - DayViewActivity → DayPage
   - DayPagerFragment → DayPager
   - Timeline 时间轴实现

09. 个人设置模块
   - ProfileActivity → ProfilePage
   - SettingsActivity → SettingsPage
   - 主题切换
   - 语言设置
   - 数据导出

10. 会员/增值模块
   - MembershipPlansActivity → MembershipPage
   - AboutActivity → AboutPage
   - SpecialThanksActivity → ThanksPage
   - VersionHistoryActivity → VersionPage
   - 隐私政策页面
```

---

## 三、ArkUI 与 Android Views 对照表

### 3.1 布局容器对照

| Android | ArkUI | 说明 |
|---------|-------|------|
| LinearLayout | Column/Row | 线性布局 |
| RelativeLayout | Stack + Position | 相对定位 |
| FrameLayout | Stack | 层叠布局 |
| ConstraintLayout | 相对定位属性 | 约束布局 |
| ScrollView | Scroll + ListContainer | 滚动视图 |
| ViewPager | Swiper | 页面滑动 |
| TabLayout + ViewPager2 | Tabs + Swiper | Tab + 滑动 |

### 3.2 常用组件对照

| Android | ArkUI | 状态管理 |
|---------|-------|----------|
| TextView | Text | - |
| EditText | TextInput | @State |
| Button | Button | - |
| ImageView | Image | - |
| RecyclerView | ListContainer | @State + LazyForEach |
| GridView | GridContainer | @State + LazyForEach |
| CardView | Card | - |
| CheckBox | Checkbox | @State |
| RadioButton | Radio | @State |
| Switch | Toggle | @State |
| ProgressBar | Progress | - |
| SeekBar | Slider | @State |
| WebView | WebView | - |
| RecyclerView.ItemDecoration | CustomListItem |

### 3.3 特殊组件对照

| Android 功能 | ArkUI 实现 | 难度 |
|-------------|-----------|------|
| Dialog | Custom Dialog / AlertDialog | 中 |
| BottomSheet | BottomSheet / 半模态弹窗 | 中 |
| PopupWindow | Custom Popup / Menu | 中 |
| DrawerLayout | SideBarContainer | 低 |
| FloatingActionButton | Button + FloatLayer | 低 |
| BottomNavigationView | BottomTabBar | 低 |
| Toolbar | NavigationTitleBar | 低 |
| SwipeRefreshLayout | Refresh | 低 |
| ViewBinding | @Track + @State | - |

### 3.4 动画对照

| Android | ArkUI | 说明 |
|---------|-------|------|
| ObjectAnimator | animate | 属性动画 |
| AnimationDrawable | ImageAnimator | 帧动画 |
| Transition | animateTo + transitions | 过渡动画 |
| SharedElement | transitionEffect | 共享元素 |

---

## 四、详细迁移步骤（按天）

### Day 1：项目框架搭建

```
任务清单：
□ 1. 安装 DevEco Studio（若未安装）
□ 2. 创建 HarmonyOS 项目，选择 Empty Ability 模板
□ 3. 配置项目基本信息（包名、应用名）
□ 4. 创建项目目录结构：
      /entry/src/main/ets/
      ├── pages/
      ├── components/
      ├── viewmodels/
      ├── models/
      ├── services/
      ├── utils/
      └── common/
□ 5. 安装 HarmonyOS SDK（API 9）
□ 6. 配置网络权限：
      ohos.permission.INTERNET
      ohos.permission.ACCESS_NETWORK_STATE
□ 7. 基础工具类：
      - Logger（日志工具）
      - Preferences（轻量存储，对标 SharedPreferences）
      - Router（页面路由）
□ 8. HTTP 客户端封装：
      - HttpRequest 封装
      - 统一错误处理
      - Token 自动注入拦截器
□ 9. WebSocket 客户端封装（参考 Android 的 ServerAiWebSocketService）
□ 10. 创建基础页面：MainPage（空壳）
□ 11. 验证编译通过
```

**产出**：可运行的基础鸿蒙项目

---

### Day 2-3：登录/注册模块

```
任务清单（Day 2）：
□ 1. 创建 LoginPage 页面
□ 2. 实现登录表单 UI（账号、密码输入）
□ 3. 实现登录按钮点击事件
□ 4. 调用登录 API（对标 ApiService.login）
□ 5. Token 存储（Preferences）
□ 6. 登录成功后跳转 MainPage
□ 7. 实现"记住密码"功能
□ 8. 实现"注册"入口
□ 9. 实现注册页面 UI
□ 10. 实现发送验证码功能（对标 /api/auth/sendCode）

任务清单（Day 3）：
□ 11. 实现注册流程（获取验证码 → 填写注册信息 → 提交）
□ 12. 实现"忘记密码"页面
□ 13. 实现生物识别登录（参考 Android BiometricPrompt）
□ 14. 添加登录页动画效果（对标 BubbleDanmakuView）
□ 15. UI 自适应（不同屏幕尺寸）
□ 16. 错误提示 UI（对标 Android Toast/Snackbar）
□ 17. 登录模块测试
```

**产出**：完整的登录注册功能

**ArkUI 关键技术点**：
```typescript
// 登录表单状态管理
@State username: string = ''
@State password: string = ''
@State isLoading: boolean = false

// 登录请求
async login() {
  this.isLoading = true
  try {
    const response = await authApi.login(this.username, this.password)
    AppStorage.Set('token', response.data.token)
    router.replaceUrl({ url: 'pages/MainPage' })
  } catch (error) {
    prompt.showToast({ message: '登录失败' })
  } finally {
    this.isLoading = false
  }
}
```

---

### Day 4：主界面 + 导航框架

```
任务清单：
□ 1. 实现 MainPage 布局（底部 TabBar）
□ 2. 创建导航目标页面（空壳）：
      - Index（首页/日记）
      - Calendar（日历）
      - Chat（聊天）
      - Schedule（日程）
      - Me（个人中心）
□ 3. 实现底部导航切换逻辑
□ 4. 实现页面懒加载（对标 Android Fragment 懒加载）
□ 5. 主页面标题栏实现
□ 6. 全局悬浮球组件（FloatingAIBallView → FloatingAIBallComponent）
□ 7. 主题管理（Light/Dark，对标 ThemeManager）
□ 8. 语言切换（对标 LanguageManager）
□ 9. MainPage 与各子页面跳转协议
□ 10. 测试导航流畅度
```

**产出**：完整的应用框架和导航

---

### Day 5-7：日记管理模块（核心）

```
任务清单（Day 5）：
□ 1. 创建日记列表页面 DiaryListPage
□ 2. 实现日记网格视图（GridContainer，对标 DiaryGridAdapter）
□ 3. 实现日记时间轴视图（ListContainer + 自定义时间轴组件）
□ 4. 实现日记列表数据请求（对标 diaryrepository）
□ 5. 实现下拉刷新（Refresh 组件）
□ 6. 实现上拉加载更多（LazyForEach 懒加载）
□ 7. 实现日记筛选（收藏/全部/草稿/回收站）

任务清单（Day 6）：
□ 8. 创建日记编辑页面 DiaryEditPage
□ 9. 实现富文本编辑器（对标 RichHtmlParser）
□ 10. 实现图片选择器（PhotoView / Album）
□ 11. 实现图片预览（ZoomImageView → ImageViewer）
□ 12. 实现天气选择器（自定义组件）
□ 13. 实现心情选择器（自定义表情选择）
□ 14. 实现日记保存（新建/编辑）

任务清单（Day 7）：
□ 15. 创建日记详情页面 DiaryViewPage
□ 16. 实现日记详情展示（图片、文字、天气、心情）
□ 17. 实现日记编辑入口
□ 18. 实现日记删除（软删除到回收站）
□ 19. 实现日记收藏/取消收藏
□ 20. 实现分享功能（对标 ShareCompat）
□ 21. 日记模块测试
```

**产出**：完整的日记管理功能

**ArkUI 关键技术点**：
```typescript
// 懒加载列表（对标 RecyclerView）
ListContainer({ listDirection: Axis.Vertical }) {
  LazyForEach(this.diaryList, (diary: Diary) => {
    ListItem() {
      DiaryCard({ diary: diary })
    }
  }, diary => diary.id)
}

// 图片选择
photoViewPicker.select(PhotoView.selectOptions(PhotoSelectMode.MULTIPLE))
```

---

### Day 8-9：AI 聊天模块

```
任务清单（Day 8）：
□ 1. 创建聊天列表页面 ChatListPage（对标 ChatManagementActivity）
□ 2. 实现聊天页面 ChatPage（对标 ChatActivity）
□ 3. 实现聊天消息列表（ChatAdapter → ChatMessageList）
□ 4. 实现消息气泡 UI（对标 ChatMessageActionPopup）
□ 5. 实现 AI 角色预设选择器（对标 AiRolePresetPickerBottomSheet）
□ 6. 实现发送消息逻辑
□ 7. 实现 WebSocket 连接（对标 ServerAiWebSocketService）

任务清单（Day 9）：
□ 8. 实现流式响应显示（打字机效果）
□ 9. 实现聊天背景管理（对标 AiChatBackgroundManager）
□ 10. 实现上下文注入（读取最近日记作为上下文）
□ 11. 实现消息操作（复制/删除/重新生成）
□ 12. 实现 DeepSeek API 对接（对标 DeepseekService）
□ 13. 实现聊天历史本地存储（HarmonyOS Relational DB）
□ 14. 聊天模块测试
```

**产出**：完整的 AI 聊天功能

---

### Day 10：日历模块

```
任务清单：
□ 1. 创建日历页面 CalendarPage
□ 2. 实现月历视图（CalendarGrid）
□ 3. 实现月历滑动切换（Swiper）
□ 4. 实现假期标注显示（对标 HolidayUtils）
□ 5. 实现日期点击事件（跳转到日记/日子页面）
□ 6. 实现日历与日记关联显示
□ 7. 实现日历快捷入口
□ 8. 日历模块测试
```

---

### Day 11：日程管理模块

```
任务清单：
□ 1. 创建日程列表页面 ScheduleListPage
□ 2. 创建日程详情页面 ScheduleDetailPage
□ 3. 实现日程创建/编辑表单
□ 4. 实现日程提醒功能（对标 AlarmManager → HarmonyOS ReminderAgent）
□ 5. 实现开机自启广播接收（WantAgent）
□ 6. 实现日程全屏闹钟界面（对标 ScheduleAlarmFullscreenActivity）
□ 7. 实现日程重复规则（每天/每周/每月等）
□ 8. 日程模块测试
```

---

### Day 12：日子模块

```
任务清单：
□ 1. 创建日子页面 DayPage（对标 DayViewActivity）
□ 2. 实现日子时间轴视图（对标 DayTimelineAdapter）
□ 3. 实现日期计算（对标 DayTimeUtils）
□ 4. 实现纪念日显示
□ 5. 实现日子与日记关联
□ 6. 日子模块测试
```

---

### Day 13：个人设置模块

```
任务清单：
□ 1. 创建个人中心页面 ProfilePage
□ 2. 实现设置页面 SettingsPage
□ 3. 实现主题切换（对标 ThemeManager）
□ 4. 实现语言切换（对标 LanguageManager）
□ 5. 实现数据导出功能（对标 DiaryExportActivity）
□ 6. 实现保险箱功能（对标 VaultActivity）
□ 7. 实现数据迁移（对标 TransferDataActivity）
□ 8. 设置模块测试
```

---

### Day 14：会员/增值模块

```
任务清单：
□ 1. 实现会员套餐页面（对标 MembershipPlansActivity）
□ 2. 实现会员权益展示
□ 3. 实现关于页面（对标 AboutActivity）
□ 4. 实现特别感谢页面（对标 SpecialThanksActivity）
□ 5. 实现版本历史页面（对标 VersionHistoryActivity）
□ 6. 实现隐私政策页面
□ 7. 实现星空星球模块（对标 StarfieldActivity/ViewActivity/MineActivity）
□ 8. 实现爱情专区模块（对标 LoveZoneActivity 等）
□ 9. 增值模块测试
```

---

### Day 15：收尾 + 测试

```
任务清单：
□ 1. 完整功能回归测试
□ 2. UI 还原度检查（对比 Android 原版）
□ 3. 性能测试（启动速度、页面切换流畅度）
□ 4. 适配测试（不同屏幕尺寸）
□ 5. 修复发现的问题
□ 6. 应用签名打包
□ 7. 生成 HAP 安装包
□ 8. 撰写发布说明
□ 9. 备份项目
□ 10. 提交代码到仓库
```

---

## 五、ArkUI 开发要点汇总

### 5.1 状态管理

| Android | ArkUI |
|---------|-------|
| LiveData | @State + @Link |
| ViewModel | @State + @StorageLink |
| SharedPreferences | AppStorage / UserinfoRepository |

```typescript
// ViewModel 等效实现
class DiaryViewModel {
  @State diaryList: Diary[] = []
  @State isLoading: boolean = false

  // 对标 LiveData 的观察者模式
  aboutToAppear() {
    this.loadDiaries()
  }
}
```

### 5.2 网络请求

```typescript
// HarmonyOS HTTP 请求封装
import http from '@ohos.net.http';

async request<T>(url: string, options: HttpRequestOptions): Promise<T> {
  let httpRequest = http.createHttp();
  try {
    const result = await httpRequest.request(url, {
      method: options.method || 'GET',
      header: options.headers || {},
      extraData: options.body
    });
    return JSON.parse(result.result as string) as T;
  } finally {
    httpRequest.destroy();
  }
}
```

### 5.3 本地数据库

```typescript
// HarmonyOS Relational DB（对标 Room）
import relationalStore from '@ohos.data.relationalStore';

const STORE_CONFIG = {
  name: 'diary.db',
  securityLevel: relationalStore.SecurityLevel.S1
};

// 创建表
rdb.insert('diaries', {
  'id': 1,
  'title': '标题',
  'content': '内容',
  'mood': 'happy',
  'weather': 'sunny',
  'createTime': Date.now()
});
```

### 5.4 页面路由

```typescript
// HarmonyOS 路由（对标 Android Intent + Navigation Component）
import router from '@ohos.router';

// 跳转到详情页
router.pushUrl({
  url: 'pages/DiaryDetailPage',
  params: {
    diaryId: diary.id
  }
});

// 接收参数
onPageShow() {
  const params = router.getParams() as NavParams;
  this.diaryId = params.diaryId;
}
```

---

## 六、避坑指南

### 6.1 UI 适配坑

| 坑点 | 解决方案 |
|------|----------|
| 圆角效果不一致 | 使用 borderRadius 属性，统一设计规范 |
| 字体大小差异 | 使用 vp/sp 单位，参考 ArkUI 字体规范 |
| 动画性能差异 | 使用 renderGroup 优化，减少 animateTo 嵌套 |
| 列表滑动流畅度 | 使用 LazyForEach 懒加载，避免一次性渲染 |

### 6.2 网络请求坑

| 坑点 | 解决方案 |
|------|----------|
| 明文 HTTP 请求被拦截 | 在 config.json 中添加 cleartextPermitted: true |
| HTTPS 证书验证 | 开发环境可禁用，正式环境配置证书 |
| 请求超时 | 设置合理的 timeout（建议 30s） |
| 文件上传 | 使用分段上传，参考 HarmonyOS 上传 API |

### 6.3 数据存储坑

| 坑点 | 解决方案 |
|------|----------|
| 数据库升级 | 使用版本管理，参考 relationalStore 版本迁移 |
| 大数据量存储 | 分页查询，避免一次性加载全部数据 |
| 敏感数据存储 | 使用 secureStorage 加密存储 |

### 6.4 权限申请坑

| 坑点 | 解决方案 |
|------|----------|
| 权限未声明 | 在 config.json 中添加 requestPermissions |
| 运行时权限 | 使用 abilityAccessCtrl 动态申请 |
| 权限被拒绝 | 提供降级方案，说明权限必要性 |

---

## 七、测试计划

### 7.1 测试矩阵

| 测试类型 | 测试内容 | 测试工具 |
|---------|---------|----------|
| **单元测试** | ViewModel、Repository、工具类 | HarmonyOS Unit Test |
| **组件测试** | 自定义组件渲染 | 手动测试 |
| **集成测试** | 模块间交互 | 手动测试 |
| **UI 还原测试** | 与 Android 原版对比 | 截图对比 |
| **适配测试** | 不同设备 | 真机测试 |
| **性能测试** | 启动速度、内存占用 | DevEco Profiler |

### 7.2 验收标准

- [ ] 所有功能与 Android 原版一致
- [ ] UI 还原度 ≥ 90%
- [ ] 应用启动时间 < 3s
- [ ] 页面切换流畅，无明显卡顿
- [ ] 在 3 种以上设备测试通过
- [ ] HAP 包签名正常，可上架应用市场

---

## 八、工具和环境清单

| 工具 | 用途 | 获取方式 |
|------|------|----------|
| DevEco Studio | 鸿蒙 IDE | [华为开发者官网](https://developer.huawei.com/consumer/cn/deveco-studio/) |
| HarmonyOS SDK | 开发套件 | DevEco Studio 内安装 |
| Node.js | 后端运行 | 保持现有 |
| MySQL | 数据库 | 保持现有 |
| Git | 版本控制 | 保持现有 |

---

## 九、风险管理

| 风险 | 影响 | 应对措施 |
|------|------|----------|
| ArkUI 组件不支持某功能 | 进度延迟 | 降级方案：使用 WebView 加载 H5 |
| WebSocket 实现复杂 | 进度延迟 | 先用 HTTP 轮询替代 |
| 性能不达标 | 无法上线 | 分阶段上线，核心优先 |
| 第三方 SDK 不兼容 | 功能缺失 | 自研或寻找替代方案 |

---

## 十、附录

### A. API 接口清单（保持不变）

| 端点 | 方法 | 说明 |
|------|------|------|
| /api/auth/register | POST | 用户注册 |
| /api/auth/login | POST | 用户登录 |
| /api/auth/sendCode | POST | 发送验证码 |
| /api/auth/forgotPassword | POST | 忘记密码 |
| /api/diary | GET/POST | 日记列表/创建 |
| /api/diary/:id | GET/PUT/DELETE | 日记详情/修改/删除 |
| /api/diary/export | POST | 导出日记 |
| /api/chat | POST | AI 聊天 |
| /api/schedule | GET/POST | 日程列表/创建 |
| /api/member/plans | GET | 会员套餐 |

### B. 项目文件清单

**核心模块文件统计**：

```
登录模块：12 个文件
主界面：10 个文件
日记管理：20 个文件
AI 聊天：15 个文件
日历：10 个文件
日程：10 个文件
日子：8 个文件
设置/个人：10 个文件
会员/增值：15 个文件
其他：10 个文件

总计：约 120 个文件需要迁移/重写
```

---

**文档版本**：1.0
**最后更新**：2026-04-20
