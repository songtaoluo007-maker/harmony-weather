export enum WeatherType {
  SUNNY = 'sunny',
  CLOUDY = 'cloudy',
  RAINY = 'rainy',
  SNOWY = 'snowy',
  STORMY = 'stormy',
  FOGGY = 'foggy'
}

export enum TimeOfDay {
  DAWN = 'dawn',
  DAY = 'day',
  DUSK = 'dusk',
  NIGHT = 'night'
}

export enum WeatherVisualState {
  CLEAR_DAY = 'clear_day',
  CLEAR_NIGHT = 'clear_night',
  CLOUDY_DAY = 'cloudy_day',
  CLOUDY_NIGHT = 'cloudy_night',
  RAIN = 'rain',
  SNOW = 'snow',
  HAZE = 'haze',
  STORM = 'storm'
}

export enum WeatherUiStatus {
  LOADING = 'loading',
  READY = 'ready',
  STALE = 'stale',
  EMPTY = 'empty',
  ERROR = 'error'
}

export class WeatherSceneState {
  hour: number = 12
  isNight: boolean = false
  visualState: WeatherVisualState = WeatherVisualState.CLEAR_DAY
}

export class CityInfo {
  id: string = ''
  name: string = ''
  province: string = ''
  latitude: number = 0
  longitude: number = 0
  isCurrentLocation: boolean = false

  constructor(id: string = '', name: string = '', province: string = '', latitude: number = 0, longitude: number = 0) {
    this.id = id
    this.name = name
    this.province = province
    this.latitude = latitude
    this.longitude = longitude
  }
}

export class WeatherAlert {
  title: string = ''
  severity: string = '提醒'
  detail: string = ''
}

export class CurrentWeather {
  temp: number = 26
  feelsLike: number = 27
  text: string = '晴'
  high: number = 29
  low: number = 23
  humidity: number = 66
  windSpeed: number = 12
  windDir: string = '东南风'
  windScale: string = '2级'
  pressure: number = 1015
  visibility: number = 28
  uv: string = '暂无数据'
  // daily_max / daily / current; empty means the time scope is unknown.
  uvScope: string = ''
  sunrise: string = '05:46'
  sunset: string = '19:13'
  precip: number = 0
  cloud: number = 10
}

export class HourlyWeather {
  time: string = ''
  temp: number = 0
  text: string = ''
  pop: number = 0
  windDir: string = ''
  windScale: string = ''
  isDay: boolean = true
  timestamp: number = 0
}

export class DailyWeather {
  date: string = ''
  week: string = ''
  textDay: string = ''
  textNight: string = ''
  high: number = 0
  low: number = 0
  windDir: string = ''
  windScale: string = ''
  humidity: number = 0
  pop: number = 0
  uvIndex: number = -1
  sunriseAt: number = 0
  sunsetAt: number = 0
  nightHours: number = 0
  nightExpectedHours: number = 0
  nightSummarySource: string = ''
  nightRange: string = ''
}

export class AirQuality {
  available: boolean = false
  standard: string = ''
  aqi: number = -1
  level: string = '暂无数据'
  pm25: number = 18
  pm10: number = 36
  no2: number = 18
  so2: number = 5
  co: number = 0.8
  o3: number = 72
  advice: string = '空气质量数据暂不可用'
}

export class LifeIndex {
  name: string = ''
  iconKey: string = ''
  brief: string = ''
  detail: string = ''
  caption: string = ''
  // local = app heuristic, qweather = provider index, empty = unknown provenance.
  source: string = ''
}

export class WeatherData {
  city: string = '深圳'
  cityId: string = '101280601'
  current: CurrentWeather = new CurrentWeather()
  hourly: HourlyWeather[] = []
  daily: DailyWeather[] = []
  air: AirQuality = new AirQuality()
  lifeIndex: LifeIndex[] = []
  alerts: WeatherAlert[] = []
  lastUpdate: number = 0
  isOffline: boolean = false
  source: string = 'mock'
  timezone: string = 'Asia/Shanghai'
  utcOffsetSeconds: number = 28800
  observedAt: number = 0

  static localDate(timestamp: number, utcOffsetSeconds: number): Date {
    return new Date(timestamp + utcOffsetSeconds * 1000)
  }

  static sceneAt(data: WeatherData, now: number = Date.now()): WeatherSceneState {
    const local: Date = WeatherData.localDate(now, data.utcOffsetSeconds)
    const scene: WeatherSceneState = new WeatherSceneState()
    scene.hour = local.getUTCHours() + local.getUTCMinutes() / 60
    const today: string = local.toISOString().substring(0, 10)
    const solar: DailyWeather | undefined = data.daily.find((day: DailyWeather) => day.date === today)
    const rise: string = solar && solar.sunriseAt > 0 ? WeatherData.localTime(solar.sunriseAt, data.utcOffsetSeconds) : data.current.sunrise
    const set: string = solar && solar.sunsetAt > 0 ? WeatherData.localTime(solar.sunsetAt, data.utcOffsetSeconds) : data.current.sunset
    scene.isNight = WeatherData.resolveVisualState('晴', scene.hour, rise, set) === WeatherVisualState.CLEAR_NIGHT
    scene.visualState = WeatherData.resolveVisualState(data.current.text, scene.hour, rise, set)
    return scene
  }

  static localTime(timestamp: number, utcOffsetSeconds: number): string {
    return WeatherData.localDate(timestamp, utcOffsetSeconds).toISOString().substring(11, 16)
  }

  static fromMock(json: Record<string, Object>): WeatherData {
    const data: WeatherData = new WeatherData()
    data.city = WeatherData.getStr(json, 'city', '深圳')
    data.cityId = WeatherData.getStr(json, 'cityId', '101280601')
    data.timezone = WeatherData.getStr(json, 'timezone', 'Asia/Shanghai')
    data.utcOffsetSeconds = WeatherData.getNum(json, 'utcOffsetSeconds', 28800)
    data.observedAt = WeatherData.getNum(json, 'observedAt', 0)
    data.source = WeatherData.getStr(json, 'source', 'mock')

    // Cache omissions are not observations. Do not let sample constructor values
    // become evidence for an outdoor-activity recommendation.
    data.current.temp = NaN
    data.current.feelsLike = NaN
    data.current.text = '未知'
    data.current.windSpeed = -1
    data.current.precip = -1
    const cur: Record<string, Object> | undefined = json['current'] as Record<string, Object> | undefined
    if (cur) {
      data.current.temp = WeatherData.getNum(cur, 'temp', NaN)
      data.current.feelsLike = WeatherData.getNum(cur, 'feelsLike', NaN)
      data.current.text = WeatherData.getStr(cur, 'text', '未知')
      data.current.high = WeatherData.getNum(cur, 'high', 29)
      data.current.low = WeatherData.getNum(cur, 'low', 23)
      data.current.humidity = WeatherData.getNum(cur, 'humidity', 66)
      data.current.windSpeed = WeatherData.getNum(cur, 'windSpeed', -1)
      data.current.windDir = WeatherData.getStr(cur, 'windDir', '东南风')
      data.current.windScale = WeatherData.getStr(cur, 'windScale', '2级')
      data.current.pressure = WeatherData.getNum(cur, 'pressure', 1015)
      data.current.visibility = WeatherData.getNum(cur, 'visibility', 28)
      data.current.uv = WeatherData.getStr(cur, 'uv', '暂无数据').trim() || '暂无数据'
      data.current.uvScope = WeatherData.getStr(cur, 'uvScope', '')
      // Do not infer scope from the presence of a daily array or from selected settings.
      // Legacy adapters stored a daily value in current.uv; only their source is evidence.
      if (cur['uvScope'] === undefined && ['弱', '中等', '较强', '很强', '极强'].includes(data.current.uv)) {
        if (data.source === 'openmeteo') data.current.uvScope = 'daily_max'
        if (data.source === 'qweather') data.current.uvScope = 'daily'
      }
      data.current.sunrise = WeatherData.getStr(cur, 'sunrise', '05:46')
      data.current.sunset = WeatherData.getStr(cur, 'sunset', '19:13')
      data.current.precip = WeatherData.getNum(cur, 'precip', -1)
      data.current.cloud = WeatherData.getNum(cur, 'cloud', 10)
    }

    const hourlyArr: Array<Record<string, Object>> | undefined =
      json['hourly'] as Array<Record<string, Object>> | undefined
    if (hourlyArr) {
      data.hourly = hourlyArr.map((h: Record<string, Object>) => {
        const item: HourlyWeather = new HourlyWeather()
        item.time = WeatherData.getStr(h, 'time', '')
        item.temp = WeatherData.getNum(h, 'temp', 0)
        item.text = WeatherData.getStr(h, 'text', '')
        item.pop = WeatherData.getNum(h, 'pop', 0)
        item.windDir = WeatherData.getStr(h, 'windDir', '')
        item.windScale = WeatherData.getStr(h, 'windScale', '')
        item.isDay = WeatherData.getBool(h, 'isDay', true)
        item.timestamp = WeatherData.getNum(h, 'timestamp', 0)
        return item
      })
    }

    const dailyArr: Array<Record<string, Object>> | undefined =
      json['daily'] as Array<Record<string, Object>> | undefined
    if (dailyArr) {
      data.daily = dailyArr.map((d: Record<string, Object>) => {
        const item: DailyWeather = new DailyWeather()
        item.date = WeatherData.getStr(d, 'date', '')
        item.week = WeatherData.getStr(d, 'week', '')
        item.textDay = WeatherData.getStr(d, 'textDay', '')
        item.textNight = WeatherData.getStr(d, 'textNight', '暂无夜间数据')
        if (!item.textNight.trim() || item.textNight === '见逐小时预报') item.textNight = '暂无夜间数据'
        item.high = WeatherData.getNum(d, 'high', 0)
        item.low = WeatherData.getNum(d, 'low', 0)
        item.windDir = WeatherData.getStr(d, 'windDir', '')
        item.windScale = WeatherData.getStr(d, 'windScale', '')
        item.humidity = WeatherData.getNum(d, 'humidity', 0)
        item.pop = WeatherData.getNum(d, 'pop', 0)
        const uvIndex: number = WeatherData.getNum(d, 'uvIndex', -1)
        item.uvIndex = uvIndex >= 0 ? uvIndex : -1
        item.sunriseAt = WeatherData.getNum(d, 'sunriseAt', 0)
        item.sunsetAt = WeatherData.getNum(d, 'sunsetAt', 0)
        item.nightHours = WeatherData.getNum(d, 'nightHours', 0)
        item.nightExpectedHours = WeatherData.getNum(d, 'nightExpectedHours', 0)
        item.nightSummarySource = WeatherData.getStr(d, 'nightSummarySource', '')
        item.nightRange = WeatherData.getStr(d, 'nightRange', '')
        return item
      })
    }

    if (cur && cur['uvScope'] === undefined && (data.source === 'openmeteo' || data.source === 'qweather')) {
      const date: string = WeatherData.localDate(data.observedAt, data.utcOffsetSeconds).toISOString().substring(0, 10)
      const uvDay: DailyWeather | undefined = data.observedAt > 0 ?
        data.daily.find((day: DailyWeather) => day.date === date) : data.daily[0]
      // The old adapters mapped null/missing UV to a plausible grade. Only a
      // corresponding numeric daily value can validate that legacy grade.
      if (!uvDay || uvDay.uvIndex < 0) {
        data.current.uv = '暂无数据'
        data.current.uvScope = ''
      }
    }

    const air: Record<string, Object> | undefined = json['air'] as Record<string, Object> | undefined
    if (air) {
      data.air.aqi = WeatherData.getNum(air, 'aqi', -1)
      data.air.available = (air['available'] === undefined || air['available'] === true) && data.air.aqi >= 0
      const legacyStandard: string = data.source === 'openmeteo' ? 'US AQI' : data.source === 'qweather' ? 'CN AQI' : ''
      data.air.standard = WeatherData.getStr(air, 'standard', legacyStandard)
      data.air.level = WeatherData.getStr(air, 'level', '暂无数据')
      data.air.pm25 = WeatherData.getNum(air, 'pm25', 18)
      data.air.pm10 = WeatherData.getNum(air, 'pm10', 36)
      data.air.no2 = WeatherData.getNum(air, 'no2', 18)
      data.air.so2 = WeatherData.getNum(air, 'so2', 5)
      data.air.co = WeatherData.getNum(air, 'co', 0.8)
      data.air.o3 = WeatherData.getNum(air, 'o3', 72)
      data.air.advice = WeatherData.getStr(air, 'advice', '空气质量数据暂不可用')
    }

    const lifeArr: Array<Record<string, Object>> | undefined =
      json['lifeIndex'] as Array<Record<string, Object>> | undefined
    if (lifeArr) {
      data.lifeIndex = lifeArr.map((l: Record<string, Object>) => {
        const item: LifeIndex = new LifeIndex()
        item.name = WeatherData.getStr(l, 'name', '')
        item.iconKey = WeatherData.getStr(l, 'iconKey', WeatherData.getStr(l, 'icon', 'info'))
        item.brief = WeatherData.getStr(l, 'brief', '')
        item.detail = WeatherData.getStr(l, 'detail', '')
        item.caption = WeatherData.getStr(l, 'caption', '')
        item.source = WeatherData.getStr(l, 'source', '')
        return item
      })
    }

    const alertArr: Array<Record<string, Object>> | undefined =
      json['alerts'] as Array<Record<string, Object>> | undefined
    if (alertArr) {
      data.alerts = alertArr.map((a: Record<string, Object>) => {
        const item: WeatherAlert = new WeatherAlert()
        item.title = WeatherData.getStr(a, 'title', '')
        item.severity = WeatherData.getStr(a, 'severity', '提醒')
        item.detail = WeatherData.getStr(a, 'detail', '')
        return item
      })
    }

    // An absent cache timestamp cannot prove today's UV or make old data fresh.
    data.lastUpdate = WeatherData.getNum(json, 'lastUpdate', 0)
    data.isOffline = WeatherData.getBool(json, 'isOffline', false)
    return data
  }

  private static getStr(obj: Record<string, Object>, key: string, fallback: string): string {
    const val: Object | undefined = obj[key]
    return val !== undefined && val !== null ? String(val) : fallback
  }

  private static getNum(obj: Record<string, Object>, key: string, fallback: number): number {
    const val: Object | undefined = obj[key]
    if (typeof val === 'number' || (typeof val === 'string' && String(val).trim().length > 0)) {
      const num: number = Number(val)
      if (Number.isFinite(num)) return num
    }
    return fallback
  }

  private static getBool(obj: Record<string, Object>, key: string, fallback: boolean): boolean {
    const val: Object | undefined = obj[key]
    if (typeof val === 'boolean') return val
    return fallback
  }

  static textToType(text: string): WeatherType {
    if (text.includes('雷')) return WeatherType.STORMY
    if (text.includes('雨')) return WeatherType.RAINY
    if (text.includes('雪')) return WeatherType.SNOWY
    if (text.includes('雾') || text.includes('霾') || text.includes('沙')) return WeatherType.FOGGY
    if (text.includes('晴')) return WeatherType.SUNNY
    return WeatherType.CLOUDY
  }

  static resolveVisualState(text: string, hour: number, sunrise: string, sunset: string): WeatherVisualState {
    const type: WeatherType = WeatherData.textToType(text)
    if (type === WeatherType.STORMY) return WeatherVisualState.STORM
    if (type === WeatherType.RAINY) return WeatherVisualState.RAIN
    if (type === WeatherType.SNOWY) return WeatherVisualState.SNOW
    if (type === WeatherType.FOGGY) return WeatherVisualState.HAZE
    const sunriseParts: string[] = sunrise.split(':')
    const sunsetParts: string[] = sunset.split(':')
    const sunriseValue: number = sunriseParts.length === 2 ? Number(sunriseParts[0]) + Number(sunriseParts[1]) / 60 : 6
    const sunsetValue: number = sunsetParts.length === 2 ? Number(sunsetParts[0]) + Number(sunsetParts[1]) / 60 : 19
    const sunriseHour: number = Number.isFinite(sunriseValue) ? sunriseValue : 6
    const sunsetHour: number = Number.isFinite(sunsetValue) ? sunsetValue : 19
    const isNight: boolean = hour < sunriseHour || hour >= sunsetHour
    if (type === WeatherType.SUNNY) {
      return isNight ? WeatherVisualState.CLEAR_NIGHT : WeatherVisualState.CLEAR_DAY
    }
    return isNight ? WeatherVisualState.CLOUDY_NIGHT : WeatherVisualState.CLOUDY_DAY
  }
}

export class WeatherUiState {
  status: WeatherUiStatus = WeatherUiStatus.LOADING
  data: WeatherData = new WeatherData()
  message: string = ''

  static loading(previous?: WeatherData): WeatherUiState {
    const state: WeatherUiState = new WeatherUiState()
    state.status = WeatherUiStatus.LOADING
    if (previous) state.data = previous
    return state
  }

  static ready(data: WeatherData): WeatherUiState {
    const state: WeatherUiState = new WeatherUiState()
    state.status = data.isOffline ? WeatherUiStatus.STALE : WeatherUiStatus.READY
    state.data = data
    return state
  }

  static error(message: string, previous?: WeatherData): WeatherUiState {
    const state: WeatherUiState = new WeatherUiState()
    state.status = previous ? WeatherUiStatus.STALE : WeatherUiStatus.ERROR
    state.message = message
    if (previous) {
      previous.isOffline = true
      state.data = previous
    }
    return state
  }
}
