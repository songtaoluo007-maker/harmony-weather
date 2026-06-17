// ─── 呼吸背景：3层叠加（渐变 + 光晕 + 粒子） ────────
// 使用 requestAnimationFrame 替代 setInterval 实现高效动画
import { WeatherType } from '../models/WeatherModels'
import { ThemeColors } from '../theme/WeatherTheme'

const BREATHE_CYCLE: number = 5000 // 呼吸周期 5秒
const PARTICLE_COUNT_SUNNY: number = 25
const PARTICLE_COUNT_RAIN: number = 60
const PARTICLE_COUNT_SNOW: number = 40

class Particle {
  x: number = 0
  y: number = 0
  vx: number = 0
  vy: number = 0
  size: number = 2
  opacity: number = 0.5
  life: number = 0
  maxLife: number = 300
}

@Component
export struct BreathingBackground {
  @Link weatherType: WeatherType
  @Link themeColors: ThemeColors
  @State breathePhase: number = 0
  private animFrameId: number = -1
  private particles: Particle[] = []
  private canvasWidth: number = 360
  private canvasHeight: number = 780

  aboutToAppear(): void {
    this.initParticles()
  }

  aboutToDisappear(): void {
    this.stopAnimation()
  }

  // 停止动画帧循环
  private stopAnimation(): void {
    if (this.animFrameId >= 0) {
      cancelAnimationFrame(this.animFrameId)
      this.animFrameId = -1
    }
  }

  // 初始化粒子
  private initParticles(): void {
    this.particles = []
    let count: number = PARTICLE_COUNT_SUNNY
    if (this.weatherType === WeatherType.RAINY || this.weatherType === WeatherType.STORMY) {
      count = PARTICLE_COUNT_RAIN
    } else if (this.weatherType === WeatherType.SNOWY) {
      count = PARTICLE_COUNT_SNOW
    }

    for (let i: number = 0; i < count; i++) {
      this.particles.push(this.createParticle())
    }
  }

  // 创建单个粒子
  private createParticle(): Particle {
    const p: Particle = new Particle()
    p.x = Math.random() * this.canvasWidth
    p.y = Math.random() * this.canvasHeight
    p.maxLife = 200 + Math.random() * 300
    p.life = Math.random() * p.maxLife

    if (this.weatherType === WeatherType.RAINY || this.weatherType === WeatherType.STORMY) {
      p.vx = -1 + Math.random() * 0.5
      p.vy = 8 + Math.random() * 6
      p.size = 1 + Math.random() * 2
      p.opacity = 0.3 + Math.random() * 0.4
    } else if (this.weatherType === WeatherType.SNOWY) {
      p.vx = -0.5 + Math.random() * 1
      p.vy = 1 + Math.random() * 2
      p.size = 2 + Math.random() * 4
      p.opacity = 0.4 + Math.random() * 0.5
    } else {
      // 晴天/多云：漂浮光点
      p.vx = -0.3 + Math.random() * 0.6
      p.vy = -0.5 + Math.random() * 0.3
      p.size = 2 + Math.random() * 5
      p.opacity = 0.15 + Math.random() * 0.35
    }
    return p
  }

  // 更新所有粒子状态
  private updateParticles(): void {
    for (let i: number = 0; i < this.particles.length; i++) {
      const p: Particle = this.particles[i]
      p.x += p.vx
      p.y += p.vy
      p.life++

      if (p.life > p.maxLife || p.y > this.canvasHeight + 10 ||
        p.x < -10 || p.x > this.canvasWidth + 10) {
        this.particles[i] = this.createParticle()
        this.particles[i].y = -10
        this.particles[i].life = 0
      }
    }
  }

  // 计算呼吸透明度
  private getBreatheOpacity(): number {
    return 0.25 + 0.15 * Math.sin(this.breathePhase * Math.PI / 180)
  }

  // 计算呼吸缩放
  private getBreatheScale(): number {
    return 1.0 + 0.03 * Math.sin((this.breathePhase + 120) * Math.PI / 180)
  }

  build() {
    Stack() {
      // Layer 1: 基础渐变
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: this.themeColors.gradient.map((c: string, i: number) => [c, i / (this.themeColors.gradient.length - 1)])
        })

      // Layer 2: 呼吸光晕
      Column()
        .width('120%')
        .height('120%')
        .position({ x: '-10%', y: '-10%' })
        .radialGradient({
          center: ['50%', '40%'],
          radius: '60%',
          colors: [['rgba(255,255,255,0.15)', 0.0], ['rgba(255,255,255,0)', 1.0]]
        })
        .opacity(this.getBreatheOpacity())
        .scale({ x: this.getBreatheScale(), y: this.getBreatheScale() })

      // Layer 3: 粒子（用 Canvas 绘制）
      Canvas((context: CanvasRenderingContext2D) => {
        // 在 Canvas onReady 时启动动画循环
        this.stopAnimation()
        this.initParticles()

        const animateFrame: (() => void) = () => {
          // 更新呼吸相位
          this.breathePhase = (this.breathePhase + 2) % 360
          this.updateParticles()

          // 清除画布
          context.clearRect(0, 0, this.canvasWidth, this.canvasHeight)

          // 绘制所有粒子
          for (let i: number = 0; i < this.particles.length; i++) {
            const p: Particle = this.particles[i]
            const lifeRatio: number = p.life / p.maxLife
            const alpha: number = lifeRatio < 0.1 ? lifeRatio * 10 :
              (lifeRatio > 0.8 ? (1 - lifeRatio) * 5 : 1)

            // 保存上下文并设置透明度
            context.save()
            context.globalAlpha = p.opacity * alpha

            if (this.weatherType === WeatherType.RAINY || this.weatherType === WeatherType.STORMY) {
              // 雨滴：拉长的线条
              context.strokeStyle = 'rgba(180,210,255,0.6)'
              context.lineWidth = p.size * 0.5
              context.beginPath()
              context.moveTo(p.x, p.y)
              context.lineTo(p.x + p.vx * 2, p.y - p.vy * 1.5)
              context.stroke()
            } else if (this.weatherType === WeatherType.SNOWY) {
              // 雪花：圆形
              context.fillStyle = '#ffffff'
              context.beginPath()
              context.arc(p.x, p.y, p.size, 0, Math.PI * 2)
              context.fill()
            } else {
              // 光点：带光晕的圆形
              const gradient: CanvasGradient = context.createRadialGradient(
                p.x, p.y, 0, p.x, p.y, p.size * 2
              )
              const innerAlpha: string = (p.opacity * alpha).toFixed(2)
              gradient.addColorStop(0, `rgba(255,255,255,${innerAlpha})`)
              gradient.addColorStop(1, 'rgba(255,255,255,0)')
              context.fillStyle = gradient
              context.beginPath()
              context.arc(p.x, p.y, p.size * 2, 0, Math.PI * 2)
              context.fill()
            }

            // 恢复上下文
            context.restore()
          }

          // 请求下一帧
          this.animFrameId = requestAnimationFrame(animateFrame)
        }

        // 启动动画循环
        this.animFrameId = requestAnimationFrame(animateFrame)
      })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
