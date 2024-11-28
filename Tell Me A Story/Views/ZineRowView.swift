import SwiftUI

struct ZineRowView: View {
    let zine: Zine
    
    var body: some View {
        HStack(spacing: 16) {
            CachedAsyncImage(url: zine.coverImageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .foregroundColor(.gray.opacity(0.2))
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            .background(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(zine.name)
                    .font(.system(size: 17, weight: .semibold))
                Text(zine.bio)
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .background(Color.white)
    }
}
