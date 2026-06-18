import { WeatherVisualState } from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'

@Component
export struct DynamicWeatherBackground {
  @Prop visualState: WeatherVisualState = WeatherVisualState.CLEAR_DAY
  @Prop hour: number = 12
  @Prop motionEnabled: boolean = true
  @Prop themeColors: ThemeColors = new ThemeColors()
  @Prop cityBackgroundResource: Resource = $r('app.media.weather_bg_day')
  @Prop hasBundledCityBackground: boolean = false
  @Prop cityBackgroundUrl: string = ''
  @State zoom: number = 1
  @State cloudOffset: number = -42
  @State rainOffset: number = -220
  @State glassOffset: number = -16

  aboutToAppear(): void {
    if (this.motionEnabled) {
      setTimeout(() => {
        this.zoom = 1.045
        this.cloudOffset = 42
        this.rainOffset = 220
        this.glassOffset = 16
      }, 160)
    }
  }

  build() {
    Stack() {
      Image(WeatherTheme.getBackgroundResource(this.visualState, this.hour))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .scale({ x: this.zoom, y: this.zoom })
        .animation({ duration: 24000, curve: Curve.EaseInOut })

      if (this.hasBundledCityBackground) {
        Image(this.cityBackgroundResource)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .brightness(WeatherTheme.getBackgroundBrightness(this.visualState))
          .scale({ x: this.zoom, y: this.zoom })
          .animation({ duration: 24000, curve: Curve.EaseInOut })
      } else if (this.cityBackgroundUrl) {
        Image(this.cityBackgroundUrl)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .brightness(WeatherTheme.getBackgroundBrightness(this.visualState))
          .scale({ x: this.zoom, y: this.zoom })
          .animation({ duration: 24000, curve: Curve.EaseInOut })
      }

      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(WeatherTheme.getWeatherOverlay(this.visualState, this.hour))

      if (WeatherTheme.shouldShowCloudLayer(this.visualState)) {
        Image($r('app.media.weather_layer_clouds'))
          .width('124%')
          .height('108%')
          .objectFit(ImageFit.Cover)
          .opacity(WeatherTheme.getCloudOpacity(this.visualState))
          .blendMode(BlendMode.SCREEN)
          .translate({ x: this.motionEnabled ? this.cloudOffset : 0 })
          .animation({
            duration: 60000,
            curve: Curve.Linear,
            iterations: this.motionEnabled ? -1 : 0,
            playMode: PlayMode.Alternate
          })
      }

      if (WeatherTheme.shouldShowRainLayer(this.visualState)) {
        Image($r('app.media.weather_layer_rain'))
          .width('112%')
          .height('126%')
          .objectFit(ImageFit.Cover)
          .opacity(this.visualState === WeatherVisualState.STORM ? 0.62 : 0.46)
          .blendMode(BlendMode.SCREEN)
          .translate({ y: this.motionEnabled ? this.rainOffset : 0 })
          .animation({
            duration: this.visualState === WeatherVisualState.STORM ? 1100 : 1700,
            curve: Curve.Linear,
            iterations: this.motionEnabled ? -1 : 0,
            playMode: PlayMode.Normal
          })
      }

      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          direction: GradientDirection.Bottom,
          colors: [[this.themeColors.scrimTop, 0], ['rgba(0,0,0,0.08)', 0.38], [this.themeColors.scrimBottom, 1]]
        })

      if (WeatherTheme.shouldShowRainLayer(this.visualState)) {
        Image($r('app.media.weather_layer_glass_rain'))
          .width('106%')
          .height('110%')
          .objectFit(ImageFit.Cover)
          .opacity(this.visualState === WeatherVisualState.STORM ? 0.48 : 0.34)
          .blendMode(BlendMode.SCREEN)
          .translate({ y: this.motionEnabled ? this.glassOffset : 0 })
          .animation({
            duration: 18000,
            curve: Curve.EaseInOut,
            iterations: this.motionEnabled ? -1 : 0,
            playMode: PlayMode.Alternate
          })
      }

      if (this.visualState === WeatherVisualState.STORM) {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(33,35,76,0.18)')
      }
    }
    .width('100%')
    .height('100%')
  }
}
