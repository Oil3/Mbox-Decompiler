//
//  EmailMessage.swift
//  Mbox extractor
//
// V2

import Foundation

struct EmailMessage {
    var parts: [EmailPart]
    var isMultipart: Bool {
        return parts.count > 1 || parts.first?.contentType.starts(with: "multipart/") ?? false
    }
    
    init(raw: String) {
        self.parts = []
        let lines = raw.components(separatedBy: .newlines)
        var currentContentType = ""
        var currentFilename = ""
        var currentPayload = ""
        var isBase64 = false
        var isAttachmentSection = false
        
        for line in lines {
            if line.starts(with: "--") {
                if isAttachmentSection {
                    // End of the attachment section, create a new part
                    if isBase64, let data = Data(base64Encoded: currentPayload) {
                        let part = EmailPart(contentType: currentContentType, filename: currentFilename, payload: data)
                        self.parts.append(part)
                    }
                    // Reset for the next part
                    currentContentType = ""
                    currentFilename = ""
                    currentPayload = ""
                    isBase64 = false
                }
                isAttachmentSection = true // Start of a new attachment section
            } else if isAttachmentSection {
                if line.starts(with: "Content-Type:") {
                    currentContentType = String(line.dropFirst("Content-Type:".count))
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else if line.lowercased().contains("filename=") {
                    if let filenameIndex = line.range(of: "filename=")?.upperBound {
                        currentFilename = String(line[filenameIndex...])
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                } else if line.starts(with: "Content-Transfer-Encoding: base64") {
                    isBase64 = true // Mark the start of Base64 content
                } else if isBase64 {
                    currentPayload += line // Accumulate the Base64 content
                }
            }
        }
    }
static func saveAttachments(from mboxPath: String, to directory: String) {
    guard let mboxContent = try? String(contentsOfFile: mboxPath) else {
        print("Failed to read mbox file")
        return
    }
    
    let messages = mboxContent.components(separatedBy: "\nFrom ")
    let queue = DispatchQueue(label: "com.example.attachmentExtraction", attributes: .concurrent)
    let group = DispatchGroup()
    
    for message in messages {
        queue.async(group: group) {
            let email = EmailMessage(raw: message)
            if email.isMultipart {
                for part in email.parts {
                    if part.contentType == "application/octet-stream" {
                        let filePath = directory + part.filename
                        
                        // Ensure the directory exists
                        let fileURL = URL(fileURLWithPath: filePath)
                        let fileDirectory = fileURL.deletingLastPathComponent()
                        if !FileManager.default.fileExists(atPath: fileDirectory.path) {
                            do {
                                try FileManager.default.createDirectory(at: fileDirectory, withIntermediateDirectories: true, attributes: nil)
                            } catch {
                                print("Failed to create directory: \(error)")
                            }
                        }
                        
                        // Save the attachment
                        print("Saving \(part.filename)")
                        do {
                            try part.payload.write(to: fileURL)
                        } catch {
                            print("Failed to save attachment: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    group.notify(queue: DispatchQueue.main) {
        print("All attachments have been processed.")
    }
}

func extractEmailAddresses(from mboxPath: String) -> [(name: String?, email: String)] {
    guard let mboxContent = try? String(contentsOfFile: mboxPath) else {
        print("Failed to read mbox file")
        return []
    }

    let messages = mboxContent.components(separatedBy: "\nFrom ")
    var emailAddresses: [(name: String?, email: String)] = []

    for message in messages {
        let lines = message.components(separatedBy: .newlines)
        for line in lines {
            if line.starts(with: "From: ") || line.starts(with: "To: ") || line.starts(with: "Cc: ") || line.starts(with: "Bcc: ") {
                let addresses = extractEmails(from: line)
                emailAddresses.append(contentsOf: addresses)
            }
        }
    }

    return emailAddresses
}

func extractEmails(from line: String) -> [(name: String?, email: String)] {
    let pattern = #"(?:"?([^"]*)"?\s)?(?:<?(.+?@[^>]+)>?)"#
    let regex = try! NSRegularExpression(pattern: pattern, options: [])
    let matches = regex.matches(in: line, options: [], range: NSRange(line.startIndex..., in: line))
    var results: [(name: String?, email: String)] = []

    for match in matches {
        let nameRange = match.range(at: 1)
        let emailRange = match.range(at: 2)
        let name = nameRange.location != NSNotFound ? String(line[Range(nameRange, in: line)!]) : nil
        let email = String(line[Range(emailRange, in: line)!])
        results.append((name: name, email: email))
    }

    return results
}

//// Usage
//let emailAddresses = extractEmailAddresses(from: mboxPath)
//for (name, email) in emailAddresses {
//    print("Name: \(name ?? "N/A"), Email: \(email)")
}

struct EmailPart {
    var contentType: String
    var filename: String
    var payload: Data
}
