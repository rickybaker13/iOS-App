import Foundation
import NaturalLanguage

class OutlineGenerator {
    enum OutlineLevel {
        case main
        case sub
        case detail
        
        var prefix: String {
            switch self {
            case .main: return "I"
            case .sub: return "A"
            case .detail: return "1"
            }
        }
    }
    
    struct OutlineItem {
        let level: OutlineLevel
        let text: String
        var number: Int
        let confidence: Double
    }
    
    static func generateOutline(from text: String) async -> String {
        print("OutlineGenerator: Generating AI-powered outline from \(text.count) characters")
        
        // Handle empty or very short text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return "No content available to generate outline from."
        }
        
        if trimmedText.count < 50 {
            return "Content too short to generate meaningful outline. Please ensure your recording contains clear speech."
        }
        
        // Use ChatGPT to generate coherent outline
        let aiService = AIService()
        
        do {
            let outline = try await aiService.generateStructuredOutline(from: trimmedText)
            print("OutlineGenerator: AI-generated outline successfully - \(outline.count) characters")
            return outline
        } catch {
            print("OutlineGenerator: AI generation failed, falling back to pattern matching")
            return generatePatternBasedOutline(from: trimmedText)
        }
    }
    
    private static func generatePatternBasedOutline(from text: String) -> String {
        print("OutlineGenerator: Generating pattern-based outline as fallback")
        
        // Use the existing extractOutlineItems function
        let items = extractOutlineItems(from: text)
        
        if items.isEmpty {
            return "No outline items generated."
        }
        
        // Format the outline using the existing formatOutline function
        return formatOutline(items: items)
    }
    
    private static func extractOutlineItems(from text: String) -> [OutlineItem] {
        var items: [OutlineItem] = []
        let sentences = text.components(separatedBy: [".", "!", "?"])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        var mainTopicNumber = 1
        var subTopicNumber = 1
        
        for sentence in sentences {
            let lowercased = sentence.lowercased()
            
            // Check for main topics (numbered items, "first", "second", etc.)
            if sentence.matches(pattern: "^\\d+\\.") || 
               sentence.matches(pattern: "^\\d+\\)") ||
               lowercased.contains("first") || lowercased.contains("second") || 
               lowercased.contains("third") || lowercased.contains("fourth") ||
               lowercased.contains("primary") || lowercased.contains("main") ||
               lowercased.contains("major") || lowercased.contains("key") {
                
                let cleanText = cleanOutlineText(sentence)
                items.append(OutlineItem(
                    level: .main,
                    text: cleanText,
                    number: mainTopicNumber,
                    confidence: 0.9
                ))
                mainTopicNumber += 1
                subTopicNumber = 1
            }
            // Check for subtopics (lettered items, "also", "additionally", etc.)
            else if sentence.matches(pattern: "^[a-z]\\.") ||
                    sentence.matches(pattern: "^[a-z]\\)") ||
                    lowercased.contains("also") || lowercased.contains("additionally") ||
                    lowercased.contains("furthermore") || lowercased.contains("moreover") ||
                    lowercased.contains("next") || lowercased.contains("then") ||
                    lowercased.contains("subsequently") || lowercased.contains("following") {
                
                let cleanText = cleanOutlineText(sentence)
                items.append(OutlineItem(
                    level: .sub,
                    text: cleanText,
                    number: subTopicNumber,
                    confidence: 0.7
                ))
                subTopicNumber += 1
            }
            // Check for details (examples, "for example", "such as", etc.)
            else if lowercased.contains("for example") || lowercased.contains("such as") ||
                    lowercased.contains("specifically") || lowercased.contains("in particular") ||
                    lowercased.contains("including") || lowercased.contains("like") ||
                    lowercased.contains("instance") || lowercased.contains("case") {
                
                let cleanText = cleanOutlineText(sentence)
                items.append(OutlineItem(
                    level: .detail,
                    text: cleanText,
                    number: 1,
                    confidence: 0.6
                ))
            }
        }
        
        // If we didn't find any structured items, create a simple outline from key sentences
        if items.isEmpty {
            let keySentences = sentences.prefix(8) // Take first 8 sentences
            for (index, sentence) in keySentences.enumerated() {
                let cleanText = cleanOutlineText(sentence)
                if index < 3 {
                    items.append(OutlineItem(
                        level: .main,
                        text: cleanText,
                        number: index + 1,
                        confidence: 0.8
                    ))
                } else {
                    items.append(OutlineItem(
                        level: .sub,
                        text: cleanText,
                        number: index - 2,
                        confidence: 0.6
                    ))
                }
            }
        }
        
        return items
    }
    
    private static func cleanOutlineText(_ text: String) -> String {
        var cleaned = text
        
        // Remove numbering patterns
        cleaned = cleaned.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^\\d+\\)\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^[a-z]\\.\\s*", with: "", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "^[a-z]\\)\\s*", with: "", options: .regularExpression)
        
        // Remove common outline prefixes
        cleaned = cleaned.replacingOccurrences(of: "^(first|second|third|fourth|fifth)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: "^(primary|main|major|key)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        
        // Remove transition words
        cleaned = cleaned.replacingOccurrences(of: "^(also|additionally|furthermore|moreover|next|then|subsequently|following)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        cleaned = cleaned.replacingOccurrences(of: "^(for example|such as|specifically|in particular|including|like|instance|case)\\s+", with: "", options: [.regularExpression, .caseInsensitive])
        
        // Clean up punctuation and spacing
        cleaned = cleaned
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: " :", with: ":")
            .replacingOccurrences(of: " ;", with: ";")
        
        // Capitalize first letter
        if let first = cleaned.first {
            cleaned = String(first).uppercased() + cleaned.dropFirst()
        }
        
        // Remove excessive whitespace
        cleaned = cleaned.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func isMainTopic(_ sentence: String) -> Bool {
        let mainTopicIndicators = [
            "first", "second", "third", "fourth", "fifth", "sixth", "seventh", "eighth", "ninth", "tenth",
            "primary", "main", "major", "key", "important", "essential", "fundamental",
            "introduction", "conclusion", "overview", "summary", "background",
            "chapter", "section", "part", "topic", "subject", "theme",
            "let's start", "let's begin", "first of all", "to begin with",
            "the first thing", "the main point", "the key concept"
        ]
        
        let lowercased = sentence.lowercased()
        return mainTopicIndicators.contains { lowercased.contains($0) } || 
               sentence.matches(pattern: "^\\d+\\.") || // Numbered points
               sentence.matches(pattern: "^[A-Z][^.!?]*:$") // Headers ending with colon
    }
    
    private static func isSubtopic(_ sentence: String) -> Bool {
        let subtopicIndicators = [
            "additionally", "furthermore", "moreover", "besides", "also",
            "specifically", "particularly", "especially", "notably",
            "for example", "such as", "including", "like", "namely",
            "in addition", "on the other hand", "however", "but",
            "another", "next", "then", "after that", "following",
            "similarly", "likewise", "in contrast", "meanwhile"
        ]
        
        let lowercased = sentence.lowercased()
        return subtopicIndicators.contains { lowercased.contains($0) } ||
               sentence.matches(pattern: "^[a-z]\\.") || // Lowercase letter points
               sentence.matches(pattern: "^•") // Bullet points
    }
    
    private static func calculateTopicConfidence(_ sentence: String) -> Double {
        var confidence = 0.0
        let lowercased = sentence.lowercased()
        
        // Length factor
        let words = sentence.components(separatedBy: .whitespaces)
        if words.count >= 5 && words.count <= 20 {
            confidence += 0.3
        }
        
        // Keyword factor
        let keywords = ["because", "therefore", "thus", "hence", "consequently", "as a result"]
        if keywords.contains(where: { lowercased.contains($0) }) {
            confidence += 0.2
        }
        
        // Structure factor
        if sentence.contains(":") || sentence.contains(";") {
            confidence += 0.1
        }
        
        return min(confidence, 1.0)
    }
    
    private static func formatSentence(_ sentence: String) -> String {
        var formatted = sentence
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove common filler words and phrases
        let fillerWords = [
            "um", "uh", "like", "you know", "sort of", "kind of",
            "basically", "actually", "literally", "obviously",
            "i mean", "right", "okay", "so", "well"
        ]
        
        for filler in fillerWords {
            formatted = formatted.replacingOccurrences(
                of: " \(filler) ",
                with: " ",
                options: .caseInsensitive
            )
        }
        
        // Fix punctuation spacing
        formatted = formatted
            .replacingOccurrences(of: " ,", with: ",")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: " ?", with: "?")
            .replacingOccurrences(of: " !", with: "!")
            .replacingOccurrences(of: " :", with: ":")
            .replacingOccurrences(of: " ;", with: ";")
        
        // Capitalize first letter
        if let first = formatted.first {
            formatted = String(first).uppercased() + formatted.dropFirst()
        }
        
        // Remove excessive whitespace
        formatted = formatted.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        
        return formatted.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func improveOutlineStructure(_ items: [OutlineItem]) -> [OutlineItem] {
        var improved = items
        
        // Ensure we have at least one main topic
        if improved.isEmpty || !improved.contains(where: { $0.level == .main }) {
            if !improved.isEmpty {
                improved[0] = OutlineItem(
                    level: .main,
                    text: improved[0].text,
                    number: 1,
                    confidence: improved[0].confidence
                )
            }
        }
        
        // Group related items
        var result: [OutlineItem] = []
        var currentMain: OutlineItem?
        
        for item in improved {
            switch item.level {
            case .main:
                if let main = currentMain {
                    result.append(main)
                }
                currentMain = item
            case .sub, .detail:
                if let main = currentMain {
                    result.append(main)
                    currentMain = nil
                }
                result.append(item)
            }
        }
        
        if let main = currentMain {
            result.append(main)
        }
        
        return result
    }
    
    private static func formatOutline(items: [OutlineItem]) -> String {
        guard !items.isEmpty else {
            return "No outline items generated."
        }
        
        var result = "OUTLINE\n"
        result += String(repeating: "=", count: 50) + "\n\n"
        
        var currentMain = 0
        var currentSub = 0
        
        for item in items {
            switch item.level {
            case .main:
                result += "\(item.number). \(item.text)\n"
                currentMain = item.number
                currentSub = 0
            case .sub:
                if let unicodeScalar = UnicodeScalar(64 + item.number) {
                    result += "   \(String(unicodeScalar)). \(item.text)\n"
                } else {
                    result += "   \(item.number)). \(item.text)\n"
                }
                currentSub = item.number
            case .detail:
                result += "      \(item.number). \(item.text)\n"
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - String Extension for Pattern Matching
extension String {
    func matches(pattern: String) -> Bool {
        return range(of: pattern, options: .regularExpression) != nil
    }
}

class NotesGenerator {
    static func generateNotes(from text: String) async -> String {
        print("NotesGenerator: Generating AI-powered notes from \(text.count) characters")
        
        // Handle empty or very short text
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty {
            return "No content available to generate notes from."
        }
        
        if trimmedText.count < 50 {
            return "Content too short to generate meaningful notes. Please ensure your recording contains clear speech."
        }
        
        // Use ChatGPT to generate coherent notes
        let aiService = AIService()
        
        do {
            let notes = try await aiService.generateStructuredNotes(from: trimmedText)
            print("NotesGenerator: AI-generated notes successfully - \(notes.count) characters")
            return notes
        } catch {
            print("NotesGenerator: AI generation failed, falling back to basic processing")
            return generateBasicNotes(from: trimmedText)
        }
    }
    
    private static func generateBasicNotes(from text: String) -> String {
        print("NotesGenerator: Generating basic notes as fallback")
        
        let sentences = text.components(separatedBy: [".", "!", "?"])
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.count > 10 }
        
        if sentences.isEmpty {
            return "Unable to extract meaningful content from the recording. Please try recording again with clearer speech."
        }
        
        var notes = "LECTURE NOTES\n"
        notes += String(repeating: "=", count: 50) + "\n\n"
        
        // Create a simple but more coherent summary
        notes += "Key Points:\n\n"
        
        let keySentences = sentences.prefix(10) // Take first 10 meaningful sentences
        for (index, sentence) in keySentences.enumerated() {
            notes += "\(index + 1). \(sentence.capitalized)\n"
        }
        
        // Add important terms
        let words = text.components(separatedBy: " ")
        let keyWords = words.filter { word in
            let cleanWord = word.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return cleanWord.count > 4 && !commonWords.contains(cleanWord)
        }
        
        let uniqueWords = Array(Set(keyWords)).prefix(15)
        if !uniqueWords.isEmpty {
            notes += "\nImportant Terms:\n"
            for word in uniqueWords {
                notes += "• \(word.capitalized)\n"
            }
        }
        
        print("NotesGenerator: Generated basic notes with \(notes.count) characters")
        return notes
    }
    
    private static let commonWords: Set<String> = [
        "the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "must", "can", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their", "mine", "yours", "hers", "ours", "theirs", "very", "really", "quite", "just", "only", "even", "still", "also", "too", "as", "so", "than", "then", "now", "here", "there", "where", "when", "why", "how", "what", "which", "who", "whom", "whose"
    ]
} 