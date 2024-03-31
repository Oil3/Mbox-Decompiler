//
//  EmailMessage.swift
//  Mbox extractor
import Foundation

struct EmailMessage {
    var headers: [String: String]
    var body: String
}

func parseEmailMessage(_ message: String) -> EmailMessage {
    var headers = [String: String]()
    var body = ""

    let lines = message.components(separatedBy: .newlines)
    var isHeader = true

    for line in lines {
        if isHeader {
            if line.isEmpty {
                isHeader = false
                continue
            }

            let headerParts = line.components(separatedBy: ": ")
            if headerParts.count == 2 {
                headers[headerParts[0]] = headerParts[1]
            }
        } else {
            body += line + "\n"
        }
    }

    return EmailMessage(headers: headers, body: body)
}

