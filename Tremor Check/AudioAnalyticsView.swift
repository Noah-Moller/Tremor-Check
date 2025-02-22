import SwiftUI
import SwiftData
import Charts

//MARK: - AudioAnalyticsView
///Displays the trends and analytics of the users previous tests

struct AudioAnalyticsView: View {
    @Binding var selectedTab: Int
    @Query(sort: \TremorCheck.date, order: .reverse) var tremorChecks: [TremorCheck]
    @State private var selectedTimeRange: TimeRange = .month
    @State private var selectedTest: TremorCheck?
    @State private var showingShareSheet = false
    @State private var pdfData: Data?
    
    @State private var animatePicker = false
    @State private var animateTrends = false
    @State private var animateHistory = false

    @State private var showAlert = false
    @State private var alertMessage = ""
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
        
        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            case .year: return 365
            }
        }
    }
    
    //An array that stores the users previous Tremor Checks within the data range.
    var filteredChecks: [TremorCheck] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -selectedTimeRange.days, to: Date())!
        return tremorChecks.filter { $0.date >= cutoffDate }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        Picker("Time Range", selection: $selectedTimeRange) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                Text(range.rawValue).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .opacity(animatePicker ? 1 : 0)
                        .scaleEffect(animatePicker ? 1 : 0.9)
                        .offset(y: animatePicker ? 0 : 20)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Trends")
                                .font(.title2.bold())
                            
                            //Displays the trends from the passed in metric.
                            TrendCard(
                                title: "Hand Stability Score",
                                data: filteredChecks,
                                value: { $0.shakeAssessment ?? 0 },
                                format: "%.1f",
                                unit: ""
                            )
                            
                            TrendCard(
                                title: "Voice Jitter",
                                data: filteredChecks.filter { !$0.voiceAssessment.results.isEmpty },
                                value: { $0.voiceAssessment.averageJitter },
                                format: "%.2f",
                                unit: "%"
                            )
                            
                            TrendCard(
                                title: "Voice Shimmer",
                                data: filteredChecks.filter { !$0.voiceAssessment.results.isEmpty },
                                value: { $0.voiceAssessment.averageShimmer },
                                format: "%.2f",
                                unit: "%"
                            )
                        }
                        .padding(.horizontal)
                        .opacity(animateTrends ? 1 : 0)
                        .scaleEffect(animateTrends ? 1 : 0.95)
                        .offset(y: animateTrends ? 0 : 20)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Test History")
                                .font(.title2.bold())
                                .padding(.horizontal)
                            
                            ForEach(filteredChecks) { check in
                                TestHistoryCard(check: check)
                                    .onTapGesture {
                                        selectedTest = check
                                    }
                            }
                            .padding(.horizontal)
                        }
                        .opacity(animateHistory ? 1 : 0)
                        .scaleEffect(animateHistory ? 1 : 0.95)
                        .offset(y: animateHistory ? 0 : 20)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
                Button(action: exportPDF) {
                    Label("Export Report", systemImage: "square.and.arrow.up")
                }
                .transition(.opacity)
                
                NavigationLink("View Your Voice Box") {
                    ViewVoiceBoxView(latestCheck: filteredChecks)
                }
            }
            .fullScreenCover(item: $selectedTest) { check in
                NavigationStack {
                    ResultsView(selectedCheck: check, selectedTab: $selectedTab, isSheet: true) {
                        
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let data = pdfData {
                    ShareSheet(activityItems: [data], isPresented: $showingShareSheet)
                } else {
                    Text("Please dismiss and try again.")
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animatePicker = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animateTrends = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    withAnimation(.spring(response: 0.7, dampingFraction: 0.7, blendDuration: 0.2)) {
                        animateHistory = true
                    }
                }
            }
        }
        .onAppear() {
            print("ALL TREMOR CHECKS: \(tremorChecks)")
        }
    }
    
    private func exportPDF() {
        let page1 = TremorReportPage1(checks: filteredChecks)
        let page2 = TremorReportPage2(checks: filteredChecks)

        let anyPage1 = AnyView(page1)
        let anyPage2 = AnyView(page2)

        PDFGenerator.generateMultiPagePDF(from: [anyPage1, anyPage2]) { data in
            if let data = data {
                self.pdfData = data
                self.showingShareSheet = true
            } else {
                self.alertMessage = "Failed to generate PDF. Please try again."
                self.showAlert = true
            }
        }
    }

    struct TrendCard: View {
        let title: String
        let data: [TremorCheck]
        let value: (TremorCheck) -> Double
        let format: String
        let unit: String
        
        @State private var appear = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .font(.headline)
                
                if data.isEmpty {
                    Text("No data available")
                        .foregroundColor(.secondary)
                        .padding()
                } else {
                    Chart {
                        ForEach(data) { item in
                            LineMark(
                                x: .value("Date", item.date),
                                y: .value("Value", value(item))
                            )
                            .foregroundStyle(.blue)
                            
                            PointMark(
                                x: .value("Date", item.date),
                                y: .value("Value", value(item))
                            )
                            .foregroundStyle(.blue)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(date.formatted(.dateTime.month().day()))
                                }
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                    appear = true
                }
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.95)
            .offset(y: appear ? 0 : 10)
        }
    }

    struct TestHistoryCard: View {
        let check: TremorCheck
        @State private var appear = false
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    if check.isDemoData {
                        Text("\(check.date.formatted(date: .abbreviated, time: .shortened)) (Demo Data)")
                            .font(.headline)
                    }else {
                        Text(check.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 20) {
                    if let shakeAssessment = check.shakeAssessment {
                        VStack(alignment: .leading) {
                            Text("Stability")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", shakeAssessment))
                                .font(.title3.bold())
                        }
                    }
                    
                    if !check.voiceAssessment.results.isEmpty {
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading) {
                            Text("Jitter")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f%%", check.voiceAssessment.averageJitter))
                                .font(.title3.bold())
                        }
                        
                        Divider()
                            .frame(height: 40)
                        
                        VStack(alignment: .leading) {
                            Text("Shimmer")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f%%", check.voiceAssessment.averageShimmer))
                                .font(.title3.bold())
                        }
                    }
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
            .onAppear {
                withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.4)) {
                    appear = true
                }
            }
            .opacity(appear ? 1 : 0)
            .scaleEffect(appear ? 1 : 0.95)
            .offset(y: appear ? 0 : 10)
        }
    }
}
