import Foundation

class TimestampedNotesGenerator {
    
    static func generateNotesWithTimestamps(from transcription: String, timestamps: [NotesTimestamp]) async -> (String, [NotesTimestamp]) {
        print("TimestampedNotesGenerator: Generating AI-powered notes with timestamps from \(transcription.count) characters")
        
        // Handle empty or very short text
        let trimmedText = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return ("No content available to generate notes from.", [])
        }
        
        if trimmedText.count < 50 {
            return ("Content too short to generate meaningful notes. Please ensure your recording contains clear speech.", [])
        }
        
        let aiService = AIService()
        
        do {
            let rawNotes = try await aiService.generateStructuredNotes(from: trimmedText)
            print("TimestampedNotesGenerator: Generated notes successfully - \(rawNotes.count) characters")
            
            let (cleanNotes, parsedSections) = extractSectionsAndCleanNotes(from: rawNotes)
            if !parsedSections.isEmpty {
                print("TimestampedNotesGenerator: Detected \(parsedSections.count) structured sections from AI output")
            } else {
                print("TimestampedNotesGenerator: No explicit section markers detected, falling back to inferred boundaries")
            }
            
            // Create timestamps based on structured sections (or fallback to inferred segments)
            let sectionTimestamps = createContentBasedTimestamps(
                from: cleanNotes,
                transcriptionTimestamps: timestamps,
                parsedSections: parsedSections
            )
            
            return (cleanNotes, sectionTimestamps)
        } catch {
            print("TimestampedNotesGenerator: AI generation failed, falling back to basic processing")
            return generateBasicNotesWithTimestamps(from: trimmedText, timestamps: timestamps)
        }
    }
    
    private static func createSimpleTimestamps(from transcriptionTimestamps: [NotesTimestamp], notesLength: Int) -> [NotesTimestamp] {
        guard !transcriptionTimestamps.isEmpty else {
            // If no timestamps available, create a single timestamp at 0:00
            return [NotesTimestamp(
                sectionTitle: "Lecture Notes",
                timestamp: 0.0,
                startIndex: 0,
                endIndex: notesLength
            )]
        }
        
        // Use the first few timestamps from the transcription to create sections
        let maxSections = min(4, transcriptionTimestamps.count) // Reduced to 4 for better content distribution
        let selectedTimestamps = Array(transcriptionTimestamps.prefix(maxSections))
        
        var sectionTimestamps: [NotesTimestamp] = []
        let sectionSize = notesLength / maxSections
        
        for (index, timestamp) in selectedTimestamps.enumerated() {
            let startIndex = index * sectionSize
            let endIndex = (index == maxSections - 1) ? notesLength : (index + 1) * sectionSize
            
            // Create more descriptive section titles based on typical lecture structure
            let sectionTitle: String
            switch index {
            case 0:
                sectionTitle = "Key Points"
            case 1:
                sectionTitle = "Important Definitions"
            case 2:
                sectionTitle = "Examples"
            case 3:
                sectionTitle = "Summary"
            default:
                sectionTitle = "Section \(index + 1)"
            }
            
            let sectionTimestamp = NotesTimestamp(
                sectionTitle: sectionTitle,
                timestamp: timestamp.timestamp,
                startIndex: startIndex,
                endIndex: endIndex
            )
            sectionTimestamps.append(sectionTimestamp)
        }
        
        return sectionTimestamps
    }
    
    // MARK: - Content Structure Analysis
    
    private static func createContentBasedTimestamps(from notes: String, transcriptionTimestamps: [NotesTimestamp], parsedSections: [ParsedSection] = []) -> [NotesTimestamp] {
        print("TimestampedNotesGenerator: Creating content-based timestamps")
        
        if !parsedSections.isEmpty {
            return createTimestampsFromParsedSections(parsedSections, transcriptionTimestamps: transcriptionTimestamps)
        }
        
        if transcriptionTimestamps.isEmpty {
            print("TimestampedNotesGenerator: No incoming timestamps, generating simple fallback")
            return createSimpleTimestamps(from: transcriptionTimestamps, notesLength: notes.count)
        }
        
        // Since AI no longer generates headers, we'll create sections based on content length
        // and assign appropriate section titles
        let totalLength = notes.count
        let numberOfSections = max(1, min(4, transcriptionTimestamps.count))
        let sectionSize = totalLength / numberOfSections
        
        var sectionTimestamps: [NotesTimestamp] = []
        let sectionTitles = ["Key Points", "Important Definitions", "Examples", "Summary"]
        
        for index in 0..<numberOfSections {
            let startIndex = index * sectionSize
            let endIndex = (index == numberOfSections - 1) ? totalLength : (index + 1) * sectionSize
            
            let sectionTitle = sectionTitles[index % sectionTitles.count]
            let timestampIndex = index % transcriptionTimestamps.count
            let timestamp = transcriptionTimestamps[timestampIndex].timestamp
            
            let sectionTimestamp = NotesTimestamp(
                sectionTitle: sectionTitle,
                timestamp: timestamp,
                startIndex: startIndex,
                endIndex: endIndex
            )
            sectionTimestamps.append(sectionTimestamp)
        }
        
        print("TimestampedNotesGenerator: Created \(sectionTimestamps.count) content-based timestamps")
        for (index, timestamp) in sectionTimestamps.enumerated() {
            print("TimestampedNotesGenerator: Section \(index): '\(timestamp.sectionTitle)' at \(timestamp.timestamp)s (chars \(timestamp.startIndex)-\(timestamp.endIndex))")
        }
        return sectionTimestamps
    }
    
    // MARK: - Section Parsing Helpers
    
    private struct ParsedSection {
        let title: String
        let startIndex: Int
        let endIndex: Int
    }
    
    private static func extractSectionsAndCleanNotes(from rawNotes: String) -> (cleanNotes: String, sections: [ParsedSection]) {
        let pattern = #"\[\[SECTION:(.+?)\]\]"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return (rawNotes, [])
        }
        
        let matches = regex.matches(in: rawNotes, range: NSRange(rawNotes.startIndex..., in: rawNotes))
        guard !matches.isEmpty else {
            return (rawNotes, [])
        }
        
        var cleanNotes = ""
        var parsedSections: [ParsedSection] = []
        
        for (index, match) in matches.enumerated() {
            guard let titleRange = Range(match.range(at: 1), in: rawNotes),
                  let markerRange = Range(match.range, in: rawNotes) else { continue }
            
            let title = rawNotes[titleRange].trimmingCharacters(in: .whitespacesAndNewlines)
            let contentStart = markerRange.upperBound
            let contentEnd = index + 1 < matches.count ?
                Range(matches[index + 1].range, in: rawNotes)!.lowerBound :
                rawNotes.endIndex
            
            let sectionContent = rawNotes[contentStart..<contentEnd].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !sectionContent.isEmpty else { continue }
            
            if !cleanNotes.isEmpty {
                cleanNotes += "\n\n"
            }
            
            let startIndex = cleanNotes.count
            cleanNotes += sectionContent
            let endIndex = cleanNotes.count
            
            parsedSections.append(ParsedSection(title: title, startIndex: startIndex, endIndex: endIndex))
        }
        
        return (cleanNotes, parsedSections)
    }
    
    private static func createTimestampsFromParsedSections(_ sections: [ParsedSection], transcriptionTimestamps: [NotesTimestamp]) -> [NotesTimestamp] {
        var sectionTimestamps: [NotesTimestamp] = []
        
        for (index, section) in sections.enumerated() {
            let matchedTimestamp = matchTimestamp(for: section.title, in: transcriptionTimestamps) ??
                (index < transcriptionTimestamps.count ? transcriptionTimestamps[index] : transcriptionTimestamps.last)
            
            let timestampValue: TimeInterval
            if let matchedTimestamp {
                timestampValue = matchedTimestamp.timestamp
            } else if let last = transcriptionTimestamps.last {
                timestampValue = last.timestamp + Double((index - transcriptionTimestamps.count + 1) * 30)
            } else {
                timestampValue = Double(index * 60)
            }
            
            let sectionTimestamp = NotesTimestamp(
                sectionTitle: section.title,
                timestamp: timestampValue,
                startIndex: section.startIndex,
                endIndex: section.endIndex
            )
            sectionTimestamps.append(sectionTimestamp)
        }
        
        return sectionTimestamps
    }
    
    private static func matchTimestamp(for sectionTitle: String, in transcriptionTimestamps: [NotesTimestamp]) -> NotesTimestamp? {
        let lowercasedTitle = sectionTitle.lowercased()
        
        if let exactMatch = transcriptionTimestamps.first(where: { $0.sectionTitle.lowercased() == lowercasedTitle }) {
            return exactMatch
        }
        
        return transcriptionTimestamps.first(where: {
            lowercasedTitle.contains($0.sectionTitle.lowercased()) ||
            $0.sectionTitle.lowercased().contains(lowercasedTitle)
        })
    }
    
    private static func generateBasicNotesWithTimestamps(from text: String, timestamps: [NotesTimestamp]) -> (String, [NotesTimestamp]) {
        print("TimestampedNotesGenerator: Generating basic notes with timestamps as fallback")
        
        let sentences = text.components(separatedBy: [".", "!", "?"])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        if sentences.isEmpty {
            return ("Unable to extract meaningful content from the recording. Please try recording again with clearer speech.", [])
        }
        
        var notes = "LECTURE NOTES\n"
        notes += String(repeating: "=", count: 50) + "\n\n"
        
        // Create sections based on available timestamps
        var sectionTimestamps: [NotesTimestamp] = []
        var currentPosition = 0
        
        // Group timestamps into logical sections
        let groupedTimestamps = groupTimestampsIntoSections(timestamps: timestamps)
        
        for (sectionIndex, group) in groupedTimestamps.enumerated() {
            let sectionTitle = "Section \(sectionIndex + 1)"
            let sectionStart = currentPosition
            
            notes += "\(sectionTitle)\n"
            notes += String(repeating: "-", count: sectionTitle.count) + "\n\n"
            
            // Add content for this section
            let sentencesForSection = sentences.dropFirst(sectionIndex * 3).prefix(3)
            for sentence in sentencesForSection {
                notes += "• \(sentence.capitalized)\n"
            }
            notes += "\n"
            
            let sectionEnd = notes.count
            
            // Create timestamp for this section using the first timestamp in the group
            if let firstTimestamp = group.first {
                let sectionTimestamp = NotesTimestamp(
                    sectionTitle: sectionTitle,
                    timestamp: firstTimestamp.timestamp,
                    startIndex: sectionStart,
                    endIndex: sectionEnd
                )
                sectionTimestamps.append(sectionTimestamp)
            }
            
            currentPosition = sectionEnd
        }
        
        // Add important terms section
        let words = text.components(separatedBy: " ")
        let keyWords = words.filter { word in
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return cleanWord.count > 4 && !commonWords.contains(cleanWord)
        }
        
        let uniqueWords = Array(Set(keyWords)).prefix(15)
        if !uniqueWords.isEmpty {
            notes += "Important Terms:\n"
            for word in uniqueWords {
                notes += "• \(word.capitalized)\n"
            }
        }
        
        print("TimestampedNotesGenerator: Generated basic notes with \(notes.count) characters and \(sectionTimestamps.count) sections")
        return (notes, sectionTimestamps)
    }
    
    private static func groupTimestampsIntoSections(timestamps: [NotesTimestamp]) -> [[NotesTimestamp]] {
        guard !timestamps.isEmpty else { return [] }
        
        var groups: [[NotesTimestamp]] = []
        var currentGroup: [NotesTimestamp] = []
        let timeThreshold: TimeInterval = 30.0 // Group timestamps within 30 seconds
        
        for timestamp in timestamps {
            if let lastTimestamp = currentGroup.last {
                if timestamp.timestamp - lastTimestamp.timestamp <= timeThreshold {
                    // Add to current group
                    currentGroup.append(timestamp)
                } else {
                    // Start new group
                    if !currentGroup.isEmpty {
                        groups.append(currentGroup)
                    }
                    currentGroup = [timestamp]
                }
            } else {
                // First timestamp
                currentGroup = [timestamp]
            }
        }
        
        // Add the last group
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        
        return groups
    }
    
    // Common words to filter out when extracting key terms
    private static let commonWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs", "what", "when", "where", "why", "how", "who", "which", "whom", "whose", "if", "then", "else", "because", "since", "while", "although", "though", "unless", "until", "whether", "while", "as", "so", "than", "like", "just", "very", "really", "quite", "rather", "too", "also", "only", "even", "still", "again", "ever", "never", "always", "often", "sometimes", "usually", "rarely", "seldom", "now", "then", "here", "there", "where", "everywhere", "anywhere", "nowhere", "somewhere", "up", "down", "in", "out", "on", "off", "over", "under", "above", "below", "between", "among", "through", "during", "before", "after", "since", "until", "from", "to", "toward", "towards", "into", "onto", "upon", "within", "without", "against", "despite", "except", "including", "concerning", "regarding", "about", "across", "around", "behind", "beneath", "beside", "beyond", "inside", "outside", "throughout", "underneath", "along", "amid", "amongst", "besides", "beyond", "despite", "except", "excluding", "following", "including", "like", "minus", "near", "off", "onto", "opposite", "outside", "over", "past", "per", "plus", "round", "save", "than", "toward", "towards", "under", "unlike", "versus", "via", "within", "without"
    ]
} 