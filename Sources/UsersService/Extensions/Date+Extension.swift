import Foundation

// MARK: Date (Append Months)

extension Date {
    func append(months: Int) -> Date {
        var dc = DateComponents()
        dc.month = months
        return Calendar.current.date(byAdding: dc, to: self)!
    }
}
