import { AtmosphereTokens as A } from '../theme/AtmosphereTokens'

// Static measured canvases: redraw on data or layout change, never start a frame loop.
@Component
export struct InstrumentDial {
  @Prop @Watch('draw') kind: string = 'wind'
  @Prop @Watch('draw') value: number = -1
  @Prop @Watch('draw') active: boolean = true
  @Prop @Watch('draw') tint: string = A.teal
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))
  private ready: boolean = false
  private canvasWidth: number = 0
  private canvasHeight: number = 0

  private line(x1: number, y1: number, x2: number, y2: number, color: string, width: number = 1): void {
    const c = this.context
    c.strokeStyle = color; c.lineWidth = width
    c.beginPath(); c.moveTo(x1, y1); c.lineTo(x2, y2); c.stroke()
  }

  private wind(): void {
    const c = this.context
    const x: number = this.canvasWidth / 2, y: number = this.canvasHeight / 2
    const radius: number = Math.min(this.canvasWidth, this.canvasHeight) * .37
    for (let index: number = 0; index < 40; index++) {
      const angle: number = index * Math.PI / 20
      const outer: number = radius, inner: number = radius - (index % 5 === 0 ? 6 : 3)
      this.line(x + Math.sin(angle) * inner, y - Math.cos(angle) * inner,
        x + Math.sin(angle) * outer, y - Math.cos(angle) * outer,
        index % 10 === 0 ? 'rgba(237,241,240,0.65)' : A.track, index % 5 === 0 ? 1.4 : .8)
    }
    c.font = '9vp sans-serif'; c.textAlign = 'center'; c.textBaseline = 'middle'
    c.fillStyle = A.gold; c.fillText('北', x, y - radius - 10)
    c.fillStyle = '#A8BAC3'
    c.fillText('南', x, y + radius + 10)
    c.fillText('西', x - radius - 10, y)
    c.fillText('东', x + radius + 10, y)
    if (this.value >= 0) {
      c.save(); c.translate(x, y); c.rotate(this.value * Math.PI / 180)
      c.fillStyle = this.tint
      c.beginPath(); c.moveTo(0, -radius + 10); c.lineTo(-5, 7); c.lineTo(0, 3); c.lineTo(5, 7); c.closePath(); c.fill()
      c.fillStyle = 'rgba(166,216,212,0.20)'
      c.beginPath(); c.moveTo(0, radius - 12); c.lineTo(-4, -3); c.lineTo(4, -3); c.closePath(); c.fill()
      c.restore()
    }
    c.fillStyle = A.ivory; c.beginPath(); c.arc(x, y, 2.5, 0, Math.PI * 2); c.fill()
  }

  private solar(): void {
    const c = this.context
    const left: number = 10, right: number = this.canvasWidth - 10, base: number = this.canvasHeight - 12
    const amplitude: number = this.canvasHeight - 24
    this.line(left, base, right, base, A.track)
    c.beginPath()
    for (let index: number = 0; index <= 80; index++) {
      const t: number = index / 80
      const x: number = left + (right - left) * t, y: number = base - Math.sin(t * Math.PI) * amplitude
      if (index === 0) c.moveTo(x, y); else c.lineTo(x, y)
    }
    c.lineTo(right, base); c.lineTo(left, base); c.closePath()
    const glow = c.createLinearGradient(0, base - amplitude, 0, base)
    glow.addColorStop(0, 'rgba(230,190,138,0.12)'); glow.addColorStop(1, 'rgba(230,190,138,0.00)')
    c.fillStyle = glow; c.fill()
    c.beginPath()
    for (let index: number = 0; index <= 80; index++) {
      const t: number = index / 80
      const x: number = left + (right - left) * t, y: number = base - Math.sin(t * Math.PI) * amplitude
      if (index === 0) c.moveTo(x, y); else c.lineTo(x, y)
    }
    c.setLineDash([3, 4]); c.strokeStyle = 'rgba(230,190,138,0.30)'; c.lineWidth = 1.2; c.stroke(); c.setLineDash([])
    if (this.value < 0) return
    c.beginPath()
    for (let index: number = 0; index <= 80; index++) {
      const t: number = this.value * index / 80
      const x: number = left + (right - left) * t, y: number = base - Math.sin(t * Math.PI) * amplitude
      if (index === 0) c.moveTo(x, y); else c.lineTo(x, y)
    }
    c.lineWidth = 1.8; c.strokeStyle = A.gold; c.stroke()
    if (this.active) {
      const x: number = left + (right - left) * this.value, y: number = base - Math.sin(this.value * Math.PI) * amplitude
      const halo = c.createRadialGradient(x, y, 2, x, y, 15)
      halo.addColorStop(0, 'rgba(255,216,164,0.35)'); halo.addColorStop(1, 'rgba(255,216,164,0)')
      c.fillStyle = halo; c.beginPath(); c.arc(x, y, 15, 0, Math.PI * 2); c.fill()
      c.fillStyle = '#FFE3B5'; c.beginPath(); c.arc(x, y, 4, 0, Math.PI * 2); c.fill()
    }
  }

  private drawScale(): void {
    const c = this.context
    const fraction: number = Math.max(0, Math.min(1, this.value))
    const gap: number = this.canvasWidth / 30
    for (let index: number = 0; index < 30; index++) {
      const selected: boolean = this.value >= 0 && (index + .5) / 30 <= fraction
      const length: number = index % 5 === 0 ? 13 : 8
      this.line(gap * (index + .5), this.canvasHeight / 2 - length / 2, gap * (index + .5),
        this.canvasHeight / 2 + length / 2, selected ? this.tint : A.track, 2)
    }
  }

  private draw(): void {
    if (!this.ready || this.canvasWidth <= 0 || this.canvasHeight <= 0) return
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight)
    if (this.kind === 'wind') this.wind()
    else if (this.kind === 'solar') this.solar()
    else this.drawScale()
  }

  build() {
    Canvas(this.context).width('100%').height('100%')
      .onReady(() => { this.ready = true; this.draw() })
      .onAreaChange((_old: Area, area: Area) => {
        this.canvasWidth = Number(area.width); this.canvasHeight = Number(area.height); this.draw()
      }).accessibilityLevel('no').hitTestBehavior(HitTestMode.None)
  }
}
