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

    // Check if the message is multipart
    if let contentType = headers["Content-Type"], contentType.contains("multipart") {
        // Extract the boundary from the Content-Type header
        if let boundaryIndex = contentType.range(of: "boundary=")?.upperBound {
            let boundary = "--" + contentType[boundaryIndex...].trimmingCharacters(in: .whitespacesAndNewlines)

            // Split the body into parts using the boundary
            let parts = body.components(separatedBy: boundary)

            // Combine the parts back into a single body string, separating them with newlines
            body = parts.joined(separator: "\n")
        }
    }

    return EmailMessage(headers: headers, body: body)
}


