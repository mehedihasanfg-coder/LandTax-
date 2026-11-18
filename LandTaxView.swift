import SwiftUI

@main
struct SOFTLANDLandTaxApp: App {
    var body: some Scene {
        WindowGroup {
            LandTaxView()
        }
    }
}

struct LandTaxView: View {
    @State private var nalText = "20"
    @State private var residentialText = "10"
    @State private var commercialText = "5"
    @State private var selectedPaidYear = 1943

    private let nalRate = 2.0
    private let residentialRate = 10.0
    private let commercialRate = 50.0
    private let industrialRate = 50.0
    private let penaltyRate = 0.0625

    private var currentFYStart: Int {
        let date = Date()
        let year = Calendar.current.component(.year, from: date)
        let month = Calendar.current.component(.month, from: date)
        return month >= 7 ? year : year - 1
    }

    private var nalArea: Double { number(nalText) }
    private var residentialArea: Double { number(residentialText) }
    private var commercialArea: Double { number(commercialText) }
    private var totalArea: Double { nalArea + residentialArea + commercialArea }

    // Union Parishad rates supplied by the user; these are configurable estimates.
    private var annualDemand: Double {
        nalArea * nalRate +
        residentialArea * residentialRate +
        commercialArea * commercialRate
    }

    // Selecting 1943 means FY 1943-44 was paid. Arrears start 1 July 1944.
    private var firstUnpaidFY: Int { selectedPaidYear + 1 }
    // All completed unpaid fiscal years only. The current FY is always separate.
    private var arrearsYears: Int { max(0, currentFYStart - firstUnpaidFY) }
    private var recentArrearsYears: Int { min(3, arrearsYears) }
    private var olderArrearsYears: Int { max(0, arrearsYears - 3) }

    private var recentArrears: Double { annualDemand * Double(recentArrearsYears) }
    private var olderArrears: Double { annualDemand * Double(olderArrearsYears) }

    // Provisional user-requested estimate: 6.25% simple interest for each
    // completed unpaid fiscal year, weighted by its age. Current FY excluded.
    private var penalty: Double {
        guard arrearsYears > 0 else { return 0 }
        let ageSum = (0..<arrearsYears).reduce(0) { partial, offset in
            partial + (currentFYStart - (firstUnpaidFY + offset))
        }
        return annualDemand * penaltyRate * Double(ageSum)
    }

    private var totalDemand: Double {
        annualDemand + recentArrears + olderArrears + penalty
    }

    private var currentFYLabel: String { fiscalLabel(currentFYStart) }
    private var paidFYLabel: String { fiscalLabel(selectedPaidYear) }

    private var recentRangeLabel: String {
        guard recentArrearsYears > 0 else { return "কোনো বকেয়া নেই" }
        let start = currentFYStart - recentArrearsYears
        let end = currentFYStart - 1
        return "\(fiscalLabel(start)) থেকে \(fiscalLabel(end))"
    }

    private var olderRangeLabel: String {
        guard olderArrearsYears > 0 else { return "কোনো বকেয়া নেই" }
        return "\(fiscalLabel(firstUnpaidFY)) থেকে \(fiscalLabel(currentFYStart - recentArrearsYears - 1))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 9) {
                header

                section(title: "জমির পরিমাণ লিখুন", icon: "person.crop.circle.fill") {
                    Text("সকল দাগের একই শ্রেণির জমি একত্র করে শতাংশে লিখুন।")
                        .font(.system(size: 13)).foregroundStyle(.secondary)
                    areaInput("নাল জমি (কৃষি২)", value: $nalText, icon: "leaf.fill")
                    areaInput("আবাসিক জমি", value: $residentialText, icon: "house.fill")
                    areaInput("বাণিজ্যিক / শিল্প জমি", value: $commercialText, icon: "building.2.fill")
                    HStack {
                        Text("মোট জমির পরিমাণ").fontWeight(.bold)
                        Spacer()
                        Text("\(totalArea, specifier: "%.2f") শতাংশ")
                            .fontWeight(.bold).foregroundStyle(Color(red: 0.04, green: 0.40, blue: 0.16))
                    }
                    .padding(.vertical, 8).padding(.horizontal, 11)
                    .background(Color.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.green.opacity(0.35)))
                }

                section(title: "সর্বশেষ কর পরিশোধের বছর", icon: "calendar") {
                    Picker("সর্বশেষ কর পরিশোধের বছর", selection: $selectedPaidYear) {
                        ForEach(1910...currentFYStart, id: \.self) { year in
                            Text(String(year)).tag(year)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12).padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 9))
                    Text("আপনি \(paidFYLabel) অর্থবছরের কর পরিশোধ করেছেন বলে ধরা হয়েছে।")
                        .font(.system(size: 13))
                    Text("বকেয়া হিসাব শুরু: ১ জুলাই \(selectedPaidYear + 1)")
                        .font(.system(size: 13, weight: .semibold)).foregroundStyle(.blue)
                }

                section(title: "এলাকার ধরন ও করের হার", icon: "chart.bar.fill") {
                    HStack {
                        Text("এলাকার ধরন").font(.system(size: 14))
                        Spacer()
                        Text("ইউনিয়ন পরিষদ")
                            .padding(.vertical, 8).padding(.horizontal, 12)
                            .frame(width: 205, alignment: .leading)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    }
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 4), spacing: 7) {
                        rateTile("নাল (কৃষি২)", nalRate)
                        rateTile("আবাসিক", residentialRate)
                        rateTile("বাণিজ্যিক", commercialRate)
                        rateTile("শিল্প", industrialRate)
                    }
                    Text("হারগুলো আপনার নির্ধারিত আনুমানিক হার।")
                        .font(.system(size: 12)).foregroundStyle(.red)
                }

                section(title: "বকেয়ার বিবরণ (স্বয়ংক্রিয় হিসাব)", icon: "calculator") {
                    VStack(alignment: .leading, spacing: 7) {
                        infoLine("নির্বাচিত বছর", "\(paidFYLabel)")
                        infoLine("বকেয়া হিসাব শুরু", "১ জুলাই \(selectedPaidYear + 1)")
                        infoLine("বর্তমান অর্থবছর", "\(currentFYLabel) (চলমান)")
                        infoLine("মোট বকেয়া অর্থবছর", "\(arrearsYears) বছর")
                        Divider()
                        infoLine("হাল দাবি (বর্তমান)", "১ বছর (\(currentFYLabel))", highlight: true)
                        infoLine("গত তিন বছরের বকেয়া", "\(recentArrearsYears) বছর (\(recentRangeLabel))")
                        infoLine("তিন বছরের ঊর্ধ্বে বকেয়া", "\(olderArrearsYears) বছর (\(olderRangeLabel))")
                    }
                    .padding(10)
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.blue.opacity(0.45)))
                }

                section(title: "হিসাবের ফলাফল", icon: "square.stack.3d.up.fill") {
                    resultLine("১। হাল দাবি (\(currentFYLabel), ১ বছর)", annualDemand)
                    resultLine("২। গত তিন বছরের বকেয়া (\(recentArrearsYears) বছর)", recentArrears)
                    resultLine("৩। তিন বছরের ঊর্ধ্বে বকেয়া (\(olderArrearsYears) বছর)", olderArrears)
                    resultLine("৪। বকেয়ার জরিমানা ও ক্ষতিপূরণ", penalty)
                    HStack {
                        Text("৫। সর্বমোট দাবি (১+২+৩+৪)")
                            .font(.system(size: 16, weight: .bold))
                        Spacer(minLength: 4)
                        Text(money(totalDemand))
                            .font(.system(size: 22, weight: .heavy))
                            .foregroundStyle(Color(red: 0.02, green: 0.39, blue: 0.14))
                    }
                    .padding(10)
                    .background(Color.green.opacity(0.09), in: RoundedRectangle(cornerRadius: 9))
                    .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.green.opacity(0.55)))
                }

                Button(action: clear) {
                    Label("Clear / মুছে ফেলুন", systemImage: "arrow.clockwise")
                        .font(.system(size: 18, weight: .bold))
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .foregroundStyle(.white)
                        .background(Color(red: 0.02, green: 0.48, blue: 0.17), in: RoundedRectangle(cornerRadius: 11))
                }
                Text("এই অ্যাপ কোনো তথ্য সংরক্ষণ করে না। Clear চাপলে সব ইনপুট মুছে যাবে।")
                    .font(.system(size: 11)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Text("এটি সরকারি হিসাবের বিকল্প নয়।")
                    .font(.system(size: 12, weight: .bold)).foregroundStyle(.red)
            }
            .padding(.horizontal, 10)
            .padding(.top, 7)
            .padding(.bottom, 16)
        }
        .background(Color(red: 0.96, green: 0.97, blue: 0.96))
        .preferredColorScheme(.light)
    }

    private var header: some View {
        VStack(spacing: 3) {
            HStack(spacing: 10) {
                Image(systemName: "house.and.flag.fill")
                    .font(.system(size: 35, weight: .medium))
                    .foregroundStyle(Color(red: 0.83, green: 0.94, blue: 0.34))
                VStack(spacing: 4) {
                    Text("ভূমি উন্নয়ন করের (আনুমানিক) হিসাব")
                        .font(.system(size: 22, weight: .heavy))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                    Text("খতিয়ানভিত্তিক ভূমি কর নির্ণয়")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.yellow)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 17)
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.01, green: 0.31, blue: 0.13))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func section<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Color(red: 0.03, green: 0.40, blue: 0.16))
            content()
        }
        .padding(11)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 13))
        .overlay(RoundedRectangle(cornerRadius: 13).stroke(Color.gray.opacity(0.24)))
    }

    private func areaInput(_ title: String, value: Binding<String>, icon: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon).foregroundStyle(.green).frame(width: 22)
            Text(title).font(.system(size: 14, weight: .medium))
            Spacer(minLength: 3)
            TextField("0", text: value)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.leading)
                .font(.system(size: 15))
                .padding(.horizontal, 9).padding(.vertical, 8)
                .frame(width: 104)
                .background(.white, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.35)))
            Text("শতাংশ").font(.system(size: 12))
        }
    }

    private func rateTile(_ title: String, _ rate: Double) -> some View {
        VStack(spacing: 4) {
            Text(title).font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.7)
            Text("৳ \(Int(rate))").font(.system(size: 20, weight: .heavy))
            Text("প্রতি শতাংশ").font(.system(size: 10))
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
        .background(Color(red: 0.94, green: 0.97, blue: 0.91), in: RoundedRectangle(cornerRadius: 9))
        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.green.opacity(0.3)))
    }

    private func infoLine(_ title: String, _ value: String, highlight: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text("• \(title):").font(.system(size: 12, weight: .medium))
            Spacer(minLength: 3)
            Text(value).font(.system(size: 12, weight: highlight ? .bold : .medium))
                .foregroundStyle(highlight ? .green : .blue)
                .multilineTextAlignment(.trailing)
        }
    }

    private func resultLine(_ title: String, _ amount: Double) -> some View {
        HStack(spacing: 5) {
            Text(title).font(.system(size: 12, weight: .semibold))
            Spacer(minLength: 3)
            Text(money(amount)).font(.system(size: 15, weight: .bold)).foregroundStyle(.blue)
        }
        .padding(.vertical, 7)
        .overlay(alignment: .bottom) { Rectangle().fill(Color.gray.opacity(0.2)).frame(height: 1) }
    }

    private func number(_ text: String) -> Double {
        let normalized = text
            .replacingOccurrences(of: "০", with: "0")
            .replacingOccurrences(of: "১", with: "1")
            .replacingOccurrences(of: "২", with: "2")
            .replacingOccurrences(of: "৩", with: "3")
            .replacingOccurrences(of: "৪", with: "4")
            .replacingOccurrences(of: "৫", with: "5")
            .replacingOccurrences(of: "৬", with: "6")
            .replacingOccurrences(of: "৭", with: "7")
            .replacingOccurrences(of: "৮", with: "8")
            .replacingOccurrences(of: "৯", with: "9")
            .replacingOccurrences(of: ",", with: ".")
        return max(0, Double(normalized) ?? 0)
    }

    private func money(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return "৳ " + (formatter.string(from: NSNumber(value: amount)) ?? "0")
    }

    private func fiscalLabel(_ start: Int) -> String {
        "\(start)-\(String(format: "%02d", (start + 1) % 100))"
    }

    private func clear() {
        nalText = ""
        residentialText = ""
        commercialText = ""
        selectedPaidYear = currentFYStart
    }
}
