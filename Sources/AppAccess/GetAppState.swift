// Decides what a user sees in the app, based on what they own.

public func getAppState(_ input: UserInput) -> AppState {

    // STEP 1: Work out what they own.
    // Only count active purchases made with their email, from any store.
    let userEmail = cleanEmail(input.email)

    var ownsUltra = false
    var ownsElite = false
    var ownsArnoldPro = false

    for purchase in input.purchases {
        if purchase.status != .active { continue }
        if userEmail.isEmpty { continue }  // a blank email never matches anything
        if cleanEmail(purchase.email) != userEmail { continue }

        switch purchase.product {
        case .ultra: ownsUltra = true
        case .elite: ownsElite = true
        case .arnoldPro: ownsArnoldPro = true
        }
    }

    // A paired device means they have an Ultra, even if we can't find the order.
    let hasUltra = ownsUltra || input.pairedDevice

    // STEP 2: Work out the path.
    // We use what they picked, unless they picked "new" but have an Ultra order.
    var path = input.chosenPath
    var message: String? = nil

    if input.chosenPath == .new && ownsUltra {
        path = .ultra
        message = "We found your order."
    }

    // STEP 3: Work out the tabs.
    var train = TrainAccess.basic
    if ownsElite || ownsArnoldPro {
        train = .full
    }

    var remote = RemoteAccess.locked
    if input.platform == .web {
        remote = .hidden  // Bluetooth doesn't work on the web
    } else if hasUltra {
        remote = .unlocked
    }

    var elite = EliteAccess.preview
    if ownsElite {
        elite = .unlocked
    }

    // STEP 4: Work out the first tab, based on the path.
    var firstTab: Tab
    switch path {
    case .ultra: firstTab = .remote
    case .elite: firstTab = .elite
    case .new: firstTab = .train
    }

    // Not covered by the rules: on the web the Remote tab is hidden,
    // so Ultra users can't start there. We send them to Train instead.
    if firstTab == .remote && remote == .hidden {
        firstTab = .train
    }

    // STEP 5: Work out the upgrade offer (at most one).
    var upgrade: Upgrade? = nil

    if ownsElite {
        upgrade = nil  // Elite members get no offer
    } else if hasUltra {
        if input.firstSessionDone {
            upgrade = .eliteTrial  // only after their first device session
        }
    } else if !ownsArnoldPro {
        upgrade = .arnoldPro
    } else {
        // The brief's order is Arnold Pro, then Ultra, then Elite. But anyone
        // reaching this line has no Ultra, so the next thing is always the Ultra
        // and Elite is never offered here.
        upgrade = .ultra
    }

    return AppState(
        path: path,
        firstTab: firstTab,
        tabs: Tabs(train: train, remote: remote, elite: elite, me: .unlocked),
        upgrade: upgrade,
        message: message
    )
}

// Emails can't contain spaces, so we remove them all and ignore capitals.
// " Sam@Example.com" becomes "sam@example.com".
func cleanEmail(_ email: String) -> String {
    let noSpaces = email.filter { !$0.isWhitespace }
    return noSpaces.lowercased()
}
