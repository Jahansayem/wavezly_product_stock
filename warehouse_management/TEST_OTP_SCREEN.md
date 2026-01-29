# OTP Screen Debug Test Instructions

## 🎯 Goal
Test if the correct OTP screen is displaying after the clean rebuild.

## 📋 Steps to Test

### Option 1: Using Batch Script (Easiest)

1. **Navigate to project folder:**
   ```
   cd C:\Users\Jahan\Downloads\wavezly\warehouse_management
   ```

2. **Run the test script:**
   ```
   run_with_logs.bat
   ```

3. **Wait for app to launch on your device** (~30-60 seconds)

4. **Test the navigation:**
   - Enter phone number: `01700000000`
   - Click "এগিয়ে যান" button
   - Watch the OTP screen appear

5. **Check your terminal window** for these logs:
   ```
   flutter: ╔═══════════════════════════════════════════════════╗
   flutter: ║ 📱 NAVIGATING TO OTP SCREEN                      ║
   flutter: ║ Phone: 8801700000000                             ║
   flutter: ║ Target: OtpVerificationScreen                    ║
   flutter: ╚═══════════════════════════════════════════════════╝
   flutter: ╔═══════════════════════════════════════════════════╗
   flutter: ║ ✅ OPENED CORRECT OTP VERIFICATION SCREEN        ║
   flutter: ║ Phone: 8801700000000                             ║
   flutter: ║ Screen: OtpVerificationScreen                    ║
   flutter: ║ File: otp_verification_screen.dart               ║
   flutter: ╚═══════════════════════════════════════════════════╝
   ```

### Option 2: Manual Command (Alternative)

1. **Open PowerShell or Command Prompt**

2. **Navigate to project:**
   ```
   cd C:\Users\Jahan\Downloads\wavezly\warehouse_management
   ```

3. **Run Flutter:**
   ```
   flutter run -d 192.168.8.210:34605
   ```

4. **Test navigation** (same as above)

5. **Watch console** for debug logs

### Option 3: Using ADB Logcat (If Flutter console doesn't work)

1. **Open a separate terminal**

2. **Run ADB logcat:**
   ```
   adb -s 192.168.8.210:34605 logcat -s flutter:V
   ```

3. **In another terminal, launch app:**
   ```
   cd warehouse_management
   flutter run -d 192.168.8.210:34605
   ```

4. **Test navigation**

5. **Check logcat window** for debug messages

---

## ✅ What to Verify on OTP Screen

### Correct UI (Target Design):
- ✅ Promo card at top with customer testimonial
- ✅ Yellow circular back button (top left)
- ✅ Blue helpline button (top right)
- ✅ Heading: "ওটিপি যাচাই করুন"
- ✅ Yellow info banner with phone number & SMS icon
- ✅ 6 OTP input boxes in a row
- ✅ Timer: "আরেকবার চেষ্টা করুন 2:59"
- ✅ Link: "মোবাইল নাম্বার পরিবর্তন করুন"
- ✅ Bottom toast: "Sent verification CODE at 01700000000"
- ✅ Submit button: **"সাবমিট"**
- ✅ NO AppBar at top

### Wrong UI (Cached/Old):
- ❌ AppBar with title "ভেরিফিকেশন"
- ❌ Button labeled "যাচাই করুন" (instead of "সাবমিট")
- ❌ Link "নতুন কোড পাঠান"

---

## 📸 Please Provide:

1. **Screenshot** of OTP screen from your device
2. **Copy-paste** of debug logs from terminal showing:
   - "📱 NAVIGATING TO OTP SCREEN" message
   - "✅ OPENED CORRECT OTP VERIFICATION SCREEN" message
3. **Answer:** Which button text do you see?
   - [ ] "সাবমিট" (Correct ✅)
   - [ ] "যাচাই করুন" (Wrong - cached ❌)
4. **Answer:** Is there an AppBar at the top?
   - [ ] No AppBar (Correct ✅)
   - [ ] Yes, with "ভেরিফিকেশন" title (Wrong - cached ❌)

---

## 🔧 Troubleshooting

### If app doesn't install:
```bash
adb uninstall com.example.warehouse_management
flutter run -d 192.168.8.210:34605
```

### If device disconnects:
```bash
adb connect 192.168.8.210:34605
flutter run -d 192.168.8.210:34605
```

### If logs don't appear:
- Try Option 3 (ADB logcat) instead
- Make sure you're entering the phone number and clicking the button
- Debug logs only appear AFTER you navigate from Login → OTP

---

## 📊 What the Logs Tell Us

**If logs show correct screen BUT UI looks wrong:**
→ Build cache issue wasn't fully cleared. Try:
```bash
flutter clean
flutter pub get
flutter run -d 192.168.8.210:34605
```

**If logs show correct screen AND UI looks correct:**
→ ✅ Issue resolved! The cache is cleared and correct screen is displaying.

**If logs don't appear at all:**
→ Navigation isn't happening. Check for errors in console during button press.
