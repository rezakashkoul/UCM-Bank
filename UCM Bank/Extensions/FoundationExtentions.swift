import Foundation

extension Date {
    
    func getPrettyDate(format: String = "EEEE, MMM d, YYYY") -> String {
        let df = DateFormatter()
        df.setLocalizedDateFormatFromTemplate(format)
        return df.string(from: self)
    }
    
    func getPrettyTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }
}

extension Double {
    
    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
    
    func toInt() -> Int? {
        if self >= Double(Int.min) && self < Double(Int.max) {
            return Int(self)
        } else {
            return nil
        }
    }
}

extension String {
    var sanitized: String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
                   .components(separatedBy: .controlCharacters)
                   .joined()
                   .lowercased()
    }
}
