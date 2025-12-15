import Foundation

extension Array {
    func safeIndexLookup(i: Index) -> Element? {
        guard i < count else { return nil }
        return self[i]
    }
}
