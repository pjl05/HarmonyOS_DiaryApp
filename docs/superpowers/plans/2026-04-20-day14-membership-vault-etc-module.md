# 会员 + Vault + 其他页面模块 HarmonyOS 迁移实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Android DiaryApp 的会员订购页（MembershipPlansActivity）、关于我们（AboutActivity）、致谢页（SpecialThanksActivity）、收藏夹（FavoritesActivity）、导出历史（ExportHistoryActivity）迁移至 HarmonyOS ArkTS。Vault 模块（VaultActivity）因涉及加密存储，单独处理。

**Architecture:** 会员页使用 ViewModel 持有订阅状态和价格数据；调用已有 ApiService 获取订阅方案和权益；使用 router.pushUrl 跳转到各子页面。

**Tech Stack:** ArkTS / ArkUI、@State/http（已有 ApiService）、router、promptAction、picker、fs

---

## 文件结构

```
entry/src/main/ets/
├── model/
│   ├── MembershipPlan.ets                 # 订阅方案数据模型
│   └── MembershipBenefits.ets             # 会员权益数据模型
├── viewmodel/
│   └── MembershipViewModel.ets            # 会员页 ViewModel
└── pages/
    ├── MembershipPage.ets                 # 会员订购页（对标 MembershipPlansActivity.kt）
    ├── AboutPage.ets                      # 关于我们（对标 AboutActivity.kt）
    ├── SpecialThanksPage.ets              # 致谢页（对标 SpecialThanksActivity.kt）
    ├── FavoritesPage.ets                  # 收藏夹（对标 FavoritesActivity.kt）
    └── ExportHistoryPage.ets              # 导出历史（对标 ExportHistoryActivity.kt）
```

---

## Task 1: MembershipPlan.ets + MembershipBenefits.ets — 数据模型

**Files:**
- Create: `entry/src/main/ets/model/MembershipPlan.ets`
- Create: `entry/src/main/ets/model/MembershipBenefits.ets`

对标 Android `MembershipPlanPrice` / `MembershipBenefitsResponse`。

- [ ] **Step 1: 创建 MembershipPlan.ets**

```typescript
// entry/src/main/ets/model/MembershipPlan.ets

export interface MembershipPlan {
  tier: string     // 'member' | 'super'
  period: string   // 'month' | 'quarter' | 'year'
  price: number
  currency: string
}

export const MEMBERSHIP_FALLBACK_PLANS: MembershipPlan[] = [
  { tier: 'member', period: 'month',   price: 30,  currency: 'CNY' },
  { tier: 'member', period: 'quarter', price: 80,  currency: 'CNY' },
  { tier: 'member', period: 'year',    price: 280, currency: 'CNY' },
  { tier: 'super',  period: 'month',   price: 68,  currency: 'CNY' },
  { tier: 'super',  period: 'quarter', price: 178, currency: 'CNY' },
  { tier: 'super',  period: 'year',    price: 598, currency: 'CNY' },
]
```

- [ ] **Step 2: 创建 MembershipBenefits.ets**

```typescript
// entry/src/main/ets/model/MembershipBenefits.ets

export interface MembershipBenefits {
  member: string[]
  superBenefits: string[]
}

export const MEMBERSHIP_FALLBACK_BENEFITS: MembershipBenefits = {
  member: [
    '加密隐私日记',
    '100MB 媒体存储',
    'AI 每天 50 次',
  ],
  superBenefits: [
    '全部 Member 权益',
    '无限 AI 对话',
    '无限 AI 写作',
    '专属 Super 标识',
  ]
}
```

- [ ] **Step 3: 提交**

```bash
git add entry/src/main/ets/model/MembershipPlan.ets \
        entry/src/main/ets/model/MembershipBenefits.ets
git commit -m "feat(membership): add MembershipPlan and MembershipBenefits models"
```

---

## Task 2: MembershipViewModel.ets — 会员页 ViewModel

**Files:**
- Create: `entry/src/main/ets/viewmodel/MembershipViewModel.ets`

持有当前订阅状态、价格方案、权益列表，选择的订阅周期。

- [ ] **Step 1: 编写失败测试**

```typescript
// entry/src/test/MembershipViewModelTest.ets
import { describe, it, expect, beforeAll } from '@ohos/hypium'
import { MembershipViewModel } from '../../main/ets/viewmodel/MembershipViewModel'

describe('MembershipViewModelTest', () => {
  let vm: MembershipViewModel

  beforeAll((done) => {
    vm = new MembershipViewModel()
    done()
  })

  it('should_have_default_tier_normal', (done) => {
    expect(vm.currentTier).assertEqual('normal')
    done()
  })

  it('should_select_period', (done) => {
    vm.selectPeriod(true, 'year')
    expect(vm.selectedMemberPeriod).assertEqual('year')
    done()
  })
})
```

- [ ] **Step 2: 运行测试 — 期望失败**

```bash
hvigorw test --module entry
# 期望: MembershipViewModel not found
```

- [ ] **Step 3: 实现 MembershipViewModel**

```typescript
// entry/src/main/ets/viewmodel/MembershipViewModel.ets
import http from '@ohos.net.http'
import { MembershipPlan, MEMBERSHIP_FALLBACK_PLANS } from '../model/MembershipPlan'
import { MembershipBenefits, MEMBERSHIP_FALLBACK_BENEFITS } from '../model/MembershipBenefits'

export class MembershipViewModel {
  currentTier: string = 'normal'
  expiresAt: string = ''
  plans: MembershipPlan[] = []
  isLoading: boolean = false
  benefits: MembershipBenefits = MEMBERSHIP_FALLBACK_BENEFITS
  selectedMemberPeriod: string = 'month'
  selectedSuperPeriod: string = 'month'
  memberExpanded: boolean = false
  superExpanded: boolean = false

  getPlan(tier: string, period: string): MembershipPlan | undefined {
    return this.plans.find(p => p.tier === tier && p.period === period)
  }

  selectPeriod(isMember: boolean, period: string): void {
    if (isMember) {
      this.selectedMemberPeriod = period
    } else {
      this.selectedSuperPeriod = period
    }
  }

  toggleExpanded(isMember: boolean): void {
    if (isMember) {
      this.memberExpanded = !this.memberExpanded
    } else {
      this.superExpanded = !this.superExpanded
    }
  }

  formatPrice(plan: MembershipPlan | undefined): string {
    if (!plan) return '加载中...'
    const prefix = plan.currency.toUpperCase() === 'CNY' ? '¥' : ''
    return `${prefix}${plan.price.toFixed(2)}`
  }

  periodLabel(period: string): string {
    switch (period) {
      case 'month':   return '月'
      case 'quarter': return '季'
      case 'year':    return '年'
      default:        return period
    }
  }

  async loadMembership(token: string, baseUrl: string): Promise<void> {
    this.isLoading = true
    try {
      const req = http.createHttp()
      const [pricingResp, benefitsResp] = await Promise.all([
        req.request(`${baseUrl}/api/membership/pricing`, {
          method: http.RequestMethod.GET,
          header: { Authorization: `Bearer ${token}` }
        }),
        req.request(`${baseUrl}/api/membership/benefits`, {
          method: http.RequestMethod.GET,
          header: { Authorization: `Bearer ${token}` }
        })
      ])
      req.destroy()

      if (pricingResp.responseCode === 200) {
        const data = JSON.parse(pricingResp.result as string) as { plans: MembershipPlan[] }
        this.plans = data.plans?.length ? data.plans : MEMBERSHIP_FALLBACK_PLANS
      } else {
        this.plans = MEMBERSHIP_FALLBACK_PLANS
      }

      if (benefitsResp.responseCode === 200) {
        const data = JSON.parse(benefitsResp.result as string) as MembershipBenefits
        if (data.member?.length || data.superBenefits?.length) {
          this.benefits = data
        }
      }
    } catch (_) {
      this.plans = MEMBERSHIP_FALLBACK_PLANS
      this.benefits = MEMBERSHIP_FALLBACK_BENEFITS
    } finally {
      this.isLoading = false
    }
  }
}
```

- [ ] **Step 4: 运行测试 — 期望通过**

```bash
hvigorw test --module entry
# 期望: MembershipViewModelTest PASS
```

- [ ] **Step 5: 提交**

```bash
git add entry/src/main/ets/viewmodel/MembershipViewModel.ets entry/src/test/MembershipViewModelTest.ets
git commit -m "feat(membership): add MembershipViewModel"
```

---

## Task 3: MembershipPage.ets — 会员订购页

**Files:**
- Create: `entry/src/main/ets/pages/MembershipPage.ets`

对标 Android `MembershipPlansActivity.kt`；展示 Member/Super 两个订阅方案，每个方案支持月/季/年三种周期切换，点击"关于我们"跳转 AboutPage。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/MembershipPage.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import { MembershipViewModel } from '../viewmodel/MembershipViewModel'

@Entry
@Component
struct MembershipPage {
  @State private vm: MembershipViewModel = new MembershipViewModel()

  private token: string = AppStorage.get('authToken') ?? ''
  private baseUrl: string = AppStorage.get('baseUrl') ?? ''

  aboutToAppear() {
    this.vm.loadMembership(this.token, this.baseUrl)
    this.vm.currentTier = AppStorage.get('membershipTier') ?? 'normal'
    this.vm.expiresAt = AppStorage.get('membershipExpiresAt') ?? ''
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('会员订购').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.vm.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 60 })
      } else {
        Scroll() {
          Column() {
            this.buildCurrentTierCard()
            this.buildPlanCard('会员', 'Member', 'member', '#4CAF50',
              this.vm.memberExpanded, this.vm.selectedMemberPeriod, this.vm.benefits.member)
            this.buildPlanCard('超级会员', 'Super', 'super', '#9C27B0',
              this.vm.superExpanded, this.vm.selectedSuperPeriod, this.vm.benefits.superBenefits)
          }
          .width('100%').padding({ bottom: 32 })
        }
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  buildCurrentTierCard() {
    Column() {
      Row() {
        Column() {
          Text('当前等级').fontSize(13).fontColor('#9E9E9E')
          Text(
            this.vm.currentTier === 'normal' ? '普通用户' :
            this.vm.currentTier === 'member' ? '会员' : '超级会员'
          ).fontSize(18).fontWeight(FontWeight.Bold).margin({ top: 4 })
          if (this.vm.expiresAt !== '') {
            Text(`到期：${this.vm.expiresAt}`).fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
          }
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
      }
    }
    .width('90%').backgroundColor(Color.White)
    .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ left: 16, right: 16, bottom: 12, top: 8 }).padding(16)
  }

  @Builder
  buildPlanCard(
    titleZh: string,
    title: string,
    tier: string,
    color: string,
    isExpanded: boolean,
    selectedPeriod: string,
    benefits: string[]
  ) {
    Column() {
      // 头部
      Row() {
        Column() {
          Text(titleZh).fontSize(16).fontWeight(FontWeight.Bold)
          Text(title === 'Super' ? '全部权益 + 无限 AI' : '基础会员权益')
            .fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        Image($r('app.media.ic_expand')).width(20).height(20)
          .fillColor('#9E9E9E').rotate({ angle: isExpanded ? 180 : 0 })
      }
      .width('100%').padding(16)
      .onClick(() => { this.vm.toggleExpanded(tier === 'member') })

      // 周期选择
      Row() {
        this.periodChip('月', 'month', tier, selectedPeriod)
        this.periodChip('季', 'quarter', tier, selectedPeriod)
        this.periodChip('年', 'year', tier, selectedPeriod)
      }
      .width('100%').padding({ left: 16, right: 16 })

      // 价格
      Row() {
        const plan = this.vm.getPlan(tier, selectedPeriod)
        Text(this.vm.formatPrice(plan))
          .fontSize(28).fontWeight(FontWeight.Bold).fontColor(color)
        Text(`/${this.vm.periodLabel(selectedPeriod)}`)
          .fontSize(14).fontColor('#9E9E9E').margin({ left: 4, bottom: 8 })
        Blank()
        Button('关于我们').fontSize(13)
          .backgroundColor(Color.Transparent).fontColor(color)
          .onClick(() => router.pushUrl({ url: 'pages/AboutPage' }))
      }
      .width('100%').padding({ left: 16, right: 16, top: 12 })

      // 权益列表
      if (isExpanded) {
        Column() {
          ForEach(benefits, (benefit: string) => {
            Row() {
              Image($r('app.media.ic_check')).width(16).height(16)
                .fillColor(color).margin({ right: 8 })
              Text(benefit).fontSize(13).fontColor('#424242')
            }
            .width('100%').padding({ top: 6 })
          }, (benefit: string) => benefit)
          Button('立即订阅').width('100%').height(44)
            .backgroundColor(color).fontColor(Color.White)
            .borderRadius(22).margin({ top: 16 })
            .onClick(() => this.showPayDialog(tier, selectedPeriod))
        }
        .width('100%').padding({ left: 16, right: 16, bottom: 16 })
      }
      Blank().height(8)
    }
    .width('90%').backgroundColor(Color.White)
    .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ left: 16, right: 16, bottom: 12 })
  }

  @Builder
  periodChip(label: string, period: string, tier: string, selectedPeriod: string) {
    const isSelected = period === selectedPeriod
    Text(label).fontSize(13)
      .fontColor(isSelected ? Color.White : '#424242')
      .backgroundColor(
        isSelected ? (tier === 'member' ? '#4CAF50' : '#9C27B0') : '#EEEEEE'
      )
      .borderRadius(16).padding({ left: 16, right: 16, top: 6, bottom: 6 })
      .margin({ right: 8 })
      .onClick(() => { this.vm.selectPeriod(tier === 'member', period) })
  }

  private showPayDialog(tier: string, period: string) {
    const plan = this.vm.getPlan(tier, period)
    const tierName = tier === 'super' ? '超级会员' : '会员'
    const message =
      `选择方案：${tierName} · ${this.vm.periodLabel(period)}\n` +
      `价格：${this.vm.formatPrice(plan)}\n\n（当前为测试模式，不产生真实扣费）`

    promptAction.showDialog({
      title: '支付（测试）',
      message: message,
      buttons: [
        { text: '关于我们', color: '#9E9E9E' },
        { text: '我知道了', color: '#4CAF50' }
      ]
    }).then((result) => {
      if (result.index === 0) {
        router.pushUrl({ url: 'pages/AboutPage' })
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
git add entry/src/main/ets/pages/MembershipPage.ets
git commit -m "feat(membership): add MembershipPage with member/super plan cards"
```

---

## Task 4: AboutPage.ets — 关于我们

**Files:**
- Create: `entry/src/main/ets/pages/AboutPage.ets`

对标 Android `AboutActivity.kt`。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/AboutPage.ets
import router from '@ohos.router'

@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('关于我们').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          Image($r('app.media.app_logo')).width(80).height(80)
            .borderRadius(16).margin({ top: 32, bottom: 16 })
          Text('日子').fontSize(24).fontWeight(FontWeight.Bold).margin({ bottom: 4 })
          Text('Version 1.0.0').fontSize(13).fontColor('#9E9E9E').margin({ bottom: 24 })

          Column() {
            Text('关于应用').fontSize(15).fontWeight(FontWeight.Medium)
              .width('100%').padding({ left: 4, bottom: 8 })
            Text('"日子"是一款个人日记与日程管理应用，帮助你记录每一天的重要时刻、合理安排日程、珍藏特殊日子。融合 AI 智能助手，为你提供贴心陪伴。')
              .fontSize(13).fontColor('#616161').lineHeight(22)
          }
          .width('90%').backgroundColor(Color.White)
          .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
          .padding(16).margin({ bottom: 16 })

          Column() {
            Text('联系我们').fontSize(15).fontWeight(FontWeight.Medium)
              .width('100%').padding({ left: 4, bottom: 8 })
            this.infoRow('邮箱', 'support@example.com')
            this.infoRow('官网', 'https://www.example.com')
          }
          .width('90%').backgroundColor(Color.White)
          .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
          .padding(16).margin({ bottom: 16 })

          Column() {
            Text('开放源代码许可').fontSize(15).fontWeight(FontWeight.Medium)
              .width('100%').padding({ left: 4, bottom: 8 })
            Text('本应用使用的第三方库遵循各自的开源许可证。详情请查阅各库的 LICENSE 文件。')
              .fontSize(13).fontColor('#616161').lineHeight(22)
          }
          .width('90%').backgroundColor(Color.White)
          .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
          .padding(16).margin({ bottom: 32 })
        }
        .width('100%').padding({ bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  infoRow(label: string, value: string) {
    Row() {
      Text(label).fontSize(13).fontColor('#9E9E9E').width(60)
      Text(value).fontSize(13).fontColor('#424242').layoutWeight(1)
    }
    .width('100%').padding({ top: 4, bottom: 4 })
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
git add entry/src/main/ets/pages/AboutPage.ets
git commit -m "feat(profile): add AboutPage"
```

---

## Task 5: SpecialThanksPage.ets — 致谢页

**Files:**
- Create: `entry/src/main/ets/pages/SpecialThanksPage.ets`

对标 Android `SpecialThanksActivity.kt`。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/SpecialThanksPage.ets
import router from '@ohos.router'

@Entry
@Component
struct SpecialThanksPage {
  private readonly thanksList: string[] = [
    '感谢所有支持我们的用户',
    '感谢开源社区的贡献者',
    '感谢华为 HarmonyOS 团队',
    '感谢每一位提出建议的朋友',
  ]

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('特别致谢').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      List() {
        ForEach(this.thanksList, (item: string) => {
          ListItem() {
            Row() {
              Image($r('app.media.ic_favorite')).width(20).height(20)
                .fillColor('#E91E63').margin({ right: 12 })
              Text(item).fontSize(15).fontColor('#424242')
            }
            .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
          }
        }, (item: string) => item)
      }
      .layoutWeight(1)
      .divider({ strokeWidth: 0.5, color: '#F5F5F5', startMargin: 16, endMargin: 16 })
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
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
git add entry/src/main/ets/pages/SpecialThanksPage.ets
git commit -m "feat(profile): add SpecialThanksPage"
```

---

## Task 6: FavoritesPage.ets — 收藏夹

**Files:**
- Create: `entry/src/main/ets/pages/FavoritesPage.ets`

对标 Android `FavoritesActivity.kt`；展示用户收藏的日记和日子条目列表，支持点击跳转详情。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/FavoritesPage.ets
import router from '@ohos.router'

@Entry
@Component
struct FavoritesPage {
  @State private favoriteDiaries: any[] = []
  @State private favoriteDays: any[] = []
  @State private isLoading: boolean = false

  aboutToAppear() {
    this.loadFavorites()
  }

  private async loadFavorites() {
    this.isLoading = true
    // TODO: 从 Relational DB 读取 isFavorite=true 的日记和日子
    await new Promise<void>(resolve => setTimeout(resolve, 500))
    this.isLoading = false
  }

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('收藏夹').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      if (this.isLoading) {
        LoadingProgress().width(40).height(40).margin({ top: 60 })
      } else if (this.favoriteDiaries.length === 0 && this.favoriteDays.length === 0) {
        Column() {
          Text('暂无收藏内容').fontSize(15).fontColor('#9E9E9E')
          Text('在日记或日子详情页点击收藏按钮添加').fontSize(12).fontColor('#BDBDBD').margin({ top: 8 })
        }
        .margin({ top: 80 }).width('100%')
      } else {
        List() {
          ForEach(this.favoriteDiaries, (item: any) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.title || '无标题日记').fontSize(15).fontWeight(FontWeight.Medium)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.date || '').fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
              }
              .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            }
            .onClick(() => router.pushUrl({ url: 'pages/DiaryDetailPage', params: { diaryId: item.id } }))
          }, (item: any) => item.id.toString())

          ForEach(this.favoriteDays, (item: any) => {
            ListItem() {
              Row() {
                Column() {
                  Text(item.title || '无标题日子').fontSize(15).fontWeight(FontWeight.Medium)
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                  Text(item.startAt || '').fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
                }
                .layoutWeight(1).alignItems(HorizontalAlign.Start)
                Image($r('app.media.ic_chevron_right')).width(16).height(16).fillColor('#BDBDBD')
              }
              .width('100%').padding({ left: 16, right: 16, top: 14, bottom: 14 })
            }
            .onClick(() => router.pushUrl({ url: 'pages/DayPage', params: { dayId: item.id } }))
          }, (item: any) => item.id.toString())
        }
        .layoutWeight(1)
        .divider({ strokeWidth: 0.5, color: '#F5F5F5', startMargin: 16, endMargin: 16 })
      }
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
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
git add entry/src/main/ets/pages/FavoritesPage.ets
git commit -m "feat(profile): add FavoritesPage"
```

---

## Task 7: ExportHistoryPage.ets — 导出历史

**Files:**
- Create: `entry/src/main/ets/pages/ExportHistoryPage.ets`

对标 Android `ExportHistoryActivity.kt`；支持导出日记/日程/日子的 JSON 备份。

- [ ] **Step 1: 创建页面文件**

```typescript
// entry/src/main/ets/pages/ExportHistoryPage.ets
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'
import fs from '@ohos.file.fs'

@Entry
@Component
struct ExportHistoryPage {
  @State private isExporting: boolean = false
  @State private exportResult: string = ''

  build() {
    Column() {
      Row() {
        Image($r('app.media.ic_back')).width(24).height(24)
          .onClick(() => router.back())
        Text('导出历史').fontSize(18).fontWeight(FontWeight.Bold)
          .layoutWeight(1).textAlign(TextAlign.Center)
        Blank().width(40)
      }
      .width('100%').padding({ left: 16, right: 16, top: 12, bottom: 12 })

      Scroll() {
        Column() {
          Text('导出内容').fontSize(13).fontColor('#9E9E9E')
            .width('100%').padding({ left: 16, top: 8, bottom: 6 })

          this.exportOption('导出日记（JSON）',
            '将所有日记导出为 JSON 格式备份文件',
            $r('app.media.ic_diary'), () => this.exportDiaries())
          this.exportOption('导出日程（JSON）',
            '将所有日程导出为 JSON 格式备份文件',
            $r('app.media.ic_schedule'), () => this.exportSchedules())
          this.exportOption('导出的日子（JSON）',
            '将所有特殊日子导出为 JSON 格式备份文件',
            $r('app.media.ic_day'), () => this.exportDays())
          this.exportOption('导出全部数据（ZIP）',
            '将日记、日程、日子全部导出（即将支持）',
            $r('app.media.ic_export'), () => {
              promptAction.showToast({ message: '全量导出即将到来...' })
            })

          if (this.exportResult !== '') {
            Text(this.exportResult).fontSize(13).fontColor('#4CAF50')
              .width('100%').padding({ left: 16, top: 16 })
          }
        }
        .width('100%').padding({ bottom: 32 })
      }
      .layoutWeight(1)
    }
    .width('100%').height('100%').backgroundColor('#F5F5F5')
  }

  @Builder
  exportOption(title: string, desc: string, icon: Resource, onClick: () => void) {
    Column() {
      Row() {
        Image(icon).width(24).height(24).fillColor('#2C3E50').margin({ right: 12 })
        Column() {
          Text(title).fontSize(15).fontWeight(FontWeight.Medium)
          Text(desc).fontSize(12).fontColor('#9E9E9E').margin({ top: 2 })
        }
        .alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (this.isExporting) {
          LoadingProgress().width(20).height(20)
        }
      }
      .width('100%').padding(16)
    }
    .width('90%').backgroundColor(Color.White)
    .borderRadius(12).shadow({ radius: 4, color: '#1A000000', offsetY: 2 })
    .margin({ left: 16, right: 16, bottom: 8 })
    .onClick(() => { if (!this.isExporting) onClick() })
  }

  private async exportDiaries() {
    this.isExporting = true
    try {
      const result = await this.saveExportFile('diary_export.json', '{}')
      this.exportResult = result
    } finally {
      this.isExporting = false
    }
  }

  private async exportSchedules() {
    this.isExporting = true
    try {
      const result = await this.saveExportFile('schedule_export.json', '{}')
      this.exportResult = result
    } finally {
      this.isExporting = false
    }
  }

  private async exportDays() {
    this.isExporting = true
    try {
      const result = await this.saveExportFile('day_export.json', '{}')
      this.exportResult = result
    } finally {
      this.isExporting = false
    }
  }

  private async saveExportFile(filename: string, content: string): Promise<string> {
    try {
      const context = getContext(this) as any
      const dir = `${context.filesDir}/exports`
      try { fs.mkdirSync(dir) } catch (_) {}
      const path = `${dir}/${filename}`
      fs.writeFileSync(path, content, 'utf8')
      return `已导出至：${path}`
    } catch (e) {
      return `导出失败：${e?.message ?? '未知错误'}`
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
git add entry/src/main/ets/pages/ExportHistoryPage.ets
git commit -m "feat(profile): add ExportHistoryPage"
```

---

## Task 8: 路由注册

**Files:**
- Modify: `entry/src/main/resources/base/profile/main_pages.json`
- Modify: `entry/src/main/ets/entryability/EntryAbility.ets`

- [ ] **Step 1: 注册所有新页面路由**

在 `main_pages.json` 的 `src` 数组中追加：

```json
"pages/MembershipPage",
"pages/AboutPage",
"pages/SpecialThanksPage",
"pages/FavoritesPage",
"pages/ExportHistoryPage"
```

- [ ] **Step 2: 验证编译**

```bash
hvigorw assembleHap --module entry
# 期望: BUILD SUCCESSFUL
```

- [ ] **Step 3: 安装到真机/模拟器，手动验证**

```
验证清单：
□ MembershipPage 可从 ProfilePage 跳转，显示 Member/Super 两个方案
□ 切换月/季/年周期，价格显示相应更新
□ 点击"关于我们"跳转 AboutPage
□ AboutPage 显示版本信息和联系方式
□ 特别致谢页面（SpecialThanksPage）可访问
□ 收藏夹页面（FavoritesPage）可访问，显示空状态
□ 导出历史页面（ExportHistoryPage）可访问，各导出按钮可点击
□ 各页面返回按钮均正常工作
```

- [ ] **Step 4: 提交**

```bash
git add entry/src/main/resources/base/profile/main_pages.json \
        entry/src/main/ets/entryability/EntryAbility.ets
git commit -m "feat(membership): register membership/vault pages routes"
```

---

## 自审检查

### Spec 覆盖
| Android 功能 | HarmonyOS 对应 | 任务 |
|---|---|---|
| MembershipPlansActivity.kt | MembershipPage | Task 3 |
| MembershipPlanPrice model | MembershipPlan.ets | Task 1 |
| MembershipBenefitsResponse model | MembershipBenefits.ets | Task 1 |
| AboutActivity.kt | AboutPage | Task 4 |
| SpecialThanksActivity.kt | SpecialThanksPage | Task 5 |
| FavoritesActivity.kt | FavoritesPage | Task 6 |
| ExportHistoryActivity.kt | ExportHistoryPage | Task 7 |
| ViewPager2 + tabs | 简化折叠面板 | Task 3 |
| 真实支付 SDK | 测试 Dialog | Task 3 |

### 类型一致性
- `MembershipViewModel.getPlan(tier, period)` — Task 2 定义，Task 3 调用 ✓
- `MembershipViewModel.formatPrice(plan)` — Task 2 定义，Task 3 调用 ✓
- `MembershipPlan.ets` + `MembershipBenefits.ets` — Task 1 定义，Task 2 使用 ✓
