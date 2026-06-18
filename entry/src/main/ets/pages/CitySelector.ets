import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { geoLocationManager } from '@kit.LocationKit'
import { CityInfo } from '../models/WeatherModels'
import { WeatherService } from '../services/WeatherService'

@Entry
@Component
struct CitySelector {
  @State cities: CityInfo[] = []
  @State selectedId: string = ''
  @State searchKey: string = ''
  @State manageMode: boolean = false
  @State locating: boolean = false
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    this.cities = this.service.getCityList()
    this.selectedId = this.service.getCurrentCity().id
  }

  private filteredCities(): CityInfo[] {
    const keyword: string = this.searchKey.trim()
    if (!keyword) return this.cities
    return this.cities.filter((city: CityInfo) => city.name.includes(keyword) || city.province.includes(keyword))
  }

  private async selectCity(city: CityInfo): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.selectCity(context, city.id)
    this.selectedId = city.id
    this.showToast(`已切换到${city.name}`)
    setTimeout(() => {
      this.getUIContext().getRouter().back()
    }, 220)
  }

  private removeCity(city: CityInfo): void {
    if (city.id === this.selectedId) {
      this.showToast('当前城市不能删除')
      return
    }
    this.cities = this.cities.filter((item: CityInfo) => item.id !== city.id)
  }

  private async locateCurrentCity(): Promise<void> {
    if (this.locating) return
    this.locating = true
    try {
      const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      const permissions: Array<Permissions> = [
        'ohos.permission.APPROXIMATELY_LOCATION',
        'ohos.permission.LOCATION'
      ] as Array<Permissions>
      const result = await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(context, permissions)
      const granted: boolean = result.authResults.some((value: number) => value === 0)
      if (!granted) {
        this.showToast('未获得定位权限，可手动选择城市', 1800)
        return
      }
      const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation()
      const nearest: CityInfo = this.service.findNearestCity(location.latitude, location.longitude)
      await this.selectCity(nearest)
    } catch (error) {
      this.showToast('定位失败，请检查系统定位开关', 1800)
    } finally {
      this.locating = false
    }
  }

  private showToast(message: string, duration: number = 1200): void {
    try {
      this.getUIContext().getPromptAction().showToast({ message: message, duration: duration })
    } catch (error) {
      console.warn('显示城市提示失败: ' + JSON.stringify(error))
    }
  }

  build() {
    Stack() {
      Image($r('app.media.weather_bg_dusk'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(5,25,55,0.64)')

      Column() {
        Row() {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.chevron_left'))
              .width(22)
              .height(22)
              .fillColor('#FFFFFF')
          }
          .width(44)
          .height(44)
          .backgroundColor('rgba(255,255,255,0.14)')
          .accessibilityText('返回')
          .onClick(() => this.getUIContext().getRouter().back())

          Text('城市管理')
            .fontSize(24)
            .fontWeight(FontWeight.Medium)
            .fontColor('#FFFFFF')
            .margin({ left: 14 })

          Blank()

          Text(this.manageMode ? '完成' : '管理')
            .fontSize(15)
            .fontColor('rgba(255,255,255,0.82)')
            .height(44)
            .padding({ left: 12, right: 12 })
            .onClick(() => {
              this.manageMode = !this.manageMode
            })
            .accessibilityText(this.manageMode ? '完成城市管理' : '管理城市')
        }
        .width('100%')
      .padding({ left: 20, right: 20, top: 44 })

        Search({ value: this.searchKey, placeholder: '搜索城市或省份' })
          .width('100%')
          .height(48)
          .fontColor('#FFFFFF')
          .placeholderColor('rgba(255,255,255,0.48)')
          .backgroundColor('rgba(255,255,255,0.14)')
          .borderRadius(24)
          .searchIcon({ src: $r('app.media.magnify') })
          .cancelButton({ style: CancelButtonStyle.CONSTANT, icon: { src: $r('app.media.close') } })
          .onChange((value: string) => {
            this.searchKey = value
          })
          .margin({ left: 20, right: 20, top: 20, bottom: 16 })

        Row() {
          Image($r('app.media.map_marker'))
            .width(24)
            .height(24)
            .fillColor('#62D2FF')
          Column() {
            Text('当前位置')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.58)')
            Text(this.service.getCurrentCity().name)
              .fontSize(17)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
          Blank()
          Text(this.locating ? '定位中…' : '重新定位')
            .fontSize(13)
            .fontColor('#62D2FF')
        }
        .width('100%')
        .height(64)
        .padding({ left: 18, right: 18 })
        .margin({ left: 20, right: 20, bottom: 14 })
        .borderRadius(20)
        .backgroundColor('rgba(255,255,255,0.12)')
        .onClick(() => {
          this.locateCurrentCity()
        })
        .accessibilityText(`当前位置${this.service.getCurrentCity().name}，点击重新定位`)

        if (this.filteredCities().length === 0) {
          Column() {
            Image($r('app.media.magnify'))
              .width(42)
              .height(42)
              .fillColor('rgba(255,255,255,0.46)')
            Text('没有找到匹配城市')
              .fontSize(16)
              .fontColor('rgba(255,255,255,0.72)')
              .margin({ top: 14 })
            Text('试试输入城市简称或省份')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.42)')
              .margin({ top: 6 })
          }
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
        } else {
          List({ space: 10 }) {
            ForEach(this.filteredCities(), (city: CityInfo) => {
              ListItem() {
                Row() {
                  Column() {
                    Row({ space: 8 }) {
                      Text(city.name)
                        .fontSize(18)
                        .fontWeight(FontWeight.Medium)
                        .fontColor('#FFFFFF')
                      if (city.id === this.selectedId) {
                        Text('当前')
                          .fontSize(10)
                          .fontColor('#083456')
                          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                          .borderRadius(10)
                          .backgroundColor('#8CDEFF')
                      }
                    }
                    Text(city.province)
                      .fontSize(12)
                      .fontColor('rgba(255,255,255,0.48)')
                      .margin({ top: 5 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  Blank()
                  if (this.manageMode) {
                    Button({ type: ButtonType.Circle }) {
                      Image($r('app.media.trash'))
                        .width(20)
                        .height(20)
                        .fillColor('#FF8B7B')
                    }
                    .width(40)
                    .height(40)
                    .backgroundColor('rgba(255,116,94,0.12)')
                    .accessibilityText(`删除${city.name}`)
                    .onClick(() => this.removeCity(city))
                  } else {
                    Image($r('app.media.chevron_right'))
                      .width(18)
                      .height(18)
                      .fillColor('rgba(255,255,255,0.48)')
                  }
                }
                .width('100%')
                .height(72)
                .padding({ left: 18, right: 14 })
                .borderRadius(22)
                .backgroundColor(city.id === this.selectedId ? 'rgba(98,210,255,0.18)' : 'rgba(255,255,255,0.10)')
                .onClick(() => {
                  if (!this.manageMode) this.selectCity(city)
                })
                .accessibilityText(`${city.name}${city.province}${city.id === this.selectedId ? '当前城市' : ''}`)
              }
            }, (city: CityInfo) => city.id)
          }
          .layoutWeight(1)
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })
          .scrollBar(BarState.Off)
        }
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
