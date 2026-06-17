// ─── 城市选择页：毛玻璃网格 + 搜索 + 入场动画 ────────
// 改进：搜索清除按钮、系统返回图标
import { router } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { WeatherService } from '../services/WeatherService'

@Entry
@Component
struct CitySelector {
  @State cities: string[] = []
  @State selectedIndex: number = -1
  @State searchKey: string = ''
  @State showContent: boolean = false
  private service: WeatherService = WeatherService.getInstance()

  aboutToAppear(): void {
    this.cities = this.service.getCityList()
    this.selectedIndex = this.cities.indexOf(this.service.getCurrentCity())
    setTimeout(() => {
      this.showContent = true
    }, 100)
  }

  // 过滤城市列表
  private getFilteredCities(): string[] {
    if (this.searchKey.length === 0) {
      return this.cities
    }
    return this.cities.filter((c: string) => c.includes(this.searchKey))
  }

  // 清除搜索框
  private clearSearch(): void {
    this.searchKey = ''
  }

  build() {
    Column() {
      // ─── 顶部栏 ─────────────────────────────
      Row() {
        // 使用符号图标替代文字箭头
        Text('<')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .width(36)
          .height(36)
          .textAlign(TextAlign.Center)
          .borderRadius(18)
          .backgroundColor('rgba(255,255,255,0.15)')
          .onClick(() => {
            router.back()
          })

        Text('选择城市')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .fontWeight(FontWeight.Medium)
          .margin({ left: 16 })

        Blank()

        Text('管理')
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.6)')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      // ─── 搜索框（带清除按钮） ───────────────
      Row() {
        TextInput({ placeholder: '搜索城市', text: this.searchKey })
          .layoutWeight(1)
          .height(44)
          .backgroundColor('transparent')
          .fontColor('#FFFFFF')
          .placeholderColor('rgba(255,255,255,0.4)')
          .onChange((value: string) => {
            this.searchKey = value
          })

        // 清除按钮：仅在有搜索内容时显示
        if (this.searchKey.length > 0) {
          Text('X')
            .fontSize(14)
            .fontColor('rgba(255,255,255,0.6)')
            .width(28)
            .height(28)
            .textAlign(TextAlign.Center)
            .borderRadius(14)
            .backgroundColor('rgba(255,255,255,0.15)')
            .margin({ left: 8 })
            .onClick(() => {
              this.clearSearch()
            })
        }
      }
      .width('100%')
      .height(44)
      .backgroundColor('rgba(255,255,255,0.1)')
      .borderRadius(12)
      .padding({ left: 12, right: 12 })
      .margin({ left: 20, right: 20, top: 12, bottom: 16 })

      // ─── 城市网格 ─────────────────────────────
      Scroll() {
        Flex({ wrap: FlexWrap.Wrap, space: { main: new LengthMetrics(12), cross: new LengthMetrics(12) } }) {
          ForEach(this.getFilteredCities(), (city: string, index: number) => {
            Column() {
              Text(city)
                .fontSize(16)
                .fontColor(this.selectedIndex === index ? '#1a1a2e' : '#FFFFFF')
                .fontWeight(this.selectedIndex === index ? FontWeight.Medium : FontWeight.Normal)

              if (this.selectedIndex === index) {
                Text('当前')
                  .fontSize(10)
                  .fontColor('rgba(26,26,46,0.6)')
                  .margin({ top: 4 })
              }
            }
            .width('30%')
            .height(72)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .borderRadius(16)
            .backgroundColor(
              this.selectedIndex === index ? 'rgba(255,255,255,0.9)' : 'rgba(255,255,255,0.08)'
            )
            .border({
              width: this.selectedIndex === index ? 0 : 1,
              color: 'rgba(255,255,255,0.12)'
            })
            .opacity(this.showContent ? 1 : 0)
            .scale({ x: this.showContent ? 1 : 0.8, y: this.showContent ? 1 : 0.8 })
            .animation({
              duration: 400,
              curve: Curve.EaseOut,
              delay: index * 40
            })
            .onClick(() => {
              this.onCitySelect(city, index)
            })
          }, (city: string, index: number) => `${index}_${city}`)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // ─── 底部提示 ─────────────────────────────
      Text('数据来源于和风天气，仅供参考')
        .fontSize(12)
        .fontColor('rgba(255,255,255,0.3)')
        .padding({ bottom: 24, top: 12 })
    }
    .width('100%')
    .height('100%')
    .linearGradient({
      direction: GradientDirection.Bottom,
      colors: [['#1a1a2e', 0], ['#16213e', 0.5], ['#0f3460', 1]]
    })
  }

  // 城市选择处理
  private async onCitySelect(city: string, index: number): Promise<void> {
    this.selectedIndex = index
    this.service.setCurrentCity(city)

    promptAction.showToast({
      message: `已切换到${city}`,
      duration: 1500
    })

    // 延迟返回，让用户看到选中效果
    setTimeout(() => {
      router.back()
    }, 300)
  }
}
