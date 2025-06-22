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
    }
    
    static func generateOutline(from text: String) -> String {
        // Split text into sentences
        let tokenizer = NLTokenizer(using: .sentence)
        tokenizer.string = text
        let sentences = tokenizer.tokens(for: text.startIndex..<text.endIndex)
            .map { String(text[$0]) }
        
        // Identify main topics and subtopics
        var outlineItems: [OutlineItem] = []
        var currentMainNumber = 1
        var currentSubNumber = 1
        var currentDetailNumber = 1
        
        // Process each sentence
        for sentence in sentences {
            let trimmedSentence = sentence.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedSentence.isEmpty { continue }
            
            // Check for main topic indicators
            if isMainTopic(sentence) {
                outlineItems.append(OutlineItem(
                    level: .main,
                    text: formatSentence(sentence),
                    number: currentMainNumber
                ))
                currentMainNumber += 1
                currentSubNumber = 1
                currentDetailNumber = 1
            }
            // Check for subtopic indicators
            else if isSubtopic(sentence) {
                outlineItems.append(OutlineItem(
                    level: .sub,
                    text: formatSentence(sentence),
                    number: currentSubNumber
                ))
                currentSubNumber += 1
                currentDetailNumber = 1
            }
            // Add as detail point
            else {
                outlineItems.append(OutlineItem(
                    level: .detail,
                    text: formatSentence(sentence),
                    number: currentDetailNumber
                ))
                currentDetailNumber += 1
            }
        }
        
        // Format the outline
        return formatOutline(items: outlineItems)
    }
    
    private static func isMainTopic(_ sentence: String) -> Bool {
        let mainTopicIndicators = [
            "first", "second", "third", "fourth", "fifth",
            "primary", "main", "major", "key",
            "introduction", "conclusion",
            "overview", "summary"
        ]
        
        let lowercased = sentence.lowercased()
        return mainTopicIndicators.contains { lowercased.contains($0) }
    }
    
    private static func isSubtopic(_ sentence: String) -> Bool {
        let subtopicIndicators = [
            "additionally", "furthermore", "moreover",
            "specifically", "particularly", "especially",
            "for example", "such as", "including"
        ]
        
        let lowercased = sentence.lowercased()
        return subtopicIndicators.contains { lowercased.contains($0) }
    }
    
    private static func formatSentence(_ sentence: String) -> String {
        // Remove common filler words and phrases
        var formatted = sentence
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "um", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "uh", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "like", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "you know", with: "", options: .caseInsensitive)
        
        // Capitalize first letter
        if let first = formatted.first {
            formatted = String(first).uppercased() + formatted.dropFirst()
        }
        
        return formatted
    }
    
    private static func formatOutline(items: [OutlineItem]) -> String {
        var result = ""
        var currentMain = 0
        var currentSub = 0
        
        for item in items {
            switch item.level {
            case .main:
                result += "\n\(item.number). \(item.text)\n"
                currentMain = item.number
                currentSub = 0
            case .sub:
                result += "   \(String(UnicodeScalar(64 + item.number))). \(item.text)\n"
                currentSub = item.number
            case .detail:
                result += "      \(item.number). \(item.text)\n"
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
} 