// A JavaScript copy of Sources/AppAccess/GetAppState.swift, so the demo page
// can run in a browser. It follows the Swift step for step and uses the
// brief's value names ("arnold_pro", "elite_trial", null).

function getAppState(input) {

  // STEP 1: Work out what they own.
  // Only count active purchases made with their email, from any store.
  const userEmail = cleanEmail(input.email);

  let ownsUltra = false;
  let ownsElite = false;
  let ownsArnoldPro = false;

  for (const purchase of input.purchases) {
    if (purchase.status !== "active") continue;
    if (userEmail === "") continue;  // a blank email never matches anything
    if (cleanEmail(purchase.email) !== userEmail) continue;

    switch (purchase.product) {
      case "ultra": ownsUltra = true; break;
      case "elite": ownsElite = true; break;
      case "arnold_pro": ownsArnoldPro = true; break;
    }
  }

  // A paired device means they have an Ultra, even if we can't find the order.
  const hasUltra = ownsUltra || input.pairedDevice;

  // STEP 2: Work out the path.
  let path = input.chosenPath;
  let message = null;

  if (input.chosenPath === "new" && ownsUltra) {
    path = "ultra";
    message = "We found your order.";
  }

  // STEP 3: Work out the tabs.
  let train = "basic";
  if (ownsElite || ownsArnoldPro) {
    train = "full";
  }

  let remote = "locked";
  if (input.platform === "web") {
    remote = "hidden";
  } else if (hasUltra) {
    remote = "unlocked";
  }

  let elite = "preview";
  if (ownsElite) {
    elite = "unlocked";
  }

  // STEP 4: Work out the first tab, based on the path.
  let firstTab;
  switch (path) {
    case "ultra": firstTab = "remote"; break;
    case "elite": firstTab = "elite"; break;
    case "new": firstTab = "train"; break;
  }

  // Not covered by the rules: Remote is hidden on the web, so start on Train.
  if (firstTab === "remote" && remote === "hidden") {
    firstTab = "train";
  }

  // STEP 5: Work out the upgrade offer (at most one).
  let upgrade = null;

  if (ownsElite) {
    upgrade = null;
  } else if (hasUltra) {
    if (input.firstSessionDone) {
      upgrade = "elite_trial";
    }
  } else if (!ownsArnoldPro) {
    upgrade = "arnold_pro";
  } else {
    upgrade = "ultra";
  }

  return {
    path: path,
    firstTab: firstTab,
    tabs: { train: train, remote: remote, elite: elite, me: "unlocked" },
    upgrade: upgrade,
    message: message,
  };
}

// Remove all spaces and ignore capitals: " Sam@Example.com" -> "sam@example.com".
function cleanEmail(email) {
  return email.replace(/\s/g, "").toLowerCase();
}

if (typeof module !== "undefined") module.exports = { getAppState };
