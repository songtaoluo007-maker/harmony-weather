import { SystemBarService } from '../services/SystemBarService'
import { abilityAccessCtrl, common } from '@kit.AbilityKit'
import { AppSettings, WeatherService } from '../services/WeatherService'
import { BottomNavigation } from '../components/BottomNavigation'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct SettingsPage {
  @State unit: string = 'c'
  @State motionEnabled: boolean = true
  @State refreshMinutes: number = 30
  @State cityName: string = ''
  @State permissionLabel: string = '查看'
  @State saving: boolean = false
  @State clearing: boolean = false
  private service: WeatherService = WeatherService.getInstance()

  async aboutToAppear(): Promise<void> {
    await this.service.initialize(this.context())
    this.restoreSettings()
    this.readPermission()
  }

  onPageShow(): void { SystemBarService.apply(this.getUIContext().getHostContext() as common.UIAbilityContext); this.restoreSettings(); this.readPermission() }
  onBackPress(): boolean { this.returnHome(); return true }
  private async returnHome(): Promise<void> {
    try { await this.getUIContext().getRouter().replaceUrl({ url: 'pages/Index' }) } catch (error) { this.toast('请点击天气入口返回') }
  }
  private context(): common.UIAbilityContext { return this.getUIContext().getHostContext() as common.UIAbilityContext }
  private toast(message: string): void {
    try { this.getUIContext().getPromptAction().showToast({ message: message }) } catch (error) {}
  }

  private restoreSettings(): void {
    const settings: AppSettings = this.service.getSettings()
    this.unit = settings.unit
    this.motionEnabled = settings.motionEnabled
    this.refreshMinutes = settings.refreshMinutes
    this.cityName = this.service.getCurrentCity().name
  }

  private readPermission(): void {
    try {
      const manager = abilityAccessCtrl.createAtManager()
      this.permissionLabel = manager.getSelfPermissionStatus('ohos.permission.APPROXIMATELY_LOCATION') ===
        abilityAccessCtrl.PermissionStatus.GRANTED ? '已允许' : '未允许'
    } catch (error) { this.permissionLabel = '查看' }
  }

  private async openPermissions(): Promise<void> {
    try {
      await this.context().startAbility({
        bundleName: 'com.huawei.hmos.settings', abilityName: 'com.huawei.hmos.settings.MainAbility',
        uri: 'application_info_entry', parameters: { pushParams: this.context().abilityInfo.bundleName }
      })
    } catch (error) {
      this.getUIContext().showAlertDialog({ title: '定位权限', message: '请前往系统设置中的应用权限管理，调整本应用的定位权限。',
        confirm: { value: '知道了', action: () => {} } })
    }
  }

  private async save(): Promise<void> {
    if (this.saving) return
    this.saving = true
    const value: AppSettings = new AppSettings()
    value.unit = this.unit; value.motionEnabled = this.motionEnabled; value.refreshMinutes = this.refreshMinutes
    if (!await this.service.saveSettings(this.context(), value)) {
      this.restoreSettings()
      this.toast('设置未能保存，请重试')
    }
    this.saving = false
  }

  private confirmClear(): void {
    if (this.clearing) return
    this.getUIContext().showAlertDialog({ title: '清理天气缓存？',
      message: '已保存的天气将被清除，城市和显示设置保留。下次查看天气需要联网。',
      primaryButton: { value: '取消', action: () => {} },
      secondaryButton: { value: '清理', action: () => this.clearCache() } })
  }

  private async clearCache(): Promise<void> {
    if (this.clearing) return
    this.clearing = true
    const cleared: boolean = await this.service.clearWeatherCache(this.context())
    this.clearing = false
    this.toast(cleared ? '天气缓存已清理' : '清理失败，请重试')
  }

  @Builder
  section(title: string) {
    Text(title).fontSize(12).fontColor(T.muted).alignSelf(ItemAlign.Start).margin({ top: 16, bottom: 10, left: 4 })
  }

  @Builder
  actionRow(icon: Resource, label: string, value: string, action: () => void) {
    Button({ type: ButtonType.Normal }) {
      Row({ space: 12 }) {
        Image(icon).width(20).height(20).fillColor(T.accent)
        Text(label).fontSize(15).fontColor(T.text).layoutWeight(1).textAlign(TextAlign.Start)
        Text(value).fontSize(12).fontColor(T.muted).maxLines(1)
        Image($r('app.media.chevron_right')).width(16).height(16).fillColor(T.muted)
      }.width('100%').constraintSize({ minHeight: 54 }).padding({ left: 16, right: 16 })
    }.width('100%').backgroundColor(Color.Transparent).borderRadius(12).onClick(action)
      .accessibilityText(`${label}${value ? '，' + value : ''}`)
  }

  @Builder
  option(label: string, selected: boolean, action: () => void) {
    Button(label, { type: ButtonType.Normal }).fontSize(12).height(44).layoutWeight(1).borderRadius(12)
      .fontColor(selected ? T.page : T.muted).backgroundColor(selected ? T.accent : T.page)
      .enabled(!this.saving).onClick(action).accessibilityText(`${label}，${selected ? '已选择' : '未选择'}`)
  }

  build() {
    Column() {
      Text('设置').fontSize(28).fontWeight(FontWeight.Medium).fontColor(T.text)
        .width('100%').padding({ left: 24, top: 48, bottom: 20 })
      Scroll() {
        Column() {
          this.section('城市与定位')
          Column() {
            this.actionRow($r('app.media.map_marker'), '城市管理', this.cityName,
              () => this.getUIContext().getRouter().pushUrl({ url: 'pages/CitySelector' }))
            Divider().color(T.border).strokeWidth(0.5).width('88%')
            this.actionRow($r('app.media.map_marker'), '定位权限', this.permissionLabel, () => this.openPermissions())
          }.width('100%').backgroundColor(T.surface).borderRadius(18)

          this.section('显示与更新')
          Column({ space: 15 }) {
            Text('温度单位').fontSize(15).fontColor(T.text).alignSelf(ItemAlign.Start)
            Row({ space: 8 }) {
              this.option('摄氏度 °C', this.unit === 'c', () => { this.unit = 'c'; this.save() })
              this.option('华氏度 °F', this.unit === 'f', () => { this.unit = 'f'; this.save() })
            }.width('100%')
            Divider().color(T.border).strokeWidth(0.5)
            Row() {
              Text('动态天气').fontSize(15).fontColor(T.text).layoutWeight(1)
              Toggle({ type: ToggleType.Switch, isOn: this.motionEnabled }).selectedColor(T.accent).enabled(!this.saving)
                .onChange((value: boolean) => { this.motionEnabled = value; this.save() }).accessibilityText('动态天气开关')
            }.width('100%').constraintSize({ minHeight: 44 })
            Divider().color(T.border).strokeWidth(0.5)
            Text('天气更新频率').fontSize(15).fontColor(T.text).alignSelf(ItemAlign.Start)
            Row({ space: 8 }) {
              this.option('15分钟', this.refreshMinutes === 15, () => { this.refreshMinutes = 15; this.save() })
              this.option('30分钟', this.refreshMinutes === 30, () => { this.refreshMinutes = 30; this.save() })
              this.option('60分钟', this.refreshMinutes === 60, () => { this.refreshMinutes = 60; this.save() })
            }.width('100%')
          }.width('100%').padding(16).backgroundColor(T.surface).borderRadius(18)

          this.section('存储与隐私')
          Column() {
            this.actionRow($r('app.media.trash'), '清理天气缓存', this.clearing ? '清理中' : '', () => this.confirmClear())
            Divider().color(T.border).strokeWidth(0.5).width('88%')
            this.actionRow($r('app.media.information_outline'), '隐私说明', '',
              () => this.getUIContext().getRouter().pushUrl({ url: 'pages/Privacy' }))
          }.width('100%').backgroundColor(T.surface).borderRadius(18)
          Column() {
            this.actionRow($r('app.media.information_outline'), '关于原境天气', '',
              () => this.getUIContext().getRouter().pushUrl({ url: 'pages/About' }))
          }.width('100%').backgroundColor(T.surface).borderRadius(18).margin({ top: 16 })
        }.width('100%').padding({ left: 24, right: 24, bottom: 24 })
      }.layoutWeight(1).width('100%').scrollBar(BarState.Off)
      BottomNavigation({ selected: 'settings' })
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
