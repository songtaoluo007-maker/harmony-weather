import {
  AirQuality,
  CityInfo,
  CurrentWeather,
  DailyWeather,
  HourlyWeather,
  LifeIndex,
  WeatherData
} from '../models/WeatherModels'
import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { util } from '@kit.ArkTS'
import { http } from '@kit.NetworkKit'
import { OpenMeteoService } from './OpenMeteoService'

interface QWeatherNowResponse {
  code: string
  now: QWeatherNow
  updateTime: string
}

interface QWeatherNow {
  temp: string
  feelsLike: string
  text: string
  windDir: string
  windScale: string
  windSpeed: string
  humidity: string
  precip: string
  pressure: string
  vis: string
  cloud: string
}

interface QWeatherDailyResponse {
  code: string
  daily: QWeatherDaily[]
}

interface QWeatherDaily {
  fxDate: string
  sunrise: string
  sunset: string
  tempMax: string
  tempMin: string
  textDay: string
  textNight: string
  windDirDay: string
  windScaleDay: string
  humidity: string
  precip: string
  uvIndex: string
}

interface QWeatherAirResponse {
  code: string
  now: QWeatherAirNow
}

interface QWeatherAirNow {
  aqi: string
  category: string
  pm10: string
  pm2p5: string
  no2: string
  so2: string
  co: string
  o3: string
}

interface QWeatherHourlyResponse {
  code: string
  hourly: QWeatherHourly[]
}

interface QWeatherHourly {
  fxTime: string
  temp: string
  text: string
  windDir: string
  windScale: string
  humidity: string
  pop: string
}

interface CityConfig {
  name: string
  id: string
  province?: string
}

interface WeatherConfig {
  provider: string
  apiKey: string
  baseUrl: string
  geoUrl: string
  lang: string
  unit: string
  defaultLocation: string
  defaultCity: string
  cacheMinutes: number
  cities: CityConfig[]
}

export class AppSettings {
  unit: string = 'c'
  motionEnabled: boolean = true
  refreshMinutes: number = 30
}

export class WeatherService {
  private static instance: WeatherService | null = null
  private cache: Map<string, WeatherData> = new Map()
  private currentCityId: string = '101280601'
  private config: WeatherConfig | null = null
  private initialized: boolean = false
  private latestData: WeatherData | null = null
  private settings: AppSettings = new AppSettings()
  private hiddenCityIds: string[] = []
  private cacheRevision: number = 0
  private cacheQueue: Promise<void> = Promise.resolve()

  static getInstance(): WeatherService {
    if (!WeatherService.instance) WeatherService.instance = new WeatherService()
    return WeatherService.instance
  }

  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) return
    await this.loadConfig(context)
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_preferences' })
      this.currentCityId = String(await store.get('selected_city_id', this.currentCityId))
      this.settings.unit = String(await store.get('temperature_unit', 'c'))
      this.settings.motionEnabled = Boolean(await store.get('motion_enabled', true))
      this.settings.refreshMinutes = Number(await store.get('refresh_minutes', 30))
      this.hiddenCityIds = JSON.parse(String(await store.get('hidden_city_ids', '[]'))) as string[]
    } catch (error) {
      console.warn('读取天气偏好失败: ' + JSON.stringify(error))
    }
    this.initialized = true
  }

  getSettings(): AppSettings {
    return this.settings
  }

  async saveSettings(context: common.UIAbilityContext, settings: AppSettings): Promise<boolean> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_preferences' })
      await store.put('temperature_unit', settings.unit)
      await store.put('motion_enabled', settings.motionEnabled)
      await store.put('refresh_minutes', settings.refreshMinutes)
      await store.flush()
      this.settings = settings
      return true
    } catch (error) {
      console.warn('保存天气设置失败: ' + JSON.stringify(error))
      return false
    }
  }

  getCurrentCity(): CityInfo {
    const found: CityInfo | undefined = this.getCityList().find((city: CityInfo) => city.id === this.currentCityId)
    return found ?? new CityInfo('101280601', '深圳', '广东')
  }

  async selectCity(context: common.UIAbilityContext, cityId: string): Promise<boolean> {
    const next: string[] = this.hiddenCityIds.filter((id: string) => id !== cityId)
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_preferences' })
      await store.put('selected_city_id', cityId)
      await store.put('hidden_city_ids', JSON.stringify(next))
      await store.flush()
      this.currentCityId = cityId
      this.hiddenCityIds = next
      return true
    } catch (error) {
      console.warn('保存当前城市失败: ' + JSON.stringify(error))
      return false
    }
  }

  getCityList(): CityInfo[] {
    const provinces: Map<string, string> = new Map([
      ['北京', '北京'], ['上海', '上海'], ['广州', '广东'], ['深圳', '广东'], ['杭州', '浙江'],
      ['南京', '江苏'], ['武汉', '湖北'], ['成都', '四川'], ['西安', '陕西'], ['重庆', '重庆'],
      ['天津', '天津'], ['苏州', '江苏'], ['长沙', '湖南'], ['青岛', '山东'], ['大连', '辽宁']
    ])
    const configs: CityConfig[] = this.config?.cities ?? [
      { name: '北京', id: '101010100' }, { name: '上海', id: '101020100' },
      { name: '广州', id: '101280101' }, { name: '深圳', id: '101280601' },
      { name: '杭州', id: '101210101' }, { name: '南京', id: '101190101' },
      { name: '武汉', id: '101200101' }, { name: '成都', id: '101270101' },
      { name: '西安', id: '101110101' }, { name: '重庆', id: '101040100' },
      { name: '天津', id: '101030100' }, { name: '苏州', id: '101190401' },
      { name: '长沙', id: '101250101' }, { name: '青岛', id: '101120201' },
      { name: '大连', id: '101070201' }
    ]
    const coordinates: Map<string, number[]> = new Map([
      ['北京', [39.9042, 116.4074]], ['上海', [31.2304, 121.4737]], ['广州', [23.1291, 113.2644]],
      ['深圳', [22.5431, 114.0579]], ['杭州', [30.2741, 120.1551]], ['南京', [32.0603, 118.7969]],
      ['武汉', [30.5928, 114.3055]], ['成都', [30.5728, 104.0668]], ['西安', [34.3416, 108.9398]],
      ['重庆', [29.5630, 106.5516]], ['天津', [39.3434, 117.3616]], ['苏州', [31.2989, 120.5853]],
      ['长沙', [28.2282, 112.9388]], ['青岛', [36.0671, 120.3826]], ['大连', [38.9140, 121.6147]]
    ])
    return configs.map((item: CityConfig) => {
      const point: number[] = coordinates.get(item.name) ?? [0, 0]
      return new CityInfo(item.id, item.name, item.province ?? provinces.get(item.name) ?? '', point[0], point[1])
    })
  }

  getSavedCities(): CityInfo[] {
    return this.getCityList().filter((city: CityInfo) => !this.hiddenCityIds.includes(city.id))
  }

  async removeSavedCity(context: common.UIAbilityContext, cityId: string): Promise<boolean> {
    if (cityId === this.currentCityId) return false
    const next: string[] = this.hiddenCityIds.concat(cityId)
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_preferences' })
      await store.put('hidden_city_ids', JSON.stringify(next))
      await store.flush()
      this.hiddenCityIds = next
      return true
    } catch (error) {
      return false
    }
  }

  hasLiveConfiguration(): boolean {
    if (this.config?.provider === 'openmeteo') return true
    if (this.config?.provider === 'mock') return false
    const key: string = this.config?.apiKey?.trim() ?? ''
    return key.length > 0 && !key.toUpperCase().includes('YOUR_')
  }

  getProvider(): string {
    return this.config?.provider === 'openmeteo' ? 'openmeteo' : this.config?.provider === 'mock' ? 'mock' : 'qweather'
  }

  findNearestCity(latitude: number, longitude: number): CityInfo {
    let nearest: CityInfo = this.getCurrentCity()
    let nearestDistance: number = Number.MAX_VALUE
    this.getCityList().forEach((city: CityInfo) => {
      const latDelta: number = city.latitude - latitude
      const lonDelta: number = city.longitude - longitude
      const distance: number = latDelta * latDelta + lonDelta * lonDelta
      if (distance < nearestDistance) {
        nearest = city
        nearestDistance = distance
      }
    })
    return nearest
  }

  peekLatestData(): WeatherData | null {
    return this.latestData
  }

  async clearWeatherCache(context: common.UIAbilityContext): Promise<boolean> {
    const operation: Promise<void> = this.cacheQueue.then(async () => {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_cache' })
      await store.clear()
      await store.flush()
      this.cacheRevision++
      this.cache.clear()
      this.latestData = null
    })
    this.cacheQueue = operation.catch(() => {})
    try { await operation; return true } catch (error) { return false }
  }

  async loadWeather(context: common.UIAbilityContext, cityId?: string, forceRefresh: boolean = false): Promise<WeatherData> {
    await this.initialize(context)
    // Read memory and capture the revision only after queued clears have settled.
    // Recheck the tail in case another clear was queued while we waited; network I/O stays outside the queue.
    while (true) {
      const pending: Promise<void> = this.cacheQueue
      await pending
      if (pending === this.cacheQueue) break
    }
    const targetId: string = cityId ?? this.currentCityId
    const revision: number = this.cacheRevision
    const city: CityInfo = this.getCityList().find((item: CityInfo) => item.id === targetId) ?? this.getCurrentCity()
    const cached: WeatherData | undefined = this.cache.get(targetId)
    const cacheMinutes: number = this.settings.refreshMinutes || this.config?.cacheMinutes || 30
    const provider: string = this.getProvider()
    if (provider !== 'mock' && !this.hasLiveConfiguration()) {
      throw new Error('在线天气配置不完整，请配置和风凭据或切换到免费 Open-Meteo')
    }
    if (!forceRefresh && cached && cached.source === provider && Date.now() - cached.lastUpdate < cacheMinutes * 60 * 1000) {
      this.refreshLifeIndex(cached)
      this.latestData = cached
      return cached
    }

    const apiReady: boolean = this.hasLiveConfiguration()
    if (apiReady) {
      try {
        const live: WeatherData = provider === 'openmeteo' ? await new OpenMeteoService().fetch(city) : await this.fetchFromAPI(city)
        this.refreshLifeIndex(live)
        await this.savePersistentCache(context, live, revision)
        if (revision === this.cacheRevision) {
          this.cache.set(targetId, live)
          this.latestData = live
        }
        return live
      } catch (error) {
        console.error('实时天气请求失败: ' + JSON.stringify(error))
        const persisted: WeatherData | null = await this.readPersistentCache(context, targetId)
        if (persisted && persisted.source === provider && revision === this.cacheRevision) {
          persisted.isOffline = true
          this.cache.set(targetId, persisted)
          this.latestData = persisted
          return persisted
        }
        throw new Error('实时天气更新失败，暂无可用的真实天气缓存')
      }
    }

    try {
      const mock: WeatherData = await this.loadMockData(context, city)
      await this.savePersistentCache(context, mock, revision)
      if (revision === this.cacheRevision) {
        this.cache.set(targetId, mock)
        this.latestData = mock
      }
      return mock
    } catch (error) {
      const persisted: WeatherData | null = await this.readPersistentCache(context, targetId)
      if (persisted && persisted.source === 'mock' && revision === this.cacheRevision) {
        persisted.isOffline = true
        this.latestData = persisted
        return persisted
      }
      throw new Error('天气数据暂时不可用')
    }
  }

  private decodeUtf8(content: Uint8Array): string {
    return util.TextDecoder.create('utf-8').decodeToString(content)
  }

  private async loadConfig(context: common.UIAbilityContext): Promise<void> {
    if (this.config) return
    const candidates: string[] = ['weather_config.local.json', 'weather_config.json']
    for (const filename of candidates) {
      try {
        const content: Uint8Array = await context.resourceManager.getRawFileContent(filename)
        this.config = JSON.parse(this.decodeUtf8(content)) as WeatherConfig
        return
      } catch (error) {
        if (filename === 'weather_config.json') console.error('读取天气配置失败: ' + JSON.stringify(error))
      }
    }
  }

  private async fetchFromAPI(city: CityInfo): Promise<WeatherData> {
    const apiKey: string = this.config!.apiKey
    const baseUrl: string = this.config!.baseUrl
    const language: string = this.config!.lang
    const nowPromise: Promise<QWeatherNowResponse> =
      this.httpGet<QWeatherNowResponse>(`${baseUrl}/v7/weather/now?location=${city.id}&key=${apiKey}&lang=${language}`)
    const dailyPromise: Promise<QWeatherDailyResponse> =
      this.httpGet<QWeatherDailyResponse>(`${baseUrl}/v7/weather/15d?location=${city.id}&key=${apiKey}&lang=${language}`)
    const airPromise: Promise<QWeatherAirResponse> =
      this.httpGet<QWeatherAirResponse>(`${baseUrl}/v7/air/now?location=${city.id}&key=${apiKey}&lang=${language}`)
    const hourlyPromise: Promise<QWeatherHourlyResponse> =
      this.httpGet<QWeatherHourlyResponse>(`${baseUrl}/v7/weather/24h?location=${city.id}&key=${apiKey}&lang=${language}`)

    const requests: Promise<Object>[] = [nowPromise, dailyPromise, airPromise, hourlyPromise]
    const results: Object[] = await Promise.all(requests)
    const nowResp: QWeatherNowResponse = results[0] as QWeatherNowResponse
    const dailyResp: QWeatherDailyResponse = results[1] as QWeatherDailyResponse
    const airResp: QWeatherAirResponse = results[2] as QWeatherAirResponse
    const hourlyResp: QWeatherHourlyResponse = results[3] as QWeatherHourlyResponse
    if (nowResp.code !== '200') throw new Error(`QWeather ${nowResp.code}`)

    const data: WeatherData = new WeatherData()
    data.city = city.name
    data.cityId = city.id
    data.current = this.parseCurrentWeather(nowResp.now)
    if (dailyResp.code === '200') {
      data.daily = this.parseDailyWeather(dailyResp.daily)
      if (dailyResp.daily.length > 0) {
        data.current.high = Number(dailyResp.daily[0].tempMax) || data.current.temp
        data.current.low = Number(dailyResp.daily[0].tempMin) || data.current.temp
        data.current.sunrise = dailyResp.daily[0].sunrise
        data.current.sunset = dailyResp.daily[0].sunset
        const uv: number = this.optionalIndex(dailyResp.daily[0].uvIndex)
        data.current.uv = this.uvText(uv)
        data.current.uvScope = uv >= 0 ? 'daily' : ''
      }
    }
    if (airResp.code === '200' && airResp.now) data.air = this.parseAirQuality(airResp.now)
    if (hourlyResp.code === '200') data.hourly = this.parseHourlyWeather(hourlyResp.hourly)
    data.lastUpdate = Date.now()
    data.source = 'qweather'
    data.lifeIndex = this.getDefaultLifeIndex(data.current, data.air, data.lastUpdate, data.utcOffsetSeconds)
    return data
  }

  private httpGet<T>(url: string): Promise<T> {
    return new Promise<T>((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      const request: http.HttpRequest = http.createHttp()
      request.request(url, {
        method: http.RequestMethod.GET,
        readTimeout: 10000,
        connectTimeout: 10000
      }).then((response: http.HttpResponse) => {
        request.destroy()
        if (response.responseCode !== 200) {
          reject(new Error(`HTTP ${response.responseCode}`))
          return
        }
        resolve(JSON.parse(response.result as string) as T)
      }).catch((error: Error) => {
        request.destroy()
        reject(error)
      })
    })
  }

  private parseCurrentWeather(now: QWeatherNow): CurrentWeather {
    const current: CurrentWeather = new CurrentWeather()
    current.temp = Number(now.temp) || 0
    current.feelsLike = Number(now.feelsLike) || 0
    current.text = now.text || '未知'
    current.humidity = Number(now.humidity) || 0
    current.windSpeed = Number(now.windSpeed) || 0
    current.windDir = now.windDir || ''
    current.windScale = `${now.windScale || ''}级`
    current.pressure = Number(now.pressure) || 0
    current.visibility = Number(now.vis) || 0
    current.precip = Number(now.precip) || 0
    current.cloud = Number(now.cloud) || 0
    return current
  }

  private parseDailyWeather(daily: QWeatherDaily[]): DailyWeather[] {
    return daily.map((item: QWeatherDaily) => {
      const value: DailyWeather = new DailyWeather()
      value.date = item.fxDate
      value.week = this.dateToWeek(item.fxDate)
      value.textDay = item.textDay
      value.textNight = item.textNight
      value.high = Number(item.tempMax) || 0
      value.low = Number(item.tempMin) || 0
      value.windDir = item.windDirDay
      value.windScale = `${item.windScaleDay}级`
      value.humidity = Number(item.humidity) || 0
      value.pop = Number(item.precip) || 0
      value.uvIndex = this.optionalIndex(item.uvIndex)
      return value
    })
  }

  private parseHourlyWeather(hourly: QWeatherHourly[]): HourlyWeather[] {
    return hourly.map((item: QWeatherHourly) => {
      const value: HourlyWeather = new HourlyWeather()
      const parts: string[] = (item.fxTime || '').split('T')
      value.time = parts.length > 1 ? parts[1].substring(0, 5) : item.fxTime
      value.temp = Number(item.temp) || 0
      value.text = item.text || ''
      value.pop = Number(item.pop) || 0
      value.windDir = item.windDir || ''
      value.windScale = item.windScale ? `${item.windScale}级` : ''
      return value
    })
  }

  private parseAirQuality(air: QWeatherAirNow): AirQuality {
    const value: AirQuality = new AirQuality()
    value.standard = 'CN AQI'
    value.aqi = this.optionalIndex(air.aqi)
    value.available = value.aqi >= 0
    if (!value.available) return value
    value.level = air.category || '未知'
    value.pm25 = Number(air.pm2p5) || 0
    value.pm10 = Number(air.pm10) || 0
    value.no2 = Number(air.no2) || 0
    value.so2 = Number(air.so2) || 0
    value.co = Number(air.co) || 0
    value.o3 = Number(air.o3) || 0
    value.advice = this.getAqiAdvice(value.aqi)
    return value
  }

  private async loadMockData(context: common.UIAbilityContext, city: CityInfo): Promise<WeatherData> {
    let content: Uint8Array
    try {
      content = await context.resourceManager.getRawFileContent('mock_weather.json')
    } catch (error) {
      throw new Error('演示天气数据不可用: ' + JSON.stringify(error))
    }
    const json: Record<string, Object> = JSON.parse(this.decodeUtf8(content)) as Record<string, Object>
    const data: WeatherData = WeatherData.fromMock(json)
    data.city = city.name
    data.cityId = city.id
    const cityIndex: number = Math.max(0, this.getCityList().findIndex((item: CityInfo) => item.id === city.id))
    const offset: number = city.id === '101280601' ? 0 : cityIndex % 5
    data.current.temp -= offset
    data.current.feelsLike -= offset
    data.current.high -= offset
    data.current.low -= Math.min(offset, 2)
    data.hourly.forEach((item: HourlyWeather, index: number) => {
      item.temp -= offset
      item.time = index === 0 ? '现在' : `${(new Date().getHours() + index) % 24}时`
    })
    data.daily.forEach((item: DailyWeather, index: number) => {
      item.high -= offset
      item.low -= Math.min(offset, 2)
      const date: Date = new Date()
      date.setDate(date.getDate() + index)
      item.date = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
      const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
      item.week = weeks[date.getDay()]
    })
    data.lastUpdate = Date.now()
    data.source = 'mock'
    data.lifeIndex = this.getDefaultLifeIndex(data.current, data.air, data.lastUpdate, data.utcOffsetSeconds)
    return data
  }

  private async savePersistentCache(context: common.UIAbilityContext, data: WeatherData, revision: number = this.cacheRevision): Promise<void> {
    const operation: Promise<void> = this.cacheQueue.then(async () => {
      if (revision !== this.cacheRevision) return
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_cache' })
      await store.put(`${data.source}_city_${data.cityId}`, JSON.stringify(data))
      await store.flush()
    })
    this.cacheQueue = operation.catch(() => {})
    try { await operation } catch (error) {
      console.warn('写入天气缓存失败: ' + JSON.stringify(error))
    }
  }

  private async readPersistentCache(context: common.UIAbilityContext, cityId: string): Promise<WeatherData | null> {
    try {
      // Fallback reads must not observe a clear before its flush outcome is known.
      while (true) {
        const pending: Promise<void> = this.cacheQueue
        await pending
        if (pending === this.cacheQueue) break
      }
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'weather_cache' })
      const raw: string = String(await store.get(`${this.getProvider()}_city_${cityId}`, ''))
      if (!raw) return null
      const data: WeatherData = WeatherData.fromMock(JSON.parse(raw) as Record<string, Object>)
      // Recompute local advice without changing the observation age or provider indices.
      this.refreshLifeIndex(data)
      return data
    } catch (error) {
      return null
    }
  }

  private dateToWeek(dateValue: string): string {
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    return weeks[new Date(dateValue).getDay()]
  }

  private uvText(value: number): string {
    if (!Number.isFinite(value) || value < 0) return '暂无数据'
    if (value <= 2) return '弱'
    if (value <= 5) return '中等'
    if (value <= 7) return '较强'
    if (value <= 10) return '很强'
    return '极强'
  }

  private optionalIndex(raw: string | undefined | null): number {
    if (typeof raw !== 'string' || !raw.trim()) return -1
    const value: number = Number(raw)
    return Number.isFinite(value) && value >= 0 ? value : -1
  }

  private getAqiAdvice(aqi: number): string {
    if (aqi <= 50) return '空气清新，适宜户外活动'
    if (aqi <= 100) return '空气质量可接受，敏感人群可适当减少户外活动'
    if (aqi <= 150) return '敏感人群建议减少长时间户外活动'
    if (aqi <= 200) return '建议减少户外活动并做好防护'
    return '空气污染较重，建议留在室内'
  }

  private getDefaultLifeIndex(current: CurrentWeather, air?: AirQuality, referenceAt: number = 0,
    utcOffsetSeconds: number = 28800): LifeIndex[] {
    const observationDate: Date = WeatherData.localDate(referenceAt, utcOffsetSeconds)
    const today: Date = WeatherData.localDate(Date.now(), utcOffsetSeconds)
    const sameDay: boolean = Number.isFinite(referenceAt) && referenceAt > 0 &&
      observationDate.getUTCFullYear() === today.getUTCFullYear() &&
      observationDate.getUTCMonth() === today.getUTCMonth() && observationDate.getUTCDate() === today.getUTCDate()
    const uvAvailable: boolean = ['弱', '中等', '较强', '很强', '极强'].includes(current.uv)
    const uv: LifeIndex = this.life('紫外线', 'uv', uvAvailable ? current.uv : '暂无数据',
      uvAvailable ? '外出请按紫外线等级做好防晒。' : '紫外线数据暂不可用，不能据此判断当前强度。')
    if (uvAvailable && current.uvScope === 'daily_max') {
      uv.caption = sameDay ? '今日峰值' : '预报峰值'
      uv.detail = '预报当天的紫外线峰值，不代表当前强度。请结合出行时段参考。'
    } else if (uvAvailable && current.uvScope === 'daily') {
      uv.caption = sameDay ? '今日预报' : '逐日预报'
      uv.detail = '当日紫外线预报，不代表当前强度。外出请按预报等级做好防晒。'
    } else if (uvAvailable && current.uvScope !== 'current') {
      uv.caption = '时段未知'
      uv.detail = '该紫外线数据的时间范围未注明，不能视为当前强度。'
    }
    return [
      this.life('穿衣', 'clothing', current.temp >= 26 ? '舒适' : '薄外套', '根据体感温度及时增减衣物'),
      uv,
      this.life('洗车', 'car', current.precip > 0 ? '不适宜' : '参考预报', '出发前请查看未来降水概率。'),
      this.life('旅游', 'travel', '暂无数据', '旅游指数暂不可用，可查看逐日天气规划行程。'),
      this.life('感冒', 'cold', '暂无数据', '感冒指数暂不可用。温差不能用于判断个人感冒风险。'),
      this.life('温差', 'temperature', `${Math.max(0, current.high - current.low)}°`, '当日最高与最低气温之差。'),
      this.exerciseAdvice(current, air)
    ]
  }

  private exerciseAdvice(current: CurrentWeather, air?: AirQuality): LifeIndex {
    const knownAir: boolean = air !== undefined && air.available === true &&
      Number.isFinite(air.aqi) && air.aqi >= 0 && ['US AQI', 'CN AQI'].includes(air.standard)
    const basis: string = knownAir && air ? `${air.standard} ${air.aqi}。` : '空气质量数据缺失或标准未知。'
    const note: string = '本地保守活动提示，仅依据天气和空气资料，不是个人健康评估。'
    // Category boundaries, not pollutant conversions or a clinical score:
    // https://www.airnow.gov/aqi/aqi-basics/
    // https://www.mee.gov.cn/ywgz/fgbz/bz/bzwb/jcffbz/202602/t20260225_1144441.shtml
    if (knownAir && air && air.aqi > 150) {
      return this.life('运动', 'sport', '室内为宜', basis + '减少或推迟户外运动，优先考虑室内活动。' + note)
    }
    // 0/35°C and 40 km/h are intentionally conservative product heuristics,
    // not official warning thresholds or claims of individual safety.
    if (/雷|雨|雪|雾|霾|沙|尘|冰雹/.test(current.text) || current.precip > 0 ||
      current.temp <= 0 || current.temp >= 35 || current.feelsLike <= 0 || current.feelsLike >= 35 || current.windSpeed >= 40) {
      return this.life('运动', 'sport', '室内为宜', basis + '有降水、低能见度、较强风或明显冷暖条件，优先考虑室内活动。' + note)
    }
    if (knownAir && air && air.aqi > 100) {
      return this.life('运动', 'sport', '减少户外', basis + '保守起见，减少长时间或高强度户外活动，留意当地空气提示。' + note)
    }
    if (!knownAir || !Number.isFinite(current.temp) || !Number.isFinite(current.feelsLike) ||
      !Number.isFinite(current.precip) || current.precip < 0 || !Number.isFinite(current.windSpeed) || current.windSpeed < 0 ||
      !/晴|云|阴/.test(current.text)) {
      return this.life('运动', 'sport', '资料不足', basis + '尚不能判断户外运动条件，请补充查看当地天气和空气信息。' + note)
    }
    if (air && air.aqi > 50) {
      return this.life('运动', 'sport', '适度活动', basis + '留意空气变化，灵活调整户外活动安排。' + note)
    }
    return this.life('运动', 'sport', '较适宜', basis + '已知天气条件较平稳，活动前仍请查看当地提醒。' + note)
  }

  private refreshLifeIndex(data: WeatherData): void {
    const referenceAt: number = data.observedAt > 0 ? data.observedAt : data.lastUpdate
    const defaults: LifeIndex[] = this.getDefaultLifeIndex(data.current, data.air, referenceAt, data.utcOffsetSeconds)
    const previous: LifeIndex[] = data.lifeIndex
    data.lifeIndex = defaults.map((local: LifeIndex) => {
      const existing: LifeIndex | undefined = previous.find((item: LifeIndex) => item.name === local.name)
      if (!existing || !existing.brief.trim() || this.isLocalLifeIndex(existing, data.source)) return local
      // Keep provider indices unless a positive exercise assertion conflicts with known
      // conditions or insufficient evidence. The guard is explicitly attributed to local.
      if (local.name === '运动' && local.brief !== '较适宜' &&
        /适宜|适合|推荐户外/.test(existing.brief + existing.detail) && !/不适宜|不宜|不适合|避免|减少|室内/.test(existing.brief)) return local
      return existing
    })
    previous.forEach((item: LifeIndex) => {
      if (!defaults.some((local: LifeIndex) => local.name === item.name)) data.lifeIndex.push(item)
    })
  }

  private isLocalLifeIndex(item: LifeIndex, provider: string): boolean {
    if (item.source === 'local') return true
    if (item.source) return false
    // Open-Meteo has no provider life-index endpoint in this adapter.
    if (provider === 'openmeteo' || provider === 'mock') return true
    // Exact legacy local wording is migration evidence; a QWeather weather source
    // alone does not prove whether an untagged index was local or provider-authored.
    const legacy: Map<string, string> = new Map([
      ['穿衣', '根据体感温度及时增减衣物'], ['紫外线', '外出请按紫外线等级做好防晒'],
      ['洗车', '出发前请查看未来降水概率。'], ['旅游', '旅游指数暂不可用，可查看逐日天气规划行程。'],
      ['感冒', '感冒指数暂不可用。温差不能用于判断个人感冒风险。'],
      ['温差', '当日最高与最低气温之差。'], ['运动', '结合空气质量选择运动强度']
    ])
    return legacy.get(item.name) === item.detail
  }

  private life(name: string, iconKey: string, brief: string, detail: string): LifeIndex {
    const value: LifeIndex = new LifeIndex()
    value.name = name
    value.iconKey = iconKey
    value.brief = brief
    value.detail = detail
    value.source = 'local'
    return value
  }
}
