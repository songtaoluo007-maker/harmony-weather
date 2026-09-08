import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit'
import { geoLocationManager } from '@kit.LocationKit'
import { CityInfo } from '../models/WeatherModels'
import { WeatherService } from '../services/WeatherService'
import { DesignTokens as T } from '../theme/DesignTokens'
import { BundledCityBackgrounds } from '../theme/BundledCityBackgrounds'

@Entry
@Component
struct CitySelector {
  @State cities: CityInfo[] = []
  @State selectedId: string = ''
  @State searchKey: string = ''
  @State manageMode: boolean = false
  @State browsingAll: boolean = false
  @State cardWidth: number = 330
  @State locating: boolean = false
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    await this.service.initialize(context)
    this.cities = this.service.getSavedCities()
    this.selectedId = this.service.getCurrentCity().id
  }

  private filteredCities(): CityInfo[] {
    const keyword: string = this.searchKey.trim()
    const list: CityInfo[] = this.browsingAll || keyword ? this.service.getCityList() : this.cities
    if (!keyword) return list
    return list.filter((city: CityInfo) => city.name.includes(keyword) || city.province.includes(keyword))
  }

  private async selectCity(city: CityInfo): Promise<void> {
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    if (!await this.service.selectCity(context, city.id)) {
      this.showToast('城市未能保存，请重试')
      return
    }
    this.selectedId = city.id
    this.showToast(`已切换到${city.name}`)
    setTimeout(() => {
      this.getUIContext().getRouter().back()
    }, 220)
  }

  private async removeCity(city: CityInfo): Promise<void> {
    if (city.id === this.selectedId) { this.showToast('当前城市不能移除'); return }
    const context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
    if (await this.service.removeSavedCity(context, city.id)) this.cities = this.service.getSavedCities()
    else this.showToast('移除失败，请重试')
  }

  private cityImage(id: string): Resource {
    return BundledCityBackgrounds.resolve(id)?.resource ?? $r('app.media.weather_bg_day')
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
    Column() {
      Row({ space: 8 }) {
        Button({ type: ButtonType.Circle }) {
          Image($r('app.media.chevron_left')).width(23).height(23).fillColor(T.text)
        }.width(44).height(44).backgroundColor(Color.Transparent)
          .onClick(() => this.getUIContext().getRouter().back()).accessibilityText('返回天气')
        Text(this.browsingAll ? '添加城市' : '我的城市').fontSize(22).fontWeight(FontWeight.Medium).fontColor(T.text)
        Blank()
        Button(this.manageMode ? '完成' : '编辑', { type: ButtonType.Normal })
          .height(44).fontSize(13).fontColor(T.accent).backgroundColor(Color.Transparent)
          .onClick(() => { this.manageMode = !this.manageMode; this.browsingAll = false })
          .accessibilityText(this.manageMode ? '完成城市编辑' : '编辑已保存城市')
        Button({ type: ButtonType.Circle }) {
          Image(this.browsingAll ? $r('app.media.close') : $r('app.media.plus'))
            .width(23).height(23).fillColor(T.text)
        }.width(44).height(44).backgroundColor(Color.Transparent)
          .onClick(() => { this.browsingAll = !this.browsingAll; this.manageMode = false })
          .accessibilityText(this.browsingAll ? '关闭添加城市' : '添加城市')
      }.width('100%').padding({ left: 12, right: 16, top: 42, bottom: 18 })

      Column({ space: 14 }) {
        Search({ value: this.searchKey, placeholder: '搜索城市或省份' })
          .width('100%').height(48).fontColor(T.text).placeholderColor(T.muted)
          .backgroundColor(T.surface).borderRadius(16)
          .searchIcon({ src: $r('app.media.magnify'), color: T.muted })
          .cancelButton({ style: CancelButtonStyle.INPUT, icon: { src: $r('app.media.close'), color: T.muted } })
          .onChange((value: string) => { this.searchKey = value })

        Row({ space: 12 }) {
          Image($r('app.media.map_marker')).width(21).height(21).fillColor(T.accent)
          Column({ space: 4 }) {
            Text('使用当前位置').fontSize(14).fontColor(T.text)
            Text('查找附近的已支持城市').fontSize(11).fontColor(T.muted)
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
          if (this.locating) {
            LoadingProgress().width(22).height(22).color(T.accent)
          } else {
            Image($r('app.media.chevron_right')).width(18).height(18).fillColor(T.muted)
          }
        }.width('100%').padding({ top: 8, bottom: 16 })
          .onClick(() => this.locateCurrentCity()).accessibilityText('定位附近城市')
        Row() {
          Text(this.searchKey ? '搜索结果' : this.browsingAll ? '支持的城市' : '已保存')
            .fontSize(12).fontColor(T.muted)
          Blank()
          Text(`${this.filteredCities().length} 座城市`).fontSize(11).fontColor(T.muted)
        }.width('100%')
      }.width('100%').padding({ left: 24, right: 24, bottom: 16 })

      if (this.filteredCities().length === 0) {
        Column({ space: 12 }) {
          Image($r('app.media.magnify')).width(42).height(42).fillColor(T.muted)
          Text('没有找到这座城市').fontSize(18).fontColor(T.text)
          Text('试试城市名称或所在省份').fontSize(12).fontColor(T.muted)
        }.layoutWeight(1).width('100%').justifyContent(FlexAlign.Start).padding({ top: 24 })
      } else {
        List({ space: 12 }) {
          ForEach(this.filteredCities(), (city: CityInfo) => {
            ListItem() { this.cityCard(city) }
          }, (city: CityInfo) => city.id)
        }.layoutWeight(1).width('100%')
          .padding({ left: 24, right: 24, bottom: 36 }).scrollBar(BarState.Off)
      }
    }.width('100%').height('100%').backgroundColor(T.page)
  }

  @Builder
  cityCard(city: CityInfo) {
    Stack({ alignContent: Alignment.Top }) {
      Image(this.cityImage(city.id)).width('100%').height(this.cardWidth * 1920 / 1080)
        .objectFit(ImageFit.Cover).translate({ y: -(this.cardWidth * 1920 / 1080 - 116) * 0.75 })
      Column().width('100%').height('100%')
        .linearGradient({ direction: GradientDirection.Right,
          colors: [['rgba(12,30,47,0.90)', 0], ['rgba(12,30,47,0.32)', 1]] })
      Row() {
        Column({ space: 8 }) {
          Row({ space: 10 }) {
            Text(city.name).fontSize(21).fontWeight(FontWeight.Medium).fontColor(T.text)
            if (city.id === this.selectedId) {
              Text('当前').fontSize(10).fontColor('#CEEAF4')
                .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                .backgroundColor('rgba(170,220,233,0.18)').borderRadius(7)
            }
          }
          Text(city.province).fontSize(12).fontColor('#C4D2DF')
        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        if (this.manageMode) {
          Button({ type: ButtonType.Circle }) {
            Image($r('app.media.trash')).width(20).height(20).fillColor('#FFD1C8')
          }.width(44).height(44).backgroundColor('rgba(81,32,33,0.65)')
            .onClick(() => this.removeCity(city)).accessibilityText(`移除${city.name}`)
        } else {
          Image($r('app.media.chevron_right')).width(18).height(18).fillColor('#D3E1EC')
        }
      }.width('100%').padding(20)
    }.width('100%').height(116).borderRadius(22).clip(true)
      .onAreaChange((_old: Area, area: Area) => { this.cardWidth = Number(area.width) })
      .border({ width: city.id === this.selectedId ? 1.2 : 0, color: '#8DBBCB' })
      .onClick(() => { if (!this.manageMode) this.selectCity(city) })
      .accessibilityText(`${city.name}，${city.province}，${city.id === this.selectedId ? '当前城市' : '点击切换'}`)
  }
}
