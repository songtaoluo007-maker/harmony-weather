import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onWindowStageCreate');
    try {
      const mainWindow: window.Window = windowStage.getMainWindowSync();
      mainWindow.setWindowLayoutFullScreen(true).catch((error: Error) => {
        hilog.warn(0x0000, 'WeatherApp', 'Unable to enable immersive layout: %{public}s', JSON.stringify(error));
      });
      mainWindow.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        statusBarContentColor: '#FFFFFF',
        isStatusBarLightIcon: true,
        navigationBarColor: '#00000000',
        navigationBarContentColor: '#FFFFFF',
        isNavigationBarLightIcon: true
      }).catch((error: Error) => {
        hilog.warn(0x0000, 'WeatherApp', 'Unable to style system bars: %{public}s', JSON.stringify(error));
      });
    } catch (error) {
      hilog.warn(0x0000, 'WeatherApp', 'Unable to prepare main window: %{public}s', JSON.stringify(error));
    }
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, 'WeatherApp', 'Failed to load content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(0x0000, 'WeatherApp', 'Succeeded in loading content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'WeatherApp', '%{public}s', 'Ability onBackground');
  }
}
