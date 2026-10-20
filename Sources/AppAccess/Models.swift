// The data that goes into and comes out of getAppState.
// The text after each "=" is the exact name used in the brief.

public enum Product: String {
    case ultra
    case elite
    case arnoldPro = "arnold_pro"
}

public enum Path: String {
    case ultra
    case elite
    case new
}

public enum Source: String {
    case shopify
    case appStore = "app_store"
    case googlePlay = "google_play"
    case web
}

public enum PurchaseStatus: String {
    case active
    case expired
    case refunded
}

public enum Platform: String {
    case ios
    case android
    case web
}

public struct Purchase {
    public var source: Source
    public var product: Product
    public var email: String
    public var status: PurchaseStatus

    public init(source: Source, product: Product, email: String, status: PurchaseStatus) {
        self.source = source
        self.product = product
        self.email = email
        self.status = status
    }
}

public struct UserInput {
    public var chosenPath: Path
    public var email: String
    public var purchases: [Purchase]  // may include purchases from other emails
    public var pairedDevice: Bool
    public var firstSessionDone: Bool
    public var platform: Platform

    public init(
        chosenPath: Path,
        email: String,
        purchases: [Purchase],
        pairedDevice: Bool,
        firstSessionDone: Bool,
        platform: Platform
    ) {
        self.chosenPath = chosenPath
        self.email = email
        self.purchases = purchases
        self.pairedDevice = pairedDevice
        self.firstSessionDone = firstSessionDone
        self.platform = platform
    }
}

public enum Tab: String {
    case train
    case remote
    case elite
}

public enum TrainAccess: String {
    case basic
    case full
}

public enum RemoteAccess: String {
    case unlocked
    case locked
    case hidden
}

public enum EliteAccess: String {
    case unlocked
    case preview
}

public enum MeAccess: String {
    case unlocked
}

public enum Upgrade: String {
    case eliteTrial = "elite_trial"
    case arnoldPro = "arnold_pro"
    case ultra
    case elite
}

public struct Tabs: Equatable {
    public var train: TrainAccess
    public var remote: RemoteAccess
    public var elite: EliteAccess
    public var me: MeAccess = .unlocked  // always unlocked
}

public struct AppState: Equatable {
    public var path: Path
    public var firstTab: Tab
    public var tabs: Tabs
    public var upgrade: Upgrade?  // nil means no offer
    public var message: String?  // nil means no message
}
