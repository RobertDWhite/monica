import SwiftUI

struct ContactAvatarView: View {
    let avatar: ContactAvatar?
    let size: CGFloat

    var body: some View {
        Group {
            if let avatar, avatar.type == "url", let url = URL(string: avatar.content) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }

    private var placeholder: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .foregroundStyle(.secondary)
    }
}
