//
//  EmailAttachment.swift
//  Mbox extractor
import Foundation

struct EmailAttachment {
    var filename: String
    var data: Data
}

func decodeBase64(_ base64String: String) -> Data? {
    return Data(base64Encoded: base64String)
}

func extractAttachments(from message: EmailMessage) -> [EmailAttachment] {
    var attachments = [EmailAttachment]()
    
    let boundary = message.headers["Content-Type"]?.components(separatedBy: "boundary=").last?.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if let boundary = boundary {
        let parts = message.body.components(separatedBy: "--\(boundary)")
        
        for part in parts {
            let lines = part.components(separatedBy: .newlines)
            var headers = [String: String]()
            var isHeader = true
            var body = ""
            
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
            
            if let contentDisposition = headers["Content-Disposition"], contentDisposition.contains("attachment") {
                if let filename = contentDisposition.components(separatedBy: "filename=").last?.trimmingCharacters(in: .whitespacesAndNewlines) {
                    if let data = decodeBase64(body) {
                        let attachment = EmailAttachment(filename: filename, data: data)
                        attachments.append(attachment)
                    }
                }
            }
        }
    }
    
    return attachments
}

func saveAttachments(_ attachments: [EmailAttachment], to directory: String) {
    for attachment in attachments {
        let filePath = directory + "/" + attachment.filename
        do {
            try attachment.data.write(to: URL(fileURLWithPath: filePath))
        } catch {
            print("Error saving attachment \(attachment.filename): \(error)")
        }
    }
}
