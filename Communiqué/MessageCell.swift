import UIKit

class MessageCell: UITableViewCell {
	var imageOnLeft: Bool = true

	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)

		imageView?.layer.masksToBounds = true
	}

	required init?(coder aDecoder: NSCoder) { abort() }

	override func layoutSubviews() {
		super.layoutSubviews()

		let imageView = self.imageView!

		if let image = imageView.image {
			var frame = CGRect.zero
			frame.size = image.size

			if imageOnLeft {
				frame.origin = CGPoint.zero
				frame.origin.x += 10.0
			} else {
				frame.origin = CGPoint(x: contentView.frame.width - image.size.width, y: 0.0)
				frame.origin.x -= 10.0
			}

			imageView.frame = frame

			// WARNING: lazy
			var center = imageView.center
			center.y = contentView.center.y
			imageView.center = center

			imageView.layer.cornerRadius = image.size.width / 2.0
		}

		var frame = detailTextLabel!.frame
		frame.size.width = self.frame.width - imageView.frame.width - 30.0

		if imageOnLeft {
			detailTextLabel!.textAlignment = .left

			let imageViewMaxX = imageView.frame.maxX
			if imageViewMaxX > 0.0 {
				frame.origin.x = imageViewMaxX + 10.0
			} else {
				frame.origin.x = 20.0
			}
		} else {
			detailTextLabel!.textAlignment = .right

			frame.origin.x = 10.0
		}

		detailTextLabel!.frame = frame

	}
}
