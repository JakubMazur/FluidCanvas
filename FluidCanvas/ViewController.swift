//
//  ViewController.swift
//  FluidCanvas
//
//  Created by Jakub Mazur on 11/12/2022.
//

import Cocoa
import StableDiffusion
import SnapKit
import CoreML

class ViewController: NSViewController {
	
	private let gridView: GridView = .init(rows: 2, columns: 2)
	private let textView: NSTextView = .init(frame: .zero)
	private lazy var button: NSButton = .init(title: "Generate", target: self, action: #selector(self.buttonTapped(_:)))
	
	private let pipeline: StableDiffusionPipeline = {
		let url = Bundle.main.resourceURL!.appending(path: "models")
		let config = MLModelConfiguration()
		config.modelDisplayName = "Testable"
		config.computeUnits = .all
		let pipeline = try! StableDiffusionPipeline(resourcesAt: url, configuration: config, disableSafety: false)
		return pipeline
	}()

	override func viewDidLoad() {
		super.viewDidLoad()
		self.arrangeSubviews()
	}
	
	private func prepareStableDiffusion() {
		do {
			let images = try pipeline.generateImages(prompt: self.textView.string, imageCount: 4, stepCount: 25, seed: Int.random(in: 0...100_000_00), disableSafety: false).compactMap { $0 }
			self.gridView.flush()
			self.gridView.append(images: images.map { NSImage(cgImage: $0, size: .init(width: gridView.frame.width/2, height: gridView.frame.height/2))})
		} catch {
			print(error)
		}
	}
		
	private func arrangeSubviews() {
		self.view.addSubview(self.gridView)
		self.view.addSubview(self.textView)
		self.view.addSubview(self.button)
		self.gridView.snp.makeConstraints { make in
			make.top.leading.trailing.equalToSuperview()
			make.height.equalTo(self.gridView.snp.width)
		}
		self.textView.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview()
			make.top.equalTo(self.gridView.snp.bottom).offset(8)
		}
		self.button.snp.makeConstraints { make in
			make.leading.trailing.equalToSuperview()
			make.top.equalTo(self.textView.snp.bottom).offset(8)
			make.bottom.equalToSuperview()
		}
		self.textView.string = ""
	}

	@objc private func buttonTapped(_ sender: NSButton) {
		self.prepareStableDiffusion()
	}


}

final class GridView: NSView {
	private let rows: Int
	private let columns: Int
	private lazy var stackViews: [NSStackView] = {
		(0...rows).map { _ in
			let stackView: NSStackView = .init(frame: .zero)
			stackView.distribution = .equalSpacing
			stackView.alignment = .centerX
			stackView.orientation = .horizontal
			stackView.spacing = 8
			return stackView
		}
	}()
	
	init(rows: Int, columns: Int) {
		self.rows = rows
		self.columns = columns
		super.init(frame: .zero)
	}
	
	required init?(coder: NSCoder) { return nil }
	
	override func viewDidMoveToSuperview() {
		super.viewDidMoveToSuperview()
		self.stackViews.enumerated().forEach { (index, view) in
			view.wantsLayer = true
			self.addSubview(view)
			view.snp.makeConstraints { make in
				if index == 0 {
					make.top.leading.trailing.equalToSuperview().inset(8)
				} else {
					make.top.equalTo(stackViews[index - 1].snp.bottom).offset(8)
					make.leading.trailing.equalToSuperview().inset(8)
				}
				if index == (stackViews.count - 1) {
					make.bottom.equalToSuperview()
				}
			}
		}
	}
	
	func flush() {
		self.stackViews.forEach { view in
			view.arrangedSubviews.forEach { subview in
				view.removeArrangedSubview(subview)
				subview.removeFromSuperview()
			}
		}
	}
	
	func append(images: [NSImage]) {
		images.forEach { self.append(image: $0) }
	}
		
	func append(image: NSImage) {
		guard let stackView = self.stackViews.first(where: { view in view.arrangedSubviews.count < columns }) else { return }
		stackView.addArrangedSubview(NSImageView(image: image))
	}
}
