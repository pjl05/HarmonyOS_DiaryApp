/**
 * 用户数据模型
 * 对标 Android UserData
 */

export class UserData {
  userId: number = 0
  username: string = ''
  email: string = ''
  nickname: string = ''
  avatar_url: string = ''
  token: string = ''

  constructor(data?: Partial<UserData>) {
    if (data) {
      this.userId = data.userId ?? 0
      this.username = data.username ?? ''
      this.email = data.email ?? ''
      this.nickname = data.nickname ?? ''
      this.avatar_url = data.avatar_url ?? ''
      this.token = data.token ?? ''
    }
  }
}

export class UserProfile {
  id: number = 0
  username: string = ''
  email: string = ''
  nickname: string | null = null
  avatar_url: string | null = null
  gender: string | null = null
  signature: string | null = null
  membership_tier: string | null = null
  membership_expires_at: string | null = null
}