//
//  MboxParser.swift
//  Mbox extractor
//
//  Created by ZZS on 30/03/2024.
//

import Foundation

func parseMboxFile(_ mboxPath: String) -> [EmailMessage] {
    do {
        let mboxContent = try String(contentsOfFile: mboxPath)
        let rawMessages = mboxContent.components(separatedBy: "\nFrom ")
        var messages = [EmailMessage]()

        for rawMessage in rawMessages {
            let message = parseEmailMessage(rawMessage)
            messages.append(message)
        }

        return messages
    } catch {
        print("Error reading mbox file: \(error)")
        return []
    }
}
