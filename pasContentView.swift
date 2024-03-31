import SwiftUI

struct pasContentView: View {
    @State private var mboxFilePath: String = ""
    @State private var outputDirectory: String = "/Users/zzs/ExtractedFiles"
    @State private var isExtracting: Bool = false
    @State private var extractionCompleted: Bool = false
    @State private var extractedFilesCount: Int = 0

    var body: some View {
        VStack {
            Text("Select .mbox File and Extract Base64 Sections")
                .font(.headline)

            HStack {
                TextField("Selected .mbox File", text: $mboxFilePath)
                    .disabled(true)

                Button("Select File") {
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = true
                    openPanel.canChooseDirectories = false
                    openPanel.allowsMultipleSelection = false
                    openPanel.allowedFileTypes = ["mbox"]
                    if openPanel.runModal() == .OK {
                        if let selectedFile = openPanel.url?.path {
                            mboxFilePath = selectedFile
                        }
                    }
                }
            }

        Button("Extract XLSX Attachments") {
            isExtracting = true
            extractionCompleted = false
            extractedFilesCount = 0

            DispatchQueue.global(qos: .userInitiated).async {
                let count = extractXLSXAttachmentsBasedOnXAttachmentId(fromMboxFile: mboxFilePath)
                DispatchQueue.main.async {
                    extractedFilesCount = count
                    isExtracting = false
                    extractionCompleted = true
                }
            }
        }
        .disabled(mboxFilePath.isEmpty || isExtracting)

        if extractionCompleted {
            Text("Extraction Completed: \(extractedFilesCount) XLSX files extracted.")
        }
        }
        .padding()
    }

 }
