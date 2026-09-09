import { http } from '@kit.NetworkKit'
import { AirQuality, CityInfo, DailyWeather, HourlyWeather, WeatherData } from '../models/WeatherModels'

interface MeteoCurrent {
  time: number
  temperature_2m: number | null
  apparent_temperature: number
  relative_humidity_2m: number
  weather_code: number | null
  is_day: number
  precipitation: number
  cloud_cover: number
  pressure_msl: number
  wind_speed_10m: number
  wind_direction_10m: number
}
interface MeteoHourly {
  time: number[]
  temperature_2m: (number | null)[]
  relative_humidity_2m: number[]
  precipitation_probability: (number | null)[]
  weather_code: (number | null)[]
  visibility: number[]
  wind_speed_10m: number[]
  wind_direction_10m: number[]
  is_day: number[]
}
interface MeteoDaily {
  time: number[]
  weather_code: number[]
  temperature_2m_max: (number | null)[]
  temperature_2m_min: (number | null)[]
  sunrise: number[]
  sunset: number[]
  uv_index_max?: (number | null)[]
  precipitation_probability_max: (number | null)[]
  wind_speed_10m_max: number[]
  wind_direction_10m_dominant: number[]
}
interface MeteoResponse {
  timezone: string
  utc_offset_seconds: number
  current: MeteoCurrent
  hourly: MeteoHourly
  daily: MeteoDaily
}
interface MeteoAirCurrent {
  us_aqi: number | null
  pm2_5: number | null
  pm10: number | null
  nitrogen_dioxide: number | null
  sulphur_dioxide: number | null
  carbon_monoxide: number | null
  ozone: number | null
}
interface MeteoAirResponse { current: MeteoAirCurrent }

/** Public non-commercial endpoint. No credentials. Never returns demo data. */
export class OpenMeteoService {
  async fetch(city: CityInfo): Promise<WeatherData> {
    const location: string = `latitude=${city.latitude}&longitude=${city.longitude}`
    const current: string = 'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m,wind_direction_10m'
    const hourly: string = 'temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,visibility,wind_speed_10m,wind_direction_10m,is_day'
    const daily: string = 'weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max,precipitation_probability_max,wind_speed_10m_max,wind_direction_10m_dominant'
    const response: MeteoResponse = await this.httpGet<MeteoResponse>(
      `https://api.open-meteo.com/v1/forecast?${location}&current=${current}&hourly=${hourly}&daily=${daily}&timezone=auto&timeformat=unixtime&forecast_days=16`)
    const data: WeatherData = this.parse(response, city)
    // Air quality is optional and cannot block current weather or its scene.
    try {
      const air: MeteoAirResponse = await this.httpGet<MeteoAirResponse>(
        `https://air-quality-api.open-meteo.com/v1/air-quality?${location}&current=us_aqi,pm2_5,pm10,nitrogen_dioxide,sulphur_dioxide,carbon_monoxide,ozone&timezone=auto&forecast_days=1`)
      if (air.current && [air.current.us_aqi, air.current.pm2_5, air.current.pm10,
        air.current.nitrogen_dioxide, air.current.sulphur_dioxide, air.current.carbon_monoxide,
        air.current.ozone].every((value: number | null) => value !== null && Number.isFinite(value) && value >= 0)) {
        data.air = this.parseAir(air.current)
      }
    } catch (error) {
      console.warn('Open-Meteo 空气质量暂不可用')
    }
    return data
  }

  private parse(response: MeteoResponse, city: CityInfo): WeatherData {
    const now: MeteoCurrent = response.current
    if (!now || now.temperature_2m === null || !Number.isFinite(now.temperature_2m) ||
      now.weather_code === null || !Number.isFinite(now.weather_code) || !Number.isFinite(now.time)) {
      throw new Error('在线天气数据不完整')
    }
    const data: WeatherData = new WeatherData()
    data.city = city.name
    data.cityId = city.id
    data.source = 'openmeteo'
    data.timezone = response.timezone
    data.utcOffsetSeconds = response.utc_offset_seconds
    data.observedAt = now.time * 1000
    data.lastUpdate = Date.now()
    data.air.available = false
    data.air.standard = 'US AQI'
    data.current.temp = Math.round(now.temperature_2m)
    data.current.feelsLike = Math.round(now.apparent_temperature)
    data.current.text = OpenMeteoService.weatherText(now.weather_code)
    data.current.humidity = now.relative_humidity_2m
    data.current.windSpeed = now.wind_speed_10m
    data.current.windDir = OpenMeteoService.windDirection(now.wind_direction_10m)
    data.current.windScale = OpenMeteoService.windScale(now.wind_speed_10m)
    data.current.pressure = Math.round(now.pressure_msl)
    data.current.precip = now.precipitation
    data.current.cloud = now.cloud_cover
    data.current.visibility = 0
    data.current.high = data.current.temp
    data.current.low = data.current.temp
    data.current.sunrise = ''
    data.current.sunset = ''
    const hours: MeteoHourly = response.hourly
    const start: number = Math.max(0, hours.time.findIndex((time: number) => time >= Math.floor(now.time / 3600) * 3600))
    for (let i: number = start; i < Math.min(hours.time.length, start + 24); i++) {
      const temperature: number | null = hours.temperature_2m[i]
      if (temperature === null || !Number.isFinite(temperature) || !Number.isFinite(hours.time[i])) continue
      const item: HourlyWeather = new HourlyWeather()
      item.timestamp = hours.time[i] * 1000
      item.time = WeatherData.localTime(item.timestamp, data.utcOffsetSeconds)
      item.temp = Math.round(temperature)
      item.text = hours.weather_code[i] !== null ? OpenMeteoService.weatherText(hours.weather_code[i] as number) : '暂无'
      item.pop = hours.precipitation_probability[i] ?? -1
      item.windDir = OpenMeteoService.windDirection(hours.wind_direction_10m[i])
      item.windScale = OpenMeteoService.windScale(hours.wind_speed_10m[i])
      item.isDay = hours.is_day[i] === 1
      data.hourly.push(item)
    }
    if (Number.isFinite(hours.visibility[start])) data.current.visibility = Math.round(hours.visibility[start] / 100) / 10
    const days: MeteoDaily = response.daily
    const weeks: string[] = ['周日', '周一', '周二', '周三', '周四', '周五', '周六']
    // The extra sixteenth forecast day is used only to complete the fifteenth night.
    for (let i: number = 0; i < Math.min(15, days.time.length); i++) {
      const high: number | null = days.temperature_2m_max[i]
      const low: number | null = days.temperature_2m_min[i]
      if (high === null || low === null || !Number.isFinite(high) || !Number.isFinite(low)) continue
      const day: DailyWeather = new DailyWeather()
      const local: Date = WeatherData.localDate(days.time[i] * 1000, data.utcOffsetSeconds)
      day.date = local.toISOString().substring(0, 10)
      day.week = weeks[local.getUTCDay()]
      day.high = Math.round(high)
      day.low = Math.round(low)
      day.textDay = OpenMeteoService.weatherText(days.weather_code[i])
      day.textNight = '暂无夜间数据'
      day.sunriseAt = days.sunrise[i] * 1000
      day.sunsetAt = days.sunset[i] * 1000
      this.summarizeNight(day, hours, days.sunrise[i + 1] * 1000, data.utcOffsetSeconds)
      day.pop = days.precipitation_probability_max[i] ?? -1
      const uv: number | null | undefined = days.uv_index_max?.[i]
      day.uvIndex = typeof uv === 'number' && Number.isFinite(uv) && uv >= 0 ? uv : -1
      day.windDir = OpenMeteoService.windDirection(days.wind_direction_10m_dominant[i])
      day.windScale = OpenMeteoService.windScale(days.wind_speed_10m_max[i])
      const humidity: number[] = hours.relative_humidity_2m.slice(i * 24, (i + 1) * 24).filter((v: number) => Number.isFinite(v))
      day.humidity = humidity.length ? Math.round(humidity.reduce((sum: number, value: number) => sum + value, 0) / humidity.length) : -1
      data.daily.push(day)
    }
    const localToday: string = WeatherData.localDate(data.observedAt, data.utcOffsetSeconds).toISOString().substring(0, 10)
    const today: DailyWeather | undefined = data.daily.find((day: DailyWeather) => day.date === localToday)
    if (today) {
      data.current.high = today.high
      data.current.low = today.low
      data.current.sunrise = WeatherData.localTime(today.sunriseAt, data.utcOffsetSeconds)
      data.current.sunset = WeatherData.localTime(today.sunsetAt, data.utcOffsetSeconds)
      if (today.uvIndex >= 0) {
        data.current.uv = today.uvIndex <= 2 ? '弱' : today.uvIndex <= 5 ? '中等' : today.uvIndex <= 7 ? '较强' : today.uvIndex <= 10 ? '很强' : '极强'
        data.current.uvScope = 'daily_max'
      }
    }
    return data
  }

  private summarizeNight(day: DailyWeather, hours: MeteoHourly, nextSunriseAt: number, offset: number): void {
    if (!Number.isFinite(day.sunsetAt) || day.sunsetAt <= 0 ||
      !Number.isFinite(nextSunriseAt) || nextSunriseAt <= day.sunsetAt) return
    day.nightSummarySource = 'hourly'
    day.nightRange = `${WeatherData.localTime(day.sunsetAt, offset)}–次日${WeatherData.localTime(nextSunriseAt, offset)}`
    day.nightExpectedHours = Math.ceil(nextSunriseAt / 3600000) - Math.ceil(day.sunsetAt / 3600000)
    const descriptions: string[] = []
    for (let i: number = 0; i < hours.time.length; i++) {
      const timestamp: number = hours.time[i] * 1000
      if (!Number.isFinite(timestamp) || timestamp < day.sunsetAt || timestamp >= nextSunriseAt) continue
      const code: number | null = hours.weather_code[i]
      if (code === null || !Number.isFinite(code)) continue
      const description: string = OpenMeteoService.weatherText(code)
      if (description === '未知') continue
      day.nightHours++
      if (!descriptions.includes(description)) descriptions.push(description)
    }
    if (descriptions.length) day.textNight = descriptions.join(' / ')
  }

  private parseAir(now: MeteoAirCurrent): AirQuality {
    const air: AirQuality = new AirQuality()
    air.available = true
    air.standard = 'US AQI'
    air.aqi = Math.round(now.us_aqi ?? 0)
    air.level = air.aqi <= 50 ? '优' : air.aqi <= 100 ? '中等' : air.aqi <= 150 ? '敏感人群注意' : air.aqi <= 200 ? '不健康' : air.aqi <= 300 ? '很不健康' : '危险'
    // Only called after every pollutant has passed the finite/non-null gate.
    air.pm25 = Math.round((now.pm2_5 as number) * 10) / 10
    air.pm10 = Math.round((now.pm10 as number) * 10) / 10
    air.no2 = Math.round((now.nitrogen_dioxide as number) * 10) / 10
    air.so2 = Math.round((now.sulphur_dioxide as number) * 10) / 10
    air.co = Math.round(now.carbon_monoxide as number) / 1000
    air.o3 = Math.round((now.ozone as number) * 10) / 10
    air.advice = '空气质量模型估算，采用美国 AQI 标准，非中国站点实测。'
    return air
  }

  static weatherText(code: number): string {
    if (code === 0) return '晴'
    if (code === 1) return '晴间多云'
    if (code === 2) return '多云'
    if (code === 3) return '阴'
    if (code === 45 || code === 48) return '雾'
    if (code >= 95) return '雷阵雨'
    if (code === 85 || code === 86) return '阵雪'
    if (code >= 80 && code <= 82) return '阵雨'
    if (code >= 71 && code <= 77) return '雪'
    if (code === 66 || code === 67 || code === 56 || code === 57) return '冻雨'
    if (code === 61) return '小雨'
    if (code === 63) return '中雨'
    if (code === 65) return '大雨'
    if (code >= 51 && code <= 55) return '毛毛雨'
    return '未知'
  }

  static windDirection(degrees: number): string {
    const directions: string[] = ['北风', '东北风', '东风', '东南风', '南风', '西南风', '西风', '西北风']
    return directions[Math.round(degrees / 45) % 8]
  }

  static windScale(kmh: number): string {
    const limits: number[] = [1, 6, 12, 20, 29, 39, 50, 62, 75, 89, 103, 118]
    const scale: number = limits.findIndex((limit: number) => kmh < limit)
    return `${scale < 0 ? 12 : scale}级`
  }

  private async httpGet<T>(url: string): Promise<T> {
    let request: http.HttpRequest | undefined = undefined
    try {
      request = http.createHttp()
      const response: http.HttpResponse = await request.request(url, {
        method: http.RequestMethod.GET, readTimeout: 12000, connectTimeout: 10000
      })
      if (response.responseCode !== 200) throw new Error(`在线天气 HTTP ${response.responseCode}`)
      return JSON.parse(response.result as string) as T
    } catch (error) {
      throw new Error('在线天气请求失败，请稍后重试')
    } finally { request?.destroy() }
  }
}
