//
//  HistoryListView.swift
//  MEMEProfitTracker
//
//  Created by WhienLiu on 2024/5/19.
//

import SwiftUI
import UniformTypeIdentifiers

struct HistoryListView: View {
    @EnvironmentObject var profitTrackerModel: ProfitTrackerModel
    @EnvironmentObject var historyListModel: HistoryListModel
    
    var body: some View {
        VStack {
            if historyListModel.historyList.isEmpty {
             Text("尚無歷史追蹤")
                Button("或導入（.csv）") {
                    let openPanel = NSOpenPanel()
                    openPanel.allowedContentTypes = [UTType.commaSeparatedText] // 修改這一行
                    
                    if openPanel.runModal() == .OK, let url = openPanel.url {
                        do {
                            let csvContent = try String(contentsOf: url)
                            historyListModel.historyList = parseCSV(content: csvContent)
                        } catch {
                            print("Failed to read file: \(error.localizedDescription)")
                        }
                    }
                }
            } else {
                ForEach(historyListModel.historyList, id: \.id) { history in
                    HStack {
                        Button(action: {
                            profitTrackerModel.symbol = history.symbol
                            profitTrackerModel.assetAmount = history.amount
                            NotificationCenter.default.post(name: NSNotification.Name("CloseHistoryListPopOver"), object: nil)
                        }) {
                            Text("代號：\(history.symbol) 數量：\(history.amount)")
                        }.buttonStyle(PlainButtonStyle())
                        Spacer()
                        Button(action: {
                            if let index = historyListModel.historyList.firstIndex(where: { $0.id == history.id }) {
                                historyListModel.historyList.remove(at: index)
                            }
                        }) {
                            Text("移除")
                        }.buttonStyle(PlainButtonStyle())
                    }
                }
                Divider()
                HStack {
                    Button("輸出（.csv）") {
                        var csvString = "symbol,amount\n"
                        for item in historyListModel.historyList {
                            let line = "\(item.symbol),\(item.amount)\n"
                            csvString.append(line)
                            
                            let savePanel = NSSavePanel()
                            savePanel.allowedContentTypes = [UTType.commaSeparatedText]
                            savePanel.nameFieldStringValue = "MEMEProfitTracker_History.csv"
                            
                            savePanel.begin { response in
                                if response == .OK, let url = savePanel.url {
                                    do {
                                        try csvString.write(to: url, atomically: true, encoding: .utf8)
                                    } catch {
                                        print("Failed to save file: \(error.localizedDescription)")
                                    }
                                }
                            }
                        }
                    }
                    Button("移除全部") {
                        historyListModel.historyList.removeAll()
                    }
                }
            }
        }
        .frame(width: 300)
        .padding()
    }
}

func parseCSV(content: String) -> [HistoryListItem] {
    var historyList: [HistoryListItem] = []
    let rows = content.split(separator: "\n")
    
    for row in rows.dropFirst() { // Skip header
        let columns = row.split(separator: ",")
        if columns.count >= 2 {
            let item: HistoryListItem = HistoryListItem(symbol: String(columns[0]), amount: String(columns[1]))
            historyList.append(item)
        }
    }
    return historyList
}
