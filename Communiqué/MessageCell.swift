import UIKit

class MessageCell: UITableViewCell {
    static var leftCell: String { return "MessageCellLeft" }
    static var rightCell: String { return "MessageCellRight" }
    static var regularCell: String { return "MessageCell" }

    @IBOutlet var avatarView: UIImageView?
    @IBOutlet var textView: UITextView!

    override func layoutSubviews() {
        super.layoutSubviews()

        if let avatarView = avatarView {
            avatarView.layer.masksToBounds = true
            avatarView.layer.cornerRadius = avatarView.frame.width / 2.0
        }
    }
}
