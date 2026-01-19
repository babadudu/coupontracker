# Runtime Fix - CouponTracker

## ✅ Fixes Applied

### 1. CouponTrackerApp.swift
- **Fixed:** Moved notification delegate setup from `init()` to `.task` modifier
- **Why:** Accessing `notificationService` during init can cause timing issues

### 2. CardTemplates.json  
- **Created:** Basic template file with 3 sample cards (Chase Sapphire Reserve, Amex Gold, Amex Platinum)
- **Location:** `/repo/CardTemplates.json`

## 🔧 CRITICAL: Add CardTemplates.json to Xcode Project

**The app will crash at runtime if this file is not in the bundle.**

### Steps to Add File to Xcode:

1. **In Xcode Navigator (left sidebar):**
   - Right-click on the project folder or "CouponTracker" group
   - Select "Add Files to 'CouponTracker'..."

2. **Navigate to the file:**
   - Find and select `CardTemplates.json`
   - Check the box: ✅ "Copy items if needed"
   - Check the box: ✅ "Add to targets: CouponTracker"
   - Click "Add"

3. **Verify the file is added:**
   - Select `CardTemplates.json` in Project Navigator
   - Open File Inspector (right sidebar)
   - Under "Target Membership", ensure "CouponTracker" is checked ✅

### Alternative: Create File in Xcode

If you prefer to create it directly in Xcode:

1. Right-click project → New File
2. Select "Empty" file
3. Name it: `CardTemplates.json`
4. Copy the content from `/repo/CardTemplates.json`
5. Paste into the new file
6. Save (Cmd+S)

## 🐛 Debugging Runtime Crashes

### Check Console for Errors

When the app crashes, look for these common errors:

#### Error 1: "Template resource 'CardTemplates.json' not found in bundle"
**Solution:** Follow steps above to add CardTemplates.json to the Xcode project

#### Error 2: "Failed to create ModelContainer"
**Solution:** This is a SwiftData issue. Try:
```bash
# Reset simulator
xcrun simctl erase all

# Or in Simulator app:
Device → Erase All Content and Settings
```

#### Error 3: "Failed to decode templates"
**Solution:** The JSON file has syntax errors. Validate it:
```bash
# In terminal:
cd /path/to/project
python3 -m json.tool CardTemplates.json
```

#### Error 4: Crash with no error message
**Solution:** Enable Zombie Objects:
```
Product → Scheme → Edit Scheme → Run → Diagnostics
☑️ Enable Zombie Objects
☑️ Address Sanitizer
```

## 🏃 Run Instructions

### Clean Build & Run

```bash
# In Xcode:
1. Cmd+Shift+K (Clean Build Folder)
2. Ensure CardTemplates.json is in project (see above)
3. Select a simulator (iPhone 15 Pro recommended)
4. Cmd+R (Build and Run)
```

### Expected Behavior

**First Launch:**
1. App shows "Loading..." screen briefly
2. Shows onboarding screen with "Welcome to CouponTracker"
3. Tap "Get Started"
4. Shows Dashboard (empty state with "Add Your First Card" button)

**Subsequent Launches:**
1. App shows "Loading..." screen briefly
2. Shows Dashboard directly (skips onboarding)

## 🧪 Testing the Fix

### Quick Test (30 seconds)

1. Launch app
2. Complete onboarding
3. See empty dashboard
4. **Success!** App is running

### Full Test (2 minutes)

1. Launch app
2. Complete onboarding
3. Tap "Add Your First Card"
4. Select "Sapphire Reserve" from list
5. Add optional nickname (e.g., "Personal")
6. Tap "Add Card"
7. Verify card appears on dashboard
8. Switch to Wallet tab
9. Verify card appears in wallet
10. **Success!** Full flow working

## 📊 Common Runtime Issues & Solutions

### Issue: App crashes immediately on launch

**Checklist:**
- [ ] CardTemplates.json is added to project target
- [ ] All SwiftData models (@Model classes) are included in Schema
- [ ] Deployment target is iOS 17.0+ 
- [ ] Running on iOS 17+ simulator or device

### Issue: App shows blank screen

**Solution:**
```swift
// Check console for:
"Failed to load user preferences"
"Failed to load home data"

// This usually means SwiftData context issue
// Try resetting simulator
```

### Issue: App crashes when adding card

**Solution:**
Check that CardRepository can access ModelContext:
```swift
// In console, look for:
"Failed to add card"
"ModelContext is nil"
```

### Issue: Template loading fails

**Solution:**
1. Verify CardTemplates.json is valid JSON
2. Check bundle contains the file:
```swift
// Add temporary debug code in AppContainer:
if Bundle.main.url(forResource: "CardTemplates", withExtension: "json") == nil {
    print("❌ CardTemplates.json NOT in bundle")
} else {
    print("✅ CardTemplates.json found in bundle")
}
```

## 📝 Verification Checklist

Before saying "it works", verify:

- [ ] App launches without crash
- [ ] Onboarding appears (first launch)
- [ ] Dashboard appears (subsequent launches)  
- [ ] Can add a card from templates
- [ ] Card appears in Home tab
- [ ] Card appears in Wallet tab
- [ ] Can tap card to view details
- [ ] Can mark benefit as done
- [ ] Can delete card
- [ ] App doesn't crash when switching tabs
- [ ] Pull-to-refresh works

## 🆘 If Still Crashing

### Get Full Crash Log

1. **In Xcode:**
   - Window → Devices and Simulators
   - Select your simulator
   - Click "View Device Logs"
   - Find the crash log for CouponTracker
   - Copy the crash log

2. **Or check Console.app:**
   - Open Console app (Cmd+Space, type "Console")
   - Select simulator device
   - Filter: "CouponTracker"
   - Look for crash reports

### What to Check in Crash Log

Look for these keywords:
- `Fatal error:`
- `Precondition failed:`
- `unexpectedly found nil`
- `Thread 1: signal SIGABRT`

### Common Crash Patterns

```
Fatal error: Failed to create ModelContainer
→ SwiftData issue: Reset simulator

Thread 1: Fatal error: Unexpectedly found nil
→ Missing dependency: Check AppContainer initialization

EXC_BAD_ACCESS
→ Memory issue: Enable Address Sanitizer

Template resource 'CardTemplates.json' not found
→ File not in bundle: Add to Xcode project
```

## ✅ Success Indicators

App is working correctly when:
1. ✅ Builds without errors
2. ✅ Runs without crashes
3. ✅ Shows onboarding on first launch
4. ✅ Shows dashboard on subsequent launches
5. ✅ Can add and view cards
6. ✅ Navigation works between all tabs
7. ✅ Data persists between app launches

---

**Current Status:** Fixes applied, waiting for Xcode project update
**Next Step:** Add CardTemplates.json to Xcode project target
**Build Status:** ✅ Compiles
**Run Status:** Pending file addition

