import Flutter
import Contacts

class ContactsPlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.example.genga/contacts",
            binaryMessenger: registrar.messenger()
        )
        let instance = ContactsPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "requestPermission":
            requestPermission(result: result)
        case "status":
            result(status())
        case "getContacts":
            getContacts(result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func status() -> String {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized: return "allowed"
        case .notDetermined: return "notAsked"
        case .denied, .restricted: return "denied"
        default: return "allowed"
        }
    }

    private func requestPermission(result: @escaping FlutterResult) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, _ in
            DispatchQueue.main.async {
                result(granted)
            }
        }
    }

    private func getContacts(result: @escaping FlutterResult) {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
        ]

        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        var contacts: [[String: Any]] = []
        do {
            try store.enumerateContacts(with: request) { contact, _ in
                let phones = contact.phoneNumbers.map { $0.value.stringValue }
                let name = "\(contact.givenName) \(contact.familyName)"
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty && !phones.isEmpty {
                    contacts.append([
                        "name": name,
                        "phones": phones,
                    ])
                }
            }
            result(contacts)
        } catch {
            result(FlutterError(
                code: "CONTACTS_ERROR",
                message: error.localizedDescription,
                details: nil
            ))
        }
    }
}
