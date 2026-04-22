/**
 * 弹幕动画组件
 * 对标 Android BubbleDanmakuView
 */

import { getLogger } from '../../utils/Logger.ets'

const logger = getLogger('DanmakuView')

interface DanmakuBubble {
  id: number
  text: string
  y: number
  duration: number
}

@Component
export struct DanmakuView {
  @State private isRunning: boolean = false
  @State private bubbles: DanmakuBubble[] = []
  private intervalId: number = -1

  private greetings: string[] = [
    '欢迎回来', '今天也要加油', '祝你心情愉快', '愿你一切顺利',
    '保持微笑', '记录美好生活', '写下此刻的你', '愿你拥有好天气',
    '别忘了喝水', '慢慢来更快', '今天也很棒', '你好呀',
    '今天你写日记了吗', '给你100分'
  ]

  aboutToAppear() {
    logger.info('DanmakuView aboutToAppear')
  }

  aboutToDisappear() {
    this.stop()
  }

  start() {
    if (this.isRunning) return
    this.isRunning = true
    this.intervalId = setInterval(() => {
      if (this.isRunning) {
        this.spawnOne()
      }
    }, 1000 + Math.random() * 500)
  }

  stop() {
    this.isRunning = false
    if (this.intervalId !== -1) {
      clearInterval(this.intervalId)
      this.intervalId = -1
    }
    this.bubbles = []
  }

  private spawnOne() {
    const text = this.greetings[Math.floor(Math.random() * this.greetings.length)]
    const id = Date.now() + Math.random()
    const newBubble: DanmakuBubble = {
      id: id,
      text: text,
      y: Math.random() * 80 + 10,
      duration: 9000 + Math.random() * 3500
    }
    this.bubbles.push(newBubble)
    setTimeout(() => {
      this.bubbles = this.bubbles.filter(b => b.id !== id)
    }, newBubble.duration)
  }

  build() {
    Stack() {
      ForEach(this.bubbles, (bubble: DanmakuBubble) => {
        Text(bubble.text)
          .fontSize(14)
          .fontColor('#00BCD4')
          .padding(10)
          .backgroundColor('#1A00BCD4')
          .borderRadius(15)
          .opacity(0.92)
          .position({ y: `${bubble.y}%` })
          .translate({ x: 300 })
      })
    }
    .width('100%')
    .height('100%')
    .clip(true)
  }
}