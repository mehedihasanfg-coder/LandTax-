# SOFTLAND Land Development Tax Calculator — iOS SwiftUI Project

This Xcode project implements the supplied screenshot's green-and-white, Bengali, card-based layout.

## Open and run
1. Extract the ZIP on a Mac with Xcode installed.
2. Open `SOFTLANDLandTax.xcodeproj`.
3. Select an iPhone simulator (or connect your iPhone).
4. In Signing & Capabilities, select your Apple developer Team if installing on a physical device.
5. Press Run.

Deployment target: iOS 16.0+

## Implemented
- Bengali UI and matching green/white visual hierarchy.
- Area inputs: Nal (Krishi-2), Residential, Commercial/Industrial.
- Auto total area and annual demand using configured rates: ৳2, ৳10, ৳50 per decimal.
- Last paid year selector from 1910 through current fiscal year.
- Selecting 1943 treats FY 1943-44 as paid; arrears begin 1 July 1944.
- Current fiscal year is always shown separately as current demand.
- Completed unpaid fiscal years are split into the latest up to three years and older years.
- Read-only arrears and penalty outputs.
- Clear resets all fields and selects current fiscal year.
- No persistence, history, database, PDF, print, or sharing.

## Calculation convention currently implemented
- Current FY starts on 1 July. The app detects the current fiscal year from the device date.
- Selecting year Y means FY Y-(Y+1) is paid; arrears begin 1 July Y+1.
- Only completed prior fiscal years are counted as arrears; current FY is a separate one-year current demand.
- Penalty is a provisional estimate: 6.25% simple interest on each completed unpaid fiscal year's annual principal, multiplied by the number of years from that fiscal year to the current fiscal-year start. Current FY is excluded.
- The rates are user-configured approximate rates, not verified official government rates.

## Important
The screenshot's sample figures and year split contained arithmetic inconsistencies. This project follows the agreed fiscal-year logic rather than reproducing those incorrect numbers. For example, with the current FY 2026-27 and last paid year 1943:
- current demand: 1 year (2026-27)
- completed arrears: 82 years (1944-45 through 2025-26)
- latest-three arrears: 3 years (2023-24 through 2025-26)
- older arrears: 79 years (1944-45 through 2022-23)

The 6.25% penalty method still needs confirmation against the applicable local Dakhila calculation before this app is used to estimate an official payable amount.

This environment cannot run Xcode or produce a signed iOS `.ipa`. The project source is prepared, but compilation, simulator QA, device installation, and signing must be completed in Xcode on macOS.
