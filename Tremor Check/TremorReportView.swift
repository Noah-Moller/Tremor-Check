import SwiftUI
import Charts

struct TremorReportPage1: View {
    let checks: [TremorCheck]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("Tremor Assessment Report")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)

            Text("Report generated on \(Date().formatted(date: .long, time: .shortened))")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 20)

            summarySection

            trendsSection
            
            Spacer()
        }
        .padding()
        .background() {
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .frame(width: 595.2, height: 841.8)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.title2.bold())
            
            Text("""
            This report includes tremor assessment data from \(checks.count) tests conducted between \(checks.last?.date.formatted(date: .long, time: .shortened) ?? "N/A") and \(checks.first?.date.formatted(date: .long, time: .shortened) ?? "N/A"). The assessments evaluate both hand stability and voice characteristics to monitor Parkinson's symptoms.
            """)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trends")
                .font(.title2.bold())

            TrendCardPDF(
                title: "Hand Stability Score",
                data: checks,
                value: { $0.shakeAssessment ?? 0.00 },
                format: "%.1f",
                unit: "",
                chartHeight: 150
            )

            TrendCardPDF(
                title: "Voice Jitter",
                data: checks.filter { !$0.voiceAssessment.results.isEmpty },
                value: { $0.voiceAssessment.averageJitter },
                format: "%.2f",
                unit: "%",
                chartHeight: 150
            )
            
        }
    }
}

struct TremorReportPage2: View {
    let checks: [TremorCheck]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TrendCardPDF(
                title: "Voice Shimmer",
                data: checks.filter { !$0.voiceAssessment.results.isEmpty },
                value: { $0.voiceAssessment.averageShimmer },
                format: "%.2f",
                unit: "%",
                chartHeight: 150
            )

            Text("Test History")
                .font(.largeTitle.bold())
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
            
            testHistorySection
            
            Spacer()
        }
        .padding()
        .background() {
            LinearGradient(
                gradient: Gradient(colors: [.purple.opacity(0.3), .blue.opacity(0.3)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        }
        .frame(width: 595.2, height: 841.8)
    }

    private var testHistorySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(checks) { check in
                TestHistoryCardPDF(check: check)
            }
        }
    }
}

struct TrendCardPDF: View {
    let title: String
    let data: [TremorCheck]
    let value: (TremorCheck) -> Double
    let format: String
    let unit: String
    let chartHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
            
            if data.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
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
                .frame(height: chartHeight)
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
    }
}

struct TestHistoryCardPDF: View {
    let check: TremorCheck
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(check.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.headline)
                Spacer()
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Stability")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f", check.shakeAssessment ?? 0))
                        .font(.title3.bold())
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
    }
}
