//
//  PreferencesViewController.swift
//  I2PLauncher
//
//  Created by Mikal Villa on 07/11/2018.
//  Copyright © 2018 The I2P Project. All rights reserved.
//
// Table view programming guide from Apple:
// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/TableView/Introduction/Introduction.html
//

import Cocoa


class PreferencesViewController: NSViewController {
  
  enum ShowAsMode {
    case bothIcon
    case menubarIcon
    case dockIcon
  }
  
  var changeDockMenubarIconTimer: Timer?
  
  // MARK: - Advanced settings objects
  @IBOutlet weak var advPrefTableView: NSTableView!
  
  // MARK: - Launcher settings objects
  @IBOutlet var radioDockIcon: NSButton?
  @IBOutlet var radioMenubarIcon: NSButton?
  @IBOutlet var radioBothIcon: NSButton?
  @IBOutlet var checkboxStartWithOSX: NSButton?
  @IBOutlet var checkboxStartFirefoxAlso: NSButton?
  
  // MARK: - Router objects
  @IBOutlet var checkboxStartWithLauncher: NSButton?
  @IBOutlet var checkboxStopWithLauncher: NSButton?
  @IBOutlet var buttonResetRouterConfig: NSButton?
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.preferredContentSize = NSMakeSize(self.view.frame.size.width, self.view.frame.size.height)
    
    if (advPrefTableView != nil) {
      // For data feeding and view
      advPrefTableView.delegate = self
      advPrefTableView.dataSource = self
      
      // Responding to Double-Click
      advPrefTableView.target = self
      advPrefTableView.doubleAction = #selector(tableViewDoubleClick(_:))
      
      // Always redraw preference items which might have changed state since last draw.
      Preferences.shared().redrawPrefTableItems()
      
      // For sorting
      advPrefTableView.tableColumns[0].sortDescriptorPrototype = NSSortDescriptor(key: "name", ascending: true)
      advPrefTableView.tableColumns[1].sortDescriptorPrototype = NSSortDescriptor(key: "defaultValue", ascending: true)
      advPrefTableView.tableColumns[2].sortDescriptorPrototype = NSSortDescriptor(key: "selectedValue", ascending: true)
    }
    
    // Update radio buttons to reflect runtime/stored preferences
    self.updateRadioButtonEffect(mode: Preferences.shared().showAsIconMode, withSideEffect: false)
    
  }
  
  override func viewDidAppear() {
    super.viewDidAppear()
    
    // Update window title
    self.parent?.view.window?.title = self.title!
  }
  
  // MARK: - Router settings functions
  
  @IBAction func checkboxStartRouterWithLauncherClicked(_ sender: NSButton) {
    switch sender.state {
    case NSOnState:
      print("on")
      Preferences.shared().startRouterOnLauncherStart = true
    case NSOffState:
      print("off")
      Preferences.shared().startRouterOnLauncherStart = false
    case NSMixedState:
      print("mixed")
    default: break
    }
  }
  
  @IBAction func checkboxStopRouterWithLauncherClicked(_ sender: NSButton) {
    switch sender.state {
    case NSOnState:
      print("on")
      Preferences.shared().stopRouterOnLauncherShutdown = true
    case NSOffState:
      print("off")
      Preferences.shared().stopRouterOnLauncherShutdown = false
    case NSMixedState:
      print("mixed")
    default: break
    }
  }
  
  @IBAction func buttonResetRouterConfigClicked(_ sender: Any) {
    // TODO: Add a modal dialog asking user if they are **really** sure
  }
  
  // MARK: - Launcher settings functions
  
  @IBAction func checkboxStartLauncherOnOSXStartupClicked(_ sender: NSButton) {
    switch sender.state {
    case NSOnState:
      print("on")
    case NSOffState:
      print("off")
    case NSMixedState:
      print("mixed")
    default: break
    }
  }
  @IBAction func checkboxStartFirefoxAlsoAtLaunchClicked(_ sender: NSButton) {
    switch sender.state {
    case NSOnState:
      print("on")
    case NSOffState:
      print("off")
    case NSMixedState:
      print("mixed")
    default: break
    }
  }
  
  // MARK: - Radio buttons functions
  
  func updateDockMenubarIcons(_ mode: ShowAsMode) -> Bool {
    // Update preferences with latest choise
    Preferences.shared().showAsIconMode = mode
    // Update runtime
    switch mode {
    case .bothIcon, .dockIcon:
      // Show dock icon
      print("Preferences: Update Dock Icon -> Show")
      if (!getDockIconStateIsShowing()) {
        return triggerDockIconShowHide(showIcon: true)
      }
    case .menubarIcon:
      // Hide dock icon
      print("Preferences: Update Dock Icon -> Hide")
      if (getDockIconStateIsShowing()) {
        return triggerDockIconShowHide(showIcon: false)
      }
    }
    // Note: In reality, this won't ever happen.
    // The switch statement above would return before this.
    return false
  }
  
  func updateRadioButtonEffect(mode: ShowAsMode, withSideEffect: Bool = true) {
    changeDockMenubarIconTimer?.invalidate()
    
    radioDockIcon?.state = NSOffState
    radioMenubarIcon?.state = NSOffState
    radioBothIcon?.state = NSOffState
    
    switch mode {
    case .bothIcon:
      radioBothIcon?.state = NSOnState
    case .dockIcon:
      radioDockIcon?.state = NSOnState
    case .menubarIcon:
      radioMenubarIcon?.state = NSOnState
    }
    
    if (withSideEffect) {
      if #available(OSX 10.12, *) {
        changeDockMenubarIconTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false, block: { _ in
          // If we're on 10.12 or later
          self.updateDockMenubarIcons(mode)
        })
      } else {
        // Fallback on earlier versions
        self.updateDockMenubarIcons(mode)
      }
    }
  }
  
  @IBAction func radioBothIconSelected(_ sender: Any) {
    updateRadioButtonEffect(mode: ShowAsMode.bothIcon)
  }
  
  @IBAction func radioDockIconOnlySelected(_ sender: Any) {
    updateRadioButtonEffect(mode: ShowAsMode.dockIcon)
  }
  
  @IBAction func radioMenubarOnlySelected(_ sender: Any) {
    updateRadioButtonEffect(mode: ShowAsMode.menubarIcon)
  }
  
  // MARK: - Triggers
  
  func triggerDockIconHideShow(showIcon state: Bool) -> Bool {
    // Get transform state.
    var transformState: ProcessApplicationTransformState
    if state {
      transformState = ProcessApplicationTransformState(kProcessTransformToForegroundApplication)
    } else {
      transformState = ProcessApplicationTransformState(kProcessTransformToUIElementApplication)
    }
    
    // Show / hide dock icon.
    var psn = ProcessSerialNumber(highLongOfPSN: 0, lowLongOfPSN: UInt32(kCurrentProcess))
    let transformStatus: OSStatus = TransformProcessType(&psn, transformState)
    return transformStatus == 0
  }
  
  func triggerDockIconShowHide(showIcon state: Bool) -> Bool {
    var result: Bool
    if state {
      result = NSApp.setActivationPolicy(NSApplicationActivationPolicy.regular)
    } else {
      result = NSApp.setActivationPolicy(NSApplicationActivationPolicy.accessory)
    }
    return result
  }
  
  func getDockIconStateIsShowing() -> Bool {
    if NSApp.activationPolicy() == NSApplicationActivationPolicy.regular {
      return true
    } else {
      return false
    }
  }
  
  
  // MARK: - Advanced
  
  @IBAction func checkboxEnableAdvancedPreferencesClicked(_ sender: NSButton) {
    switch sender.state {
    case NSOnState:
      print("on")
      Preferences.shared().allowAdvancedPreferenceEdit = true
    case NSOffState:
      print("off")
      Preferences.shared().allowAdvancedPreferenceEdit = false
    case NSMixedState:
      print("mixed")
    default: break
    }
  }

  
  // End of Class
}


