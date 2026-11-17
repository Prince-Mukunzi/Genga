import AppIntents
import UIKit

@available(iOS 16.0, *)
struct LogMomoMessageIntent: AppIntent {
  static var title: LocalizedStringResource = "Log MoMo SMS"
  static var description = IntentDescription(
    "Reads a MoMo SMS and opens Genga with the amount filled in."
  )

  static var openAppWhenRun: Bool = true

  @Parameter(title: "Message")
  var message: String

  static var parameterSummary: some ParameterSummary {
    Summary("Log \(\.$message) in Genga")
  }

  @MainActor
  func perform() async throws -> some IntentResult {
    await UIApplication.shared.open(MomoMessage(message).link)
    return .result()
  }
}

struct MomoMessage {
  let text: String

  init(_ text: String) {
    self.text = text
  }

  var isIncome: Bool {
    let lower = text.lowercased()
    return lower.contains("received") || lower.contains("deposit")
  }

  // The first "<number> RWF" is the transaction; later ones are balance and fee.
  var amount: String? {
    firstNumber(matching: #"([\d,]+(?:\.\d+)?)\s?RWF"#)
  }

  var balance: String? {
    firstNumber(matching: #"balance\D{0,12}([\d,]+(?:\.\d+)?)\s?RWF"#)
  }

  private func firstNumber(matching pattern: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
      let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
      let range = Range(match.range(at: 1), in: text)
    else { return nil }
    return text[range].replacingOccurrences(of: ",", with: "")
  }

  var link: URL {
    var components = URLComponents()
    components.scheme = "genga"
    components.host = "add"
    components.queryItems = [
      URLQueryItem(name: "type", value: isIncome ? "income" : "expense"),
      URLQueryItem(name: "source", value: "momo"),
    ]
    if let amount {
      components.queryItems?.append(URLQueryItem(name: "amount", value: amount))
    }
    if let balance {
      components.queryItems?.append(URLQueryItem(name: "balance", value: balance))
    }
    return components.url ?? URL(string: "genga://add")!
  }
}
