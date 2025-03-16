//
//  unihack.swift
//  unihack
//
//  Created by Trang Nguyễn on 16/3/2025.
//

import WidgetKit
import SwiftUI
import Intents

// Data structure for the widget
struct RecentPostWidgetEntry: TimelineEntry {
    let date: Date
    let postData: PostData?
    
    // Default entry for placeholder
    static let placeholder = RecentPostWidgetEntry(
        date: Date(),
        postData: PostData(
            hasData: true,
            imageUrl: "",
            description: "Latest photo caption will appear here",
            authorName: "Username",
            authorImage: "",
            date: "MM/DD/YYYY"
        )
    )
}

// Post data model
struct PostData: Codable {
    let hasData: Bool
    let imageUrl: String
    let description: String
    let authorName: String
    let authorImage: String
    let date: String
    var message: String?
}

// Provider to load data for the widget
struct Provider: TimelineProvider {
    // App group ID must match what's configured in Flutter
    let appGroupId = "group.com.unihack.widget"
    
    // Placeholder for widget gallery
    func placeholder(in context: Context) -> RecentPostWidgetEntry {
        return RecentPostWidgetEntry.placeholder
    }
    
    // Preview snapshot for widget gallery
    func getSnapshot(in context: Context, completion: @escaping (RecentPostWidgetEntry) -> Void) {
        let entry = RecentPostWidgetEntry.placeholder
        completion(entry)
    }
    
    // Actual data loading
    func getTimeline(in context: Context, completion: @escaping (Timeline<RecentPostWidgetEntry>) -> Void) {
        let userDefaults = UserDefaults(suiteName: appGroupId)
        
        var entry: RecentPostWidgetEntry
        
        // Try to load post data from shared user defaults
        if let postDataString = userDefaults?.string(forKey: "post_data"),
           let postDataData = postDataString.data(using: .utf8) {
            do {
                let postData = try JSONDecoder().decode(PostData.self, from: postDataData)
                entry = RecentPostWidgetEntry(date: Date(), postData: postData)
            } catch {
                print("Error decoding post data: \(error)")
                entry = RecentPostWidgetEntry(
                    date: Date(),
                    postData: PostData(
                        hasData: false,
                        imageUrl: "",
                        description: "",
                        authorName: "",
                        authorImage: "",
                        date: "",
                        message: "Error loading data"
                    )
                )
            }
        } else {
            // No data available
            entry = RecentPostWidgetEntry(
                date: Date(),
                postData: PostData(
                    hasData: false,
                    imageUrl: "",
                    description: "",
                    authorName: "",
                    authorImage: "",
                    date: "",
                    message: "No data available"
                )
            )
        }
        
        // Update again in 1 hour
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
}

// Small widget view
struct SmallWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let postData = entry.postData, postData.hasData {
                // Background image
                if !postData.imageUrl.isEmpty {
                    AsyncImage(url: URL(string: postData.imageUrl)) { phase in
                        switch phase {
                        case .empty:
                            Color.gray.opacity(0.3)
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            Color.gray.opacity(0.3)
                        @unknown default:
                            Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color.gray.opacity(0.3)
                }
                
                // Gradient overlay for better text visibility
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                
                // Author info at the bottom
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        // Profile picture
                        if !postData.authorImage.isEmpty {
                            AsyncImage(url: URL(string: postData.authorImage)) { phase in
                                switch phase {
                                case .empty:
                                    Circle().fill(Color.gray)
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    Circle().fill(Color.gray)
                                @unknown default:
                                    Circle().fill(Color.gray)
                                }
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 28, height: 28)
                        }
                        
                        // Author name
                        Text(postData.authorName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    // Date
                    Text(postData.date)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
            } else {
                // No data state
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                    
                    Text(entry.postData?.message ?? "No recent posts")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// Medium widget view
struct MediumWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let postData = entry.postData, postData.hasData {
            HStack(spacing: 0) {
                // Image part (left side)
                AsyncImage(url: URL(string: postData.imageUrl)) { phase in
                    switch phase {
                    case .empty:
                        Color.gray.opacity(0.3)
                    case .success(let image):
                        image.resizable().aspectRatio(contentMode: .fill)
                    case .failure:
                        Color.gray.opacity(0.3)
                    @unknown default:
                        Color.gray.opacity(0.3)
                    }
                }
                .frame(width: UIScreen.main.bounds.width * 0.3)
                .clipped()
                
                // Info part (right side)
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        // Profile picture
                        if !postData.authorImage.isEmpty {
                            AsyncImage(url: URL(string: postData.authorImage)) { phase in
                                switch phase {
                                case .empty:
                                    Circle().fill(Color.gray)
                                case .success(let image):
                                    image.resizable().aspectRatio(contentMode: .fill)
                                case .failure:
                                    Circle().fill(Color.gray)
                                @unknown default:
                                    Circle().fill(Color.gray)
                                }
                            }
                            .frame(width: 28, height: 28)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 28, height: 28)
                        }
                        
                        // Author name
                        Text(postData.authorName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                    }
                    
                    // Date
                    Text(postData.date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    // Description
                    Text(postData.description)
                        .font(.caption)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        } else {
            // No data state
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.title)
                    .foregroundColor(.gray)
                
                Text(entry.postData?.message ?? "No recent posts")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Main widget view that handles different sizes
struct RecentPostWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: Provider.Entry
    
    var body: some View {
        VStack {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                // For large widget, we can use a similar layout to medium but with more content
                VStack(spacing: 0) {
                    // Use medium widget layout on top
                    MediumWidgetView(entry: entry)
                    
                    // Add more posts or info below if needed
                    if let postData = entry.postData, postData.hasData {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Description")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 16)
                                .padding(.top, 12)
                            
                            Text(postData.description)
                                .font(.body)
                                .padding(.horizontal, 16)
                                .padding(.bottom, 16)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            @unknown default:
                MediumWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            Color(UIColor.systemBackground)
        }
    }
}

struct unihack: Widget {
    let kind: String = "RecentPostWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RecentPostWidgetEntryView(entry: entry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .widgetURL(URL(string: "unihack://widget/open"))
        }
        .configurationDisplayName("Recent Post")
        .description("Shows your most recent post")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Preview for SwiftUI canvas
struct RecentPostWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RecentPostWidgetEntryView(entry: RecentPostWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            RecentPostWidgetEntryView(entry: RecentPostWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            RecentPostWidgetEntryView(entry: RecentPostWidgetEntry.placeholder)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}