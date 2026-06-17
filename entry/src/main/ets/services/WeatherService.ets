// ─── 天气数据服务：和风天气 QWeather API 接入 ─────────
// API 文档: https://dev.qweather.com/docs/api/
// 配置文件: resources/rawfile/weather_config.json
import { WeatherData, CurrentWeather, HourlyWeather, DailyWeather, AirQuality, LifeIndex } from '../models/WeatherModels'
import { common } from '@kit.AbilityKit'
import { http } from '@kit.NetworkKit'

// 和风天气 API 响应类型定义
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
  dew: string
}

interface QWeatherDailyResponse {
  code: string
  daily: QWeatherDaily[]
}

interface QWeatherDaily {
  fxDate: string
  sunrise: string
  sunset: string
  moonrise: string
  moonset: string
  moonPhase: string
  tempMax: string
  tempMin: string
  textDay: string
  textNight: string
  wind360Day: string
  windDirDay: string
  windScaleDay: string
  windSpeedDay: string
  wind360Night: string
  windDirNight: string
  windScaleNight: string
  windSpeedNight: string
  humidity: string
  precip: string
  uvIndex: string
  vis: string
  cloud: string
}

interface QWeatherAirResponse {
  code: string
  now: QWeatherAirNow
}

interface QWeatherAirNow {
  aqi: string
  level: string
  category: string
  primary: string
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

export class WeatherService {
  private static instance: WeatherService | null = null
  private cache: Map<string, WeatherData> = new Map()
  private currentCity: string = '深圳'
  private config: WeatherConfig | null = null

  static getInstance(): WeatherService {
    if (!WeatherService.instance) {
      WeatherService.instance = new WeatherService()
    }
    return WeatherService.instance
  }

  getCurrentCity(): string {
    return this.currentCity
  }

  setCurrentCity(city: string): void {
    this.currentCity = city
  }

  // 获取城市列表
  getCityList(): string[] {
    if (this.config) {
      return this.config.cities.map((c: CityConfig) => c.name)
    }
    return ['北京', '上海', '广州', '深圳', '杭州', '南京', '武汉', '成都', '西安', '重庆',
      '天津', '苏州', '长沙', '青岛', '大连']
  }

  // 根据城市名获取城市 ID
  private getCityId(city: string): string {
    if (this.config) {
      const found: CityConfig | undefined = this.config.cities.find((c: CityConfig) => c.name === city)
      if (found) {
        return found.id
      }
    }
    // 默认返回深圳
    return '101280601'
  }

  // 加载配置文件
  private async loadConfig(context: common.UIAbilityContext): Promise<void> {
    if (this.config) {
      return
    }
    try {
      const content: Uint8Array = await context.resourceManager.getRawFileContent('weather_config.json')
      const jsonStr: string = String.fromCharCode(...content)
      this.config = JSON.parse(jsonStr) as WeatherConfig
    } catch (e) {
      console.error('加载配置文件失败: ' + JSON.stringify(e))
    }
  }

  // 主加载方法：优先使用 API，失败则回退到 mock
  async loadWeather(context: common.UIAbilityContext, city?: string): Promise<WeatherData> {
    const targetCity: string = city ?? this.currentCity

    // 加载配置
    await this.loadConfig(context)

    // 检查缓存
    const cached: WeatherData | undefined = this.cache.get(targetCity)
    const cacheMinutes: number = this.config?.cacheMinutes ?? 30
    if (cached && Date.now() - cached.lastUpdate < cacheMinutes * 60 * 1000) {
      return cached
    }

    // 如果配置了真实 API key，尝试从 API 获取
    if (this.config && this.config.apiKey && this.config.apiKey !== 'YOUR_API_KEY_HERE') {
      try {
        const data: WeatherData = await this.fetchFromAPI(targetCity)
        this.cache.set(targetCity, data)
        return data
      } catch (e) {
        console.error('API 请求失败，回退到 mock 数据: ' + JSON.stringify(e))
      }
    }

    // 回退：从 rawfile 加载模拟数据
    try {
      const data: WeatherData = await this.loadMockData(context, targetCity)
      this.cache.set(targetCity, data)
      return data
    } catch (e) {
      console.error('加载 mock 数据失败: ' + JSON.stringify(e))
      return this.getDefaultData()
    }
  }

  // ─── 和风天气 API 请求 ─────────────────────────────

  // 从和风天气 API 获取完整天气数据
  private async fetchFromAPI(city: string): Promise<WeatherData> {
    const locationId: string = this.getCityId(city)
    const apiKey: string = this.config!.apiKey
    const baseUrl: string = this.config!.baseUrl

    // 并行请求多个接口
    const [nowResp, dailyResp, airResp, hourlyResp] = await Promise.all([
      this.httpGet<QWeatherNowResponse>(`${baseUrl}/v7/weather/now?location=${locationId}&key=${apiKey}&lang=${this.config!.lang}`),
      this.httpGet<QWeatherDailyResponse>(`${baseUrl}/v7/weather/7d?location=${locationId}&key=${apiKey}&lang=${this.config!.lang}`),
      this.httpGet<QWeatherAirResponse>(`${baseUrl}/v7/air/now?location=${locationId}&key=${apiKey}&lang=${this.config!.lang}`),
      this.httpGet<QWeatherHourlyResponse>(`${baseUrl}/v7/weather/24h?location=${locationId}&key=${apiKey}&lang=${this.config!.lang}`)
    ])

    // 构建 WeatherData
    const data: WeatherData = new WeatherData()
    data.city = city

    // 解析实时天气
    if (nowResp.code === '200' && nowResp.now) {
      data.current = this.parseCurrentWeather(nowResp.now)
    }

    // 解析每日预报
    if (dailyResp.code === '200' && dailyResp.daily) {
      data.daily = this.parseDailyWeather(dailyResp.daily)
      // 从第一天提取日出日落
      if (dailyResp.daily.length > 0) {
        data.current.sunrise = dailyResp.daily[0].sunrise
        data.current.sunset = dailyResp.daily[0].sunset
      }
    }

    // 解析空气质量
    if (airResp.code === '200' && airResp.now) {
      data.air = this.parseAirQuality(airResp.now)
    }

    // 解析逐小时预报
    if (hourlyResp.code === '200' && hourlyResp.hourly) {
      data.hourly = this.parseHourlyWeather(hourlyResp.hourly)
    }

    // 生活指数（如果需要可单独请求）
    data.lifeIndex = this.getDefaultLifeIndex()

    data.lastUpdate = Date.now()
    return data
  }

  // HTTP GET 请求封装
  private httpGet<T>(url: string): Promise<T> {
    return new Promise<T>((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      const httpRequest: http.HttpRequest = http.createHttp()
      httpRequest.request(url, {
        method: http.RequestMethod.GET,
        readTimeout: 10000,
        connectTimeout: 10000
      }).then((response: http.HttpResponse) => {
        httpRequest.destroy()
        if (response.responseCode === 200) {
          const result: T = JSON.parse(response.result as string) as T
          resolve(result)
        } else {
          reject(new Error(`HTTP ${response.responseCode}`))
        }
      }).catch((err: Error) => {
        httpRequest.destroy()
        reject(err)
      })
    })
  }

  // 解析实时天气
  private parseCurrentWeather(now: QWeatherNow): CurrentWeather {
    const current: CurrentWeather = new CurrentWeather()
    current.temp = Number(now.temp) || 0
    current.feelsLike = Number(now.feelsLike) || 0
    current.text = now.text || '未知'
    current.humidity = Number(now.humidity) || 0
    current.windSpeed = Number(now.windSpeed) || 0
    current.windDir = now.windDir || ''
    current.windScale = now.windScale || ''
    current.pressure = Number(now.pressure) || 0
    current.visibility = Number(now.vis) || 0
    current.high = 0 // 从 daily 数据补充
    current.low = 0
    return current
  }

  // 解析每日预报
  private parseDailyWeather(daily: QWeatherDaily[]): DailyWeather[] {
    return daily.map((d: QWeatherDaily) => {
      const item: DailyWeather = new DailyWeather()
      item.date = d.fxDate
      item.week = this.dateToWeek(d.fxDate)
      item.textDay = d.textDay
      item.textNight = d.textNight
      item.high = Number(d.tempMax) || 0
      item.low = Number(d.tempMin) || 0
      item.windDir = d.windDirDay
      item.windScale = d.windScaleDay
      item.humidity = Number(d.humidity) || 0
      return item
    })
  }

  // 解析空气质量
  private parseAirQuality(air: QWeatherAirNow): AirQuality {
    const aq: AirQuality = new AirQuality()
    aq.aqi = Number(air.aqi) || 0
    aq.level = air.category || '未知'
    aq.pm25 = Number(air.pm2p5) || 0
    aq.pm10 = Number(air.pm10) || 0
    aq.no2 = Number(air.no2) || 0
    aq.so2 = Number(air.so2) || 0
    aq.co = Number(air.co) || 0
    aq.o3 = Number(air.o3) || 0
    aq.advice = this.getAqiAdvice(aq.aqi)
    return aq
  }

  // 解析逐小时预报
  private parseHourlyWeather(hourly: QWeatherHourly[]): HourlyWeather[] {
    return hourly.map((h: QWeatherHourly) => {
      const item: HourlyWeather = new HourlyWeather()
      // 提取时间 HH:mm
      const timeStr: string = h.fxTime || ''
      const timeParts: string[] = timeStr.split('T')
      item.time = timeParts.length > 1 ? timeParts[1].substring(0, 5) : timeStr
      item.temp = Number(h.temp) || 0
      item.text = h.text || ''
      item.icon = WeatherData.textToIcon(item.text)
      return item
    })
  }

  // 日期转星期
  private dateToWeek(dateStr: string): string {
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    const date: Date = new Date(dateStr)
    return weeks[date.getDay()]
  }

  // AQI 建议
  private getAqiAdvice(aqi: number): string {
    if (aqi <= 50) return '空气质量令人满意，基本无空气污染'
    if (aqi <= 100) return '空气质量可接受，某些污染物可能对少数人有轻微影响'
    if (aqi <= 150) return '敏感人群可能会有影响，一般人群影响较小'
    if (aqi <= 200) return '进一步加剧易感人群症状，可能对心脏和呼吸系统有影响'
    if (aqi <= 300) return '健康影响加重，应减少户外活动'
    return '健康影响严重，应避免户外活动'
  }

  // 默认生活指数
  private getDefaultLifeIndex(): LifeIndex[] {
    return [
      { name: '穿衣', icon: '衣', brief: '舒适', detail: '建议穿薄外套' },
      { name: '运动', icon: '动', brief: '适宜', detail: '适合户外运动' },
      { name: '紫外线', icon: '光', brief: '中等', detail: '建议涂防晒霜' },
      { name: '洗车', icon: '洗', brief: '适宜', detail: '适合洗车' },
      { name: '旅游', icon: '游', brief: '适宜', detail: '适合出游' },
      { name: '感冒', icon: '健', brief: '少发', detail: '注意适当增减衣物' }
    ]
  }

  // ─── Mock 数据回退 ─────────────────────────────────

  // 从 rawfile 加载模拟数据
  private async loadMockData(context: common.UIAbilityContext, city: string): Promise<WeatherData> {
    const content: Uint8Array = await context.resourceManager.getRawFileContent('mock_weather.json')
    const jsonStr: string = String.fromCharCode(...content)
    const jsonObj: Record<string, Object> = JSON.parse(jsonStr) as Record<string, Object>

    const data: WeatherData = WeatherData.fromMock(jsonObj)
    data.city = city

    // 模拟不同城市的温度差异
    const cityList: string[] = this.getCityList()
    const cityOffset: number = cityList.indexOf(city)
    if (cityOffset > 0) {
      data.current.temp = 26 - cityOffset % 5
      data.current.high = 28 - cityOffset % 5
      data.current.low = 19 - cityOffset % 3
      data.current.feelsLike = 24 - cityOffset % 4
    }

    return data
  }

  // 默认兜底数据
  private getDefaultData(): WeatherData {
    const data: WeatherData = new WeatherData()
    data.city = this.currentCity
    data.current.temp = 26
    data.current.text = '晴'
    data.current.high = 28
    data.current.low = 19
    data.lastUpdate = Date.now()
    return data
  }
}
