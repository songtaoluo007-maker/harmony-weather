// ─── 天气类型枚举 ───────────────────────────────────
export enum WeatherType {
  SUNNY = 'sunny',
  CLOUDY = 'cloudy',
  RAINY = 'rainy',
  SNOWY = 'snowy',
  STORMY = 'stormy',
  FOGGY = 'foggy'
}

// ─── 时段枚举 ───────────────────────────────────────
export enum TimeOfDay {
  DAWN = 'dawn',     // 5-7
  DAY = 'day',       // 7-17
  DUSK = 'dusk',     // 17-19
  NIGHT = 'night'    // 19-5
}

// ─── 当前天气 ───────────────────────────────────────
export class CurrentWeather {
  temp: number = 26
  feelsLike: number = 24
  text: string = '晴'
  high: number = 28
  low: number = 19
  humidity: number = 65
  windSpeed: number = 12
  windDir: string = '东南风'
  windScale: string = '2级'
  pressure: number = 1015
  visibility: number = 15
  uv: string = '中等'
  sunrise: string = '06:50'
  sunset: string = '18:20'
}

// ─── 逐小时 ─────────────────────────────────────────
export class HourlyWeather {
  time: string = ''
  temp: number = 0
  text: string = ''
  icon: string = ''
}

// ─── 每日预报 ───────────────────────────────────────
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
}

// ─── 空气质量 ───────────────────────────────────────
export class AirQuality {
  aqi: number = 50
  level: string = '优'
  pm25: number = 30
  pm10: number = 60
  no2: number = 45
  so2: number = 5
  co: number = 0.8
  o3: number = 8
  advice: string = '空气质量令人满意，基本无空气污染'
}

// ─── 生活指数 ───────────────────────────────────────
export class LifeIndex {
  name: string = ''
  icon: string = ''
  brief: string = ''
  detail: string = ''
}

// ─── 完整天气数据 ───────────────────────────────────
export class WeatherData {
  city: string = '深圳'
  current: CurrentWeather = new CurrentWeather()
  hourly: HourlyWeather[] = []
  daily: DailyWeather[] = []
  air: AirQuality = new AirQuality()
  lifeIndex: LifeIndex[] = []
  lastUpdate: number = 0

  // 从 mock JSON 解析天气数据（使用辅助函数简化赋值）
  static fromMock(json: Record<string, Object>): WeatherData {
    const data: WeatherData = new WeatherData()
    data.city = WeatherData.getStr(json, 'city', '深圳')

    // 解析当前天气
    const cur: Record<string, Object> | undefined = json['current'] as Record<string, Object> | undefined
    if (cur) {
      data.current.temp = WeatherData.getNum(cur, 'temp', 26)
      data.current.feelsLike = WeatherData.getNum(cur, 'feelsLike', 24)
      data.current.text = WeatherData.getStr(cur, 'text', '晴')
      data.current.high = WeatherData.getNum(cur, 'high', 28)
      data.current.low = WeatherData.getNum(cur, 'low', 19)
      data.current.humidity = WeatherData.getNum(cur, 'humidity', 65)
      data.current.windSpeed = WeatherData.getNum(cur, 'windSpeed', 12)
      data.current.windDir = WeatherData.getStr(cur, 'windDir', '东南风')
      data.current.windScale = WeatherData.getStr(cur, 'windScale', '2级')
      data.current.pressure = WeatherData.getNum(cur, 'pressure', 1015)
      data.current.visibility = WeatherData.getNum(cur, 'visibility', 15)
      data.current.uv = WeatherData.getStr(cur, 'uv', '中等')
      data.current.sunrise = WeatherData.getStr(cur, 'sunrise', '06:50')
      data.current.sunset = WeatherData.getStr(cur, 'sunset', '18:20')
    }

    // 解析逐小时预报
    const hourlyArr: Array<Record<string, Object>> | undefined =
      json['hourly'] as Array<Record<string, Object>> | undefined
    if (hourlyArr) {
      data.hourly = hourlyArr.map((h: Record<string, Object>) => {
        const item: HourlyWeather = new HourlyWeather()
        item.time = WeatherData.getStr(h, 'time', '')
        item.temp = WeatherData.getNum(h, 'temp', 0)
        item.text = WeatherData.getStr(h, 'text', '')
        item.icon = WeatherData.textToIcon(item.text)
        return item
      })
    }

    // 解析每日预报（包含 textNight 处理）
    const dailyArr: Array<Record<string, Object>> | undefined =
      json['daily'] as Array<Record<string, Object>> | undefined
    if (dailyArr) {
      data.daily = dailyArr.map((d: Record<string, Object>) => {
        const item: DailyWeather = new DailyWeather()
        item.date = WeatherData.getStr(d, 'date', '')
        item.week = WeatherData.getStr(d, 'week', '')
        item.textDay = WeatherData.getStr(d, 'textDay', '')
        item.textNight = WeatherData.getStr(d, 'textNight', '')
        item.high = WeatherData.getNum(d, 'high', 0)
        item.low = WeatherData.getNum(d, 'low', 0)
        item.windDir = WeatherData.getStr(d, 'windDir', '')
        item.windScale = WeatherData.getStr(d, 'windScale', '')
        item.humidity = WeatherData.getNum(d, 'humidity', 0)
        return item
      })
    }

    // 解析空气质量
    const air: Record<string, Object> | undefined = json['air'] as Record<string, Object> | undefined
    if (air) {
      data.air.aqi = WeatherData.getNum(air, 'aqi', 50)
      data.air.level = WeatherData.getStr(air, 'level', '优')
      data.air.pm25 = WeatherData.getNum(air, 'pm25', 30)
      data.air.pm10 = WeatherData.getNum(air, 'pm10', 60)
      data.air.no2 = WeatherData.getNum(air, 'no2', 45)
      data.air.so2 = WeatherData.getNum(air, 'so2', 5)
      data.air.co = WeatherData.getNum(air, 'co', 0.8)
      data.air.o3 = WeatherData.getNum(air, 'o3', 8)
      data.air.advice = WeatherData.getStr(air, 'advice', '')
    }

    // 解析生活指数
    const lifeArr: Array<Record<string, Object>> | undefined =
      json['lifeIndex'] as Array<Record<string, Object>> | undefined
    if (lifeArr) {
      data.lifeIndex = lifeArr.map((l: Record<string, Object>) => {
        const item: LifeIndex = new LifeIndex()
        item.name = WeatherData.getStr(l, 'name', '')
        item.icon = WeatherData.getStr(l, 'icon', '')
        item.brief = WeatherData.getStr(l, 'brief', '')
        item.detail = WeatherData.getStr(l, 'detail', '')
        return item
      })
    }

    data.lastUpdate = Date.now()
    return data
  }

  // 辅助方法：安全获取字符串值
  private static getStr(obj: Record<string, Object>, key: string, fallback: string): string {
    const val: Object | undefined = obj[key]
    if (val !== undefined && val !== null) {
      return String(val)
    }
    return fallback
  }

  // 辅助方法：安全获取数值
  private static getNum(obj: Record<string, Object>, key: string, fallback: number): number {
    const val: Object | undefined = obj[key]
    if (val !== undefined && val !== null) {
      const num: number = Number(val)
      if (!Number.isNaN(num)) {
        return num
      }
    }
    return fallback
  }

  // 天气文本转图标（使用 ArkTS 安全的 emoji）
  static textToIcon(text: string): string {
    if (text.includes('晴')) return '☀'
    if (text.includes('多云')) return '⛅'
    if (text.includes('阴')) return '☁'
    if (text.includes('雨')) return '🌧'
    if (text.includes('雪')) return '❄'
    if (text.includes('雷')) return '⛈'
    if (text.includes('雾') || text.includes('霾')) return '🌫'
    return '☀'
  }

  // 天气文本转天气类型
  static textToType(text: string): WeatherType {
    if (text.includes('晴')) return WeatherType.SUNNY
    if (text.includes('多云')) return WeatherType.CLOUDY
    if (text.includes('雨') || text.includes('雷')) return WeatherType.RAINY
    if (text.includes('雪')) return WeatherType.SNOWY
    if (text.includes('雾') || text.includes('霾')) return WeatherType.FOGGY
    return WeatherType.CLOUDY
  }
}
