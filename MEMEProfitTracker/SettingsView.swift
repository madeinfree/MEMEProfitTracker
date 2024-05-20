//
//  SettingsView.swift
//  MEMEProfitTracker
//
//  Created by WhienLiu on 2024/5/19.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var profitTrackerModel: ProfitTrackerModel
    @EnvironmentObject var historyListModel: HistoryListModel
    @State private var tempSymbol: String = "BTCUSDT"
    @State private var tempAssetAmount: String = "1"
    
    var body: some View {
        VStack {
            Text("代幣編號")
            TextField("代幣編號", text: self.$tempSymbol)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            Text("代幣數量")
            TextField("代幣數量", text: self.$tempAssetAmount)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .onChange(of: tempAssetAmount) { oldValue, newValue in
                let filtered = newValue.filter { "0123456789.".contains($0) }
                if filtered != newValue {
                    self.tempAssetAmount = filtered
                }
            }
            Button("開始追蹤") {
                profitTrackerModel.symbol = tempSymbol
                profitTrackerModel.assetAmount = tempAssetAmount
                let newHistory = HistoryListItem(symbol: tempSymbol, amount: tempAssetAmount)
                historyListModel.historyList.append(newHistory)
                NotificationCenter.default.post(name: NSNotification.Name("CloseSettingsViewPopOver"), object: nil)
            }.disabled(tempSymbol.isEmpty)
        }
        .padding()
        .frame(width: 300)
        .onAppear {
            tempSymbol = profitTrackerModel.symbol
            tempAssetAmount = profitTrackerModel.assetAmount
        }
    }
}
