import Combine
import CoreGraphics

@MainActor
final class TestModel: ObservableObject {
    @Published var notes = ["first", "second"]
    @Published var selected = 0
    @Published var text = ""
    @Published var allowNewlines = false
    @Published var target = "A"
    @Published var sent: [String] = []
    @Published var flag = true
}
