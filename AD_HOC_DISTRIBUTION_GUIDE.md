# Ad Hoc Distribution Guide for ClassMateAI

This guide will walk you through setting up ad hoc distribution for your ClassMateAI iOS app, allowing you to distribute the app to testers without going through the App Store.

## Prerequisites

1. **Apple Developer Account** (Paid membership required)
2. **MacinCloud with Xcode** (You already have this set up)
3. **Physical iOS Device** for testing
4. **Testers' Device UDIDs** (Unique Device Identifiers)

## Step 1: Your Xcode Project is Ready

Since you're using MacinCloud and Xcode opens your ClassMateAI project, your Xcode project is already properly configured. You can skip the project creation steps and go directly to configuration.

## Step 2: Configure Bundle Identifier

1. In your MacinCloud Xcode session, select your project in the navigator
2. Select the `ClassMateAI` target
3. Go to the `General` tab
4. Update the `Bundle Identifier` to something unique (e.g., `com.yourname.ClassMateAI`)

## Step 3: Set Up Code Signing

1. In the same target settings, go to the `Signing & Capabilities` tab
2. Make sure `Automatically manage signing` is checked
3. Select your Team (Apple Developer account)
4. Xcode will automatically create a development certificate and provisioning profile

## Step 4: Collect Device UDIDs

You need the UDIDs of all test devices. Here's how to get them:

### Method 1: Using Xcode in MacinCloud
1. Connect the device to your MacinCloud instance (if possible)
2. In Xcode, go to `Window > Devices and Simulators`
3. Select the device
4. Copy the `Identifier` (this is the UDID)

### Method 2: Using Online Tools (Recommended for MacinCloud)
- Visit https://udid.io/ on the device
- Follow the instructions to get the UDID
- This is often easier when using remote development

### Method 3: Using iTunes (if you have local access)
1. Connect device to computer
2. Open iTunes
3. Click on the device icon
4. Click `Serial Number` until you see the UDID
5. Copy the UDID

## Step 5: Create Ad Hoc Provisioning Profile

1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to `Certificates, Identifiers & Profiles`
3. Select `Profiles` from the left sidebar
4. Click the `+` button to create a new profile
5. Select `Ad Hoc` and click `Continue`
6. Select your App ID and click `Continue`
7. Select your distribution certificate and click `Continue`
8. Select all the devices you want to include and click `Continue`
9. Give your profile a name (e.g., "ClassMateAI Ad Hoc")
10. Click `Generate`
11. Download the provisioning profile

## Step 6: Install Provisioning Profile in Xcode

1. In your MacinCloud Xcode session, go to `Xcode > Preferences > Accounts`
2. Select your Apple ID
3. Click `Download Manual Profiles` or drag the downloaded `.mobileprovision` file into Xcode
4. Go back to your project settings
5. In `Signing & Capabilities`, uncheck `Automatically manage signing`
6. Select your ad hoc provisioning profile from the dropdown

## Step 7: Build for Ad Hoc Distribution

1. In Xcode, select `Product > Archive`
2. Wait for the archive to complete
3. In the Organizer window, select your archive
4. Click `Distribute App`
5. Select `Ad Hoc` and click `Next`
6. Select your ad hoc provisioning profile and click `Next`
7. Choose a location to save the `.ipa` file
8. Click `Export`

## Step 8: Distribute to Testers

### Option 1: Using TestFlight (Recommended)
1. Upload your `.ipa` to App Store Connect
2. Add testers via email
3. Testers receive an email invitation to download TestFlight
4. They can install and test your app through TestFlight

### Option 2: Using Diawi (Popular third-party service)
1. Sign up for a Diawi account
2. Upload your `.ipa` file
3. Get a download link
4. Share the link with testers
5. Testers can install directly on their devices

### Option 3: Direct Distribution
1. Share the `.ipa` file with testers
2. Testers need to install the app using one of these methods:
   - **iTunes** (older method)
   - **Apple Configurator 2**
   - **Third-party tools** like Diawi, TestFlight, or HockeyApp

## Step 9: Testers Install the App

### For TestFlight:
1. Testers receive an email invitation
2. They download TestFlight from the App Store
3. Accept the invitation in TestFlight
4. Install your app through TestFlight

### For Direct Distribution:
1. Testers need to trust your developer certificate:
   - Go to `Settings > General > VPN & Device Management`
   - Find your developer certificate
   - Tap `Trust [Your Name]`
2. Install the app using the method you chose

## MacinCloud-Specific Considerations

### File Transfer
- Use the file transfer features in MacinCloud to download your `.ipa` file
- You can also use cloud storage services (Dropbox, Google Drive) to share files

### Device Testing
- Since you're using MacinCloud, you'll need to test on physical devices
- Consider using TestFlight for easier distribution and testing

### Performance
- Archive builds might take longer in MacinCloud
- Consider building during off-peak hours

## Troubleshooting

### Common Issues:

1. **"Untrusted Developer" Error**
   - Go to `Settings > General > VPN & Device Management`
   - Trust your developer certificate

2. **"App Cannot Be Installed" Error**
   - Check that the device UDID is included in the provisioning profile
   - Verify the bundle identifier matches
   - Ensure the provisioning profile is valid and not expired

3. **Code Signing Errors**
   - Check that your certificates are valid
   - Verify the provisioning profile includes the correct devices
   - Make sure the bundle identifier matches

4. **Archive Fails**
   - Clean the build folder (`Product > Clean Build Folder`)
   - Check for any compilation errors
   - Verify all required files are included in the project

5. **MacinCloud-Specific Issues**
   - Ensure you have sufficient storage space
   - Check your MacinCloud session hasn't timed out
   - Restart Xcode if needed

## Best Practices

1. **Keep UDIDs Updated**: Regularly update your provisioning profile with new device UDIDs
2. **Version Management**: Use semantic versioning for your app versions
3. **Testing Checklist**: Create a testing checklist for your testers
4. **Feedback Collection**: Set up a system to collect feedback from testers
5. **Regular Updates**: Plan regular updates to keep testers engaged
6. **MacinCloud Sessions**: Save your work frequently and be mindful of session timeouts

## Alternative Distribution Methods

### TestFlight (Recommended for MacinCloud users)
- Free with Apple Developer account
- Easy to manage testers
- Automatic updates
- Built-in crash reporting
- Works well with remote development setups

### Enterprise Distribution
- For internal company use
- Requires Enterprise Developer account
- No device limit
- Cannot be distributed publicly

### App Store
- For public distribution
- Requires App Store review
- Available to all users
- Automatic updates

## Next Steps

Once you have ad hoc distribution set up:

1. **Test thoroughly** on multiple devices
2. **Collect feedback** from testers
3. **Iterate and improve** based on feedback
4. **Prepare for App Store submission** when ready

## Support

If you encounter issues:
1. Check Apple's [Developer Documentation](https://developer.apple.com/documentation/)
2. Visit [Apple Developer Forums](https://developer.apple.com/forums/)
3. Contact Apple Developer Support if needed
4. Check MacinCloud support for platform-specific issues

---

**Note**: This guide assumes you have a paid Apple Developer account. Ad hoc distribution is not available with free developer accounts. 