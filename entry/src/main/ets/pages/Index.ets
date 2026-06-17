// ─── 主页面：全屏沉浸式天气仪表盘 ────────────────────
// 支持下拉刷新、骨架屏加载、错误处理
import { router } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { WeatherData, WeatherType } from '../models/WeatherModels'
import { ThemeColors, WeatherTheme } from '../theme/WeatherTheme'
import { WeatherService } from '../services/WeatherService'
import { BreathingBackground } from '../components/BreathingBackground'
import { HeroSection } from '../components/HeroSection'
import { HourlyCapsules } from '../components/HourlyCapsules'
import { WeeklyForecast } from '../components/WeeklyForecast'
import { DataGrid } from '../components/DataGrid'
import { AirQualityCard } from '../components/AirQualityCard'
import { LifeIndexGrid } from '../components/LifeIndexGrid'

@Entry
@Component
struct Index {
  @State weatherData: WeatherData = new WeatherData()
  @State weatherType: WeatherType = WeatherType.SUNNY
  @State themeColors: ThemeColors = new ThemeColors()
  @State isLoaded: boolean = false
  @State hasError: boolean = false
  @State errorMsg: string = ''
  @State refreshRotate: number = 0
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.loadData()
  }

  // 加载天气数据
  async loadData(): Promise<void> {
    this.hasError = false
    this.errorMsg = ''
    try {
      const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
      const data: WeatherData = await this.service.loadWeather(context)
      this.weatherData = data
      this.weatherType = WeatherData.textToType(data.current.text)
      this.themeColors = WeatherTheme.getColors(this.weatherType, new Date().getHours())
      this.isLoaded = true
    } catch (e) {
      this.hasError = true
      this.errorMsg = '加载天气数据失败，请检查网络连接'
      console.error('加载天气数据失败: ' + JSON.stringify(e))
    }
  }

  // 下拉刷新
  async onRefresh(): Promise<void> {
    this.refreshRotate += 360
    this.isLoaded = false
    await this.loadData()
  }

  // 重试加载
  async onRetry(): Promise<void> {
    await this.loadData()
  }

  build() {
    Stack() {
      // ─── 呼吸背景 ─────────────────────────────
      BreathingBackground({
        weatherType: $weatherType,
        themeColors: $themeColors
      })

      // ─── 骨架屏（加载中） ─────────────────────
      if (!this.isLoaded && !this.hasError) {
        this.skeletonBuilder()
      }

      // ─── 错误页面 ─────────────────────────────
      if (this.hasError) {
        this.errorBuilder()
      }

      // ─── 内容层 ───────────────────────────────
      if (this.isLoaded) {
        this.contentBuilder()
      }
    }
    .width('100%')
    .height('100%')
  }

  // 骨架屏 Builder
  @Builder
  skeletonBuilder() {
    Column() {
      // 顶部骨架
      Row() {
        Column()
          .width(80)
          .height(18)
          .borderRadius(9)
          .backgroundColor('rgba(255,255,255,0.15)')
        Blank()
        Column()
          .width(22)
          .height(22)
          .borderRadius(11)
          .backgroundColor('rgba(255,255,255,0.15)')
        Column()
          .width(22)
          .height(22)
          .borderRadius(11)
          .backgroundColor('rgba(255,255,255,0.15)')
          .margin({ left: 16 })
      }
      .width('100%')
      .padding({ left: 24, right: 24, top: 16 })

      // 温度骨架
      Column()
        .width(160)
        .height(80)
        .borderRadius(12)
        .backgroundColor('rgba(255,255,255,0.1)')
        .margin({ top: 80 })

      // 文字骨架
      Column()
        .width(100)
        .height(24)
        .borderRadius(12)
        .backgroundColor('rgba(255,255,255,0.1)')
        .margin({ top: 16 })

      // 卡片骨架
      ForEach([0, 1, 2, 3], (_: number, index: number) => {
        Column()
          .width('90%')
          .height(80)
          .borderRadius(16)
          .backgroundColor('rgba(255,255,255,0.08)')
          .margin({ top: 16 })
      })

      Spacer()
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }

  // 错误页面 Builder
  @Builder
  errorBuilder() {
    Column() {
      Text('⚠')
        .fontSize(48)
        .margin({ bottom: 16 })

      Text(this.errorMsg)
        .fontSize(16)
        .fontColor('rgba(255,255,255,0.8)')
        .margin({ bottom: 24 })

      Text('重试')
        .fontSize(16)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Medium)
        .padding({ left: 32, right: 32, top: 12, bottom: 12 })
        .borderRadius(24)
        .backgroundColor('rgba(255,255,255,0.2)')
        .border({ width: 1, color: 'rgba(255,255,255,0.3)' })
        .onClick(() => {
          this.onRetry()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  // 主内容 Builder
  @Builder
  contentBuilder() {
    Scroll() {
      Column() {
        // 顶部栏：城市名 + 刷新 + 城市选择
        Row() {
          Text(this.weatherData.city)
            .fontSize(18)
            .fontColor(this.themeColors.textColor)
            .layoutWeight(1)

          // 刷新按钮
          Text('⟳')
            .fontSize(22)
            .fontColor(this.themeColors.textSecondary)
            .rotate({ angle: this.refreshRotate })
            .animation({ duration: 600, curve: Curve.EaseOut })
            .onClick(() => {
              this.onRefresh()
            })

          // 城市选择按钮
          Text('☰')
            .fontSize(22)
            .fontColor(this.themeColors.textSecondary)
            .margin({ left: 20 })
            .onClick(() => {
              router.pushUrl({ url: 'pages/CitySelector' })
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24, top: 16 })

        // Hero 区：温度 + 天气
        HeroSection({
          city: this.weatherData.city,
          current: this.weatherData.current,
          themeColors: this.themeColors
        })

        // 逐小时胶囊
        HourlyCapsules({
          hourly: this.weatherData.hourly,
          themeColors: this.themeColors
        })
          .opacity(1)
          .translate({ y: 0 })
          .animation({ duration: 600, curve: Curve.EaseOut, delay: 200 })

        // 7日预报
        WeeklyForecast({
          daily: this.weatherData.daily,
          themeColors: this.themeColors
        })
          .margin({ top: 16 })
          .opacity(1)
          .translate({ y: 0 })
          .animation({ duration: 600, curve: Curve.EaseOut, delay: 400 })

        // 空气质量
        AirQualityCard({
          air: this.weatherData.air,
          themeColors: this.themeColors
        })
          .margin({ top: 16 })
          .opacity(1)
          .translate({ y: 0 })
          .animation({ duration: 600, curve: Curve.EaseOut, delay: 600 })

        // 数据网格
        DataGrid({
          current: this.weatherData.current,
          themeColors: this.themeColors
        })
          .margin({ top: 16 })
          .opacity(1)
          .translate({ y: 0 })
          .animation({ duration: 600, curve: Curve.EaseOut, delay: 800 })

        // 生活指数
        LifeIndexGrid({
          lifeIndex: this.weatherData.lifeIndex,
          themeColors: this.themeColors
        })
          .margin({ top: 16 })
          .opacity(1)
          .translate({ y: 0 })
          .animation({ duration: 600, curve: Curve.EaseOut, delay: 1000 })

        // 底部信息
        Column() {
          Text(`数据更新于 ${new Date(this.weatherData.lastUpdate).toLocaleTimeString()}`)
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
          Text('Powered by QWeather')
            .fontSize(10)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 4 })
        }
        .margin({ top: 24, bottom: 40 })
        .opacity(1)
        .animation({ duration: 600, curve: Curve.EaseOut, delay: 1200 })
      }
      .width('100%')
    }
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .height('100%')
  }
}
