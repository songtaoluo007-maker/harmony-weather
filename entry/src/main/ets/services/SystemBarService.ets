import { common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { DesignTokens as T } from '../theme/DesignTokens'

/** Latest visible page wins; a late window lookup cannot restyle a replacement page. */
export class SystemBarService {
  private static revision: number = 0
  static apply(context: common.UIAbilityContext, overScene: boolean = false): void {
    const revision: number = ++SystemBarService.revision
    const light: boolean = T.current.isLight
    window.getLastWindow(context).then((win: window.Window) => {
      if (revision !== SystemBarService.revision) return
      return win.setWindowSystemBarProperties({
        statusBarColor: '#00000000', navigationBarColor: '#00000000',
        statusBarContentColor: T.barInk(light, overScene), isStatusBarLightIcon: !light || overScene,
        navigationBarContentColor: T.barInk(light), isNavigationBarLightIcon: !light
      })
    }).catch(() => { /* The window may be gone during navigation or shutdown. */ })
  }
}
