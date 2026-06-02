import Cocoa
import FlutterMacOS
import audioplayers_darwin
import desktop_multi_window
import file_picker
import isar_flutter_libs
import printing
import sqflite_darwin

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
      AudioplayersDarwinPlugin.register(
        with: controller.registrar(forPlugin: "AudioplayersDarwinPlugin")
      )
      FilePickerPlugin.register(
        with: controller.registrar(forPlugin: "FilePickerPlugin")
      )
      IsarFlutterLibsPlugin.register(
        with: controller.registrar(forPlugin: "IsarFlutterLibsPlugin")
      )
      PrintingPlugin.register(
        with: controller.registrar(forPlugin: "PrintingPlugin")
      )
      SqflitePlugin.register(
        with: controller.registrar(forPlugin: "SqflitePlugin")
      )
    }

    super.awakeFromNib()
  }
}
