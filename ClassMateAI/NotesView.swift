import SwiftUI
import UIKit

struct NotesView: View {
    let lecture: Lecture
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var notesText: String
    @State private var notesAttributedData: Data?
    @State private var showingDeleteAlert = false
    @State private var showingSaveSuccess = false
    @State private var selectedRange: NSRange = NSRange()
    @State private var showingColorPicker = false
    @State private var showingBackgroundColorPicker = false
    @State private var showingFontSizePicker = false
    @State private var selectedTextColor: UIColor = .black
    @State private var selectedBackgroundColor: UIColor = .yellow
    @State private var selectedFontSize: CGFloat = 16.0
    @State private var audioPlayer = AudioPlayer()
    @State private var formatCommand: RichTextFormatCommand = .none
    @State private var timelineSections: [TimelineSectionContent]
    @State private var activeSectionID: UUID?
    
    private var currentLecture: Lecture? {
        dataManager.subjects.flatMap { $0.lectures }.first { $0.id == lecture.id }
    }
    
    private var hasTimelineSections: Bool {
        !timelineSections.isEmpty
    }
    
    init(lecture: Lecture) {
        self.lecture = lecture
        self._notesText = State(initialValue: lecture.notes)
        self._notesAttributedData = State(initialValue: lecture.notesAttributedData)
        let sections = NotesView.buildTimelineSections(from: lecture)
        self._timelineSections = State(initialValue: sections)
        self._activeSectionID = State(initialValue: sections.first?.id)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                formattingToolbar
                
                if hasTimelineSections {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(timelineSections.indices, id: \.self) { index in
                                timelineSectionCard(for: $timelineSections[index])
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                } else {
                    baseEditor
                }
            }
            .navigationTitle("Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveNotes() }
                        .fontWeight(.semibold)
                }
            }
            .alert("Delete Notes", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) { deleteNotes() }
            } message: {
                Text("Are you sure you want to delete these notes? This action cannot be undone.")
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedTextColor, title: "Text Color") {
                    triggerFormat(.textColor(selectedTextColor))
                }
            }
            .sheet(isPresented: $showingBackgroundColorPicker) {
                ColorPickerView(selectedColor: $selectedBackgroundColor, title: "Background Color") {
                    triggerFormat(.backgroundColor(selectedBackgroundColor))
                }
            }
            .sheet(isPresented: $showingFontSizePicker) {
                FontSizePickerView(selectedSize: $selectedFontSize) {
                    triggerFormat(.fontSize(selectedFontSize))
                }
            }
            .overlay(saveOverlay)
            .onAppear {
                if let current = currentLecture {
                    notesText = current.notes
                    notesAttributedData = current.notesAttributedData
                    let sections = NotesView.buildTimelineSections(from: current)
                    timelineSections = sections
                    activeSectionID = sections.first?.id
                }
            }
        }
    }
    
    private var baseEditor: some View {
        RichTextEditor(
            text: $notesText,
            selection: $selectedRange,
            formatCommand: formatCommand,
            onFormatCommandHandled: { formatCommand = .none },
            onAttributedTextChanged: { attributedData in
                notesAttributedData = attributedData
            },
            attributedData: notesAttributedData
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20) // Add padding here since we removed it from UITextView
    }
    
    private var formattingToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                Button { triggerFormat(.bold) } label: { Image(systemName: "bold") }
                Button { triggerFormat(.italic) } label: { Image(systemName: "italic") }
                Button { triggerFormat(.underline) } label: { Image(systemName: "underline") }
                Button { triggerFormat(.strikethrough) } label: { Image(systemName: "strikethrough") }
                
                Divider().frame(height: 20)
                
                Button { showingColorPicker = true } label: { Image(systemName: "paintbrush.fill") }
                Button { showingBackgroundColorPicker = true } label: { Image(systemName: "highlighter") }
                Button { showingFontSizePicker = true } label: { Image(systemName: "textformat.size") }
                
                Divider().frame(height: 20)
                
                Button(action: copyText) { Image(systemName: "doc.on.doc") }
                Button(action: pasteText) { Image(systemName: "doc.on.clipboard") }
                Button { showingDeleteAlert = true } label: { Image(systemName: "trash").foregroundColor(.red) }
            }
            .foregroundColor(.matePrimary)
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
        .background(Color.mateSecondary.opacity(0.1))
    }
    
    private func timelineSectionCard(for section: Binding<TimelineSectionContent>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header with timestamp link
            HStack {
                Text(section.wrappedValue.timestamp.sectionTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.mateText)
                
                Spacer()
                
                Button {
                    jumpToTimestamp(section.wrappedValue.timestamp)
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                        Text(formatTimestamp(section.wrappedValue.timestamp.timestamp))
                            .font(.caption)
                    }
                    .foregroundColor(.matePrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            
            // Editable text area - expands to fit content, no scrolling
            RichTextEditor(
                text: section.text,
                selection: section.selection,
                formatCommand: section.formatCommand.wrappedValue,
                onFormatCommandHandled: { section.formatCommand.wrappedValue = .none },
                onAttributedTextChanged: { data in
                    section.attributedData.wrappedValue = data
                },
                attributedData: section.attributedData.wrappedValue,
                onSelectionChange: { range in
                    section.selection.wrappedValue = range
                    activeSectionID = section.wrappedValue.id
                },
                isScrollEnabled: false
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func saveNotes() {
        if hasTimelineSections {
            let (combined, timestamps) = NotesView.combineTextAndTimestamps(from: timelineSections)
            notesText = combined
            notesAttributedData = NotesView.combineAttributedData(from: timelineSections)
            dataManager.updateNotesWithTimestamps(for: lecture, notes: combined, timestamps: timestamps)
        } else {
            dataManager.updateNotesWithAttributedData(for: lecture, notes: notesText, attributedData: notesAttributedData)
        }
        showingSaveSuccess = true
    }
    
    private func deleteNotes() {
        dataManager.deleteNotes(for: lecture)
        notesText = ""
        notesAttributedData = nil
        timelineSections.removeAll()
        dismiss()
    }
    
    private func copyText() {
        if hasTimelineSections {
            guard let id = activeSectionID,
                  let index = timelineSections.firstIndex(where: { $0.id == id }),
                  timelineSections[index].selection.length > 0 else { return }
            let nsString = timelineSections[index].text as NSString
            UIPasteboard.general.string = nsString.substring(with: timelineSections[index].selection)
        } else {
            guard selectedRange.length > 0 else { return }
            let nsString = notesText as NSString
            UIPasteboard.general.string = nsString.substring(with: selectedRange)
        }
    }
    
    private func pasteText() {
        guard let pastedText = UIPasteboard.general.string else { return }
        if hasTimelineSections {
            guard let id = activeSectionID,
                  let index = timelineSections.firstIndex(where: { $0.id == id }) else { return }
            var section = timelineSections[index]
            let nsString = section.text as NSString
            section.text = nsString.replacingCharacters(in: section.selection, with: pastedText)
            section.selection = NSRange(location: section.selection.location, length: pastedText.count)
            timelineSections[index] = section
        } else {
            let nsString = notesText as NSString
            notesText = nsString.replacingCharacters(in: selectedRange, with: pastedText)
            selectedRange = NSRange(location: selectedRange.location, length: pastedText.count)
        }
    }
    
    private func jumpToTimestamp(_ timestamp: NotesTimestamp) {
        guard let recordingURL = currentLecture?.recordingURL else { return }
        audioPlayer.play(url: recordingURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            audioPlayer.seek(to: timestamp.timestamp)
        }
    }
    
    private func triggerFormat(_ command: RichTextFormatCommand) {
        if hasTimelineSections {
            guard let id = activeSectionID,
                  let index = timelineSections.firstIndex(where: { $0.id == id }) else { return }
            timelineSections[index].formatCommand = command
        } else {
            formatCommand = command
        }
    }
    
    private var saveOverlay: some View {
        Group {
            if showingSaveSuccess {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Text("Notes saved successfully!")
                        .font(.headline)
                        .foregroundColor(.mateText)
                }
                .padding()
                .background(Color.mateCardBackground)
                .cornerRadius(12)
                .shadow(radius: 5)
                .transition(.scale.combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSaveSuccess = false
                        }
                    }
                }
            }
        }
    }
    
    private func formatTimestamp(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private static func buildTimelineSections(from lecture: Lecture) -> [TimelineSectionContent] {
        guard let timestamps = lecture.notesTimestamps, !timestamps.isEmpty else { return [] }
        return timestamps.map { timestamp in
            let content = extractSectionContent(from: lecture.notes, timestamp: timestamp)
            return TimelineSectionContent(timestamp: timestamp, text: content)
        }
    }
    
    static func extractSectionContent(from notes: String, timestamp: NotesTimestamp) -> String {
        let startIndex = timestamp.startIndex
        let endIndex = min(timestamp.endIndex, notes.count)
        guard startIndex < notes.count && endIndex > startIndex else { return "" }
        
        let start = notes.index(notes.startIndex, offsetBy: startIndex)
        let end = notes.index(notes.startIndex, offsetBy: endIndex)
        var content = String(notes[start..<end])
        
        let headers = ["KEY POINTS", "IMPORTANT DEFINITIONS", "EXAMPLES", "SUMMARY"]
        for header in headers {
            if content.uppercased().hasPrefix(header) {
                let lines = content.components(separatedBy: .newlines)
                content = lines.dropFirst().joined(separator: "\n")
                break
            }
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func combineTextAndTimestamps(from sections: [TimelineSectionContent]) -> (String, [NotesTimestamp]) {
        var combined = ""
        var newTimestamps: [NotesTimestamp] = []
        var currentIndex = 0
        
        for section in sections {
            let header = section.timestamp.sectionTitle.uppercased()
            let body = section.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let sectionString = "\(header)\n\(body)\n\n"
            let startIndex = currentIndex
            currentIndex += sectionString.count
            let timestamp = NotesTimestamp(
                sectionTitle: section.timestamp.sectionTitle,
                timestamp: section.timestamp.timestamp,
                startIndex: startIndex,
                endIndex: currentIndex
            )
            newTimestamps.append(timestamp)
            combined.append(sectionString)
        }
        
        return (combined, newTimestamps)
    }
    
    private static func combineAttributedData(from sections: [TimelineSectionContent]) -> Data? {
        let combined = NSMutableAttributedString()
        let headerFont = UIFont.boldSystemFont(ofSize: UIFont.preferredFont(forTextStyle: .headline).pointSize)
        
        for section in sections {
            let header = NSAttributedString(
                string: section.timestamp.sectionTitle.uppercased() + "\n",
                attributes: [.font: headerFont]
            )
            combined.append(header)
            
            if let data = section.attributedData,
               let attributed = try? NSAttributedString(
                    data: data,
                    options: [.documentType: NSAttributedString.DocumentType.rtf],
                    documentAttributes: nil
               ) {
                combined.append(attributed)
            } else {
                combined.append(NSAttributedString(string: section.text))
            }
            combined.append(NSAttributedString(string: "\n\n"))
        }
        
        return try? combined.data(
            from: NSRange(location: 0, length: combined.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}

struct TimelineSectionContent: Identifiable, Equatable {
    let id: UUID = UUID()
    var timestamp: NotesTimestamp
    var text: String
    var attributedData: Data? = nil
    var selection: NSRange = NSRange(location: 0, length: 0)
    var formatCommand: RichTextFormatCommand = .none

    static func == (lhs: TimelineSectionContent, rhs: TimelineSectionContent) -> Bool {
        lhs.id == rhs.id
            && lhs.text == rhs.text
            && lhs.attributedData == rhs.attributedData
            && lhs.selection == rhs.selection
            && lhs.formatCommand == rhs.formatCommand
    }
}

struct ColorPickerView: View {
    @Binding var selectedColor: UIColor
    let title: String
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private let colors: [UIColor] = [
        .black, .red, .orange, .yellow, .green, .blue, .purple, .brown,
        .systemPink, .systemTeal, .systemIndigo, .systemGray
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text(title)
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 15) {
                    ForEach(colors, id: \.self) { color in
                        Button(action: {
                            selectedColor = color
                        }) {
                            Circle()
                                .fill(Color(color))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 3)
                                )
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct FontSizePickerView: View {
    @Binding var selectedSize: CGFloat
    let onApply: () -> Void
    @Environment(\.dismiss) var dismiss
    
    private let fontSizes: [CGFloat] = [12, 14, 16, 18, 20, 24, 28, 32, 36, 48]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Font Size")
                    .font(.headline)
                    .padding(.top)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                    ForEach(fontSizes, id: \.self) { size in
                        Button(action: {
                            selectedSize = size
                        }) {
                            Text("\(Int(size))")
                                .font(.system(size: size))
                                .foregroundColor(.mateText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(selectedSize == size ? Color.matePrimary.opacity(0.2) : Color.mateSecondary.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

