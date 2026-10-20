import Testing
@testable import AppAccess

// Helpers so each test only spells out what matters to it.

func purchase(
    _ product: Product,
    email: String = "sam@example.com",
    status: PurchaseStatus = .active,
    source: Source = .shopify
) -> Purchase {
    Purchase(source: source, product: product, email: email, status: status)
}

func user(
    path: Path = .new,
    email: String = "sam@example.com",
    purchases: [Purchase] = [],
    paired: Bool = false,
    firstSessionDone: Bool = false,
    platform: Platform = .ios
) -> UserInput {
    UserInput(
        chosenPath: path,
        email: email,
        purchases: purchases,
        pairedDevice: paired,
        firstSessionDone: firstSessionDone,
        platform: platform
    )
}

// MARK: - The example from the brief

@Test("The example from the brief gives the exact expected output") func briefExample() {
    let result = getAppState(user(
        path: .new,
        purchases: [purchase(.ultra, email: " Sam@Example.com")]
    ))

    #expect(result == AppState(
        path: .ultra,
        firstTab: .remote,
        tabs: Tabs(train: .basic, remote: .unlocked, elite: .preview, me: .unlocked),
        upgrade: nil,
        message: "We found your order."
    ))
}

// MARK: - Which purchases count

@Test("Emails match even with different capitals and spaces") func emailIgnoresCapitalsAndSpaces() {
    let result = getAppState(user(
        email: "  SAM@example.COM ",
        purchases: [purchase(.elite, email: "sam @Example.com")]
    ))
    #expect(result.tabs.elite == .unlocked)
}

@Test("A blank email doesn't match purchases with no email") func blankEmailMatchesNothing() {
    let result = getAppState(user(email: "  ", purchases: [purchase(.elite, email: "")]))
    #expect(result.tabs.elite == .preview)
}

@Test("Purchases under someone else's email don't count") func purchasesFromOtherEmailsDontCount() {
    let result = getAppState(user(purchases: [purchase(.elite, email: "alex@example.com")]))
    #expect(result.tabs.elite == .preview)
}

@Test("Expired and refunded purchases don't count") func expiredAndRefundedPurchasesDontCount() {
    let result = getAppState(user(purchases: [
        purchase(.elite, status: .expired),
        purchase(.ultra, status: .refunded),
    ]))
    #expect(result.tabs.elite == .preview)
    #expect(result.tabs.remote == .locked)
    #expect(result.path == .new)
}

@Test("Purchases from Shopify, App Store, Google Play and web all count") func purchasesFromEveryStoreCount() {
    for store in [Source.shopify, .appStore, .googlePlay, .web] {
        let result = getAppState(user(purchases: [purchase(.elite, source: store)]))
        #expect(result.tabs.elite == .unlocked)
    }
}

// MARK: - Path and first tab

@Test("First tab matches the chosen path") func firstTabMatchesChosenPath() {
    #expect(getAppState(user(path: .ultra)).firstTab == .remote)
    #expect(getAppState(user(path: .elite)).firstTab == .elite)
    #expect(getAppState(user(path: .new)).firstTab == .train)
}

@Test("Picking \"I'm an Elite member\" doesn't unlock Elite on its own") func choosingElitePathDoesNotUnlockElite() {
    let result = getAppState(user(path: .elite))
    #expect(result.path == .elite)
    #expect(result.firstTab == .elite)
    #expect(result.tabs.elite == .preview)
    #expect(result.tabs.train == .basic)
}

@Test("New user without an Ultra stays on the new path with no message") func newUserWithoutUltraStaysNewWithNoMessage() {
    let result = getAppState(user(path: .new, purchases: [purchase(.elite)]))
    #expect(result.path == .new)
    #expect(result.message == nil)
}

@Test("Only new users get the \"We found your order.\" message") func onlyNewUsersGetTheFoundOrderMessage() {
    let ultraPath = getAppState(user(path: .ultra, purchases: [purchase(.ultra)]))
    #expect(ultraPath.path == .ultra)
    #expect(ultraPath.message == nil)

    let elitePath = getAppState(user(path: .elite, purchases: [purchase(.ultra)]))
    #expect(elitePath.path == .elite)
    #expect(elitePath.message == nil)
}

@Test("New user with a paired device but no order isn't moved") func newUserWithPairedDeviceButNoOrderIsNotMoved() {
    // There's no order to "find", so we don't show that message.
    let result = getAppState(user(path: .new, paired: true))
    #expect(result.path == .new)
    #expect(result.message == nil)
    #expect(result.tabs.remote == .unlocked)
}

// MARK: - Tabs

@Test("A paired device unlocks Remote without an order") func pairedDeviceUnlocksRemoteWithoutAnOrder() {
    #expect(getAppState(user(path: .ultra, paired: true)).tabs.remote == .unlocked)
}

@Test("Elite unlocks Elite and the full Train tab") func eliteUnlocksEliteAndFullTrain() {
    let result = getAppState(user(purchases: [purchase(.elite)]))
    #expect(result.tabs.elite == .unlocked)
    #expect(result.tabs.train == .full)
}

@Test("Arnold Pro unlocks the full Train tab only") func arnoldProUnlocksFullTrainOnly() {
    let result = getAppState(user(purchases: [purchase(.arnoldPro)]))
    #expect(result.tabs.train == .full)
    #expect(result.tabs.elite == .preview)
}

@Test("Tabs they don't own are locked, not hidden") func unownedTabsAreLockedNotHidden() {
    let result = getAppState(user(platform: .android))
    #expect(result.tabs == Tabs(train: .basic, remote: .locked, elite: .preview, me: .unlocked))
}

@Test("Remote is hidden on the web, even for Ultra owners") func remoteIsHiddenOnWebEvenForOwners() {
    let result = getAppState(user(purchases: [purchase(.ultra)], paired: true, platform: .web))
    #expect(result.tabs.remote == .hidden)
}

// MARK: - The uncovered case

@Test("Uncovered case: Ultra path on the web starts on Train") func ultraPathOnWebStartsOnTrainBecauseRemoteIsHidden() {
    let result = getAppState(user(path: .ultra, purchases: [purchase(.ultra)], platform: .web))
    #expect(result.path == .ultra)
    #expect(result.firstTab == .train)
}

@Test("Uncovered case: new user moved to Ultra path on the web also starts on Train") func newUserMovedToUltraPathOnWebAlsoStartsOnTrain() {
    let result = getAppState(user(path: .new, purchases: [purchase(.ultra)], platform: .web))
    #expect(result.path == .ultra)
    #expect(result.message == "We found your order.")
    #expect(result.firstTab == .train)
}

// MARK: - Upgrade offer

@Test("Ultra owner gets no offer before their first session") func ultraOwnerGetsNoOfferBeforeFirstSession() {
    let result = getAppState(user(path: .ultra, purchases: [purchase(.ultra)], firstSessionDone: false))
    #expect(result.upgrade == nil)
}

@Test("Ultra owner gets the Elite trial after their first session") func ultraOwnerGetsEliteTrialAfterFirstSession() {
    let result = getAppState(user(path: .ultra, purchases: [purchase(.ultra)], firstSessionDone: true))
    #expect(result.upgrade == .eliteTrial)
}

@Test("Ultra owner with Arnold Pro still only gets the Elite trial") func ultraOwnerWithArnoldProStillOnlyGetsEliteTrial() {
    let result = getAppState(user(purchases: [purchase(.ultra), purchase(.arnoldPro)], firstSessionDone: true))
    #expect(result.upgrade == .eliteTrial)
}

@Test("A paired device counts as owning an Ultra for offers") func pairedDeviceCountsAsUltraOwnerForOffers() {
    // We shouldn't try to sell an Ultra to someone who has one paired.
    #expect(getAppState(user(path: .ultra, paired: true)).upgrade == nil)
    #expect(getAppState(user(path: .ultra, paired: true, firstSessionDone: true)).upgrade == .eliteTrial)
}

@Test("Elite members get no offer") func eliteMembersGetNoOffer() {
    #expect(getAppState(user(purchases: [purchase(.elite)])).upgrade == nil)
    #expect(getAppState(user(purchases: [purchase(.elite), purchase(.ultra)], firstSessionDone: true)).upgrade == nil)
}

@Test("Someone who owns nothing is offered Arnold Pro") func ownsNothingGetsArnoldProOffer() {
    #expect(getAppState(user()).upgrade == .arnoldPro)
}

@Test("Someone with Arnold Pro is offered the Ultra") func ownsArnoldProGetsUltraOffer() {
    #expect(getAppState(user(purchases: [purchase(.arnoldPro)])).upgrade == .ultra)
}

@Test("The Ultra is still offered on the web") func ultraOfferStillShownOnWeb() {
    // Remote is hidden on the web, but the Ultra itself can still be sold there.
    #expect(getAppState(user(purchases: [purchase(.arnoldPro)], platform: .web)).upgrade == .ultra)
}

@Test("Expired Elite member is treated as owning nothing") func expiredEliteMemberIsOfferedArnoldPro() {
    // Expired Elite doesn't count, so they're treated like someone who owns nothing.
    #expect(getAppState(user(path: .elite, purchases: [purchase(.elite, status: .expired)])).upgrade == .arnoldPro)
}

// MARK: - Names match the brief

@Test("Value names match the brief exactly") func valueNamesMatchTheBrief() {
    #expect(Product.arnoldPro.rawValue == "arnold_pro")
    #expect(Source.appStore.rawValue == "app_store")
    #expect(Source.googlePlay.rawValue == "google_play")
    #expect(Upgrade.eliteTrial.rawValue == "elite_trial")
    #expect(Upgrade.arnoldPro.rawValue == "arnold_pro")
    #expect(MeAccess.unlocked.rawValue == "unlocked")
}

@Test("New user who owns Elite stays on the new path") func newUserWhoOwnsEliteStaysOnNewPath() {
    // The brief only moves "new" users who own an Ultra, so Elite owners stay put.
    let result = getAppState(user(path: .new, purchases: [purchase(.elite)]))
    #expect(result.path == .new)
    #expect(result.firstTab == .train)
    #expect(result.tabs.train == .full)
    #expect(result.tabs.elite == .unlocked)
}
