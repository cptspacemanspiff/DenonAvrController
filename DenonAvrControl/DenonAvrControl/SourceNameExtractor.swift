//
//  SourceNameExtractor.swift
//
//  Extracts source names from JavaScript and renaming mappings from HTML.
//  Requires SwiftSoup (https://github.com/scinfu/SwiftSoup)
//

import Foundation
import SwiftSoup

public enum SourceNameExtractor {
    /// Extracts all source names from a JavaScript string (e.g., from buttonFuncRenameSet).
    /// - Parameter js: The JavaScript code as a string.
    /// - Returns: An array of source names (e.g., ["BD", "DVD", "TV", ...])
    public static func extractSourceNames(from js: String) -> [String] {
        let pattern = #"Source==\"([A-Z0-9/]+)\""#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let nsrange = NSRange(js.startIndex ..< js.endIndex, in: js)
        let matches = regex.matches(in: js, range: nsrange)
        let names = matches.compactMap { match -> String? in
            guard let range = Range(match.range(at: 1), in: js) else { return nil }
            return String(js[range])
        }
        return names
    }

    /// Extracts renaming mappings from the HTML (input fields with names like textFuncRename*)
    /// - Parameter html: The HTML string to parse.
    /// - Returns: A dictionary mapping source keys to their renamed value.
    public static func extractRenameMappings(from html: String) -> [String: String] {
        var mapping: [String: String] = [:]
        do {
            let doc = try SwiftSoup.parse(html)
            let inputs = try doc.select("input[name^=textFuncRename]")
            for input in inputs.array() {
                let name = try input.attr("name")
                let value = try input.attr("value")
                if let key = name.components(separatedBy: "textFuncRename").last, !key.isEmpty {
                    mapping[key] = value
                }
            }
        } catch {
            print("Error parsing HTML: \(error)")
        }
        return mapping
    }

    /// Utility: Extracts the first <script> block from HTML (if you want to auto-extract JS from HTML)
    public static func extractFirstScript(from html: String) -> String? {
        do {
            let doc = try SwiftSoup.parse(html)
            if let script = try doc.select("script").first() {
                return try script.html()
            }
        } catch {
            print("Error extracting script: \(error)")
        }
        return nil
    }
}
