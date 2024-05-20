//
//  MEMEProfitTrackerApp.swift
//  MEMEProfitTracker
//
//  Created by WhienLiu on 2024/5/18.
//

import SwiftUI
import Alamofire
import Combine

class ProfitTrackerModel: ObservableObject {
    @Published var symbol: String = "BTCUSDT"
    @Published var assetAmount: String = "0"
}

struct HistoryListItem: Identifiable {
    let id = UUID()
    let symbol: String
    let amount: String
}
class HistoryListModel: ObservableObject {
    @Published var historyList: [HistoryListItem] = []
}

@main
struct MEMEProfitTrackerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.profitTrackerModel)
                .environmentObject(appDelegate.historyListModel)
            HistoryListView()
                .environmentObject(appDelegate.profitTrackerModel)
                .environmentObject(appDelegate.historyListModel)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var profitTrackerModel = ProfitTrackerModel()
    var historyListModel = HistoryListModel()
    private var cancellables = Set<AnyCancellable>()
    
    var titleStatus = 0
    var statusItem: NSStatusItem!
    var timer: Timer?
    var timeInterval: Double = 5.0
    var symbol: String = "BTCUSDT"
    var assetAmount: String = "0"
    var settingsViewPopover: NSPopover!
    var historyListViewPopover: NSPopover!
    var eventMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "eyes", accessibilityDescription: nil)
            button.action = #selector(showMenu)
            startUpdateProfit()
        }
        
        settingsViewPopover = NSPopover()
        let settingsView = SettingsView()
            .environmentObject(profitTrackerModel)
            .environmentObject(historyListModel)
        settingsViewPopover?.contentViewController = NSHostingController(rootView: settingsView)
        
        historyListViewPopover = NSPopover()
        let historyListView = HistoryListView()
            .environmentObject(profitTrackerModel)
            .environmentObject(historyListModel)
        historyListViewPopover?.contentViewController = NSHostingController(rootView: historyListView)
        
        profitTrackerModel.$symbol.sink { newSymbol in
            self.symbol = newSymbol
        }.store(in: &cancellables)
        
        profitTrackerModel.$assetAmount.sink { newAmount in
            self.assetAmount = newAmount
        }.store(in: &cancellables)
        
        NotificationCenter.default.addObserver(self, selector: #selector(toggleSettingsViewPopover), name: NSNotification.Name("CloseSettingsViewPopOver"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(toggleHistoryListViewPopover), name: NSNotification.Name("CloseHistoryListPopOver"), object: nil)
        NSApplication.shared.setActivationPolicy(.accessory)
    }
    
    func startUpdateProfit() {
        updateProfit()
        timer = Timer.scheduledTimer(timeInterval: self.timeInterval, target: self, selector: #selector(updateProfit), userInfo: nil, repeats: true)
    }
    
    @objc func updateProfit() {
        struct SymbolPrice: Decodable {
            let price: String
            let symbol: String
            
            var priceFloat: Float? {
                return Float(price)
            }
        }
        
        let parameters: [String: Any] = [
            "symbol": symbol
        ]
        AF.request("https://api3.binance.com/api/v3/ticker/price", parameters: parameters).responseDecodable(of: SymbolPrice.self) { response in
            switch response.result {
            case .success(let symbolPrice):
                if let button = self.statusItem.button {
                    if self.titleStatus == 0 {
                        button.title = "\(symbolPrice.symbol)"
                        self.titleStatus = 1
                    } else {
                        if let priceFloat = symbolPrice.priceFloat {
                            button.title = "$\(String(format: "%.5f", priceFloat))(\(priceFloat * (Float(self.assetAmount) ?? 1)))"
                            self.titleStatus = 0
                        }
                    }
                }
            case .failure(let error):
                print("Error: \(error)")
                self.profitTrackerModel.symbol = "BTCUSDT"
            }
        }
    }
    
    @objc func showMenu() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "調整追蹤代幣", action: #selector(toggleSettingsViewPopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "查看歷史追蹤", action: #selector(toggleHistoryListViewPopover), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "瀏覽幣安現貨", action: #selector(openBroswer), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "結束應用", action: #selector(quit), keyEquivalent: "Q"))
        
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
    }
    
    @objc func openBroswer(url: String) {
        if let url = URL(string: "https://www.binance.com/zh-TC/trade/\(self.profitTrackerModel.symbol)?type=spot") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func toggleSettingsViewPopover(_ sender: Any?) {
        if let button = statusItem.button {
            if settingsViewPopover.isShown {
                settingsViewPopover.performClose(sender)
            } else {
                settingsViewPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                startMonitoringClicks()
            }
        }
    }
    
    @objc func toggleHistoryListViewPopover(_ sender: Any?) {
        if let button = statusItem.button {
            if historyListViewPopover.isShown {
                historyListViewPopover.performClose(sender)
            } else {
                historyListViewPopover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                startMonitoringClicks()
            }
        }
    }
    
    func startMonitoringClicks() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] event in
            self?.handleMouseClick(event: event)
        }
    }
    
    func stopMonitoringClicks() {
        if let eventMonitor = eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
        
    func handleMouseClick(event: NSEvent) {
        let popovers = [settingsViewPopover, historyListViewPopover]
        let clickLocation = NSEvent.mouseLocation
        
        for popover in popovers {
            if popover!.isShown, let popoverWindow = popover!.contentViewController!.view.window {
                let convertedLocation = popoverWindow.convertFromScreen(NSRect(origin: clickLocation, size: .zero)).origin
                if !popoverWindow.frame.contains(convertedLocation) {
                    popover!.performClose(nil)
                }
            }
        }
        
        if !popovers.contains(where: { $0!.isShown }) {
            stopMonitoringClicks()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        timer?.invalidate()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
