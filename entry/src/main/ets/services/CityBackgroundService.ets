import { common } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { http } from '@kit.NetworkKit'
import { CityInfo } from '../models/WeatherModels'

interface WikiThumbnail {
  source: string
  width: number
  height: number
}

interface WikiPage {
  title: string
  fullurl?: string
  thumbnail?: WikiThumbnail
}

interface WikiQuery {
  pages: WikiPage[]
}

interface WikiImageResponse {
  query?: WikiQuery
}

interface CachedCityBackground {
  cityId: string
  imageUrl: string
  sourceUrl: string
  attribution: string
  fetchedAt: number
}

export class CityBackground {
  cityId: string = ''
  imageUrl: string = ''
  sourceUrl: string = ''
  attribution: string = ''
  fetchedAt: number = 0

  static fromCache(value: CachedCityBackground): CityBackground {
    const result: CityBackground = new CityBackground()
    result.cityId = value.cityId
    result.imageUrl = value.imageUrl
    result.sourceUrl = value.sourceUrl
    result.attribution = value.attribution
    result.fetchedAt = value.fetchedAt
    return result
  }
}

/**
 * Resolves a representative city photo automatically from Wikipedia's page image API.
 * Results are cached locally for 30 days. The weather scene remains responsible for
 * daylight and weather treatment, so one city image can be reused across all conditions.
 */
export class CityBackgroundService {
  private static instance: CityBackgroundService | null = null
  private memoryCache: Map<string, CityBackground> = new Map()
  private readonly cacheLifetime: number = 30 * 24 * 60 * 60 * 1000

  static getInstance(): CityBackgroundService {
    if (!CityBackgroundService.instance) CityBackgroundService.instance = new CityBackgroundService()
    return CityBackgroundService.instance
  }

  async resolve(context: common.UIAbilityContext, city: CityInfo, forceRefresh: boolean = false): Promise<CityBackground> {
    const memory: CityBackground | undefined = this.memoryCache.get(city.id)
    if (!forceRefresh && memory && this.isFresh(memory.fetchedAt)) return memory

    const persisted: CityBackground | null = await this.readCache(context, city.id)
    if (!forceRefresh && persisted && this.isFresh(persisted.fetchedAt)) {
      this.memoryCache.set(city.id, persisted)
      return persisted
    }

    try {
      const fresh: CityBackground = await this.fetchCityImage(city)
      this.memoryCache.set(city.id, fresh)
      await this.writeCache(context, fresh)
      return fresh
    } catch (error) {
      if (persisted) {
        this.memoryCache.set(city.id, persisted)
        return persisted
      }
      return new CityBackground()
    }
  }

  private isFresh(timestamp: number): boolean {
    return timestamp > 0 && Date.now() - timestamp < this.cacheLifetime
  }

  private async fetchCityImage(city: CityInfo): Promise<CityBackground> {
    const titles: string[] = this.getCandidateTitles(city.name)
    for (const title of titles) {
      const result: CityBackground | null = await this.fetchTitle(city.id, title)
      if (result) return result
    }
    throw new Error(`未找到${city.name}城市影像`)
  }

  private getCandidateTitles(cityName: string): string[] {
    if (cityName.endsWith('市')) return [cityName]
    return [`${cityName}市`, cityName]
  }

  private async fetchTitle(cityId: string, title: string): Promise<CityBackground | null> {
    const encodedTitle: string = encodeURIComponent(title)
    const url: string = 'https://zh.wikipedia.org/w/api.php?action=query&prop=pageimages%7Cinfo' +
      '&piprop=thumbnail&pithumbsize=1600&inprop=url&format=json&formatversion=2&origin=*&titles=' + encodedTitle
    const response: WikiImageResponse = await this.httpGet<WikiImageResponse>(url)
    const pages: WikiPage[] = response.query?.pages ?? []
    if (pages.length === 0 || !pages[0].thumbnail?.source) return null

    const value: CityBackground = new CityBackground()
    value.cityId = cityId
    value.imageUrl = pages[0].thumbnail!.source
    value.sourceUrl = pages[0].fullurl ?? `https://zh.wikipedia.org/wiki/${encodedTitle}`
    value.attribution = `城市影像 · 维基百科 · ${pages[0].title}`
    value.fetchedAt = Date.now()
    return value
  }

  private httpGet<T>(url: string): Promise<T> {
    return new Promise<T>((resolve: (value: T) => void, reject: (reason: Error) => void) => {
      const request: http.HttpRequest = http.createHttp()
      request.request(url, {
        method: http.RequestMethod.GET,
        readTimeout: 10000,
        connectTimeout: 10000,
        header: {
          'User-Agent': 'harmony-weather/1.0'
        }
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

  private async readCache(context: common.UIAbilityContext, cityId: string): Promise<CityBackground | null> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'city_background_cache' })
      const raw: string = String(await store.get(`city_${cityId}`, ''))
      if (!raw) return null
      return CityBackground.fromCache(JSON.parse(raw) as CachedCityBackground)
    } catch (error) {
      return null
    }
  }

  private async writeCache(context: common.UIAbilityContext, value: CityBackground): Promise<void> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, { name: 'city_background_cache' })
      await store.put(`city_${value.cityId}`, JSON.stringify(value))
      await store.flush()
    } catch (error) {
      console.warn('写入城市背景缓存失败: ' + JSON.stringify(error))
    }
  }
}
