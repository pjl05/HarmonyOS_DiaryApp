/**
 * FloatingAIBallView - 悬浮球组件
 * 替换 Android: FloatingAIBallView (拖拽悬浮球)
 */
import router from '@ohos.router'

@Component
export struct FloatingAIBallView {
  @State offsetX: number = 0
  @State offsetY: number = 300
  @State scale: number = 1

  private startX: number = 0
  private startY: number = 0
  private screenWidth: number = 360
  private screenHeight: number = 780

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
          router.pushUrl({ url: 'pages/ChatPage' }).catch(() => {})
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
          this.startX = this.offsetX
          this.startY = this.offsetY
          animateTo({ duration: 160 }, () => {
            this.scale = 1.06
          })
        })
        .onActionUpdate((event) => {
          const newX = this.startX + event.fingerX
          const newY = this.startY + event.fingerY
          this.offsetX = newX.coerceIn(-(this.screenWidth - 56) / 2, (this.screenWidth - 56) / 2)
          this.offsetY = newY.coerceIn(96, this.screenHeight - 180)
        })
        .onActionEnd(() => {
          animateTo({ duration: 260, curve: Curve.FastOutSlowIn }, () => {
            this.scale = 1
            this.offsetX = this.offsetX > 0 ? this.screenWidth - 56 - 20 : -this.screenWidth / 2 + 28
          })
        })
    )
    .onAreaChange((_, newArea) => {
      this.screenWidth = newArea.width as number
      this.screenHeight = newArea.height as number
    })
  }
}