import SwiftUI
import UIKit

struct OutlineView: View {
    let lecture: Lecture
    @EnvironmentObject var dataManager: DataManager
    @Environment(\.dismiss) var dismiss
    
    @State private var outlineText: String
    @State private var outlineAttributedData: Data?
    @State private var showingDeleteAlert = false
    @State private var showingSaveSuccess = false
    @State private var selectedRange: NSRange = NSRange()
    @State private var formatCommand: RichTextFormatCommand = .none
    @State private var showingColorPicker = false
    @State private var showingBackgroundColorPicker = false
    @State private var showingFontSizePicker = false
    @State private var selectedTextColor: UIColor = .black
    @State private var selectedBackgroundColor: UIColor = .yellow
    @State private var selectedFontSize: CGFloat = 16.0
    
    // Get the current lecture data from DataManager
    private var currentLecture: Lecture? {
        dataManager.subjects.flatMap { $0.lectures }.first { $0.id == lecture.id }
    }
    
    init(lecture: Lecture) {
        self.lecture = lecture
        self._outlineText = State(initialValue: lecture.outline)
        self._outlineAttributedData = State(initialValue: lecture.outlineAttributedData)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Formatting Toolbar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Basic formatting
                        Button(action: { formatCommand = .bold }) {
                            Image(systemName: "bold")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Button(action: { formatCommand = .italic }) {
                            Image(systemName: "italic")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Button(action: { formatCommand = .underline }) {
                            Image(systemName: "underline")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Button(action: { formatCommand = .strikethrough }) {
                            Image(systemName: "strikethrough")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        // Text color
                        Button(action: { showingColorPicker = true }) {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(.matePrimary)
                        }
                        
                        // Background color (highlighting)
                        Button(action: { showingBackgroundColorPicker = true }) {
                            Image(systemName: "highlighter")
                                .foregroundColor(.matePrimary)
                        }
                        
                        // Font size
                        Button(action: { showingFontSizePicker = true }) {
                            Image(systemName: "textformat.size")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Divider()
                            .frame(height: 20)
                        
                        // Copy/Paste
                        Button(action: { copyText() }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.matePrimary)
                        }
                        
                        Button(action: { pasteText() }) {
                            Image(systemName: "doc.on.clipboard")
                                .foregroundColor(.matePrimary)
                        }
                        
                        // Delete
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color.mateSecondary.opacity(0.1))
                
                // Rich Text Editor
                RichTextEditor(
                    text: $outlineText,
                    selection: $selectedRange,
                    formatCommand: formatCommand,
                    onFormatCommandHandled: { formatCommand = .none },
                    onAttributedTextChanged: { attributedData in
                        outlineAttributedData = attributedData
                    },
                    attributedData: outlineAttributedData
                )
                .padding()
            }
            .navigationTitle("Outline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveOutline()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Delete Outline", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteOutline()
                }
            } message: {
                Text("Are you sure you want to delete this outline? This action cannot be undone.")
            }
            .sheet(isPresented: $showingColorPicker) {
                ColorPickerView(selectedColor: $selectedTextColor, title: "Text Color") {
                    formatCommand = .textColor(selectedTextColor)
                }
            }
            .sheet(isPresented: $showingBackgroundColorPicker) {
                ColorPickerView(selectedColor: $selectedBackgroundColor, title: "Background Color") {
                    formatCommand = .backgroundColor(selectedBackgroundColor)
                }
            }
            .sheet(isPresented: $showingFontSizePicker) {
                FontSizePickerView(selectedSize: $selectedFontSize) {
                    formatCommand = .fontSize(selectedFontSize)
                }
            }
            .overlay(
                Group {
                    if showingSaveSuccess {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            Text("Outline saved successfully!")
                                .font(.headline)
                                .foregroundColor(.mateText)
                        }
                        .padding()
                        .background(Color.mateCardBackground)
                        .cornerRadius(12)
                        .shadow(radius: 5)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showingSaveSuccess = false
                                }
                            }
                        }
                    }
                }
            )
            .onAppear {
                // Update text if lecture data has changed
                if let current = currentLecture {
                    outlineText = current.outline
                    outlineAttributedData = current.outlineAttributedData
                }
            }
        }
    }
    
    private func saveOutline() {
        dataManager.updateOutlineWithAttributedData(for: lecture, outline: outlineText, attributedData: outlineAttributedData)
        showingSaveSuccess = true
    }
    
    private func deleteOutline() {
        dataManager.deleteOutline(for: lecture)
        outlineText = ""
        outlineAttributedData = nil
        dismiss()
    }
    
    private func copyText() {
        guard selectedRange.length > 0 else { return }
        let nsString = outlineText as NSString
        let selectedText = nsString.substring(with: selectedRange)
        UIPasteboard.general.string = selectedText
    }
    
    private func pasteText() {
        if let pastedText = UIPasteboard.general.string {
            let nsString = outlineText as NSString
            let newText = nsString.replacingCharacters(in: selectedRange, with: pastedText)
            outlineText = newText
            
            // Update selection range
            let newRange = NSRange(location: selectedRange.location, length: pastedText.count)
            selectedRange = newRange
        }
    }
} 