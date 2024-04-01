////
////  LogViewModel.swift
////  Mbox extractor
//import Foundation
//import Combine
//import SwiftUI
//
//class LogViewModel: ObservableObject {
//    @Published var logMessages: [String] = []
//
//    func addLogMessage(_ message: String) {
//        DispatchQueue.main.async {
//            self.logMessages.append(message)
//            // Keep only the latest 500 messages to avoid clutter.
//            if self.logMessages.count > 500 {
//                self.logMessages.removeFirst()
//            }
//        }
//    }
//}
//
//class LogStream: TextOutputStream {
//    private var logViewModel: LogViewModel
//
//    init(logViewModel: LogViewModel) {
//        self.logViewModel = logViewModel
//    }
//
//    func write(_ string: String) {
//        logViewModel.addLogMessage(string)
//    }
//}
