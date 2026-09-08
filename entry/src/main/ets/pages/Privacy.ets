import { PageHeader } from '../components/PageHeader'
import { DesignTokens as T } from '../theme/DesignTokens'

@Entry
@Component
struct Privacy {
  @Builder
  paragraph(title: string, body: string) {
    Column({ space: 10 }) {
      Text(title).fontSize(17).fontWeight(FontWeight.Medium).fontColor(T.text)
      Text(body).fontSize(14).lineHeight(24).fontColor(T.muted)
    }.width('100%').alignItems(HorizontalAlign.Start).margin({ bottom: 24 })
  }
  build() {
    Column() {
      PageHeader({ heading: '隐私说明' })
      Scroll() {
        Column() {
          this.paragraph('天气与城市', '查询天气时，会向天气服务发送所选城市的经纬度与天气参数。应用不要求注册账户；当前版本未集成广告或行为统计 SDK。')
          this.paragraph('定位权限', '只有点击城市管理中的定位按钮时才申请权限并读取位置，用于匹配当前支持的城市。设备坐标在本机完成匹配，不作为设备轨迹上传。拒绝定位后仍可手动选城。')
          this.paragraph('本机存储', '城市、显示设置与历史天气保存在本机。可在设置中清理天气缓存，城市与偏好不会一并删除。卸载应用会移除其本地数据。')
          this.paragraph('资讯阅读', '点击资讯栏目后，会连接相应的官方网页。原网站可能接收 IP、浏览器信息并使用 Cookie 或其第三方资源，适用原网站的隐私规则。阅读器不向网页开放本机文件、定位、相机、麦克风或应用数据。')
          this.paragraph('权限管理', '可通过“设置 → 定位权限”进入系统应用设置，查看或撤销权限。天气更新频率仅在使用应用时生效。')
        }.width('100%').padding({ left: 24, right: 24, bottom: 32 })
      }.width('100%').layoutWeight(1).scrollBar(BarState.Off)
    }.width('100%').height('100%').backgroundColor(T.page)
  }
}
