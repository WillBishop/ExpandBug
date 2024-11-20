//
//  ViewController.swift
//  ExpandBug
//
//  Created by Will Bishop on 20/11/2024.
//

import UIKit
import SwiftUI
import Combine

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let button = UIButton(type: .system)
        button.setTitle("Show Modal", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
        ])
        button.addTarget(self, action: #selector(showModal), for: .touchUpInside)
    }
    
    @objc func showModal() {
        self.present(BottomSheet(content: BugView()), animated: true)
    }
    
}


@available(iOS 15.0, *)
struct BugView: View {
    
    @EnvironmentObject var model: BottomSheetModel
    
    var body: some View {
        VStack {
            Text(String(describing: model.expanded))
            Button {
                model.expanded.toggle()
            } label: {
                Text("Toggle")
            }
        }
    }
}

@available(iOS 15.0, *)
public class BottomSheetModel: ObservableObject {
    @Published var size: CGSize = .zero
    
    /// Whether the modal is self-sizing or expanded to fill the vertical height of the screen
    @Published var expanded: Bool = false
}

@available(iOS 16.0, *)
class BottomSheet<T: View>: UIViewController {
    
    private let hostController: UIHostingController<Modal<T>>
    private let model = BottomSheetModel()
    private var cancellables: [AnyCancellable] = []
    
    init(content: T) {
        self.hostController = UIHostingController(rootView: Modal(model: self.model, content: content))
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        self.view.addSubview(hostController.view)
        hostController.view.backgroundColor = .clear
        hostController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])
        hostController.didMove(toParent: self)
        
        self.model.$size.sink { [weak self] size in
            self?.sizeDidChange(size)
        }.store(in: &cancellables)

        self.model.$expanded.sink { [weak self] expanded in
            self?.setExpanded(expanded)
        }.store(in: &cancellables)
    }
    
    private func sizeDidChange(_ size: CGSize) {
        guard !model.expanded else {
            self.sheetPresentationController?.detents = [.large()]
            return
        }
        self.sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.detents = [.custom(resolver: { context in
                return size.height
            })]
        }
    }
    
    private func setExpanded(_ expanded: Bool) {
        self.sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.detents = [.large()]
        }
        if !expanded {
            self.sizeDidChange(model.size)
        }
    }
    
    private struct Modal<Content: View>: View {
        
        @ObservedObject var model: BottomSheetModel
        @Environment(\.colorScheme) private var colorScheme
        var content: Content
        
        var body: some View {
            ZStack {
                Rectangle()
                    .fill(.regularMaterial)
                    .foregroundStyle(colorScheme == .dark ? .clear : .white.opacity(0.8))
                    .ignoresSafeArea()
                content
                    .environmentObject(model)
                    .fixedSize(horizontal: false, vertical: !model.expanded)
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear
                                .onAppear {
                                    self.model.size = proxy.size
                                }
                                .onChange(of: proxy.size) { _ in
                                    self.model.size = proxy.size
                                }
                        }
                    }
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
