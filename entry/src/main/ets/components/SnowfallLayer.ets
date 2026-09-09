import { SnowField, SnowFlake } from '../models/SnowField'

@Component
export struct SnowfallLayer {
  @Prop @Watch('syncMotion') motionEnabled: boolean = true
  @Prop @Watch('syncMotion') active: boolean = true
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private canvasWidth: number = 0
  private canvasHeight: number = 0
  private ready: boolean = false
  private phase: number = 0
  private timer: number = -1
  private previousFrame: number = 0

  aboutToDisappear(): void { this.ready = false; this.stopMotion() }

  private stopMotion(): void {
    if (this.timer >= 0) clearInterval(this.timer)
    this.timer = -1
  }

  private syncMotion(): void {
    this.stopMotion()
    if (!this.ready || !this.motionEnabled || !this.active) return
    this.previousFrame = Date.now()
    // Twenty canvas updates/second; no ArkUI state mutation per particle/frame.
    this.timer = setInterval(() => {
      const now: number = Date.now()
      this.phase = (this.phase + (now - this.previousFrame) / 18000) % 1
      this.previousFrame = now
      this.draw()
    }, 50)
  }

  private draw(): void {
    if (!this.ready) return
    this.canvas.clearRect(0, 0, this.canvasWidth, this.canvasHeight)
    SnowField.frame(this.canvasWidth, this.canvasHeight, this.phase).forEach((flake: SnowFlake) => {
      this.canvas.fillStyle = `rgba(240,249,255,${flake.opacity * 0.15})`
      this.canvas.beginPath()
      this.canvas.arc(flake.x, flake.y, flake.radius * 2, 0, Math.PI * 2)
      this.canvas.fill()
      this.canvas.fillStyle = `rgba(255,255,255,${flake.opacity})`
      this.canvas.beginPath()
      this.canvas.arc(flake.x, flake.y, flake.radius, 0, Math.PI * 2)
      this.canvas.fill()
    })
  }

  build() {
    Canvas(this.canvas).width('100%').height('100%')
      .onReady(() => { this.ready = true; this.draw(); this.syncMotion() })
      .onAreaChange((_old: Area, area: Area) => {
        this.canvasWidth = Number(area.width)
        this.canvasHeight = Number(area.height)
        this.draw()
      })
      .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
