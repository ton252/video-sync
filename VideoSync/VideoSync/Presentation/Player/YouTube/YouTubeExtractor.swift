//
//  YouTubeExtractor.swift
//  VideoSync
//
//  Created by ton252 on 17.04.2024.
//

import Foundation

class YouTubeExtractor {
    func extractVideoId(link: String) -> String? {
        let urlString = URLComponents(string: link).flatMap { urlComp in
            var comp = urlComp
            comp.queryItems = nil
            return comp.string
        } ?? ""
        let patterns = [
            "(?<=watch\\?v=)[^#&?\\n]*",            // Standard URL
            "(?<=youtu.be/)[^#&?\\n]*",             // Shortened URL
            "(?<=youtube.com/embed/)[^#&?\\n]*",    // Embed URL
            "(?<=youtube.com/shorts/)[^#&?\\n]*"    // Shorts URL
        ]
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern)
            let range = NSRange(location: 0, length: urlString.utf16.count)
            if let match = regex?.firstMatch(in: urlString, options: [], range: range) {
                if let range = Range(match.range, in: urlString) {
                    return String(urlString[range])
                }
            }
        }
        return nil
    }
    
    func isValidLink(_ link: String) -> Bool {
        return extractVideoId(link: link) != nil
    }
}
