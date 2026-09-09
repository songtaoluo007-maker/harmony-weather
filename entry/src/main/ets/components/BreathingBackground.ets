import { AnimatorResult } from '@kit.ArkUI'
import { WeatherVisualState } from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'
import { SnowfallLayer } from './SnowfallLayer'

@Component
export struct DynamicWeatherBackground {
  @Prop @Watch('restartMotion') visualState: WeatherVisualState = WeatherVisualState.CLEAR_DAY
  @Prop hour: number = 12
  @Prop isNight: boolean = false
  @Prop nightPhoto: boolean = false
  @Prop cityImageAspect: number = 1.5
  @Prop @Watch('restartMotion') motionEnabled: boolean = true
  @Prop @Watch('restartMotion') active: boolean = true
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop cityBackgroundResource: Resource = $r('app.media.weather_bg_day')
  @Prop hasBundledCityBackground: boolean = false
  @Prop cityBackgroundUrl: string = ''
  @State sceneWidth: number = 390
  @State cloudPhase: number = 0
  @State rainPhase: number = 0
  @State glassPhase: number = 0
  private animators: AnimatorResult[] = []
  private mounted: boolean = false

  aboutToAppear(): void { this.mounted = true; this.restartMotion() }
  aboutToDisappear(): void { this.mounted = false; this.stopMotion() }

  private stopMotion(): void {
    this.animators.forEach((animation: AnimatorResult) => animation.cancel())
    this.animators = []
  }

  private restartMotion(): void {
    this.stopMotion()
    if (!this.mounted || !this.motionEnabled || !this.active) return
    if (WeatherTheme.shouldShowCloudLayer(this.visualState)) {
      const clouds: AnimatorResult = this.getUIContext().createAnimator({
        duration: 42000, easing: 'ease-in-out', delay: 0, fill: 'forwards',
        direction: 'alternate', iterations: -1, begin: 0, end: 1
      })
      clouds.onFrame = (value: number) => { this.cloudPhase = value }
      this.animators.push(clouds)
      clouds.play()
    }
    if (WeatherTheme.shouldShowRainLayer(this.visualState)) {
      const rain: AnimatorResult = this.getUIContext().createAnimator({
        duration: this.visualState === WeatherVisualState.STORM ? 1600 : 2400,
        easing: 'linear', delay: 0, fill: 'forwards', direction: 'normal', iterations: -1, begin: 0, end: 1
      })
      rain.onFrame = (value: number) => { this.rainPhase = value }
      this.animators.push(rain)
      rain.play()
      const glass: AnimatorResult = this.getUIContext().createAnimator({
        duration: 24000, easing: 'linear', delay: 0, fill: 'forwards',
        direction: 'normal', iterations: -1, begin: 0, end: 1
      })
      glass.onFrame = (value: number) => { this.glassPhase = value }
      this.animators.push(glass)
      glass.play()
    }
  }

  private sceneHeight(): number { return Math.min(700, Math.max(470, this.sceneWidth * 1.55)) }
  private photoHeight(): number { return Math.min(this.sceneHeight() * 0.66, Math.max(this.sceneHeight() * 0.42, this.sceneWidth / this.cityImageAspect)) }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Stack({ alignContent: Alignment.Top }) {
        if (this.nightPhoto) {
          Column().width('100%').height('100%').backgroundColor(this.themeColors.skyTop)
        } else {
          Image(WeatherTheme.getBackgroundResource(this.visualState, this.hour, this.isNight))
            .width('100%').height('100%').objectFit(ImageFit.Cover)
        }
        if (this.hasBundledCityBackground || this.cityBackgroundUrl) {
          if (this.nightPhoto) {
            Image(this.cityBackgroundResource).width('100%').height(this.photoHeight()).objectFit(ImageFit.Cover)
              .translate({ y: this.sceneHeight() - this.photoHeight() - 20 })
              .brightness(WeatherTheme.getBackgroundBrightness(this.visualState, true))
            Column().width('100%').height(this.photoHeight() * 0.35)
              .linearGradient({ direction: GradientDirection.Bottom,
                colors: [[this.themeColors.skyTop, 0], ['rgba(0,0,0,0)', 1]] })
              .translate({ y: this.sceneHeight() - this.photoHeight() - 20 })
          } else {
            Image(this.hasBundledCityBackground ? this.cityBackgroundResource : this.cityBackgroundUrl)
              .width('100%').height('100%').objectFit(ImageFit.Cover)
              .brightness(WeatherTheme.getBackgroundBrightness(this.visualState, this.isNight))
          }
        }
        Column().width('100%').height('100%')
          .backgroundColor(WeatherTheme.getWeatherOverlay(this.visualState, this.hour, this.isNight))
        // Hide the blurred skyline baked into legacy portrait photos; the
        // lower, sharp city remains visible beneath the procedural sky layers.
        Column().width('100%').height('100%')
          .linearGradient({ direction: GradientDirection.Bottom,
            colors: [[this.themeColors.skyTop, 0], [this.themeColors.skyTop, 0.37],
              ['rgba(0,0,0,0)', 0.70]] })
        if (WeatherTheme.shouldShowCloudLayer(this.visualState)) {
          Image($r('app.media.weather_layer_clouds'))
            .width('150%').height('110%').objectFit(ImageFit.Cover)
            .opacity(WeatherTheme.getCloudOpacity(this.visualState)).blendMode(BlendMode.SCREEN)
            .translate({ x: (this.cloudPhase - 0.5) * this.sceneWidth * 0.4 })
        }
        if (WeatherTheme.shouldShowRainLayer(this.visualState)) {
          ForEach([0, 1], (tile: number) => {
            Image($r('app.media.weather_layer_rain'))
              .width('100%').height(this.sceneHeight()).objectFit(ImageFit.Fill)
              .opacity(this.visualState === WeatherVisualState.STORM ? 0.52 : 0.38)
              .blendMode(BlendMode.SCREEN)
              .translate({ y: (this.rainPhase - tile) * this.sceneHeight() })
          })
          Image($r('app.media.weather_layer_glass_rain'))
            .width('100%').height('100%').objectFit(ImageFit.Cover)
            .opacity(0.15).blendMode(BlendMode.SCREEN)
          Image($r('app.media.weather_layer_glass_rain'))
            .width('112%').height('120%').objectFit(ImageFit.Cover)
            .opacity(0.32 * Math.min(1, this.glassPhase * 10, (1 - this.glassPhase) * 10))
            .blendMode(BlendMode.SCREEN).translate({ y: this.glassPhase * 70 - 30 })
        }
        if (this.visualState === WeatherVisualState.SNOW) {
          SnowfallLayer({ motionEnabled: this.motionEnabled, active: this.active })
            .width('100%').height('100%')
        }
        Column().width('100%').height('100%')
          .linearGradient({
            direction: GradientDirection.Bottom,
            colors: [[this.themeColors.scrimTop, 0], ['rgba(12,32,48,0.04)', 0.48],
              [this.themeColors.pageBackground, 1]]
          })
      }
      .width('100%').height(this.sceneHeight()).clip(true)
    }
    .width('100%').height('100%').backgroundColor(this.themeColors.pageBackground)
    .onAreaChange((_old: Area, area: Area) => { this.sceneWidth = Number(area.width) })
    .hitTestBehavior(HitTestMode.None).accessibilityLevel('no-hide-descendants')
  }
}
