import { LifeIndex, WeatherAlert, WeatherData } from './WeatherModels'
import { PollutantValue, WeatherPresentation } from './WeatherPresentation'

export class WeatherDetailRow {
  label: string
  value: string
  unit: string
  constructor(label: string, value: string, unit: string = '') { this.label = label; this.value = value; this.unit = unit }
}

export class WeatherDetailContent {
  title: string = ''
  subtitle: string = ''
  headline: string = ''
  context: string = ''
  metadata: string = ''
  iconKey: string = ''
  layout: string = 'list'
  rows: WeatherDetailRow[] = []
}

/** Sheet content is shared and testable, independent of the native modal lifecycle. */
export class WeatherDetailPresentation {
  static air(data: WeatherData): WeatherDetailContent {
    const detail = new WeatherDetailContent()
    detail.title = '空气质量'
    detail.layout = 'metrics'
    detail.subtitle = `${data.city} · ${data.air.standard}`
    const available: boolean = data.air.available && Number.isFinite(data.air.aqi) && data.air.aqi >= 0
    detail.headline = available ? `${data.air.aqi} · ${data.air.level}` : '空气质量暂不可用'
    detail.context = available ? (data.source === 'openmeteo' ?
      'CAMS 空气质量模型估算，非站点实测。\n不同 AQI 标准不宜直接比较。' : data.air.advice) :
      '当前未取得可用空气质量数据，请稍后刷新。'
    if (available) {
      detail.rows = WeatherPresentation.pollutants(data.air).map((item: PollutantValue) =>
        new WeatherDetailRow(item.label, item.value, item.unit))
    }
    detail.metadata = WeatherDetailPresentation.metadata(data) + '\n空气观测时刻：未提供'
    return detail
  }

  static life(data: WeatherData, item: LifeIndex): WeatherDetailContent {
    const detail = new WeatherDetailContent()
    detail.title = item.name
    detail.subtitle = `${data.city} · ${WeatherDetailPresentation.lifeCaption(data, item) || '生活气象'}`
    detail.headline = item.brief || '暂无数据'
    detail.context = item.detail || '当前暂无该项指数，请稍后刷新。'
    detail.iconKey = item.iconKey
    detail.metadata = WeatherDetailPresentation.metadata(data)
    if (item.source === 'local') detail.metadata += '\n建议来源：本地天气规则'
    else if (item.source === 'qweather') detail.metadata += '\n指数来源：和风天气'
    return detail
  }

  static lifeCaption(data: WeatherData, item: LifeIndex, now: number = Date.now()): string {
    const peak: boolean = data.current.uvScope === 'daily_max'
    if (item.iconKey !== 'uv' || item.source !== 'local' || (!peak && data.current.uvScope !== 'daily')) return item.caption || ''
    const fallback: string = peak ? '预报峰值' : '逐日预报'
    const stamp: number = data.observedAt > 0 ? data.observedAt : data.lastUpdate
    if (!Number.isFinite(stamp) || stamp <= 0 || !Number.isFinite(now) || !Number.isFinite(data.utcOffsetSeconds)) return fallback
    const date: string = WeatherData.localDate(stamp, data.utcOffsetSeconds).toISOString().substring(0, 10)
    return date === WeatherData.localDate(now, data.utcOffsetSeconds).toISOString().substring(0, 10) ?
      (peak ? '今日峰值' : '今日预报') : fallback
  }

  static alerts(data: WeatherData): WeatherDetailContent {
    const detail = new WeatherDetailContent()
    detail.title = '天气预警'
    detail.subtitle = data.city
    detail.headline = data.alerts.length > 0 ? `${data.alerts.length} 项预警` : '暂无预警信息'
    detail.rows = data.alerts.map((alert: WeatherAlert) => new WeatherDetailRow(alert.title, alert.detail))
    detail.metadata = WeatherDetailPresentation.metadata(data)
    return detail
  }

  private static metadata(data: WeatherData): string {
    const source: string = data.source === 'openmeteo' ? 'Open-Meteo' :
      data.source === 'qweather' ? '和风天气' : data.source === 'mock' ? '示例数据' : '来源未提供'
    const update: string = Number.isFinite(data.lastUpdate) && data.lastUpdate > 0 && Number.isFinite(data.utcOffsetSeconds) ?
      WeatherData.localDate(data.lastUpdate, data.utcOffsetSeconds).toISOString().substring(5, 16).replace('T', ' ') : '未提供'
    return `天气数据：${source}\n资料更新：${update}${data.isOffline ? ' · 离线缓存，请刷新后参考' : ''}`
  }
}
