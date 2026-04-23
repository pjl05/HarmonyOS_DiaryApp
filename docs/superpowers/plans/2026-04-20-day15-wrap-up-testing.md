# Day 15 — 收尾 + 测试 (Wrap-up + Testing)

> 目标：完成所有剩余模块（Vault 加密、AI 聊天集成），完成全量集成测试，验证整体功能完整性。

## 剩余工作量评估

| 模块 | 状态 | 说明 |
|------|------|------|
| Vault 加密 | **未实现** | Day 14 单独处理，HarmonyOS 加密 API |
| AI 聊天集成 | **部分** | Day 8-9 基础 UI，真实 API 接入 |
| Charts（ProfileActivity） | **未实现** | Canvas 自定义绘制，单独迭代 |
| 真实支付 SDK | **未实现** | Member/Super 真实支付 |
| 单元测试覆盖 | **缺口** | 各模块补充测试 |

---

## Task 1: Vault 加密模块

### 目标

实现日记加密存储功能，包括：密码设置/修改、验证、解密查看。

### HarmonyOS 加密 API

HarmonyOS 提供以下安全 API：

- `cryptoFramework` — 对称/非对称加密（AES、DES、RSA）
- ` huapigetssion` — 安全会话管理
- `@ohos.userIAM.userAuth` — 生物认证（已在 Day 13 覆盖）
- `EncryptedSharedPreferences` — Android 特有，HarmonyOS 等效方案

### 实现方案

**数据加密层**

```typescript
// EntryAbility.ets — 应用启动时初始化加密引擎
import cryptoFramework from '@ohos.security.cryptoFramework';

function generateAESKey(): cryptoFramework.SymKey {
    let keyGenerator = cryptoFramework.createSymKeyGenerator('AES256');
    let key = keyGenerator.generateSymKey();
    return key;
}

// 加密日记内容
async function encryptDiaryContent(content: string, password: string): Promise<string> {
    let cipher = cryptoFramework.createCipher('AES256|CBC|PKCS7');
    let key = generateAESKey();
    // ... 加密逻辑
}

// 解密日记内容
async function decryptDiaryContent(encrypted: string, password: string): Promise<string> {
    let decipher = cryptoFramework.createDecipher('AES256|CBC|PKCS7');
    // ... 解密逻辑
}
```

**加密存储**

```typescript
// VaultDao.ets — 加密日记的 RDB 读写
import data_relational from '@ohos.data.relational';

function insertEncryptedDiary(store: RDBStore, diary: EncryptedDiary): Promise<void> {
    let bucket: data_relational.ValuesBucket = {
        'id': diary.id,
        'content_encrypted': diary.encryptedContent,
        'iv': diary.iv, // 初始化向量
        'created_at': diary.createdAt
    };
    store.insert('encrypted_di_ary', bucket);
}
```

**密码验证**

```typescript
// VaultAuthManager.ets
import userIAM_auth from '@ohos.userIAM.userAuth';

function verifyVaultPassword(password: string): boolean {
    // 使用 PBKDF2 验证密码
    // 存储 salt + derived key
}

// 生物认证解锁
function unlockWithBiometric(callback: (result) => void): void {
    let authInstance = userIAM_auth.getAuthInstance();
    authInstance.auth();
}
```

### 文件清单

| 文件 | 职责 |
|------|------|
| `VaultCryptoManager.ets` | AES 加密/解密引擎 |
| `VaultDao.ets` | 加密日记 RDB CRUD |
| `VaultRepository.ets` | 加密数据访问接口 |
| `VaultViewModel.ets` | 密码/生物认证状态管理 |
| `VaultUnlockDialog.ets` | 解锁弹窗 UI |
| `EncryptedDiaryListPage.ets` | 加密日记列表页 |

### 验证点

- [ ] 密码设置后日记加密存储
- [ ] 密码验证成功后日记明文显示
- [ ] 生物认证快速解锁
- [ ] 错误密码后锁定机制

---

## Task 2: AI 聊天真实 API 集成

### 现状

Day 8-9 已完成：
- 聊天 UI（ChatPage.ets）
- AI 回复展示（气泡样式）
- 基础对话管理

### 接入真实 AI API

**配置读取**

```typescript
// AiApiService.ets
import http from '@ohos.net.http';

interface AiConfig {
    appId: string;
    apiKey: string;
    apiSecret: string;
    modelId: string;
    endpoint: string;
}

class AiApiService {
    private config: AiConfig;

    async sendMessage(prompt: string, context: ChatContext[]): Promise<string> {
        // 调用 AI API（AppID/Key/Secret 从 PreferencesHelper 读取）
        // 处理流式响应（SSE 或 轮询）
        // 错误处理：401/403/429/500
    }
}
```

**网络请求**

```typescript
// AiApiService.ets
async sendMessage(prompt: string): Promise<string> {
    let httpRequest = http.createHttp();
    let response = await httpRequest.request(
        'https://api.xxx.com/v1/chat',
        {
            method: http.RequestMethod.POST,
            header: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${this.config.apiKey}`
            },
            extraData: JSON.stringify({
                'model': this.config.modelId,
                'messages': [{ 'role': 'user', 'content': prompt }]
            })
        }
    );
    return JSON.parse(response.result as string).choices[0].message.content;
}
```

**错误处理**

```typescript
// 错误分类处理
function handleAiError(error: AiError): DialogMessage {
    switch (error.code) {
        case 'INVALID_API_KEY':
            return { type: 'error', text: 'API 密钥无效，请在设置中检查' };
        case 'QUOTA_EXCEEDED':
            return { type: 'warning', text: 'AI 调用额度已用完，请明日再试' };
        case 'NETWORK_ERROR':
            return { type: 'error', text: '网络连接失败，请检查网络' };
        default:
            return { type: 'error', text: 'AI 暂时无法回复，请稍后再试' };
    }
}
```

### 文件清单

| 文件 | 职责 |
|------|------|
| `AiApiService.ets` | AI API 网络请求 |
| `AiErrorHandler.ets` | 错误分类与用户提示 |
| `ChatViewModel.ets` | 增强：真实 API 调用 + 上下文管理 |
| `ChatPage.ets` | 增强：加载状态/错误状态 UI |

### 验证点

- [ ] AI 配置完整时真实回复
- [ ] API 密钥错误时友好提示
- [ ] 网络异常时降级处理

---

## Task 3: 支付 SDK 集成（可选）

### 现状

Day 14 的 MembershipPage 仅显示价格，无真实支付。

### HarmonyOS 支付

华为应用内支付 API：
- `IAP` SDK（In-App Purchase）
- 订单创建、支付、验证

### 实现方案

```typescript
// PaymentService.ets
import iap from '@hw-iap';

class PaymentService {
    async purchaseMembership(planId: string, period: string): Promise<PurchaseResult> {
        // 创建订单
        let order = await iap.createOrder({
            'productId': planId,
            'period': period
        });
        // 调起支付
        let result = await iap.startPayment(order);
        // 验证收据
        return result;
    }
}
```

> 注：如果项目不需要真实支付，保持 Day 14 的 mock 状态即可。

---

## Task 4: 全量 UI 集成验证

### 验证清单

| 页面 | 验证点 |
|------|--------|
| 登录注册 | 登录/注册流程、token 存储 |
| 首页 | 日记列表/日历视图/AI 助手 Tab 切换 |
| 日记详情 | 创建/编辑/删除、富文本 |
| 日记列表 | 左滑删除、分类筛选 |
| 日程 | 日程列表/新增/编辑/提醒 |
| AI 聊天 | 发送接收、流式输出 |
| 个人中心 | 头像/昵称/签名修改 |
| 设置 | 各项配置保存生效 |
| 会员页 | 价格展示、购买流程 |
| 日子页 | 日程联动、时间轴 |
| Vault | 加密日记解锁查看 |

### 测试用例

```typescript
// e2e/diary.spec.ts
import { test, expect } from '@playwright/test';

test('完整日记流程', async ({ page }) => {
    // 登录
    await page.goto('/pages/LoginPage');
    await page.fill('username', 'test@example.com');
    await page.fill('password', 'password123');
    await page.click('button[type="submit"]');

    // 创建日记
    await page.goto('/pages/DiaryEditorPage');
    await page.fill('title', '测试日记');
    await page.fill('content', '这是测试内容');
    await page.click('保存');

    // 验证出现在列表
    await page.goto('/pages/DiaryListPage');
    await expect(page.locator('text=测试日记')).toBeVisible();
});

test('Vault 加密流程', async ({ page }) => {
    await page.goto('/pages/VaultPage');
    await page.fill('password', '123456');
    await page.click('解锁');
    await expect(page.locator('text=加密日记')).toBeVisible();
});
```

---

## Task 5: 单元测试覆盖率补全

### 覆盖率目标

| 模块 | 最低覆盖率 |
|------|-----------|
| ViewModel | 80%+ |
| Repository | 80%+ |
| UseCase | 80%+ |
| DAO | 70%+ |

### 测试框架

HarmonyOS 测试：
- `ohos.test` — 单元测试
- `import test from '@ohos.test'`

### 测试示例

```typescript
// DayViewModel.test.ets
import test from '@ohos.test';

@Suite
class DayViewModelTest {
    @Test
    'elapsed days calculation'() {
        let today = new Date();
        let pastDate = new Date(today.getTime() - 30 * 24 * 60 * 60 * 1000);
        let elapsed = calculateElapsedDays(pastDate);
        expect(elapsed).assertEqual(30);
    }

    @Test
    'remaining days calculation'() {
        let target = new Date();
        target.setDate(target.getDate() + 7);
        let remaining = calculateRemainingDays(target);
        expect(remaining).assertEqual(7);
    }
}
```

---

## Task 6: 性能与稳定性

### 性能检查

- [ ] 首页加载 < 2s
- [ ] 日记列表滑动无卡顿（60fps）
- [ ] AI 响应展示无白屏
- [ ] 大图日记加载优化

### 稳定性检查

- [ ] 无 crash ANR
- [ ] 弱网络下 graceful degradation
- [ ] 数据存储完整性

---

## Task 7: 最终发布准备

### 清单

- [ ] 所有页面路由注册完成
- [ ] APP图标和启动页配置
- [ ] 权限声明（config.json）
- [ ] 应用签名配置
- [ ] 测试报告生成

### 目录结构（最终）

```
entry/src/main/
├── ets/
│   ├── entryability/
│   │   └── EntryAbility.ets          # 应用入口
│   ├── pages/
│   │   ├── MainPage.ets              # 主页（4Tab）
│   │   ├── LoginPage.ets             # 登录注册
│   │   ├── DiaryEditorPage.ets        # 日记编辑
│   │   ├── DiaryDetailPage.ets        # 日记详情
│   │   ├── SchedulePage.ets           # 日程
│   │   ├── ChatPage.ets               # AI 聊天
│   │   ├── ProfilePage.ets            # 个人中心
│   │   ├── SettingsPage.ets           # 设置
│   │   ├── MembershipPage.ets         # 会员
│   │   ├── DayPage.ets                # 日子
│   │   ├── DayPagerPage.ets           # 日子切换
│   │   ├── AboutPage.ets              # 关于
│   │   ├── SpecialThanksPage.ets       # 感谢
│   │   ├── FavoritesPage.ets          # 收藏
│   │   └── ExportHistoryPage.ets      # 导出历史
│   ├── components/
│   │   ├── DiaryCard.ets
│   │   ├── ScheduleItem.ets
│   │   ├── AiChatBubble.ets
│   │   ├── MembershipBenefits.ets
│   │   ├── AvatarView.ets
│   │   └── ...
│   ├── viewmodel/
│   │   ├── LoginViewModel.ets
│   │   ├── DiaryViewModel.ets
│   │   ├── ScheduleViewModel.ets
│   │   ├── ChatViewModel.ets
│   │   ├── ProfileViewModel.ets
│   │   ├── SettingsViewModel.ets
│   │   ├── MembershipViewModel.ets
│   │   ├── DayViewModel.ets
│   │   └── DayPagerViewModel.ets
│   ├── model/
│   │   ├── DiaryModel.ets
│   │   ├── ScheduleModel.ets
│   │   └── ...
│   ├── repository/
│   │   ├── DiaryRepository.ets
│   │   ├── ScheduleRepository.ets
│   │   ├── UserRepository.ets
│   │   └── ...
│   ├── dao/
│   │   ├── DiaryDao.ets
│   │   ├── ScheduleDao.ets
│   │   └── ...
│   └── utils/
│       ├── PreferencesHelper.ets
│       ├── DateTimeUtils.ets
│       ├── NetworkHelper.ets
│       └── ...
├── resources/
│   ├── base/element/
│   ├── base/media/
│   └── rawfile/
└── module.json5
```

---

## 时间估算

| Task | 复杂度 | 估算 |
|------|--------|------|
| Task 1: Vault 加密 | 高（加密+生物认证） | 4h |
| Task 2: AI 真实 API | 中（网络+错误处理） | 2h |
| Task 3: 支付 SDK | 低（可选） | 0.5h |
| Task 4: 全量 UI 验证 | 中（E2E 测试） | 3h |
| Task 5: 单元测试补全 | 中（覆盖率提升） | 2h |
| Task 6: 性能稳定性 | 低 | 1h |
| Task 7: 发布准备 | 低 | 0.5h |
| **总计** | | **~13h** |

---

## 下一步

1. 执行 Day 15 各 Task
2. 如有时间，增量实现 Charts（Canvas 自定义绘制）
3. 最终验证：15 天全部功能可用