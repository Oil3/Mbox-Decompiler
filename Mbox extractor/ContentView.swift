    //
    //  ContentView.swift
    //  Mbox extractor
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var mboxPath: URL?
    @State private var outputDirectory: URL?
    @State private var extractionResult: String = ""
    @State private var showMboxPicker = false
    @State private var showOutputPicker = false
    @State private var isExtracting = false
    
    var body: some View {
        VStack(spacing: 20) {
            Button("Select mbox file") {
                showMboxPicker = true
            }
            .fileImporter(
                isPresented: $showMboxPicker,
                allowedContentTypes: [.data, .directory],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        let accessGranted = url.startAccessingSecurityScopedResource()  // sandbox related
                        if accessGranted {
                            mboxPath = url
                        } else {
                            print("Access to the file was not granted.")
                        }
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }            
            Text(mboxPath?.path ?? "No file selected")
            
            Button("Select output directory") {
                showOutputPicker = true
            }
            .fileImporter(
                isPresented: $showOutputPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    outputDirectory = urls.first
                case .failure(let error):
                    print("Error selecting directory: \(error.localizedDescription)")
                }
            }
            Text(outputDirectory?.path ?? "No directory selected")
            
            Button("Extract Attachments") {
                if let mboxPath = mboxPath, let outputDirectory = outputDirectory {
                    isExtracting = true
                    extractAttachmentsFromMbox(from: mboxPath.path, outputDirectory: outputDirectory.path) { result in
                        extractionResult = result
                        isExtracting = false
                    }
                } else {
                    extractionResult = "Please select an mbox file and an output directory."
                }
            }
            if isExtracting {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
            Text(extractionResult)
                .padding()
        }
    }
    func parseMboxFile(_ mboxPath: String) -> [EmailMessage] {
        do {
            let mboxContent = try String(contentsOfFile: mboxPath)
            let rawMessages = mboxContent.components(separatedBy: "\nFrom ")
            var messages = [EmailMessage]()
            
            for rawMessage in rawMessages.dropFirst() { // Skip the first element as it will be empty due to the split
                let message = parseEmailMessage(rawMessage)
                messages.append(message)
            }
            
            return messages
        } catch {
            print("Error reading mbox file: \(error)")
            return []
        }
    }
    func extractAttachmentsFromMbox(from mboxPath: String, outputDirectory: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                print("Parsing mbox file...")
                let messages = parseMboxFile(mboxPath)
                print("Found \(messages.count) messages.")
                
                let extractionQueue = DispatchQueue(label: "com.example.attachmentExtraction", attributes: .concurrent) //multithreading
                let group = DispatchGroup()

                for (index, message) in messages.enumerated() {
                    group.enter()
                    extractionQueue.async {
                       // print("Extracting attachments from message \(index + 1)...")
                        let attachments = extractAttachments(from: message)
                        print("Extracting \(attachments.count) attachments in message \(index + 1).")
                                                usleep(10000) // 0.01secs

                        saveAttachments(attachments, to: outputDirectory)
                        group.leave()//leaving multithereading
                    
                }
                    group.wait()  // Wait for all tasks to complete
            }
                DispatchQueue.main.async {
                    completion("Extraction complete. Check the output directory for attachments.")
                }
            }
        }
    }}

struct EmailAttachment {
    var filename: String
    var data: Data
}

func decodeBase64(_ base64String: String) -> Data? {
    return Data(base64Encoded: base64String)
}

func extractAttachments(from message: EmailMessage) -> [EmailAttachment] {
    var attachments = [EmailAttachment]()
    
    let lines = message.body.components(separatedBy: .newlines)
    var attachmentFound = false
    var attachmentData = ""
    var filename = ""
    var attachmentCounter = 1
    
    for line in lines {
        if attachmentFound {
            if line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                continue
            } else if line.starts(with: "--") {
                if let data = decodeBase64(attachmentData) {
                        // Generates a dynamic name when no filename retrieved
                    if filename.isEmpty {
                        let timestamp = Int(Date().timeIntervalSince1970)
                        filename = "UnnamedAttachment_\(timestamp)_\(attachmentCounter)"
                        attachmentCounter += 1
                    }
                    let attachment = EmailAttachment(filename: filename, data: data)
                    attachments.append(attachment)
                }
                attachmentFound = false
                attachmentData = ""
                filename = ""
            } else {
                attachmentData += line
            }
        } else if line.starts(with: "X-Attachment-Id:") {
            attachmentFound = true
            if let contentDispositionIndex = lines.firstIndex(where: { $0.contains("Content-Disposition:") }),
               let filenameIndex = lines[contentDispositionIndex].range(of: "filename=")?.upperBound {
                filename = lines[contentDispositionIndex][filenameIndex...]
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            }
        }
    }
    
    return attachments
}

func saveAttachments(_ attachments: [EmailAttachment], to directory: String) {
        // Create the output directory if it doesn't exist
    let directoryURL = URL(fileURLWithPath: directory)
    if !FileManager.default.fileExists(atPath: directory) {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error creating directory: \(error)")
            return
        }
    }
    
    for attachment in attachments {
        let filePath = directoryURL.appendingPathComponent(attachment.filename).path
        do {
            try attachment.data.write(to: URL(fileURLWithPath: filePath))
            print("Saved attachment: \(attachment.filename)")
        } catch {
            print("Error saving attachment \(attachment.filename): \(error)")
        }
    }
}

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
