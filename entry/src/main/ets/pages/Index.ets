import { common } from '@kit.AbilityKit'
import {
  WeatherData,
  WeatherUiState,
  WeatherUiStatus,
  WeatherVisualState
} from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'
import { BundledCityBackground, BundledCityBackgrounds } from '../theme/BundledCityBackgrounds'
import { AppSettings, WeatherService } from '../services/WeatherService'
import { CityBackground, CityBackgroundService } from '../services/CityBackgroundService'
import { DynamicWeatherBackground } from '../components/BreathingBackground'
import { HeroSection } from '../components/HeroSection'
import { HourlyCapsules } from '../components/HourlyCapsules'
import { WeeklyForecast } from '../components/WeeklyForecast'
import { DataGrid } from '../components/DataGrid'
import { AirQualityCard } from '../components/AirQualityCard'
import { LifeIndexGrid } from '../components/LifeIndexGrid'

@Entry
@Component
struct Index {
  @State uiState: WeatherUiState = new WeatherUiState()
  @State weatherData: WeatherData = new WeatherData()
  @State visualState: WeatherVisualState = WeatherVisualState.CLEAR_DAY
  @State themeColors: ThemeColors = new ThemeColors()
  @State refreshing: boolean = false
  @State motionEnabled: boolean = true
  @State unit: string = 'c'
  @State currentHour: number = new Date().getHours()
  @State cityBackgroundResource: Resource = $r('app.media.weather_bg_day')
  @State hasBundledCityBackground: boolean = false
  @State cityBackgroundUrl: string = ''
  @State cityBackgroundAttribution: string = ''
  private service: WeatherService = WeatherService.getInstance()
  private backgroundService: CityBackgroundService = CityBackgroundService.getInstance()
  private loadedCityId: string = ''
  private timeTimerId: number = -1

  async aboutToAppear(): Promise<void> {
    await this.loadData(false)
    this.startTimeObserver()
  }

  aboutToDisappear(): void {
    if (this.timeTimerId >= 0) {
      clearInterval(this.timeTimerId)
      this.timeTimerId = -1
    }
  }

  async onPageShow(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    const settings: AppSettings = this.service.getSettings()
    this.motionEnabled = settings.motionEnabled
    this.unit = settings.unit
    const selectedId: string = this.service.getCurrentCity().id
    if (this.loadedCityId && selectedId !== this.loadedCityId) await this.loadData(true)
  }

  private async loadData(forceRefresh: boolean): Promise<void> {
    const previous: WeatherData | undefined = this.weatherData.lastUpdate > 0 ? this.weatherData : undefined
    if (!forceRefresh && !previous) this.uiState = WeatherUiState.loading()
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      await this.service.initialize(context)
      const settings: AppSettings = this.service.getSettings()
      this.motionEnabled = settings.motionEnabled
      this.unit = settings.unit
      const data: WeatherData = await this.service.loadWeather(context, undefined, forceRefresh)
      this.weatherData = data
      this.currentHour = new Date().getHours()
      this.visualState = WeatherData.resolveVisualState(
        data.current.text,
        this.currentHour,
        data.current.sunrise,
        data.current.sunset
      )
      this.themeColors = WeatherTheme.getColors(this.visualState)
      this.uiState = WeatherUiState.ready(data)
      if (this.loadedCityId !== data.cityId) {
        this.hasBundledCityBackground = false
        this.cityBackgroundUrl = ''
        this.cityBackgroundAttribution = ''
      }
      this.loadedCityId = data.cityId
      this.updateCityBackground(context, data.cityId)
    } catch (error) {
      this.uiState = WeatherUiState.error('天气数据暂时不可用，请稍后重试', previous)
    } finally {
      this.refreshing = false
    }
  }

  private async updateCityBackground(
    context: common.UIAbilityContext,
    cityId: string
  ): Promise<void> {
    const city = this.service.getCityList().find(item => item.id === cityId) ?? this.service.getCurrentCity()
    const bundled: BundledCityBackground | null = BundledCityBackgrounds.resolve(cityId)
    if (bundled) {
      if (this.weatherData.cityId !== cityId) return
      this.cityBackgroundResource = bundled.resource
      this.hasBundledCityBackground = true
      this.cityBackgroundUrl = ''
      this.cityBackgroundAttribution = bundled.attribution
      return
    }
    const result: CityBackground = await this.backgroundService.resolve(context, city)
    if (this.weatherData.cityId !== cityId) return
    this.hasBundledCityBackground = false
    this.cityBackgroundUrl = result.imageUrl
    this.cityBackgroundAttribution = result.attribution
  }

  private displayTemperature(value: number): number {
    return this.unit === 'f' ? Math.round(value * 9 / 5 + 32) : value
  }

  private startTimeObserver(): void {
    if (this.timeTimerId >= 0) clearInterval(this.timeTimerId)
    this.timeTimerId = setInterval(() => {
      const hour: number = new Date().getHours()
      if (hour !== this.currentHour) {
        this.currentHour = hour
        this.visualState = WeatherData.resolveVisualState(
          this.weatherData.current.text,
          hour,
          this.weatherData.current.sunrise,
          this.weatherData.current.sunset
        )
        this.themeColors = WeatherTheme.getColors(this.visualState)
      }
    }, 60000)
  }

  private dateText(): string {
    const now: Date = new Date()
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return `${now.getMonth() + 1}月${now.getDate()}日 ${weeks[now.getDay()]}`
  }

  private updateText(): string {
    if (!this.weatherData.lastUpdate) return ''
    const date: Date = new Date(this.weatherData.lastUpdate)
    const minute: string = date.getMinutes().toString().padStart(2, '0')
    return `${date.getHours()}:${minute} 更新`
  }

  build() {
    Stack() {
      DynamicWeatherBackground({
        visualState: this.visualState,
        hour: this.currentHour,
        motionEnabled: this.motionEnabled,
        themeColors: this.themeColors,
        cityBackgroundResource: this.cityBackgroundResource,
        hasBundledCityBackground: this.hasBundledCityBackground,
        cityBackgroundUrl: this.cityBackgroundUrl
      })
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

      if (this.uiState.status === WeatherUiStatus.LOADING && this.weatherData.lastUpdate === 0) {
        this.skeletonBuilder()
      } else if (this.uiState.status === WeatherUiStatus.ERROR) {
        this.errorBuilder()
      } else {
        this.contentBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  skeletonBuilder() {
    Column() {
      Row() {
        Column()
          .width(128)
          .height(28)
          .borderRadius(14)
          .backgroundColor('rgba(255,255,255,0.18)')
        Blank()
        Column()
          .width(44)
          .height(44)
          .borderRadius(22)
          .backgroundColor('rgba(255,255,255,0.16)')
      }
      .width('100%')
      Column()
        .width(188)
        .height(112)
        .borderRadius(24)
        .backgroundColor('rgba(255,255,255,0.14)')
        .alignSelf(ItemAlign.Start)
        .margin({ top: 80 })
      ForEach([0, 1, 2], (_: number) => {
        Column()
          .width('100%')
          .height(142)
          .borderRadius(28)
          .backgroundColor('rgba(255,255,255,0.12)')
          .margin({ top: 16 })
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 20, right: 20, top: 24 })
  }

  @Builder
  errorBuilder() {
    Column() {
      Image($r('app.media.information_outline'))
        .width(52)
        .height(52)
        .fillColor('#FFFFFF')
      Text('暂时无法获取天气')
        .fontSize(22)
        .fontWeight(FontWeight.Medium)
        .fontColor('#FFFFFF')
        .margin({ top: 20 })
      Text(this.uiState.message)
        .fontSize(14)
        .fontColor('rgba(255,255,255,0.68)')
        .margin({ top: 8 })
      Button('重新加载')
        .height(46)
        .padding({ left: 28, right: 28 })
        .fontColor('#073251')
        .backgroundColor('#8CDEFF')
        .borderRadius(23)
        .margin({ top: 24 })
        .onClick(() => this.loadData(true))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  contentBuilder() {
    Refresh({ refreshing: $$this.refreshing }) {
      Scroll() {
        Column() {
          this.topBar()

          if (this.uiState.status === WeatherUiStatus.STALE || this.weatherData.isOffline) {
            Row({ space: 8 }) {
              Image($r('app.media.information_outline'))
                .width(17)
                .height(17)
                .fillColor(this.themeColors.textColor)
              Text('网络不可用，正在显示上次更新的数据')
                .fontSize(12)
                .fontColor(this.themeColors.textColor)
            }
            .height(34)
            .padding({ left: 12, right: 12 })
            .borderRadius(17)
            .backgroundColor(this.themeColors.strongTint)
            .margin({ left: 20, right: 20, top: 8 })
          }

          HeroSection({
            current: this.weatherData.current,
            displayTemp: this.displayTemperature(this.weatherData.current.temp),
            displayFeels: this.displayTemperature(this.weatherData.current.feelsLike),
            displayHigh: this.displayTemperature(this.weatherData.current.high),
            displayLow: this.displayTemperature(this.weatherData.current.low),
            unitLabel: '°',
            themeColors: this.themeColors
          })

          if (this.weatherData.alerts.length > 0) {
            Row({ space: 9 }) {
              Image($r('app.media.alert'))
                .width(18)
                .height(18)
                .fillColor('#FFFFFF')
              Text(this.weatherData.alerts[0].title)
                .fontSize(13)
                .fontWeight(FontWeight.Medium)
                .fontColor('#FFFFFF')
              Image($r('app.media.chevron_right'))
                .width(16)
                .height(16)
                .fillColor('#FFFFFF')
            }
            .height(34)
            .padding({ left: 14, right: 12 })
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20, bottom: 10 })
            .borderRadius(20)
            .backgroundColor('rgba(255,104,82,0.88)')
            .onClick(() => {
              this.getUIContext().getPromptAction().showToast({
                message: this.weatherData.alerts[0].detail,
                duration: 2600
              })
            })
            .accessibilityText(`${this.weatherData.alerts[0].title}，点击查看详情`)
          }

          HourlyCapsules({ hourly: this.weatherData.hourly, themeColors: this.themeColors, unit: this.unit })
            .margin({ left: 12, right: 12 })

          WeeklyForecast({ daily: this.weatherData.daily, themeColors: this.themeColors, unit: this.unit })
            .margin({ left: 12, right: 12, top: 8 })
            .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/WeatherDetails' }))

          AirQualityCard({
            air: this.weatherData.air,
            current: this.weatherData.current,
            unit: this.unit,
            themeColors: this.themeColors
          })
            .margin({ left: 12, right: 12, top: 8 })

          LifeIndexGrid({ lifeIndex: this.weatherData.lifeIndex, themeColors: this.themeColors })
            .padding({ left: 12, right: 12 })
            .margin({ top: 8 })

          Column() {
            Text('更多天气数据')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.themeColors.textColor)
              .alignSelf(ItemAlign.Start)
              .margin({ left: 18, bottom: 4 })
            DataGrid({ current: this.weatherData.current, themeColors: this.themeColors, unit: this.unit })
          }
          .width('100%')
          .padding({ top: 14, bottom: 8 })
          .margin({ left: 12, right: 12, top: 4 })
          .borderRadius(24)
          .backgroundColor(this.themeColors.sectionTint)

          Column() {
            Text(this.updateText())
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
            Text(this.weatherData.source === 'qweather' ? '数据来源：和风天气' : '演示数据 · 配置本地 API 密钥后获取实时天气')
              .fontSize(10)
              .fontColor(this.themeColors.textTertiary)
              .margin({ top: 5 })
            if (this.cityBackgroundAttribution) {
              Text(this.cityBackgroundAttribution)
                .fontSize(10)
                .fontColor(this.themeColors.textTertiary)
                .margin({ top: 4 })
            }
          }
          .margin({ top: 12, bottom: 36 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onRefreshing(() => {
      this.refreshing = true
      this.loadData(true)
    })
  }

  @Builder
  topBar() {
    Row() {
      Row({ space: 9 }) {
        Image($r('app.media.map_marker'))
          .width(23)
          .height(23)
          .fillColor(this.themeColors.textColor)
        Column() {
          Text(`${this.weatherData.city}市`)
            .fontSize(21)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.themeColors.textColor)
          Text(this.dateText())
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 3 })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))
      .accessibilityText(`当前城市${this.weatherData.city}，点击切换城市`)

      Blank()

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.map_marker'))
          .width(21)
          .height(21)
          .fillColor(this.themeColors.textColor)
      }
      .width(44)
      .height(44)
      .backgroundColor(this.themeColors.sectionTint)
      .accessibilityText('城市管理')
      .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.cog'))
          .width(22)
          .height(22)
          .fillColor(this.themeColors.textColor)
      }
      .width(44)
      .height(44)
      .backgroundColor(this.themeColors.sectionTint)
      .margin({ left: 10 })
      .accessibilityText('天气设置')
      .onClick(() => this.getUIContext().getRouter().pushUrl({ url: 'pages/Settings' }))
    }
    .width('100%')
    .padding({ left: 22, right: 20, top: 44 })
  }
}
