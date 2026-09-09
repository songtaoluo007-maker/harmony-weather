export class BundledCityBackground {
  resource: Resource
  attribution: string
  isNightPhoto: boolean
  aspectRatio: number
  sourceUrl: string
  licenseUrl: string

  constructor(resource: Resource, attribution: string, isNightPhoto: boolean = false, aspectRatio: number = 1.5,
    sourceUrl: string = '', licenseUrl: string = '') {
    this.resource = resource
    this.attribution = attribution
    this.isNightPhoto = isNightPhoto
    this.aspectRatio = aspectRatio
    this.sourceUrl = sourceUrl
    this.licenseUrl = licenseUrl
  }
}

export class BundledCityBackgrounds {
  static resolve(cityId: string): BundledCityBackground | null {
    switch (cityId) {
      case '101010100': return new BundledCityBackground($r('app.media.city_bg_101010100'), '城市影像 · 维基百科 · 北京市')
      case '101020100': return new BundledCityBackground($r('app.media.city_bg_101020100'), '城市影像 · 维基百科 · 上海市')
      case '101280101': return new BundledCityBackground($r('app.media.city_bg_101280101'), '城市影像 · 维基百科 · 广州市')
      case '101280601': return new BundledCityBackground($r('app.media.city_bg_101280601'), '城市影像 · 维基百科 · 深圳市')
      case '101210101': return new BundledCityBackground($r('app.media.city_bg_101210101'), '城市影像 · 维基百科 · 杭州市')
      case '101190101': return new BundledCityBackground($r('app.media.city_bg_101190101'), '城市影像 · 维基百科 · 南京市')
      case '101200101': return new BundledCityBackground($r('app.media.city_bg_101200101'), '城市影像 · 维基百科 · 武汉市')
      case '101270101': return new BundledCityBackground($r('app.media.city_bg_101270101'), '城市影像 · 维基百科 · 成都市')
      case '101110101': return new BundledCityBackground($r('app.media.city_bg_101110101'), '城市影像 · 维基百科 · 西安市')
      case '101040100': return new BundledCityBackground($r('app.media.city_bg_101040100'), '城市影像 · 维基百科 · 重庆市')
      case '101030100': return new BundledCityBackground($r('app.media.city_bg_101030100'), '城市影像 · 维基百科 · 天津市')
      case '101190401': return new BundledCityBackground($r('app.media.city_bg_101190401'), '城市影像 · 维基百科 · 苏州市')
      case '101250101': return new BundledCityBackground($r('app.media.city_bg_101250101'), '城市影像 · 维基百科 · 长沙市')
      case '101120201': return new BundledCityBackground($r('app.media.city_bg_101120201'), '城市影像 · 维基百科 · 青岛市')
      case '101070201': return new BundledCityBackground($r('app.media.city_bg_101070201'), '城市影像 · 维基百科 · 大连市')
      default: return null
    }
  }
}
