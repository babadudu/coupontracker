---
name: add-swift-file
description: Run when creating any new .swift file in the ios/ directory to register it in the Xcode project
---

# Add Swift File to Xcode Project

New Swift files won't compile until added to `project.pbxproj`. Missing entries cause:
```
error: cannot find 'ClassName' in scope
```

## Required Entries (4 per file)

Each new file needs these entries in `ios/CouponTracker.xcodeproj/project.pbxproj`:

### 1. PBXFileReference
Declares the file exists. Add in alphabetical order within the section.
```
{ID1} /* FileName.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileName.swift; sourceTree = "<group>"; };
```

### 2. PBXBuildFile
Links file to compilation.
```
{ID2} /* FileName.swift in Sources */ = {isa = PBXBuildFile; fileRef = {ID1} /* FileName.swift */; };
```

### 3. PBXGroup
Add file reference ID to the appropriate group's `children` array (match folder structure).

### 4. PBXSourcesBuildPhase
Add build file ID to the correct target's `files` array:
- Main app: `CouponTracker` target
- Tests: `CouponTrackerTests` target

## ID Generation

Use unique 24-character uppercase hex IDs. Pattern:
```
XXXX1234567890ABCDEF0001  (source file)
XXXX1234567890ABCDEF0002  (build file)
```
Where XXXX is a 4-char prefix based on filename (e.g., `BSVC` for BenefitStateService).

## Verification

```bash
xcodebuild -project ios/CouponTracker.xcodeproj -scheme CouponTracker -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```
Expect: `** BUILD SUCCEEDED **`
