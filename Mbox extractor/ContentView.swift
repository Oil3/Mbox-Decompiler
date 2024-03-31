//
//  ContentView.swift
//  Mbox extractor
import SwiftUI

struct ContentView: View {
    @State private var mboxPath: String = ""
    @State private var outputDirectory: String = ""
    @State private var extractionResult: String = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Path to mbox file", text: $mboxPath)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Output directory", text: $outputDirectory)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Extract Attachments") {
                extractAttachmentsFromMbox(from: mboxPath, outputDirectory: outputDirectory) { result in
                    extractionResult = result
                }
            }

            Text(extractionResult)
                .padding()
        }
    }

    func extractAttachmentsFromMbox(from mboxPath: String, outputDirectory: String, completion: @escaping (String) -> Void) {
        DispatchQueue.global(qos: .background).async {
            do {
                let messages = parseMboxFile(mboxPath)
                for message in messages {
                    let attachments = extractAttachments(from: message)
                    saveAttachments(attachments, to: outputDirectory)
                }
                DispatchQueue.main.async {
                    completion("Extraction complete. Check the output directory for attachments.")
                }
            } catch {
                DispatchQueue.main.async {
                    completion("Error: \(error.localizedDescription)")
                }
            }
        }
    }
}


